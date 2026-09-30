const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

admin.initializeApp({
  projectId: "storyverse-465bd"
});

const db = admin.firestore();

async function check() {
  try {
    const uid = '6ZAS0t5zKJR4xSlae6F9ay8kQul2';
    const doc = await db.collection('users').doc(uid).get();
    console.log(`Emulator users/${uid} exists:`, doc.exists);
    if (doc.exists) {
      console.log('Data:', doc.data());
    }
  } catch (e) {
    console.error(e);
  }
}

check();
