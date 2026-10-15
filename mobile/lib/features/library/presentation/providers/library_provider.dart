import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/watch_history_model.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';
import 'package:storyverse/features/library/data/library_repository.dart';

final detailedWatchHistoryProvider =
    StreamProvider<List<ContinueWatchingItem>>((ref) async* {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchHistory')
      .limit(100)
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate =
          (a.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate =
          (b.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final Set<String> processedStoryIds = {};
    final items = <ContinueWatchingItem>[];

    // Parallel resolution of story and episode details
    final futures = docs.map((doc) async {
      final data = doc.data();
      final storyId = data['storyId'] as String?;
      final episodeId = data['episodeId'] as String?;
      if (storyId == null) return null;

      try {
        final story = await storyRepo.getStory(storyId);
        if (story == null) return null;

        final episodes = await storyRepo.getEpisodes(storyId);
        final episode = episodes.firstWhere(
          (e) => e.id == episodeId,
          orElse: () => episodes.isNotEmpty
              ? episodes.first
              : EpisodeModel(
                  id: episodeId ?? 'ep1',
                  storyId: storyId,
                  episodeNumber: 1,
                  title: 'Episode 1',
                  description: 'Episode 1',
                  duration: (data['totalDuration'] as num?)?.toInt() ?? 60,
                  videoUrl: '',
                  thumbnailUrl: story.thumbnailUrl,
                  views: 0,
                  status: 'published',
                  createdAt: DateTime.now(),
                ),
        );
        final historyEntry = WatchHistoryModel.fromFirestore(doc);
        return ContinueWatchingItem(
          story: story,
          episode: episode,
          history: historyEntry,
        );
      } catch (_) {
        return null;
      }
    });

    final resolved = await Future.wait(futures);
    for (final item in resolved) {
      if (item != null && !processedStoryIds.contains(item.story.id)) {
        processedStoryIds.add(item.story.id);
        items.add(item);
      }
    }
    yield items;
  }
});

final isFavoriteProvider = StreamProvider.family<bool, String>((ref, storyId) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(false);
  return ref.watch(libraryRepositoryProvider).isFavorite(storyId);
});

final isInLibraryProvider = StreamProvider.family<bool, String>((ref, storyId) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(false);
  return ref.watch(libraryRepositoryProvider).isInLibrary(storyId);
});

final favoriteStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .limit(100)
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null) {
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final watchHistoryStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchHistory')
      .limit(100)
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    Set<String> processedStoryIds = {};
    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null && !processedStoryIds.contains(storyId)) {
        processedStoryIds.add(storyId);
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final libraryStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('library')
      .limit(100)
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null) {
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final savedStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final asyncStories = ref.watch(libraryStoriesProvider);
  return asyncStories.whenData((allStories) => 
      allStories.where((s) => s.categoryId != 'ai-generated').toList());
});

final aiStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final libraryStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('library')
      .limit(100)
      .snapshots();

  await for (final snapshot in libraryStream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    final stories = <StoryModel>[];
    final processedIds = <String>{};

    for (var doc in snapshot.docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null && !processedIds.contains(storyId)) {
        processedIds.add(storyId);
        final story = await storyRepo.getStory(storyId);
        if (story != null && story.categoryId == 'ai-generated') {
          stories.add(story);
        }
      }
    }

    try {
      final aiGenSnapshot = await FirebaseFirestore.instance
          .collection('aiGenerations')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      for (var doc in aiGenSnapshot.docs) {
        if (!processedIds.contains(doc.id)) {
          processedIds.add(doc.id);
          final data = doc.data();
          final result = data['result'] as Map<String, dynamic>?;
          stories.add(
            StoryModel(
              id: doc.id,
              title: result?['title'] ?? data['title'] ?? 'Untitled AI Story',
              description: result != null ? result['description'] ?? '' : '',
              fullDescription: result?['story'] ?? data['storyContent'] ?? '',
              thumbnailUrl:
                  'https://firebasestorage.googleapis.com/v0/b/storyverse-465bd.appspot.com/o/placeholders%2Fai_story_cover.png?alt=media',
              bannerUrl: null,
              genreId: (data['genre'] ?? 'ai').toString().toLowerCase(),
              categoryId: 'ai-generated',
              language: data['language'] ?? 'English',
              tags: ['ai', (data['genre'] ?? '').toString().toLowerCase()],
              author: user.uid,
              status: 'published',
              episodeCount: 1,
              views: 0,
              rating: 0.0,
              isDemo: false,
              isPublished: true,
              isTrending: false,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              updatedAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
          );
        }
      }
    } catch (_) {
      // Fallback: proceed with stories resolved from user's library
    }

    stories.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    yield stories;
  }
});
