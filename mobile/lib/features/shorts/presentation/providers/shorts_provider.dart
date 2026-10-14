import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/shorts/data/shorts_repository.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class ShortsMuteNotifier extends Notifier<bool> {
  @override
  bool build() {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null && profile.preferences.containsKey('isMuted')) {
      return profile.preferences['isMuted'] as bool? ?? false;
    }
    return false;
  }

  void setMuted(bool value) {
    state = value;
  }
}

final shortsMuteProvider = NotifierProvider<ShortsMuteNotifier, bool>(() {
  return ShortsMuteNotifier();
});

final shortsFeedProvider =
    AsyncNotifierProvider<ShortsFeedNotifier, List<ShortsItem>>(() {
      return ShortsFeedNotifier();
    });

class ShortsFeedNotifier extends AsyncNotifier<List<ShortsItem>> {
  bool _isLoadingMore = false;

  @override
  Future<List<ShortsItem>> build() async {
    final repo = ref.read(shortsRepositoryProvider);
    return await repo.fetchRandomShortsBatch(batchSize: 10);
  }

  /// Appends another batch of random episodes to the feed as the user scrolls
  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    final currentList = state.value;
    if (currentList == null) return;

    _isLoadingMore = true;
    try {
      final repo = ref.read(shortsRepositoryProvider);
      final nextBatch = await repo.fetchRandomShortsBatch(batchSize: 8);

      if (nextBatch.isNotEmpty) {
        state = AsyncData([...currentList, ...nextBatch]);
      }
    } catch (_) {
      // Keep existing list on pagination error
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Refreshes feed with a fresh random batch and resets session cache
  Future<void> refreshFeed() async {
    final repo = ref.read(shortsRepositoryProvider);
    repo.resetSeenSession();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.fetchRandomShortsBatch(batchSize: 10),
    );
  }
}
