const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// No active functions exported.
// The generateStory function was migrated to the standalone backend/ai service
// to avoid Firebase Blaze plan requirements.
