const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 'D:\\StoryVerseSecrets\\serviceAccountKey.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Service account key not found at ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id || 'storyverse-465bd'
  });
}

const db = admin.firestore();

async function removeDemoCatalog() {
  console.log('🧹 Removing StoryVerse demo catalog from Firestore...');
  const snap = await db.collection('stories').where('isDemo', '==', true).get();
  console.log(`Found ${snap.size} demo stories to remove.`);

  for (const doc of snap.docs) {
    const episodes = await doc.ref.collection('episodes').get();
    for (const ep of episodes.docs) {
      await ep.ref.delete();
    }
    await doc.ref.delete();
    console.log(`   ✓ Deleted demo story: ${doc.id}`);
  }

  console.log('✅ Demo catalog removal complete.');
  process.exit(0);
}

removeDemoCatalog().catch(err => {
  console.error('Removal failed:', err);
  process.exit(1);
});
