import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/advertisement_model.dart';
import 'package:storyverse/core/models/comment_model.dart';
import 'package:storyverse/features/story/data/comment_repository.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';
import 'package:storyverse/core/models/watch_history_model.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';

final masterCatalogProvider = StreamProvider<List<StoryModel>>((ref) async* {
  print('=================================');
  print('STORYVERSE CATALOG STREAM INIT');
  print('=================================');
  yield ref
      .read(storyRepositoryProvider)
      .getDemoStories(); // Initial state while loading

  yield* ref.read(storyRepositoryProvider).streamStories();
});

final trendingStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    return catalog.where((s) => s.isTrending).take(5).toList();
  });
});

final latestStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    return catalog.take(10).toList();
  });
});

final allStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    return catalog.take(50).toList();
  });
});

final storyDetailsProvider = FutureProvider.family<StoryModel?, String>((
  ref,
  id,
) async {
  return ref.watch(storyRepositoryProvider).getStory(id);
});

final storyEpisodesProvider = StreamProvider.family<List<EpisodeModel>, String>(
  (ref, storyId) {
    return ref.watch(storyRepositoryProvider).streamEpisodes(storyId);
  },
);

final advertisementsProvider = FutureProvider<List<AdvertisementModel>>((
  ref,
) async {
  return ref.watch(storyRepositoryProvider).getAdvertisements();
});

final genresProvider = Provider<AsyncValue<List<String>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    return catalog
        .map((s) => s.genreId)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  });
});

final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    return catalog
        .map((s) => s.categoryId)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  });
});

final storyCommentsProvider = StreamProvider.family<List<CommentModel>, String>(
  (ref, storyId) {
    return ref.watch(commentRepositoryProvider).streamComments(storyId);
  },
);

final storiesByGenreProvider =
    Provider.family<AsyncValue<List<StoryModel>>, String>((ref, genreId) {
      final catalogAsync = ref.watch(masterCatalogProvider);
      return catalogAsync.whenData((catalog) {
        return catalog.where((s) => s.genreId == genreId).take(20).toList();
      });
    });

final storiesByCategoryProvider =
    Provider.family<AsyncValue<List<StoryModel>>, String>((ref, categoryId) {
      final catalogAsync = ref.watch(masterCatalogProvider);
      return catalogAsync.whenData((catalog) {
        return catalog
            .where((s) => s.categoryId == categoryId)
            .take(20)
            .toList();
      });
    });

final watchHistoryProgressProvider =
    FutureProvider.family<WatchHistoryModel?, String>((ref, ids) async {
      final parts = ids.split('||');
      if (parts.length != 2) return null;
      return ref
          .watch(watchHistoryRepositoryProvider)
          .getEpisodeProgress(parts[0], parts[1]);
    });

final continueWatchingProvider = FutureProvider<List<ContinueWatchingItem>>((
  ref,
) async {
  final history = await ref
      .watch(watchHistoryRepositoryProvider)
      .getContinueWatching();
  List<ContinueWatchingItem> items = [];

  for (var entry in history) {
    try {
      final story = await ref
          .watch(storyRepositoryProvider)
          .getStory(entry.storyId);
      final episodes = await ref
          .watch(storyRepositoryProvider)
          .getEpisodes(entry.storyId);
      if (story != null && episodes.isNotEmpty) {
        final episode = episodes.firstWhere((e) => e.id == entry.episodeId);
        items.add(
          ContinueWatchingItem(story: story, episode: episode, history: entry),
        );
      }
    } catch (e) {
      // Skip if not found
    }
  }
  return items;
});
