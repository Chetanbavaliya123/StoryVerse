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

  // Load both master catalog and continue watching together using Future.wait
  final catalogFuture = ref.watch(masterCatalogProvider.future).catchError((_) {
    return storyRepo.getDemoStories();
  });
  final historyFuture = ref.watch(continueWatchingProvider.future).catchError((_) {
    return <ContinueWatchingItem>[];
  });

  final results = await Future.wait([catalogFuture, historyFuture]);
  final catalog = results[0] as List<StoryModel>;
  final continueWatching = results[1] as List<ContinueWatchingItem>;

  final list = catalog.isNotEmpty ? catalog : storyRepo.getDemoStories();

  final trending = list.where((s) => s.isTrending).take(5).toList();
  final heroStories = trending.isNotEmpty ? trending : list.take(5).toList();

  final sorted = List<StoryModel>.from(list);
  sorted.sort((a, b) {
    final double scoreA = a.views + (a.rating * 100);
    final double scoreB = b.views + (b.rating * 100);
    return scoreB.compareTo(scoreA);
  });
  final topTen = sorted.take(10).toList();

  final newArrivals = list.take(10).toList();

  return HomeFeedData(
    heroStories: heroStories,
    continueWatching: continueWatching,
    topTen: topTen,
    newArrivals: newArrivals,
  );
});
