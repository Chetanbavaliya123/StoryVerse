import { initializeApp, getApps, getApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import * as fs from 'fs';
import * as path from 'path';

// Helper to safely extract .env variables across environments
function getFirebaseConfig() {
  const env: Record<string, string> = {};

  const possibleEnvPaths = [
    path.resolve(process.cwd(), '.env'),
    path.resolve(process.cwd(), 'admin/.env'),
  ];

  for (const envPath of possibleEnvPaths) {
    if (fs.existsSync(envPath)) {
      try {
        const content = fs.readFileSync(envPath, 'utf-8');
        for (const line of content.split('\n')) {
          const trimmed = line.trim();
          if (trimmed && !trimmed.startsWith('#')) {
            const [key, ...vals] = trimmed.split('=');
            if (key && vals.length) {
              env[key.trim()] = vals.join('=').trim();
            }
          }
        }
        break;
      } catch {
        // continue search
      }
    }
  }

  return {
    apiKey: env.VITE_FIREBASE_API_KEY || process.env.VITE_FIREBASE_API_KEY || '',
    authDomain: env.VITE_FIREBASE_AUTH_DOMAIN || process.env.VITE_FIREBASE_AUTH_DOMAIN || '',
    projectId: env.VITE_FIREBASE_PROJECT_ID || process.env.VITE_FIREBASE_PROJECT_ID || '',
    storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET || process.env.VITE_FIREBASE_STORAGE_BUCKET || '',
    messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID || process.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '',
    appId: env.VITE_FIREBASE_APP_ID || process.env.VITE_FIREBASE_APP_ID || '',
  };
}

const firebaseConfig = getFirebaseConfig();
const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const db = getFirestore(app);

export async function checkDatabase() {
  console.log('===============================================================');
  console.log('STORYVERSE FIRESTORE DATABASE INSPECTION');
  console.log(`Connected to Project: ${firebaseConfig.projectId}`);
  console.log('===============================================================\n');

  try {
    const storiesRef = collection(db, 'stories');
    const storiesSnap = await getDocs(storiesRef);

    console.log(`Total Stories in 'stories' collection: ${storiesSnap.size}\n`);

    if (storiesSnap.empty) {
      console.log('No stories found.');
      return;
    }

    const categories = new Set<string>();
    const genres = new Set<string>();
    const languages = new Set<string>();

    for (const storyDoc of storiesSnap.docs) {
      const data = storyDoc.data();
      const storyId = storyDoc.id;

      if (data.categoryId) categories.add(String(data.categoryId));
      if (data.genreId) genres.add(String(data.genreId));
      if (data.language) languages.add(String(data.language));

      // Fetch episodes subcollection: stories/{storyId}/episodes
      const epRef = collection(db, 'stories', storyId, 'episodes');
      const epSnap = await getDocs(epRef);

      const isPublished = data.status === 'published' || data.isPublished === true;
      const statusLabel = isPublished ? 'Published' : 'Draft';
      const demoLabel = data.isDemo ? '[DEMO]' : '[REGULAR]';
      const trendLabel = data.isTrending ? '★ Trending' : '';

      console.log(`${demoLabel} "${data.title || 'Untitled'}" [ID: ${storyId}]`);
      console.log(`  └─ Category: ${data.categoryId || 'N/A'} | Genre: ${data.genreId || 'N/A'} | Language: ${data.language || 'N/A'}`);
      console.log(`  └─ Status: ${statusLabel} ${trendLabel} | Views: ${data.views || 0} | Rating: ${data.rating || 0}`);
      console.log(`  └─ Subcollection Episodes: ${epSnap.size} (declared count: ${data.totalEpisodes ?? data.episodeCount ?? 0})`);

      if (!epSnap.empty) {
        const sortedEpisodes = epSnap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a: any, b: any) => (a.episodeNumber || 0) - (b.episodeNumber || 0));

        for (const ep of sortedEpisodes as any[]) {
          console.log(`     • Ep ${ep.episodeNumber}: "${ep.title}" (${ep.duration || 0}s)`);
        }
      }
      console.log('');
    }

    console.log('===============================================================');
    console.log('SUMMARY METADATA:');
    console.log('Unique Categories:', Array.from(categories));
    console.log('Unique Genres:    ', Array.from(genres));
    console.log('Unique Languages: ', Array.from(languages));
    console.log('===============================================================');
  } catch (error: any) {
    console.error('Error querying Firestore:', error?.message || error);
  }
}

// Execute check
checkDatabase()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
