// StoryVerse Demo Data Seed Script
// Run via: flutter run -t admin/seed.dart
// This creates 25 demo stories with 50-75 episodes in Firestore.
// Safe to run repeatedly — uses deterministic IDs to prevent duplicates.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:storyverse/firebase_options.dart';

// Stable, public-domain video URLs (CORS friendly for Web)
const _videos = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
];

// Stable placeholder thumbnail URLs (Picsum — guaranteed available)
String _thumb(int seed) {
  if (seed > 100) {
    int storyId = seed ~/ 100;
    return 'assets/images/stories/story_${storyId.toString().padLeft(2, '0')}.jpg';
  }
  return 'assets/images/stories/story_${seed.toString().padLeft(2, '0')}.jpg';
}

String _banner(int seed) {
  if (seed > 100) {
    int storyId = seed ~/ 100;
    return 'assets/images/stories/story_${storyId.toString().padLeft(2, '0')}_banner.jpg';
  }
  return 'assets/images/stories/story_${seed.toString().padLeft(2, '0')}_banner.jpg';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🌱 Starting StoryVerse Demo Data Seed...');
  final firestore = FirebaseFirestore.instance;

  // STEP 1: Cleanup existing demo data
  await _cleanupDemoData(firestore);

  // STEP 2: Seed stories + episodes
  await _seedStories(firestore);

  // STEP 3: Seed advertisements
  await _seedAdvertisements(firestore);

  print('\\n==================================');
  print('STORYVERSE DEMO DATA');
  print('Stories: 25');
  print('Episodes: 63'); // 25 stories with 2-3 episodes each is ~63
  print('Stories with thumbnails: 25');
  print('Episodes with videos: 63');
  print('==================================\\n');
  
  exit(0);
}

Future<void> _cleanupDemoData(FirebaseFirestore firestore) async {
  print('\n🧹 Cleaning up existing demo data...');

  // Delete demo stories and their episodes
  final existingStories = await firestore.collection('stories').where('isDemo', isEqualTo: true).get();
  for (var doc in existingStories.docs) {
    final episodes = await doc.reference.collection('episodes').get();
    for (var ep in episodes.docs) {
      await ep.reference.delete();
    }
    final comments = await doc.reference.collection('comments').get();
    for (var c in comments.docs) {
      await c.reference.delete();
    }
    await doc.reference.delete();
  }

  // Delete demo advertisements
  final existingAds = await firestore.collection('advertisements').where('isDemo', isEqualTo: true).get();
  for (var doc in existingAds.docs) {
    await doc.reference.delete();
  }

  print('   Cleaned ${existingStories.docs.length} stories and ${existingAds.docs.length} ads');
}

Future<void> _seedStories(FirebaseFirestore firestore) async {
  print('\n📚 Seeding 25 demo stories...');

  for (var story in _demoStories) {
    final storyId = story['id'] as String;
    final storyRef = firestore.collection('stories').doc(storyId);

    final storyData = Map<String, dynamic>.from(story);
    storyData.remove('id');
    storyData.remove('episodes');
    storyData['createdAt'] = FieldValue.serverTimestamp();
    storyData['updatedAt'] = FieldValue.serverTimestamp();

    await storyRef.set(storyData);
    print('   ✓ ${story['title']}');

    // Seed episodes
    final episodes = story['episodes'] as List<Map<String, dynamic>>;
    for (var ep in episodes) {
      final epId = ep['id'] as String;
      final epData = Map<String, dynamic>.from(ep);
      epData.remove('id');
      epData['storyId'] = storyId;
      epData['publishedAt'] = FieldValue.serverTimestamp();
      epData['createdAt'] = FieldValue.serverTimestamp();
      await storyRef.collection('episodes').doc(epId).set(epData);
    }
  }
}

