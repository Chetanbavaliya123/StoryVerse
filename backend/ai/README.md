# StoryVerse AI Backend

This is a standalone Node.js Express backend for generating AI stories using the Gemini API.
It replaces the Firebase Cloud Functions dependency to allow the project to remain on the Firebase Spark (free) plan.

## 1. Installation

```bash
cd backend/ai
npm install
```

## 2. Environment Variables

Create a `.env` file in the `backend/ai` directory (do not commit this to Git).

```env
GEMINI_API_KEY=your_gemini_api_key
PORT=3000
```

## 3. Local Development

**1. Gemini API Key**
The backend requires a Gemini API key. Create a `.env` file in the `backend/ai` directory:
```text
GEMINI_API_KEY=YOUR_PRIVATE_KEY
PORT=3000
```
*(Note: Do not commit the `.env` file to Git)*

**2. Firebase Admin Credentials**
Because this backend connects to Firebase Admin to verify ID tokens and save to Firestore, you must provide Firebase credentials via an environment variable.

*Windows PowerShell Setup:*
```powershell
cd backend/ai

# Point to the secure path where your downloaded serviceAccountKey.json is located
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\SECURE_PATH\serviceAccountKey.json"

# Start the server
npm run dev
```

The server will start on `http://localhost:3000`.

## 4. Endpoints

* `GET /health` : Returns `{ "status": "ok" }`. Does not require authentication or Gemini key.
* `POST /api/generate-story` : Requires `Authorization: Bearer <Firebase ID Token>`.

## 5. Production Deployment

This backend can be deployed to any low-cost or free Node.js hosting service (e.g., Render, Railway, Fly.io, Heroku). 

Requirements for deployment:
1. Set the `GEMINI_API_KEY` environment variable on the host.
2. Provide the Firebase Admin SDK credentials (usually via a JSON string in an environment variable that you parse, or a secure file).
3. Ensure the hosting platform binds to `process.env.PORT`.
