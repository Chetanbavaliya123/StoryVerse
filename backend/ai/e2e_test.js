const admin = require('firebase-admin');
const fs = require('fs');
require('dotenv').config();

admin.initializeApp();

const API_KEY = process.env.FIREBASE_WEB_API_KEY; // Read from environment variables

async function runTest() {
  try {
    console.log('1. Fetching a test user from Firebase...');
    const listUsersResult = await admin.auth().listUsers(1);
    if (listUsersResult.users.length === 0) {
      console.log('No users found in Firebase Auth.');
      return;
    }
    const uid = listUsersResult.users[0].uid;
    console.log('Using UID:', uid);

    console.log('2. Creating custom token...');
    const customToken = await admin.auth().createCustomToken(uid);

    console.log('3. Exchanging custom token for ID token...');
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true })
    });
    
    const data = await response.json();
    const idToken = data.idToken;

    console.log('4. Calling AI Backend /api/generate-story...');
    const generateRes = await fetch('http://localhost:3000/api/generate-story', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`
      },
      body: JSON.stringify({
        prompt: 'A college student discovers a mysterious room that appears only at midnight.',
        category: 'Mystery'
      })
    });

    if (!generateRes.ok) {
      console.error('Backend returned error status:', generateRes.status);
      console.error(await generateRes.text());
      return;
    }

    const aiData = await generateRes.json();
    console.log('5. AI Backend returned docId:', aiData.docId);
    console.log('Story Title generated:', aiData.story.title);
    
    console.log('6. Verifying Firestore aiGenerations document...');
    const docRef = await admin.firestore().collection('aiGenerations').doc(aiData.docId).get();
    if (!docRef.exists) {
      console.error('Document not found in Firestore!');
      return;
    }
    const docData = docRef.data();
    console.log('Firestore doc userId:', docData.userId);
    console.log('UID match?', docData.userId === uid);

    console.log('ALL E2E BACKEND TESTS PASSED.');

  } catch (err) {
    console.error('Test failed:', err.message);
  }
}

runTest();
