const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

async function runDiagnostic() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("No API key found in environment.");
    return;
  }
  
  console.log("=== DIAGNOSTIC START ===");
  console.log("Model: gemini-3.7-flash");
  
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: 'gemini-3.7-flash',
    generationConfig: {
      responseMimeType: 'application/json',
    }
  });

  const aiPrompt = "Test generation for diagnostic purposes. Return a tiny valid JSON object: {\"status\": \"ok\"}";

  try {
    const result = await model.generateContent(aiPrompt);
    console.log("Success! Received response.");
    console.log(result.response.text());
  } catch (error) {
    console.log("=== DIAGNOSTIC ERROR DETAILS ===");
    console.log("Error Message:", error.message);
    console.log("Error Name:", error.name);
    console.log("Error Type:", typeof error);
    
    // Inspect specific GoogleGenerativeAIError fields if any
    console.log("Error Status:", error.status || "N/A");
    console.log("Error Code:", error.code || "N/A");
    console.log("Error Details:", error.details || "N/A");
    console.log("Response headers (if attached):", error.response ? "Yes" : "No");
    
    // Convert to JSON to see if there are hidden fields (excluding sensitive keys)
    const errObj = JSON.parse(JSON.stringify(error, Object.getOwnPropertyNames(error)));
    
    // Safely print errObj without stack or credentials
    delete errObj.stack;
    if (errObj.request) delete errObj.request;
    if (errObj.config) delete errObj.config;
    
    console.log("Raw Error Object Structure (Safe):");
    console.log(JSON.stringify(errObj, null, 2));
  }
}

runDiagnostic();
