import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';

class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() => '';

  void update(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      state = value;
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final searchStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(storyRepositoryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  return repo.searchStories(query);
});
