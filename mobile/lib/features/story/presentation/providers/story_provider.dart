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
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';

final masterCatalogProvider = StreamProvider<List<StoryModel>>((ref) {
  return ref.watch(storyRepositoryProvider).streamStories();
});

final trendingStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    final trending = list.where((s) => s.isTrending).take(5).toList();
    return trending.isNotEmpty ? trending : list.take(5).toList();
  });
});

final latestStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    return list.take(10).toList();
  });
});

final allStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    return list.take(50).toList();
  });
});

final popularStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    var sorted = List<StoryModel>.from(list);
    sorted.sort((a, b) => b.views.compareTo(a.views));
    return sorted.take(20).toList();
  });
});

final topTenStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    var sorted = List<StoryModel>.from(list);
    sorted.sort((a, b) {
      double scoreA = a.views + (a.rating * 100);
      double scoreB = b.views + (b.rating * 100);
      return scoreB.compareTo(scoreA);
    });
    return sorted.take(10).toList();
  });
});

final storiesByLanguageProvider = Provider.family<AsyncValue<List<StoryModel>>, String>((ref, language) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    return list.where((s) => s.language.trim().toLowerCase() == language.trim().toLowerCase()).toList();
  });
});

final storiesByMultiFilterProvider = Provider.family<AsyncValue<List<StoryModel>>, Map<String, String?>>((ref, filters) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    var filtered = List<StoryModel>.from(list);
    
    final genre = filters['genre'];
    if (genre != null && genre.isNotEmpty) {
      filtered = filtered.where((s) => s.genreId.toLowerCase() == genre.toLowerCase()).toList();
    }
    
    final language = filters['language'];
    if (language != null && language.isNotEmpty) {
      filtered = filtered.where((s) => s.language.trim().toLowerCase() == language.trim().toLowerCase()).toList();
    }
    
    final category = filters['category'];
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((s) => s.categoryId.toLowerCase() == category.toLowerCase()).toList();
    }
    
    return filtered;
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
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    final genres = list
        .map((s) => s.genreId)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return genres;
  });
});

final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final catalogAsync = ref.watch(masterCatalogProvider);
  return catalogAsync.whenData((catalog) {
    final list = catalog.isNotEmpty
        ? catalog
        : ref.read(storyRepositoryProvider).getDemoStories();
    final categories = list
        .map((s) => s.categoryId)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
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
        final list = catalog.isNotEmpty
            ? catalog
            : ref.read(storyRepositoryProvider).getDemoStories();
        final target = genreId.trim().toLowerCase();
        return list
            .where((s) {
              final g = s.genreId.trim().toLowerCase();
              final tags = s.tags.map((t) => t.trim().toLowerCase()).toList();
              return g == target || tags.contains(target);
            })
            .take(20)
            .toList();
      });
    });

final storiesByCategoryProvider =
    Provider.family<AsyncValue<List<StoryModel>>, String>((ref, categoryId) {
      final catalogAsync = ref.watch(masterCatalogProvider);
      return catalogAsync.whenData((catalog) {
        final list = catalog.isNotEmpty
            ? catalog
            : ref.read(storyRepositoryProvider).getDemoStories();
        return list
            .where((s) => s.categoryId.toLowerCase() == categoryId.toLowerCase())
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
  // Bind to auth state changes for strict user isolation
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return [];

  final historyRepo = ref.watch(watchHistoryRepositoryProvider);
  final history = await historyRepo.getContinueWatching();
  if (history.isEmpty) return [];

  final storyRepo = ref.watch(storyRepositoryProvider);
  final futures = history.map((entry) async {
    try {
      final story = await storyRepo.getStory(entry.storyId);
      final episodes = await storyRepo.getEpisodes(entry.storyId);
      if (story != null && episodes.isNotEmpty) {
        final episode = episodes.firstWhere(
          (e) => e.id == entry.episodeId,
          orElse: () => episodes.first,
        );
        return ContinueWatchingItem(
          story: story,
          episode: episode,
          history: entry,
        );
      }
    } catch (_) {}
    return null;
  }).toList();

  final resolved = await Future.wait(futures);
  return resolved.whereType<ContinueWatchingItem>().toList();
});
