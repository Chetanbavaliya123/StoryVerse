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
      .limit(20)
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
      .limit(20)
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
      .limit(20)
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
      .limit(20)
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

final aiStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final asyncStories = ref.watch(libraryStoriesProvider);
  return asyncStories.whenData((allStories) => 
      allStories.where((s) => s.categoryId == 'ai-generated').toList());
});
