import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/data/demo_story_catalog.dart';
import 'package:storyverse/core/utils/video_url_helper.dart';

final shortsRepositoryProvider = Provider<ShortsRepository>((ref) {
  return ShortsRepository(FirebaseFirestore.instance);
});

class ShortsItem {
  final StoryModel story;
  final EpisodeModel episode;

  const ShortsItem({
    required this.story,
    required this.episode,
  });

  String get uniqueKey => '${story.id}_${episode.id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortsItem &&
          runtimeType == other.runtimeType &&
          story.id == other.story.id &&
          episode.id == other.episode.id;

  @override
  int get hashCode => story.id.hashCode ^ episode.id.hashCode;
}

class ShortsRepository {
  final FirebaseFirestore? _firestore;
  final Random _random = Random();
  final Set<String> _seenEpisodeKeys = <String>{};

  ShortsRepository([this._firestore]) {
    initializeDemoCatalog();
  }

  /// Clears seen episode cache for a fresh session
  void resetSeenSession() {
    _seenEpisodeKeys.clear();
  }

  /// Fetches a randomized batch of eligible public episodes across public stories.
  /// Batching prevents fetching the entire database at once.
  Future<List<ShortsItem>> fetchRandomShortsBatch({int batchSize = 10}) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        // 1. Fetch published public stories from Firestore
        final storiesSnapshot = await firestore
            .collection('stories')
            .where('status', isEqualTo: 'published')
            .get()
            .timeout(const Duration(seconds: 8));

        final eligibleStories = storiesSnapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .where((s) => s.isPublished && s.categoryId != 'ai-generated')
            .toList();

        if (eligibleStories.isNotEmpty) {
          // Shuffle stories to ensure varied discovery across genres and languages
          eligibleStories.shuffle(_random);

          // Sample stories and query their episodes subcollections in parallel
          final storiesToQuery = eligibleStories.take(batchSize).toList();

          final episodeFutures = storiesToQuery.map((story) async {
            try {
              final episodesSnapshot = await firestore
                  .collection('stories')
                  .doc(story.id)
                  .collection('episodes')
                  .where('isPublished', isEqualTo: true)
                  .get()
                  .timeout(const Duration(seconds: 4));

              final eligibleEpisodes = episodesSnapshot.docs
                  .map((doc) => EpisodeModel.fromFirestore(doc))
                  .where((ep) =>
                      ep.isPublished &&
                      ep.status == 'published' &&
                      ep.videoUrl.trim().isNotEmpty &&
                      !VideoUrlHelper.isYouTube(ep.videoUrl))
                  .toList();

              if (eligibleEpisodes.isEmpty) return null;

              eligibleEpisodes.shuffle(_random);

              // Find an episode not seen yet in this session
              EpisodeModel? selectedEpisode;
              for (final ep in eligibleEpisodes) {
                final key = '${story.id}_${ep.id}';
                if (!_seenEpisodeKeys.contains(key)) {
                  selectedEpisode = ep;
                  _seenEpisodeKeys.add(key);
                  break;
                }
              }

              selectedEpisode ??= eligibleEpisodes.first;
              return ShortsItem(story: story, episode: selectedEpisode);
            } catch (_) {
              return null;
            }
          });

          final results = await Future.wait(episodeFutures);
          final items = results.whereType<ShortsItem>().toList();

          if (items.isNotEmpty) {
            items.shuffle(_random);
            return items;
          }
        }
      } catch (_) {
        // Fall through to local fallback catalog on Firestore error / timeout
      }
    }

    // 2. Offline / Fallback Catalog handling
    return getFallbackShortsBatch(batchSize);
  }

  /// Builds a randomized batch from demo catalog when offline or Firestore empty
  List<ShortsItem> getFallbackShortsBatch(int batchSize) {
    final items = <ShortsItem>[];
    final stories = demoStoryCatalog.where((s) => s.status == 'published').toList();
    stories.shuffle(_random);

    for (final story in stories) {
      if (items.length >= batchSize) break;

      final episodes = demoEpisodesCatalog[story.id] ?? [];
      final validEpisodes = episodes
          .where((ep) =>
              ep.videoUrl.trim().isNotEmpty &&
              !VideoUrlHelper.isYouTube(ep.videoUrl))
          .toList();

      if (validEpisodes.isEmpty) continue;
      validEpisodes.shuffle(_random);

      EpisodeModel? chosenEp;
      for (final ep in validEpisodes) {
        final key = '${story.id}_${ep.id}';
        if (!_seenEpisodeKeys.contains(key)) {
          chosenEp = ep;
          _seenEpisodeKeys.add(key);
          break;
        }
      }
      chosenEp ??= validEpisodes.first;

      items.add(ShortsItem(story: story, episode: chosenEp));
    }

    items.shuffle(_random);
    return items;
  }
}
