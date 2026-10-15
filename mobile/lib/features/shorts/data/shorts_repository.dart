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

          // Query multiple stories to collect a rich candidate pool of episodes
          final storiesToQuery = eligibleStories.take(15).toList();

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

              if (eligibleEpisodes.isEmpty) return <ShortsItem>[];

              // Include all valid episodes from this story as candidates
              return eligibleEpisodes
                  .map((ep) => ShortsItem(story: story, episode: ep))
                  .toList();
            } catch (_) {
              return <ShortsItem>[];
            }
          });

          final results = await Future.wait(episodeFutures);
          final allCandidates = results.expand((list) => list).toList();

          if (allCandidates.isNotEmpty) {
            allCandidates.shuffle(_random);

            // Filter unseen episodes in this session
            var unseen = allCandidates
                .where((item) => !_seenEpisodeKeys.contains(item.uniqueKey))
                .toList();

            // If we've seen all or almost all, reset seen cache so user has continuous endless feed
            if (unseen.isEmpty) {
              _seenEpisodeKeys.clear();
              unseen = allCandidates;
            }

            final batch = unseen.take(batchSize).toList();
            for (final item in batch) {
              _seenEpisodeKeys.add(item.uniqueKey);
            }

            return batch;
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
    final allCandidates = <ShortsItem>[];
    final stories = demoStoryCatalog.where((s) => s.status == 'published').toList();

    for (final story in stories) {
      final episodes = demoEpisodesCatalog[story.id] ?? [];
      final validEpisodes = episodes
          .where((ep) =>
              ep.videoUrl.trim().isNotEmpty &&
              !VideoUrlHelper.isYouTube(ep.videoUrl))
          .toList();

      for (final ep in validEpisodes) {
        allCandidates.add(ShortsItem(story: story, episode: ep));
      }
    }

    if (allCandidates.isEmpty) return [];

    allCandidates.shuffle(_random);

    var unseen = allCandidates
        .where((item) => !_seenEpisodeKeys.contains(item.uniqueKey))
        .toList();

    if (unseen.isEmpty) {
      _seenEpisodeKeys.clear();
      unseen = allCandidates;
    }

    final batch = unseen.take(batchSize).toList();
    for (final item in batch) {
      _seenEpisodeKeys.add(item.uniqueKey);
    }

    return batch;
  }
}
