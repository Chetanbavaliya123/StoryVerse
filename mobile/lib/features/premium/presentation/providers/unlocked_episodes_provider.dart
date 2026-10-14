import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnlockedEpisodesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void unlockEpisode(String episodeId) {
    state = {...state, episodeId};
  }

  bool isUnlocked(String episodeId) {
    return state.contains(episodeId);
  }
}

final unlockedEpisodesProvider =
    NotifierProvider<UnlockedEpisodesNotifier, Set<String>>(() {
  return UnlockedEpisodesNotifier();
});
