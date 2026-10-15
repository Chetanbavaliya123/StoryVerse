import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';

class HomeFeedData {
  final List<StoryModel> heroStories;
  final List<ContinueWatchingItem> continueWatching;
  final List<StoryModel> topTen;
  final List<StoryModel> newArrivals;

  const HomeFeedData({
    required this.heroStories,
    required this.continueWatching,
    required this.topTen,
    required this.newArrivals,
  });
}

final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  final storyRepo = ref.read(storyRepositoryProvider);

  // Watch masterCatalogProvider and continueWatchingProvider reactively
  final catalogAsync = ref.watch(masterCatalogProvider);
  final continueWatchingAsync = ref.watch(continueWatchingProvider);

  List<StoryModel> list;
  if (catalogAsync.hasValue && catalogAsync.value!.isNotEmpty) {
    list = catalogAsync.value!;
  } else if (catalogAsync.isLoading) {
    try {
      final streamResult = await ref.watch(masterCatalogProvider.future);
      list = streamResult.isNotEmpty ? streamResult : storyRepo.getDemoStories();
    } catch (_) {
      list = storyRepo.getDemoStories();
    }
  } else {
    list = storyRepo.getDemoStories();
  }

  final continueWatching = continueWatchingAsync.value ?? <ContinueWatchingItem>[];

  // 1. Hero stories (Featured in Hero Carousel)
  // When an admin flags stories with "Feature in Hero Carousel (Popular)",
  // exactly those stories should appear in the Hero Carousel slider!
  final flaggedHero = list.where((s) => s.isPopular).toList();
  List<StoryModel> heroStories;
  if (flaggedHero.isNotEmpty) {
    heroStories = flaggedHero;
  } else {
    // Fallback ONLY when zero stories have been flagged by the admin
    final trending = list.where((s) => s.isTrending).toList();
    heroStories = trending.isNotEmpty ? trending : list;
  }

  // 2. Top 10 Ranked stories (Prioritize isTopTen, then highest popularity score, up to 10)
  final topTen = <StoryModel>[];
  for (final s in list.where((s) => s.isTopTen)) {
    if (topTen.length >= 10) break;
    if (!topTen.any((item) => item.id == s.id)) {
      topTen.add(s);
    }
  }
  final sortedByScore = List<StoryModel>.from(list);
  sortedByScore.sort((a, b) {
    final double scoreA = a.views + (a.rating * 100);
    final double scoreB = b.views + (b.rating * 100);
    return scoreB.compareTo(scoreA);
  });
  for (final s in sortedByScore) {
    if (topTen.length >= 10) break;
    if (!topTen.any((item) => item.id == s.id)) {
      topTen.add(s);
    }
  }

  // 3. New Arrivals (Prioritize isNew, then newest by date, up to 10)
  final newArrivals = <StoryModel>[];
  for (final s in list.where((s) => s.isNew)) {
    if (newArrivals.length >= 10) break;
    if (!newArrivals.any((item) => item.id == s.id)) {
      newArrivals.add(s);
    }
  }
  final sortedByDate = List<StoryModel>.from(list);
  sortedByDate.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
  for (final s in sortedByDate) {
    if (newArrivals.length >= 10) break;
    if (!newArrivals.any((item) => item.id == s.id)) {
      newArrivals.add(s);
    }
  }

  return HomeFeedData(
    heroStories: heroStories,
    continueWatching: continueWatching,
    topTen: topTen,
    newArrivals: newArrivals,
  );
});
