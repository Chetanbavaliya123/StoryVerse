const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin with Service Account
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

// Video URLs (Reliable public-domain MP4s for all devices & web)
const SAMPLE_VIDEOS = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://raw.githubusercontent.com/mediaelement/mediaelement-files/master/big_buck_bunny.mp4',
  'https://vjs.zencdn.net/v/oceans.mp4',
  'https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-576p.mp4'
];

// Curated high-resolution covers matching each genre perfectly
const DEMO_STORIES = [
  {
    id: 'demo_story_romance',
    title: 'Prem Ki Dastaan',
    description: 'Ek anokhi prem kahani jo waqt ki har deewar ko tod deti hai.',
    fullDescription: 'Sameer aur Riya ki kahani jo college ke purane library se shuru hokar shahar ke sabse bade faisle tak pahunchti hai. Jab do alag-alag duniya ke log ek dusre ke sapno me sahara dhoondte hain, toh shuru hoti hai ek aisi dastaan jo na sirf unhe balki unke parivaaron ko bhi badal kar rakh deti hai.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=1200&auto=format&fit=crop&q=80',
    genreId: 'romance',
    categoryId: 'romance',
    language: 'Hindi',
    author: 'Kabir Sharma',
    tags: ['romance', 'love', 'drama', 'hindi', 'college', 'emotional'],
    status: 'published',
    isPublished: true,
    isTrending: true,
    isDemo: true,
    views: 45200,
    totalViews: 45200,
    rating: 4.9,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1540,
    episodes: [
      {
        id: 'ep_romance_1',
        episodeNumber: 1,
        title: 'Pehli Mulaqaat',
        description: 'College library ki shaam jahan Sameer aur Riya ke sapne pehli baar takraate hain.',
        duration: 310,
        views: 12500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_romance_2',
        episodeNumber: 2,
        title: 'Unkahi Baatein',
        description: 'Barsaat ki ek dophar me unke dil ke gehre raaz saamne aate hain.',
        duration: 295,
        views: 10400,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_romance_3',
        episodeNumber: 3,
        title: 'Faaslo Ka Mod',
        description: 'Parivaar ke faisle unhe do alag shehron me bhej dete hain.',
        duration: 320,
        views: 8900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_romance_4',
        episodeNumber: 4,
        title: 'Purani Diary',
        description: 'Ek purani diary jo unke bich ke bhed ko mita sakti hai.',
        duration: 285,
        views: 7300,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_romance_5',
        episodeNumber: 5,
        title: 'Hamesha Ke Liye',
        description: 'Station ke aakhri platform par ek aakhri faisla jo zindagi badal deta hai.',
        duration: 330,
        views: 6100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_horror',
    title: 'Andheri Haveli',
    description: 'Jo ek baar is haveli me kadam rakhta hai, uski aawaz hamesha ke liye kho jaati hai.',
    fullDescription: 'Pahadon ke bich basi ek 200 saal purani haveli jahan har raat barah baje ghanti bajti hai bina kisi ke chhue. Vikram jab apne purkhe ki haveli ki sachai jaan ne gaon pahunchta hai, toh use pata chalta hai ki wahan koi aisi aatma rehti hai jo sirf badla chahti hai.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=1200&auto=format&fit=crop&q=80',
    genreId: 'horror',
    categoryId: 'horror',
    language: 'Hindi',
    author: 'Aditya Roy',
    tags: ['horror', 'ghost', 'mansion', 'hindi', 'mystery', 'dark'],
    status: 'published',
    isPublished: true,
    isTrending: true,
    isDemo: true,
    views: 38900,
    totalViews: 38900,
    rating: 4.7,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: '16+',
    totalDuration: 1610,
    episodes: [
      {
        id: 'ep_horror_1',
        episodeNumber: 1,
        title: 'Haveli Ka Darwaza',
        description: 'Vikram haveli ke band darwaze ko pehli baar kholta hai aur ek thandi hawa mehsoos karta hai.',
        duration: 315,
        views: 11200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_horror_2',
        episodeNumber: 2,
        title: 'Aadhi Raat Ki Ghanti',
        description: 'Raat ke theek 12 baje bina kisi ke chhue chat ki ghanti baj uthti hai.',
        duration: 340,
        views: 9500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_horror_3',
        episodeNumber: 3,
        title: 'Aaine Ka Saaya',
        description: 'Haveli ke purane aaine me ek aisa chehra dikhta hai jo kamre me maujood nahi.',
        duration: 300,
        views: 7800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_horror_4',
        episodeNumber: 4,
        title: 'Tehkhaane Ka Raaz',
        description: 'Haveli ke niche ek purani band kitab milti hai jisme us aatma ka dard likha hai.',
        duration: 325,
        views: 5900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_horror_5',
        episodeNumber: 5,
        title: 'Aakhri Mukti',
        description: 'Vikram aatma ko mukti dilane ke liye sabse khatarnak koshish karta hai.',
        duration: 330,
        views: 4500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_comedy',
    title: 'Haso Ane Hasavo',
    description: 'Ahmedabad na pol ma Jethalal ane Popatlal jevo rangilo parivar.',
    fullDescription: 'Ahmedabad na juno pol ma Chhaganbhai ane Maganbhai ni dukan aamne-saamne chhe. Ek divas moti lottery lagya ni vaat failay chhe ane aakho pol hase chhe. Subah thi sanj sudhi thilak ane hasya thi bharpoor kissa.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=1200&auto=format&fit=crop&q=80',
    genreId: 'comedy',
    categoryId: 'comedy',
    language: 'Gujarati',
    author: 'Ramesh Patel',
    tags: ['comedy', 'gujarati', 'family', 'fun', 'humor', 'ahmedabad'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 29400,
    totalViews: 29400,
    rating: 4.8,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1390,
    episodes: [
      {
        id: 'ep_comedy_1',
        episodeNumber: 1,
        title: 'Pol Ma Dhamal',
        description: 'Chhaganlal ane Maganlal ni dukan par subah ni garma-garam chani charcha.',
        duration: 260,
        views: 8200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_comedy_2',
        episodeNumber: 2,
        title: 'Lottery Ni Vaat',
        description: 'Bajar ma vaat failay chhe ke koik ni 1 crore ni lottery lagi chhe.',
        duration: 280,
        views: 7100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_comedy_3',
        episodeNumber: 3,
        title: 'Mehmaan Ni Entry',
        description: 'Mumbaikar mehmaan aave chhe ane ghotado sharu thay chhe.',
        duration: 275,
        views: 5900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_comedy_4',
        episodeNumber: 4,
        title: 'Nakli Heera',
        description: 'Ek nakli heera no kissa je aakha mohalla ne heran kare chhe.',
        duration: 285,
        views: 4600,
        thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_comedy_5',
        episodeNumber: 5,
        title: 'Sacho Haso',
        description: 'Lottery no sacho malik samne aave chhe ane badha hasi pade chhe.',
        duration: 290,
        views: 3600,
        thumbnailUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_thriller',
    title: 'The Silent Room',
    description: 'Every sound is a witness, every silence is a confession.',
    fullDescription: 'Special Agent Laura Cross is summoned to an underground classified interrogation facility where high-profile prisoner 407 has suddenly ceased all vocalization. As unexplainable radio interference surges and power grids fail, Laura realizes that the prisoner is not trapped with them—they are trapped with the prisoner.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=1200&auto=format&fit=crop&q=80',
    genreId: 'thriller',
    categoryId: 'thriller',
    language: 'English',
    author: 'Laura Vance',
    tags: ['thriller', 'suspense', 'investigation', 'noir', 'mystery', 'crime'],
    status: 'published',
    isPublished: true,
    isTrending: true,
    isDemo: true,
    views: 51200,
    totalViews: 51200,
    rating: 4.9,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: '16+',
    totalDuration: 1720,
    episodes: [
      {
        id: 'ep_thriller_1',
        episodeNumber: 1,
        title: 'The Sealed Door',
        description: 'Agent Laura steps into the airtight interrogation chamber of Sector 4.',
        duration: 335,
        views: 14200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_thriller_2',
        episodeNumber: 2,
        title: 'The Missing Voice',
        description: 'Audio transcripts reveal a hidden Morse code pattern in the prisoner breathing rhythm.',
        duration: 345,
        views: 12100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_thriller_3',
        episodeNumber: 3,
        title: 'The Hidden Floor',
        description: 'A secret basement level is discovered that does not exist on official blueprints.',
        duration: 350,
        views: 9900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_thriller_4',
        episodeNumber: 4,
        title: 'The Betrayal',
        description: 'Laura realizes her own handler is the person the prisoner has been shielding all along.',
        duration: 340,
        views: 8200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_thriller_5',
        episodeNumber: 5,
        title: 'The Final Protocol',
        description: 'A countdown begins to purge the facility before the classified truth escapes to the world.',
        duration: 350,
        views: 6800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_fantasy',
    title: 'Mayavi Talav',
    description: 'Sahyadri chya dongrat laplele ek jaadui rahasya.',
    fullDescription: 'Sahyadri chya ghanadaat dongraat ek ashi gupt jagah ahe jithe vanaspati aani jaadui shakti vasatat. Shivraj naavacha ek tarun yodhya ya talavacha shodh gheto aani aple gaav sankatatoon vachavato. Pournimechya ratri talavachya madhyabhagi chamknara jaadui mani sarvanna aakashachya shaktiyanshi jodto.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
    genreId: 'fantasy',
    categoryId: 'fantasy',
    language: 'Marathi',
    author: 'Yashwant Joshi',
    tags: ['fantasy', 'magic', 'marathi', 'sahyadri', 'mythology', 'adventure'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 32100,
    totalViews: 32100,
    rating: 4.8,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1470,
    episodes: [
      {
        id: 'ep_fantasy_1',
        episodeNumber: 1,
        title: 'Jungle Cha Marg',
        description: 'Shivraj dongrachya ghanadaat margavar aushadhi vanaspati shodhat pravas shuru karto.',
        duration: 290,
        views: 8900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_fantasy_2',
        episodeNumber: 2,
        title: 'Pournimechi Ratra',
        description: 'Chandra aakashat yeto aani talavacha jaadui prakash ghanadaat vanat pasarto.',
        duration: 300,
        views: 7400,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_fantasy_3',
        episodeNumber: 3,
        title: 'Jaadui Mani',
        description: 'Talavachya madhyabhagi ek tejasvi mani chamkato jyachya kade aloukik shakti ahe.',
        duration: 285,
        views: 6100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_fantasy_4',
        episodeNumber: 4,
        title: 'Rakshasacha Hulla',
        description: 'Janglatil shaktiyavar kabja karnari ek kali taqat talavavar aakraman karte.',
        duration: 295,
        views: 5200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_fantasy_5',
        episodeNumber: 5,
        title: 'Vijayi Prakash',
        description: 'Shivraj gaavacha aani talavacha samman rakhoon jaadui prakashala parat sthaapit karto.',
        duration: 300,
        views: 4500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_mystery',
    title: 'The Clockwork Alibi',
    description: 'Time never lies, but the hands of the clock can be turned back.',
    fullDescription: 'Detective Julian Sterling investigates the impossible death of master horologist Arthur Pendelton. Found inside a bank-grade vault sealed from the inside, Pendelton was surrounded by hundreds of running timepieces, with a single antique watch ticking precisely fifteen minutes fast.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=1200&auto=format&fit=crop&q=80',
    genreId: 'mystery',
    categoryId: 'mystery',
    language: 'English',
    author: 'Julian Sterling',
    tags: ['mystery', 'detective', 'puzzle', 'clocks', 'investigation', 'classic'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 28500,
    totalViews: 28500,
    rating: 4.6,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1530,
    episodes: [
      {
        id: 'ep_mystery_1',
        episodeNumber: 1,
        title: 'Stopped at Midnight',
        description: 'Detective Sterling enters the vault where 100 antique clocks tick in eerie unison.',
        duration: 300,
        views: 8100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_mystery_2',
        episodeNumber: 2,
        title: 'The Broken Gear',
        description: 'A hidden spring inside the grandfather clock points toward an impossible mechanical trick.',
        duration: 310,
        views: 6900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_mystery_3',
        episodeNumber: 3,
        title: 'The Apprentice',
        description: 'Pendelton prodigy reveals an unfinished masterpiece that threatened a powerful rival.',
        duration: 305,
        views: 5400,
        thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_mystery_4',
        episodeNumber: 4,
        title: 'The Second Key',
        description: 'Evidence surfaces proving a duplicate key was forged decades before the crime occurred.',
        duration: 315,
        views: 4500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_mystery_5',
        episodeNumber: 5,
        title: 'The Verdict of Time',
        description: 'Julian reassembles the clockwork mechanism to expose the killer exact timeline.',
        duration: 300,
        views: 3600,
        thumbnailUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_scifi',
    title: 'Chronos Protocol',
    description: 'When the timeline fractures, only memory can repair the future.',
    fullDescription: 'In the year 2184, orbital station Aethelgard detects anomalous ripples in the space-time fabric. Chief Physicist Dr. Noah Mercer oversees the Chronos Array when a distress signal arrives from three hours into the future, recorded in his own trembling voice.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&auto=format&fit=crop&q=80',
    genreId: 'sci-fi',
    categoryId: 'sci-fi',
    language: 'English',
    author: 'Dr. Elena Cruz',
    tags: ['sci-fi', 'space', 'time-travel', 'quantum', 'future', 'technology'],
    status: 'published',
    isPublished: true,
    isTrending: true,
    isDemo: true,
    views: 41800,
    totalViews: 41800,
    rating: 4.9,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1680,
    episodes: [
      {
        id: 'ep_scifi_1',
        episodeNumber: 1,
        title: 'Temporal Anomaly',
        description: 'The sensors of Orbital Station Aethelgard detect an echo from three hours ahead.',
        duration: 320,
        views: 11800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_scifi_2',
        episodeNumber: 2,
        title: 'The Echo Transmission',
        description: 'Noah decodes his own voice warning the crew not to initiate the quantum jump.',
        duration: 340,
        views: 9700,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_scifi_3',
        episodeNumber: 3,
        title: 'Fractured Reality',
        description: 'Alternate versions of the station begin overlapping in the observation deck.',
        duration: 335,
        views: 8100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_scifi_4',
        episodeNumber: 4,
        title: 'The Core Overload',
        description: 'The temporal reactor destabilizes, forcing the engineers to make a critical sacrifice.',
        duration: 345,
        views: 6700,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_scifi_5',
        episodeNumber: 5,
        title: 'The New Tomorrow',
        description: 'Noah recalibrates the array and realigns the timeline, securing humanity future.',
        duration: 340,
        views: 5500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_adventure',
    title: 'Kille Raigad Chi Mohim',
    description: 'Sahyadri chya kalyavar viranche pavool.',
    fullDescription: 'Aniket, Rohan aani Swati Sahyadri chya kadekot dongraat trek la jaatat. Tyanche kade ek puratana nakasha ahe jo tyanla kille Raigad chya gupit bhitigade gheun jaato. Sahas, ekmeghacha vishwas aani itihasacha gaurav ya dastaan madhe disto.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&auto=format&fit=crop&q=80',
    genreId: 'adventure',
    categoryId: 'adventure',
    language: 'Marathi',
    author: 'Aniket Shinde',
    tags: ['adventure', 'trekking', 'sahyadri', 'marathi', 'mountains', 'history'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 24100,
    totalViews: 24100,
    rating: 4.7,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1420,
    episodes: [
      {
        id: 'ep_adventure_1',
        episodeNumber: 1,
        title: 'Nakashyacha Shodh',
        description: 'Puranya granthalayat ek hathane lehilela nakasha sapadato.',
        duration: 275,
        views: 6800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_adventure_2',
        episodeNumber: 2,
        title: 'Dongrachi Vaat',
        description: 'Sahyadri chya unch kada khadakivar chadhun te rasta shodhatat.',
        duration: 285,
        views: 5700,
        thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_adventure_3',
        episodeNumber: 3,
        title: 'Gupit Ghaat',
        description: 'Achanak aalelya pavsaat tyanla ek guha disate jithe puratan aavshesh ahet.',
        duration: 290,
        views: 4600,
        thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_adventure_4',
        episodeNumber: 4,
        title: 'Sankat Ani Sahas',
        description: 'Ek tudaleli saakhal tyanche chadhne sankatat takte, pan ekmekancha aadhar tyanna vachavto.',
        duration: 280,
        views: 3800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_adventure_5',
        episodeNumber: 5,
        title: 'Shikharavar Tiranga',
        description: 'Khajina mhanje aamchi sanskruti aani itihas, he samjun te shikhar gathatat.',
        duration: 290,
        views: 3200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_action',
    title: 'Kutch Na Ranveer',
    description: 'Ran ni reti par shaurya ane balidan ni vaat.',
    fullDescription: 'Kutch na safed ran par andhari raat ma ghuspaithiyaon no samno karto ek dalpat sena no jawan Ranveer. Desh ni raksha mate te pote ane tena mitro jiv na jokham par aave chhe. Reti na tofan vachhe shaurya ni amar gatha.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=1200&auto=format&fit=crop&q=80',
    genreId: 'action',
    categoryId: 'action',
    language: 'Gujarati',
    author: 'Dilip Rawal',
    tags: ['action', 'kutch', 'gujarati', 'army', 'bravery', 'patriotism'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 36700,
    totalViews: 36700,
    rating: 4.8,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: '16+',
    totalDuration: 1590,
    episodes: [
      {
        id: 'ep_action_1',
        episodeNumber: 1,
        title: 'Ran Ni Raat',
        description: 'Kutch na safed ran ma thandi raat vachhe petroling sharu thay chhe.',
        duration: 310,
        views: 10500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_action_2',
        episodeNumber: 2,
        title: 'Chhupe Chhaya',
        description: 'Border na khuna ma koik sandighdh halchal pakday chhe.',
        duration: 320,
        views: 8900,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_action_3',
        episodeNumber: 3,
        title: 'Samne Ladaai',
        description: 'Chhati thoki ne jawan Ranveer ane tena sathio aagad vadhe chhe.',
        duration: 315,
        views: 7400,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_action_4',
        episodeNumber: 4,
        title: 'Chakravyuh',
        description: 'Dushman ghutaniya teki deve teva plan sathe gherabandi thay chhe.',
        duration: 325,
        views: 5800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_action_5',
        episodeNumber: 5,
        title: 'Desh No Tirango',
        description: 'Ranveer dushman ne pachhadine tirango lehrato kare chhe.',
        duration: 320,
        views: 4100,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  },
  {
    id: 'demo_story_drama',
    title: 'Pita Ki Pagdi',
    description: 'Ek aam parivaar ki shaan aur bacchon ke sapno ke bich ki dastaan.',
    fullDescription: 'Pandit Ramcharan ne hamesha imandari se padhaya aur parivaar chalaya. Jab unke bete ko corporate duniya me faisla lena padta hai ki wo baap ke asoolon par chale ya bheed me kho jaye, tab shuru hoti hai ek aisi jang jo har dil ko chhoo leti hai.',
    thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=800&auto=format&fit=crop&q=80',
    bannerUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=1200&auto=format&fit=crop&q=80',
    genreId: 'drama',
    categoryId: 'drama',
    language: 'Hindi',
    author: 'Premchand (Modern Adapt.)',
    tags: ['drama', 'family', 'father', 'hindi', 'values', 'emotions'],
    status: 'published',
    isPublished: true,
    isTrending: false,
    isDemo: true,
    views: 33400,
    totalViews: 33400,
    rating: 4.7,
    episodeCount: 5,
    totalEpisodes: 5,
    ageCategory: 'all-ages',
    totalDuration: 1450,
    episodes: [
      {
        id: 'ep_drama_1',
        episodeNumber: 1,
        title: 'Master Ji Ki Cycle',
        description: 'Ramcharan ji ki purani cycle aur unke chote makan ki subah.',
        duration: 280,
        views: 9200,
        thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[0]
      },
      {
        id: 'ep_drama_2',
        episodeNumber: 2,
        title: 'Bada Shahar',
        description: 'Beta pehli baar corporate office me kadam rakhta hai jahan asoolon ki keemat lagti hai.',
        duration: 295,
        views: 7800,
        thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[1]
      },
      {
        id: 'ep_drama_3',
        episodeNumber: 3,
        title: 'Shart',
        description: 'Company me ek galat project par sign karne ka dabav aata hai.',
        duration: 290,
        views: 6500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[2]
      },
      {
        id: 'ep_drama_4',
        episodeNumber: 4,
        title: 'Pita Ki Nazar',
        description: 'Beta ghar aakar baap ke purane chashme aur pagdi ko dekhta hai aur faisla leta hai.',
        duration: 285,
        views: 5400,
        thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[3]
      },
      {
        id: 'ep_drama_5',
        episodeNumber: 5,
        title: 'Sach Ki Jeet',
        description: 'Beta sach ka sath dekar parivaar ka sir fakhr se ooncha karta hai.',
        duration: 300,
        views: 4500,
        thumbnailUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=600&auto=format&fit=crop&q=80',
        videoUrl: SAMPLE_VIDEOS[4]
      }
    ]
  }
];

async function seedDemoCatalog() {
  console.log('===============================================================');
  console.log('STORYVERSE DEMO CATALOG SEEDING');
  console.log('1 Story Per Category + 5 Episodes Each');
  console.log('===============================================================\n');

  let storiesCreated = 0;
  let episodesCreated = 0;

  for (const story of DEMO_STORIES) {
    const storyId = story.id;
    const storyRef = db.collection('stories').doc(storyId);

    const storyData = {
      title: story.title,
      description: story.description,
      fullDescription: story.fullDescription,
      thumbnailUrl: story.thumbnailUrl,
      bannerUrl: story.bannerUrl,
      genreId: story.genreId.toLowerCase(),
      categoryId: story.categoryId.toLowerCase(),
      language: story.language,
      author: story.author,
      tags: story.tags,
      status: story.status,
      isPublished: story.isPublished,
      isTrending: story.isTrending,
      isDemo: true,
      views: story.views,
      totalViews: story.totalViews,
      rating: story.rating,
      episodeCount: 5,
      totalEpisodes: 5,
      ageCategory: story.ageCategory,
      totalDuration: story.totalDuration,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Check if story already exists to preserve original createdAt
    const existingStory = await storyRef.get();
    if (!existingStory.exists) {
      storyData.createdAt = admin.firestore.FieldValue.serverTimestamp();
      await storyRef.set(storyData);
      console.log(`[CREATED STORY] ${story.categoryId.toUpperCase()} -> "${story.title}" (${story.language}) [ID: ${storyId}]`);
    } else {
      await storyRef.set(storyData, { merge: true });
      console.log(`[UPDATED STORY]  ${story.categoryId.toUpperCase()} -> "${story.title}" (${story.language}) [ID: ${storyId}]`);
    }
    storiesCreated++;

    // Seed 5 Connected Episodes in stories/{storyId}/episodes/{episodeId}
    for (const ep of story.episodes) {
      const epRef = storyRef.collection('episodes').doc(ep.id);
      const epData = {
        storyId: storyId,
        episodeNumber: ep.episodeNumber,
        title: ep.title,
        description: ep.description,
        videoUrl: ep.videoUrl,
        thumbnailUrl: ep.thumbnailUrl,
        duration: ep.duration,
        views: ep.views,
        status: 'published',
        isPublished: true,
        mediaType: 'video',
        sourceType: 'external',
        storagePath: '',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      const existingEp = await epRef.get();
      if (!existingEp.exists) {
        epData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        epData.publishedAt = admin.firestore.FieldValue.serverTimestamp();
        await epRef.set(epData);
      } else {
        await epRef.set(epData, { merge: true });
      }
      episodesCreated++;
    }
    console.log(`   └─ 5 episodes synced for "${story.title}"`);
  }

  console.log('\n===============================================================');
  console.log(`SEED COMPLETE!`);
  console.log(`Total Categories: ${DEMO_STORIES.length}`);
  console.log(`Total Stories:    ${storiesCreated}`);
  console.log(`Total Episodes:   ${episodesCreated}`);
  console.log('===============================================================');
  process.exit(0);
}

seedDemoCatalog().catch(err => {
  console.error('Seeding failed with error:', err);
  process.exit(1);
});