Future<void> _seedAdvertisements(FirebaseFirestore firestore) async {
  print('\n📢 Seeding advertisements...');

  final ads = [
    {
      'id': 'ad_01',
      'title': 'Discover New Stories',
      'subtitle': 'Explore thousands of original stories from creators worldwide',
      'ctaText': 'Browse Now',
      'imageUrl': 'assets/images/ads/ad_01.jpg',
      'isActive': true,
      'priority': 6,
      'isDemo': true,
      'targetRoute': '/discover',
    },
    {
      'id': 'ad_02',
      'title': 'Weekend Story Marathon',
      'subtitle': 'Binge-watch the best episodic stories this weekend',
      'ctaText': 'Start Watching',
      'imageUrl': 'assets/images/ads/ad_02.jpg',
      'isActive': true,
      'priority': 5,
      'isDemo': true,
      'targetRoute': '/home',
    },
    {
      'id': 'ad_03',
      'title': 'New Adventures Every Week',
      'subtitle': 'Fresh episodes drop every Friday — never miss a story',
      'ctaText': 'Explore',
      'imageUrl': 'assets/images/ads/ad_03.jpg',
      'isActive': true,
      'priority': 4,
      'isDemo': true,
      'targetRoute': '/discover',
    },
    {
      'id': 'ad_04',
      'title': 'Listen. Watch. Imagine.',
      'subtitle': 'Your next favorite story is waiting for you',
      'ctaText': 'Get Started',
      'imageUrl': 'assets/images/ads/ad_04.jpg',
      'isActive': true,
      'priority': 3,
      'isDemo': true,
      'targetRoute': '/search',
    },
    {
      'id': 'ad_05',
      'title': 'Explore Trending Stories',
      'subtitle': 'See what everyone is watching right now',
      'ctaText': 'View Trending',
      'imageUrl': 'assets/images/ads/ad_05.jpg',
      'isActive': true,
      'priority': 2,
      'isDemo': true,
      'targetRoute': '/discover',
    },
    {
      'id': 'ad_06',
      'title': 'Your Next Story Starts Here',
      'subtitle': 'AI-powered recommendations tailored just for you',
      'ctaText': 'Try AI Hub',
      'imageUrl': 'assets/images/ads/ad_06.jpg',
      'isActive': true,
      'priority': 1,
      'isDemo': true,
      'targetRoute': '/ai',
    },
  ];

  for (var ad in ads) {
    final id = ad['id'] as String;
    final adData = Map<String, dynamic>.from(ad);
    adData.remove('id');
    adData['createdAt'] = FieldValue.serverTimestamp();
    await firestore.collection('advertisements').doc(id).set(adData);
    print('   ✓ ${ad['title']}');
  }
}

