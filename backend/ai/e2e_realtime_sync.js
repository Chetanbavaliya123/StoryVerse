const admin = require('firebase-admin');
require('dotenv').config();

// Initialize Firebase Admin (which acts as both our Admin Panel simulator and our Flutter listener for this E2E test)
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

async function runRealtimeE2ETest() {
  console.log("=== STARTING REAL-TIME ADMIN -> FIREBASE -> FLUTTER SYNC TEST ===");

  const storyId = 'e2e_test_story_' + Date.now();
  const episodeId = 'e2e_test_episode_' + Date.now();

  let storySnapshotReceived = false;
  let episodeSnapshotReceived = false;

  // 1. Simulate Flutter: Attach Real-time Listeners (Snapshots)
  console.log("1. Simulating Flutter App: Attaching real-time snapshots...");
  
  const unsubscribeStory = db.collection('stories').where('status', '==', 'published').onSnapshot(snap => {
    snap.docChanges().forEach(change => {
      if (change.type === 'added' && change.doc.id === storyId) {
        console.log("-> FLUTTER RECEIVED REAL-TIME STORY EVENT!");
        const data = change.doc.data();
        console.log(`   Title: ${data.title}`);
        console.log(`   Description: ${data.description}`);
        console.log(`   Thumbnail: ${data.thumbnailUrl}`);
        storySnapshotReceived = true;
      }
    });
  });

  const unsubscribeEpisode = db.collection('stories').doc(storyId).collection('episodes').where('isPublished', '==', true).onSnapshot(snap => {
    snap.docChanges().forEach(change => {
      if (change.type === 'added' && change.doc.id === episodeId) {
        console.log("-> FLUTTER RECEIVED REAL-TIME EPISODE EVENT!");
        const data = change.doc.data();
        console.log(`   Episode: ${data.episodeNumber}`);
        console.log(`   Video URL: ${data.videoUrl}`);
        episodeSnapshotReceived = true;
      }
    });
  });

  // Give listeners a second to initialize
  await new Promise(r => setTimeout(r, 2000));

  // 2. Simulate Admin Panel: Create Story
  console.log("2. Simulating Admin Panel: Saving 'StoryVerse E2E Test Story'...");
  await db.collection('stories').doc(storyId).set({
    title: "StoryVerse E2E Test Story",
    description: "Temporary story used to verify Admin to Firebase to Flutter realtime synchronization.",
    categoryId: "fantasy",
    genreId: "adventure",
    language: "English",
    author: "StoryVerse Admin",
    status: "published",
    isTrending: false,
    thumbnailUrl: "https://example.com/test-thumbnail.jpg",
    bannerUrl: "",
    isPublished: true,
    totalEpisodes: 1,
    totalViews: 0,
    views: 0,
    rating: 5,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Wait for snapshot
  await new Promise(r => setTimeout(r, 3000));

  // 3. Simulate Admin Panel: Create Episode
  console.log("3. Simulating Admin Panel: Saving Episode 1...");
  await db.collection('stories').doc(storyId).collection('episodes').doc(episodeId).set({
    storyId: storyId,
    episodeNumber: 1,
    title: "The Beginning of the Test",
    description: "Testing video playback sync",
    videoUrl: "https://example.com/test-video.mp4",
    thumbnailUrl: "https://example.com/test-episode-thumb.jpg",
    duration: 120,
    views: 0,
    status: "published",
    isPublished: true,
    sourceType: "external",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Wait for snapshot
  await new Promise(r => setTimeout(r, 3000));

  // 4. Verify Results
  console.log("4. Verifying Real-Time Sync Results...");
  console.log("Story received in real-time:", storySnapshotReceived ? "PASS" : "FAIL");
  console.log("Episode received in real-time:", episodeSnapshotReceived ? "PASS" : "FAIL");

  // 5. Cleanup
  console.log("5. Cleaning up test data...");
  await db.collection('stories').doc(storyId).collection('episodes').doc(episodeId).delete();
  await db.collection('stories').doc(storyId).delete();
  
  unsubscribeStory();
  unsubscribeEpisode();

  console.log("=== TEST COMPLETE ===");
  process.exit(0);
}

runRealtimeE2ETest().catch(console.error);
