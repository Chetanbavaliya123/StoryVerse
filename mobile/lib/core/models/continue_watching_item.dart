import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/watch_history_model.dart';

class ContinueWatchingItem {
  final StoryModel story;
  final EpisodeModel episode;
  final WatchHistoryModel history;

  ContinueWatchingItem({
    required this.story,
    required this.episode,
    required this.history,
  });
}