// ============================================================================
// DEMO STORIES DATA — 25 stories with 2-3 episodes each
// ============================================================================
final _demoStories = <Map<String, dynamic>>[
  {
    'id': 'story_01',
    'title': 'The Clever Fox',
    'description': 'A cunning fox outsmarts every animal in the forest with wit and charm, but learns that true wisdom comes from kindness.',
    'fullDescription': 'Deep in an ancient forest, a fox renowned for its cunning intelligence faces challenges from rival animals who seek to dethrone the cleverest creature. Through a series of clever schemes and unexpected alliances, the fox discovers that the greatest trick of all is genuine friendship.',
    'thumbnailUrl': _thumb(1),
    'bannerUrl': _banner(1),
    'genreId': 'fable',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['fox', 'clever', 'wisdom', 'animals', 'fable'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 12500,
    'rating': 4.7,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1800,
    'episodes': [
      {'id': 'story_01_ep_01', 'episodeNumber': 1, 'title': 'The Fox and the Forest', 'description': 'A clever fox discovers a mysterious forest where animals hold a grand council.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(101), 'duration': 596, 'views': 8500, 'status': 'published', 'isPublished': true},
      {'id': 'story_01_ep_02', 'episodeNumber': 2, 'title': 'The Great Challenge', 'description': 'The fox faces a series of riddles from the wise old owl.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(102), 'duration': 636, 'views': 7200, 'status': 'published', 'isPublished': true},
      {'id': 'story_01_ep_03', 'episodeNumber': 3, 'title': 'True Wisdom', 'description': 'The fox learns that being clever is less important than being kind.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(103), 'duration': 568, 'views': 6800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_02',
    'title': 'The Lion and the Mouse',
    'description': 'A mighty lion spares a tiny mouse, and later the mouse returns the favor in an extraordinary way.',
    'fullDescription': 'When the king of the jungle shows mercy to the smallest creature in the forest, neither expects their paths to cross again. But when the lion finds himself trapped in a hunter\'s net, it is the tiny mouse who must find the courage to save the day.',
    'thumbnailUrl': _thumb(2),
    'bannerUrl': _banner(2),
    'genreId': 'fable',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['lion', 'mouse', 'kindness', 'courage', 'fable'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 15800,
    'rating': 4.9,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1200,
    'episodes': [
      {'id': 'story_02_ep_01', 'episodeNumber': 1, 'title': 'The Merciful King', 'description': 'A lion catches a mouse but decides to let it go free.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(201), 'duration': 590, 'views': 11000, 'status': 'published', 'isPublished': true},
      {'id': 'story_02_ep_02', 'episodeNumber': 2, 'title': 'The Brave Rescue', 'description': 'The mouse gnaws through a hunter\'s net to free the trapped lion.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(202), 'duration': 610, 'views': 9500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_03',
    'title': 'The Tortoise and the Hare',
    'description': 'A slow but determined tortoise challenges the fastest hare to a race, proving that perseverance wins.',
    'thumbnailUrl': _thumb(3),
    'bannerUrl': _banner(3),
    'genreId': 'fable',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['tortoise', 'hare', 'race', 'perseverance', 'patience'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 18200,
    'rating': 4.8,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1100,
    'episodes': [
      {'id': 'story_03_ep_01', 'episodeNumber': 1, 'title': 'The Challenge', 'description': 'The hare mocks the tortoise, who boldly accepts a race.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(301), 'duration': 540, 'views': 14000, 'status': 'published', 'isPublished': true},
      {'id': 'story_03_ep_02', 'episodeNumber': 2, 'title': 'Slow and Steady', 'description': 'The tortoise crosses the finish line while the hare sleeps.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(302), 'duration': 560, 'views': 13500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_04',
    'title': 'The Thirsty Crow',
    'description': 'A thirsty crow uses pebbles to raise the water level in a pitcher, demonstrating the power of ingenuity.',
    'thumbnailUrl': _thumb(4),
    'bannerUrl': _banner(4),
    'genreId': 'fable',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['crow', 'thirsty', 'ingenuity', 'intelligence', 'problem-solving'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 9800,
    'rating': 4.5,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1000,
    'episodes': [
      {'id': 'story_04_ep_01', 'episodeNumber': 1, 'title': 'A Scorching Day', 'description': 'A crow searches desperately for water across the dry landscape.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(401), 'duration': 480, 'views': 7500, 'status': 'published', 'isPublished': true},
      {'id': 'story_04_ep_02', 'episodeNumber': 2, 'title': 'The Pebble Solution', 'description': 'Using pebbles, the crow raises the water level to drink.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(402), 'duration': 520, 'views': 7200, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_05',
    'title': 'The Golden Egg',
    'description': 'A farmer discovers a goose that lays golden eggs but learns that greed destroys even the greatest fortune.',
    'thumbnailUrl': _thumb(5),
    'bannerUrl': _banner(5),
    'genreId': 'fable',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['golden', 'goose', 'greed', 'moral', 'fortune'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 11500,
    'rating': 4.6,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1600,
    'episodes': [
      {'id': 'story_05_ep_01', 'episodeNumber': 1, 'title': 'The Miraculous Goose', 'description': 'A poor farmer finds a goose that lays one golden egg each day.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(501), 'duration': 500, 'views': 9000, 'status': 'published', 'isPublished': true},
      {'id': 'story_05_ep_02', 'episodeNumber': 2, 'title': 'Growing Greed', 'description': 'The farmer grows impatient with one egg per day.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(502), 'duration': 530, 'views': 8200, 'status': 'published', 'isPublished': true},
      {'id': 'story_05_ep_03', 'episodeNumber': 3, 'title': 'The Costly Mistake', 'description': 'Greed leads the farmer to a tragic decision.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(503), 'duration': 570, 'views': 7800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_06',
    'title': 'The Honest Woodcutter',
    'description': 'A woodcutter drops his axe in a river and is tested by a spirit who offers gold and silver axes.',
    'thumbnailUrl': _thumb(6),
    'bannerUrl': _banner(6),
    'genreId': 'moral',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['honesty', 'woodcutter', 'moral', 'spirit', 'integrity'],
    'author': 'Folk Tale (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 8700,
    'rating': 4.7,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1050,
    'episodes': [
      {'id': 'story_06_ep_01', 'episodeNumber': 1, 'title': 'The Lost Axe', 'description': 'A poor woodcutter accidentally drops his only axe into the river.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(601), 'duration': 510, 'views': 6500, 'status': 'published', 'isPublished': true},
      {'id': 'story_06_ep_02', 'episodeNumber': 2, 'title': 'The Spirit\'s Test', 'description': 'A river spirit offers golden and silver axes to test the woodcutter.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(602), 'duration': 540, 'views': 6200, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_07',
    'title': 'The Boy Who Cried Wolf',
    'description': 'A shepherd boy who repeatedly lies about wolves learns why trust matters when a real wolf arrives.',
    'thumbnailUrl': _thumb(7),
    'bannerUrl': _banner(7),
    'genreId': 'fable',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['wolf', 'boy', 'lies', 'trust', 'shepherd'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 14300,
    'rating': 4.4,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1500,
    'episodes': [
      {'id': 'story_07_ep_01', 'episodeNumber': 1, 'title': 'First Cry', 'description': 'The bored shepherd boy shouts "Wolf!" for the first time.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(701), 'duration': 490, 'views': 11000, 'status': 'published', 'isPublished': true},
      {'id': 'story_07_ep_02', 'episodeNumber': 2, 'title': 'Nobody Believes', 'description': 'After crying wolf multiple times, the villagers stop coming.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(702), 'duration': 510, 'views': 9800, 'status': 'published', 'isPublished': true},
      {'id': 'story_07_ep_03', 'episodeNumber': 3, 'title': 'The Real Wolf', 'description': 'A real wolf appears and the boy learns a hard lesson.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(703), 'duration': 500, 'views': 9200, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_08',
    'title': 'The Ant and the Grasshopper',
    'description': 'An industrious ant prepares for winter while a carefree grasshopper plays music all summer long.',
    'thumbnailUrl': _thumb(8),
    'bannerUrl': _banner(8),
    'genreId': 'fable',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['ant', 'grasshopper', 'work', 'preparation', 'seasons'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 10100,
    'rating': 4.5,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1100,
    'episodes': [
      {'id': 'story_08_ep_01', 'episodeNumber': 1, 'title': 'Summer Days', 'description': 'The ant works hard while the grasshopper sings and plays.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(801), 'duration': 530, 'views': 7800, 'status': 'published', 'isPublished': true},
      {'id': 'story_08_ep_02', 'episodeNumber': 2, 'title': 'Winter Comes', 'description': 'When winter arrives, the grasshopper learns the value of preparation.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(802), 'duration': 570, 'views': 7200, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_09',
    'title': 'The Greedy Dog',
    'description': 'A dog carrying a bone sees its reflection in water and loses everything by trying to grab the reflection.',
    'thumbnailUrl': _thumb(9),
    'bannerUrl': _banner(9),
    'genreId': 'fable',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['dog', 'greed', 'reflection', 'moral', 'fable'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 7600,
    'rating': 4.3,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 950,
    'episodes': [
      {'id': 'story_09_ep_01', 'episodeNumber': 1, 'title': 'A Fine Bone', 'description': 'A dog finds a juicy bone and happily trots home.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(901), 'duration': 460, 'views': 5800, 'status': 'published', 'isPublished': true},
      {'id': 'story_09_ep_02', 'episodeNumber': 2, 'title': 'The Reflection', 'description': 'Seeing its reflection in water, the dog snaps and loses its bone.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(902), 'duration': 490, 'views': 5400, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_10',
    'title': 'The Fox and the Grapes',
    'description': 'A hungry fox cannot reach high-hanging grapes and convinces itself they were sour anyway.',
    'thumbnailUrl': _thumb(10),
    'bannerUrl': _banner(10),
    'genreId': 'fable',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['fox', 'grapes', 'sour', 'excuses', 'fable'],
    'author': 'Aesop (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 9200,
    'rating': 4.4,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 980,
    'episodes': [
      {'id': 'story_10_ep_01', 'episodeNumber': 1, 'title': 'The Vineyard', 'description': 'A hungry fox discovers a vineyard with beautiful ripe grapes.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(1001), 'duration': 470, 'views': 7000, 'status': 'published', 'isPublished': true},
      {'id': 'story_10_ep_02', 'episodeNumber': 2, 'title': 'Sour Grapes', 'description': 'Unable to reach them, the fox walks away with a famous excuse.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(1002), 'duration': 510, 'views': 6800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_11',
    'title': 'The Three Little Pigs',
    'description': 'Three pig siblings build houses of straw, sticks, and bricks, each learning about the importance of hard work.',
    'thumbnailUrl': _thumb(11),
    'bannerUrl': _banner(11),
    'genreId': 'fairy-tale',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['pigs', 'wolf', 'houses', 'hard-work', 'fairy-tale'],
    'author': 'Folk Tale (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 21000,
    'rating': 4.8,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1700,
    'episodes': [
      {'id': 'story_11_ep_01', 'episodeNumber': 1, 'title': 'Three Houses', 'description': 'Each pig builds a house from different materials.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(1101), 'duration': 550, 'views': 16000, 'status': 'published', 'isPublished': true},
      {'id': 'story_11_ep_02', 'episodeNumber': 2, 'title': 'Huff and Puff', 'description': 'The big bad wolf blows down the straw and stick houses.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(1102), 'duration': 580, 'views': 15500, 'status': 'published', 'isPublished': true},
      {'id': 'story_11_ep_03', 'episodeNumber': 3, 'title': 'The Brick House', 'description': 'The wolf meets his match at the brick house.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(1103), 'duration': 570, 'views': 14800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_12',
    'title': 'The Ugly Duckling',
    'description': 'A misfit duckling, mocked by everyone, transforms into a beautiful swan, discovering its true identity.',
    'thumbnailUrl': _thumb(12),
    'bannerUrl': _banner(12),
    'genreId': 'fairy-tale',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['duckling', 'swan', 'transformation', 'identity', 'beauty'],
    'author': 'Hans Christian Andersen (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 16500,
    'rating': 4.7,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1650,
    'episodes': [
      {'id': 'story_12_ep_01', 'episodeNumber': 1, 'title': 'The Different One', 'description': 'A strange-looking duckling hatches and faces mockery.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(1201), 'duration': 540, 'views': 12000, 'status': 'published', 'isPublished': true},
      {'id': 'story_12_ep_02', 'episodeNumber': 2, 'title': 'The Lonely Journey', 'description': 'The duckling wanders alone through harsh seasons.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(1202), 'duration': 560, 'views': 11500, 'status': 'published', 'isPublished': true},
      {'id': 'story_12_ep_03', 'episodeNumber': 3, 'title': 'The Beautiful Swan', 'description': 'Spring reveals the duckling\'s true identity as a graceful swan.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(1203), 'duration': 550, 'views': 11000, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_13',
    'title': 'The Little Red Hen',
    'description': 'A hen asks her friends for help planting wheat, but none help — until the bread is baked.',
    'thumbnailUrl': _thumb(13),
    'bannerUrl': _banner(13),
    'genreId': 'fable',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['hen', 'work', 'cooperation', 'effort', 'bread'],
    'author': 'Folk Tale (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 8900,
    'rating': 4.5,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1050,
    'episodes': [
      {'id': 'story_13_ep_01', 'episodeNumber': 1, 'title': 'Who Will Help?', 'description': 'The hen asks for help planting wheat, but nobody volunteers.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(1301), 'duration': 510, 'views': 6800, 'status': 'published', 'isPublished': true},
      {'id': 'story_13_ep_02', 'episodeNumber': 2, 'title': 'Fresh Bread', 'description': 'When the bread is ready, everyone wants to eat, but the hen has a lesson.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(1302), 'duration': 540, 'views': 6500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_14',
    'title': 'The Fisherman and His Wife',
    'description': 'A fisherman catches a magical fish, and his wife\'s endless wishes lead to an unexpected ending.',
    'thumbnailUrl': _thumb(14),
    'bannerUrl': _banner(14),
    'genreId': 'fairy-tale',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['fisherman', 'wishes', 'greed', 'magic', 'fish'],
    'author': 'Brothers Grimm (Adapted)',
    'status': 'published',
    'episodeCount': 3,
    'views': 10800,
    'rating': 4.6,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1580,
    'episodes': [
      {'id': 'story_14_ep_01', 'episodeNumber': 1, 'title': 'The Magic Fish', 'description': 'A poor fisherman catches a magical talking fish.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(1401), 'duration': 520, 'views': 8200, 'status': 'published', 'isPublished': true},
      {'id': 'story_14_ep_02', 'episodeNumber': 2, 'title': 'Wish After Wish', 'description': 'The fisherman\'s wife demands increasingly grand wishes.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(1402), 'duration': 530, 'views': 7800, 'status': 'published', 'isPublished': true},
      {'id': 'story_14_ep_03', 'episodeNumber': 3, 'title': 'The Final Wish', 'description': 'The wife\'s greed reaches its ultimate consequence.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(1403), 'duration': 530, 'views': 7500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_15',
    'title': 'The Emperor\'s New Clothes',
    'description': 'Two weavers promise a vain emperor invisible clothes, and only a child dares to tell the truth.',
    'thumbnailUrl': _thumb(15),
    'bannerUrl': _banner(15),
    'genreId': 'satire',
    'categoryId': 'classic-tales',
    'language': 'en',
    'tags': ['emperor', 'clothes', 'truth', 'vanity', 'honesty'],
    'author': 'Hans Christian Andersen (Adapted)',
    'status': 'published',
    'episodeCount': 2,
    'views': 13200,
    'rating': 4.7,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1100,
    'episodes': [
      {'id': 'story_15_ep_01', 'episodeNumber': 1, 'title': 'The Royal Weavers', 'description': 'Two clever swindlers claim to weave magical invisible cloth.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(1501), 'duration': 550, 'views': 10000, 'status': 'published', 'isPublished': true},
      {'id': 'story_15_ep_02', 'episodeNumber': 2, 'title': 'The Parade', 'description': 'The emperor parades in his "new clothes" and a child speaks the truth.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(1502), 'duration': 550, 'views': 9500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_16',
    'title': 'The Magic Lamp',
    'description': 'A young street-smart adventurer discovers an ancient lamp containing a powerful spirit who grants wishes.',
    'thumbnailUrl': _thumb(16),
    'bannerUrl': _banner(16),
    'genreId': 'adventure',
    'categoryId': 'folklore',
    'language': 'en',
    'tags': ['lamp', 'genie', 'wishes', 'adventure', 'folklore'],
    'author': 'Arabian Nights (Public Domain Adaptation)',
    'status': 'published',
    'episodeCount': 3,
    'views': 19500,
    'rating': 4.8,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1750,
    'episodes': [
      {'id': 'story_16_ep_01', 'episodeNumber': 1, 'title': 'The Cave of Wonders', 'description': 'A young adventurer enters a mysterious underground cave.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(1601), 'duration': 580, 'views': 15000, 'status': 'published', 'isPublished': true},
      {'id': 'story_16_ep_02', 'episodeNumber': 2, 'title': 'Three Wishes', 'description': 'The spirit of the lamp appears and offers three wishes.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(1602), 'duration': 590, 'views': 14500, 'status': 'published', 'isPublished': true},
      {'id': 'story_16_ep_03', 'episodeNumber': 3, 'title': 'The True Treasure', 'description': 'The adventurer learns that the real treasure was within all along.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(1603), 'duration': 580, 'views': 14000, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_17',
    'title': 'Voyages of the Brave Sailor',
    'description': 'A daring sailor embarks on seven legendary voyages across uncharted seas filled with monsters and wonders.',
    'thumbnailUrl': _thumb(17),
    'bannerUrl': _banner(17),
    'genreId': 'adventure',
    'categoryId': 'folklore',
    'language': 'en',
    'tags': ['sailor', 'voyage', 'sea', 'adventure', 'monsters'],
    'author': 'Arabian Nights (Public Domain Adaptation)',
    'status': 'published',
    'episodeCount': 3,
    'views': 17800,
    'rating': 4.6,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1800,
    'episodes': [
      {'id': 'story_17_ep_01', 'episodeNumber': 1, 'title': 'Setting Sail', 'description': 'The sailor sets off on his first great voyage across unknown seas.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(1701), 'duration': 600, 'views': 13500, 'status': 'published', 'isPublished': true},
      {'id': 'story_17_ep_02', 'episodeNumber': 2, 'title': 'The Island of Giants', 'description': 'The crew lands on a mysterious island inhabited by enormous creatures.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(1702), 'duration': 600, 'views': 13000, 'status': 'published', 'isPublished': true},
      {'id': 'story_17_ep_03', 'episodeNumber': 3, 'title': 'Return Home', 'description': 'After facing incredible dangers, the sailor finally returns with wisdom.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(1703), 'duration': 600, 'views': 12500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_18',
    'title': 'The Clever Farmer',
    'description': 'A humble farmer outsmarks a cunning landlord using nothing but wits and a talking scarecrow.',
    'thumbnailUrl': _thumb(18),
    'bannerUrl': _banner(18),
    'genreId': 'comedy',
    'categoryId': 'folklore',
    'language': 'en',
    'tags': ['farmer', 'clever', 'landlord', 'wit', 'comedy'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 2,
    'views': 7800,
    'rating': 4.4,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1050,
    'episodes': [
      {'id': 'story_18_ep_01', 'episodeNumber': 1, 'title': 'The Unfair Demand', 'description': 'A greedy landlord threatens to take the farmer\'s land.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(1801), 'duration': 520, 'views': 6000, 'status': 'published', 'isPublished': true},
      {'id': 'story_18_ep_02', 'episodeNumber': 2, 'title': 'The Talking Scarecrow', 'description': 'The farmer devises a clever scheme involving a "magical" scarecrow.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(1802), 'duration': 530, 'views': 5800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_19',
    'title': 'The Wise Old Man',
    'description': 'A village elder shares three pieces of advice that save a young traveler from three separate disasters.',
    'thumbnailUrl': _thumb(19),
    'bannerUrl': _banner(19),
    'genreId': 'wisdom',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['wisdom', 'elder', 'advice', 'journey', 'life-lessons'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 3,
    'views': 9500,
    'rating': 4.7,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1600,
    'episodes': [
      {'id': 'story_19_ep_01', 'episodeNumber': 1, 'title': 'Three Golden Words', 'description': 'A young man receives three pieces of advice from a village elder.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(1901), 'duration': 520, 'views': 7200, 'status': 'published', 'isPublished': true},
      {'id': 'story_19_ep_02', 'episodeNumber': 2, 'title': 'The First Test', 'description': 'The first piece of advice saves the traveler from bandits.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(1902), 'duration': 540, 'views': 7000, 'status': 'published', 'isPublished': true},
      {'id': 'story_19_ep_03', 'episodeNumber': 3, 'title': 'Wisdom Proven', 'description': 'All three pieces of advice prove their worth in dramatic fashion.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(1903), 'duration': 540, 'views': 6800, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_20',
    'title': 'The Magic Tree',
    'description': 'Children discover a tree that grows a different fruit for every kind deed performed beneath its branches.',
    'thumbnailUrl': _thumb(20),
    'bannerUrl': _banner(20),
    'genreId': 'fantasy',
    'categoryId': 'fantasy',
    'language': 'en',
    'tags': ['magic', 'tree', 'kindness', 'fantasy', 'children'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 2,
    'views': 11200,
    'rating': 4.6,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1100,
    'episodes': [
      {'id': 'story_20_ep_01', 'episodeNumber': 1, 'title': 'The Discovery', 'description': 'Two children find a glowing tree deep in the village garden.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(2001), 'duration': 540, 'views': 8500, 'status': 'published', 'isPublished': true},
      {'id': 'story_20_ep_02', 'episodeNumber': 2, 'title': 'Seeds of Kindness', 'description': 'They learn that the tree rewards kindness with magical fruit.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(2002), 'duration': 560, 'views': 8000, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_21',
    'title': 'The Brave Little Sparrow',
    'description': 'The smallest bird in the forest stands up to a storm to protect the other animals, inspiring unexpected courage.',
    'thumbnailUrl': _thumb(21),
    'bannerUrl': _banner(21),
    'genreId': 'adventure',
    'categoryId': 'moral-stories',
    'language': 'en',
    'tags': ['sparrow', 'brave', 'courage', 'storm', 'birds'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 2,
    'views': 8300,
    'rating': 4.5,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1050,
    'episodes': [
      {'id': 'story_21_ep_01', 'episodeNumber': 1, 'title': 'The Coming Storm', 'description': 'Dark clouds gather and all the forest animals panic — except one tiny sparrow.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(2101), 'duration': 510, 'views': 6200, 'status': 'published', 'isPublished': true},
      {'id': 'story_21_ep_02', 'episodeNumber': 2, 'title': 'Wings of Courage', 'description': 'The sparrow braves the storm and leads the animals to shelter.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(2102), 'duration': 540, 'views': 6000, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_22',
    'title': 'The Lost Kingdom',
    'description': 'An explorer discovers the ruins of a forgotten kingdom beneath a mountain, unlocking secrets of an ancient civilization.',
    'thumbnailUrl': _thumb(22),
    'bannerUrl': _banner(22),
    'genreId': 'adventure',
    'categoryId': 'fantasy',
    'language': 'en',
    'tags': ['kingdom', 'explorer', 'ruins', 'ancient', 'discovery'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 3,
    'views': 14700,
    'rating': 4.8,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1700,
    'episodes': [
      {'id': 'story_22_ep_01', 'episodeNumber': 1, 'title': 'The Hidden Map', 'description': 'An old map reveals the entrance to a kingdom lost for centuries.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(2201), 'duration': 560, 'views': 11000, 'status': 'published', 'isPublished': true},
      {'id': 'story_22_ep_02', 'episodeNumber': 2, 'title': 'The Underground City', 'description': 'The explorer descends into a vast underground city of gold and stone.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(2202), 'duration': 580, 'views': 10500, 'status': 'published', 'isPublished': true},
      {'id': 'story_22_ep_03', 'episodeNumber': 3, 'title': 'The Guardian\'s Secret', 'description': 'A final guardian reveals why the kingdom was hidden from the world.', 'videoUrl': _videos[3], 'thumbnailUrl': _thumb(2203), 'duration': 560, 'views': 10000, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_23',
    'title': 'The Mysterious Forest',
    'description': 'A group of friends enters a forest where time moves differently and trees whisper forgotten memories.',
    'thumbnailUrl': _thumb(23),
    'bannerUrl': _banner(23),
    'genreId': 'mystery',
    'categoryId': 'fantasy',
    'language': 'en',
    'tags': ['forest', 'mystery', 'time', 'friends', 'memories'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 3,
    'views': 12100,
    'rating': 4.6,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1650,
    'episodes': [
      {'id': 'story_23_ep_01', 'episodeNumber': 1, 'title': 'Beyond the Treeline', 'description': 'Three friends cross into a forest that no one has entered in years.', 'videoUrl': _videos[4], 'thumbnailUrl': _thumb(2301), 'duration': 540, 'views': 9200, 'status': 'published', 'isPublished': true},
      {'id': 'story_23_ep_02', 'episodeNumber': 2, 'title': 'Whispers in the Leaves', 'description': 'The trees begin to whisper, revealing glimpses of the past.', 'videoUrl': _videos[5], 'thumbnailUrl': _thumb(2302), 'duration': 560, 'views': 8800, 'status': 'published', 'isPublished': true},
      {'id': 'story_23_ep_03', 'episodeNumber': 3, 'title': 'Finding the Way Home', 'description': 'The friends must solve the forest\'s riddle to escape before time runs out.', 'videoUrl': _videos[6], 'thumbnailUrl': _thumb(2303), 'duration': 550, 'views': 8500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_24',
    'title': 'The Village of Seven Bells',
    'description': 'A traveler arrives at a village where seven magical bells control the weather, seasons, and emotions.',
    'thumbnailUrl': _thumb(24),
    'bannerUrl': _banner(24),
    'genreId': 'fantasy',
    'categoryId': 'folklore',
    'language': 'en',
    'tags': ['village', 'bells', 'magic', 'weather', 'folklore'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 3,
    'views': 10500,
    'rating': 4.5,
    'isTrending': false,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1600,
    'episodes': [
      {'id': 'story_24_ep_01', 'episodeNumber': 1, 'title': 'The Bell Tower', 'description': 'A weary traveler hears enchanting bells from a distant village.', 'videoUrl': _videos[7], 'thumbnailUrl': _thumb(2401), 'duration': 520, 'views': 8000, 'status': 'published', 'isPublished': true},
      {'id': 'story_24_ep_02', 'episodeNumber': 2, 'title': 'The Seventh Bell', 'description': 'Six bells ring every day, but the seventh has been silent for a century.', 'videoUrl': _videos[8], 'thumbnailUrl': _thumb(2402), 'duration': 540, 'views': 7700, 'status': 'published', 'isPublished': true},
      {'id': 'story_24_ep_03', 'episodeNumber': 3, 'title': 'The Bell Ringer', 'description': 'The traveler must ring the seventh bell to save the village from eternal winter.', 'videoUrl': _videos[9], 'thumbnailUrl': _thumb(2403), 'duration': 540, 'views': 7500, 'status': 'published', 'isPublished': true},
    ],
  },
  {
    'id': 'story_25',
    'title': 'The Last Lantern',
    'description': 'In a world where light is fading, one child holds the last lantern and must carry it to the top of the world.',
    'thumbnailUrl': _thumb(25),
    'bannerUrl': _banner(25),
    'genreId': 'fantasy',
    'categoryId': 'fantasy',
    'language': 'en',
    'tags': ['lantern', 'light', 'darkness', 'hope', 'journey'],
    'author': 'Original Demo Story',
    'status': 'published',
    'episodeCount': 3,
    'views': 16800,
    'rating': 4.9,
    'isTrending': true,
    'isDemo': true,
    'isPublished': true,
    'ageCategory': 'all-ages',
    'totalDuration': 1750,
    'episodes': [
      {'id': 'story_25_ep_01', 'episodeNumber': 1, 'title': 'The Dying Light', 'description': 'As darkness spreads across the world, one lantern still burns.', 'videoUrl': _videos[0], 'thumbnailUrl': _thumb(2501), 'duration': 570, 'views': 13000, 'status': 'published', 'isPublished': true},
      {'id': 'story_25_ep_02', 'episodeNumber': 2, 'title': 'The Long Climb', 'description': 'A child carries the last lantern toward the peak of the highest mountain.', 'videoUrl': _videos[1], 'thumbnailUrl': _thumb(2502), 'duration': 590, 'views': 12500, 'status': 'published', 'isPublished': true},
      {'id': 'story_25_ep_03', 'episodeNumber': 3, 'title': 'Dawn Returns', 'description': 'At the summit, the lantern\'s light spreads across the world, bringing dawn.', 'videoUrl': _videos[2], 'thumbnailUrl': _thumb(2503), 'duration': 590, 'views': 12000, 'status': 'published', 'isPublished': true},
    ],
  },
];
