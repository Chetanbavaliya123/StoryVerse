require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Firebase Admin SDK
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else {
    admin.initializeApp();
  }
} catch (e) {
  console.error("Firebase Admin initialization error:", e.message);
}

const db = admin.firestore();

const app = express();
app.use(cors({ origin: true })); // Allow requests from any origin (Flutter web/mobile)
app.use(express.json({ limit: '1mb' })); // Prevent oversized request bodies

// --- Middleware: Verify Firebase Auth Token ---
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized: Missing or invalid token' });
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // contains uid
    next();
  } catch (error) {
    console.error('Authentication Error:', error.message);
    return res.status(403).json({ error: 'Forbidden: Invalid token' });
  }
};

// --- Endpoints ---

// 1. Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// 2. AI Story Generation
app.post('/api/generate-story', authenticate, async (req, res) => {
  try {
    const { prompt, category, tone, length, language } = req.body;
    const uid = req.user.uid;

    // Basic Validation & Rate Protection
    if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
      return res.status(400).json({ error: 'A valid prompt is required.' });
    }
    if (prompt.length > 2000) {
      return res.status(400).json({ error: 'Prompt is too long. Max 2000 characters.' });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('Missing GEMINI_API_KEY in environment');
      return res.status(503).json({ error: 'AI generation service is currently unavailable.' });
    }

    // Determine Language
    const selectedLanguage = (language && language.toLowerCase() === 'hindi') ? 'Hindi' : 'English';
    const langCode = selectedLanguage === 'Hindi' ? 'hi' : 'en';

    let languageInstruction = "Generate the complete story in English.";
    if (selectedLanguage === 'Hindi') {
      languageInstruction = "Generate the complete story in Hindi using Devanagari script. Do NOT use English or Roman Hindi.";
    }

    // Call Gemini
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: 'gemini-3.5-flash-lite',
      generationConfig: {
        responseMimeType: 'application/json',
      }
    });

    const safeCategory = category || 'Fiction';
    const aiPrompt = `
You are a master storyteller. Create an engaging, creative story based on the user's prompt.
The story must belong to the category: "${safeCategory}".
${tone ? `The tone should be: "${tone}".` : ''}
${length ? `The story length should be: "${length}".` : ''}
${languageInstruction}

User prompt: "${prompt}"

Respond ONLY with a valid JSON object matching this schema exactly:
{
  "title": "A captivating title",
  "description": "A short summary or teaser",
  "category": "The story category",
  "characters": [
    {
      "name": "Character name",
      "description": "Short character bio/description"
    }
  ],
  "story": "The complete story text (if it's a short story, put the full text here. Use markdown formatting)",
  "chapters": [
    {
      "title": "Chapter 1 Title",
      "content": "Full content of the chapter"
    }
  ]
}
Note: If it's a short story, you can leave the 'chapters' array empty or provide a single chapter. If it's a multi-chapter story, divide the 'story' into 'chapters'. The 'story' field should contain the full text or an introduction.
Do NOT repeat the opening paragraph inside the chapters. Ensure character names are spelled consistently.
`;

    let result = null;
    let apiAttempt = 0;
    const maxApiAttempts = 3;

    while (apiAttempt < maxApiAttempts) {
      apiAttempt++;
      try {
        result = await model.generateContent(aiPrompt);
        break; // Success
      } catch (genError) {
        const errStr = genError.message.toLowerCase();
        const isTransient = errStr.includes('503') || errStr.includes('429') || errStr.includes('quota') || errStr.includes('exhausted') || errStr.includes('timeout') || errStr.includes('fetch');
        
        if (isTransient && apiAttempt < maxApiAttempts) {
          const delayMs = Math.floor(Math.random() * 1000) + (apiAttempt === 1 ? 1000 : apiAttempt === 2 ? 3000 : 7000);
          console.warn(`[API Attempt ${apiAttempt}/${maxApiAttempts}] Gemini transient error. Retrying in ${delayMs}ms...`);
          await new Promise(resolve => setTimeout(resolve, delayMs));
        } else {
          throw genError; // Max attempts reached or non-transient
        }
      }
    }

    let responseText = result.response.text();

    // Safely normalize markdown/code fences
    responseText = responseText.trim();
    if (responseText.startsWith('```json')) {
      responseText = responseText.substring(7);
    } else if (responseText.startsWith('```')) {
      responseText = responseText.substring(3);
    }
    if (responseText.endsWith('```')) {
      responseText = responseText.substring(0, responseText.length - 3);
    }
    responseText = responseText.trim();

    let storyJson;
    try {
      storyJson = JSON.parse(responseText);
    } catch (parseError) {
      throw new Error(`Quality Validation Failed: AI returned malformed JSON.`);
    }

    // Basic structure validation
    if (!storyJson.title || (!storyJson.story && (!storyJson.chapters || storyJson.chapters.length === 0))) {
      throw new Error(`Quality Validation Failed: AI returned incomplete story data.`);
    }

    storyJson.language = langCode;

    // Save to Firestore (aiGenerations) to preserve the existing architecture
    const generationDoc = {
      userId: uid,
      prompt: prompt,
      category: safeCategory,
      language: langCode,
      result: storyJson,
      status: 'completed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection('aiGenerations').add(generationDoc);

    // Return the response matching the existing Flutter client expectation
    return res.status(200).json({
      docId: docRef.id,
      story: storyJson
    });

  } catch (error) {
    console.error('Generate Story Error:', error.message);
    
    const errMessage = error.message.toLowerCase();
    
    // Prevent exposing internal/API keys or deep stack traces to the client
    if (errMessage.includes('api key') || errMessage.includes('403') || errMessage.includes('400')) {
      return res.status(503).json({ error: 'AI generation service configuration error. Please check backend credentials.' });
    }
    if (errMessage.includes('404')) {
      return res.status(503).json({ error: 'AI generation model is currently unavailable or misconfigured.' });
    }
    if (errMessage.includes('429') || errMessage.includes('quota') || errMessage.includes('exhausted') || errMessage.includes('503')) {
      return res.status(503).json({ error: 'AI generation service is currently busy or experiencing high demand. Please try again later.' });
    }
    if (errMessage.includes('quality validation failed')) {
      return res.status(422).json({ error: 'Failed to generate a high-quality story. Please try a different prompt.' });
    }
    if (errMessage.includes('malformed')) {
      return res.status(500).json({ error: 'The AI generated an invalid format. Please try again.' });
    }

    res.status(500).json({ error: 'An unexpected error occurred during story generation.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`StoryVerse AI Backend listening on 0.0.0.0:${PORT}`);
});
