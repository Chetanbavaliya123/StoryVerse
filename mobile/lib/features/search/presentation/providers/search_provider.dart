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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      state = value;
      if (value.trim().isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).add(value.trim());
      }
    });
  }

  void setImmediate(String value) {
    _debounceTimer?.cancel();
    state = value;
    if (value.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).add(value.trim());
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return [
      'Romance',
      'Action Thriller',
      'Hindi Stories',
      'Sci-Fi',
      'Ghost Hunter',
    ];
  }

  void add(String term) {
    if (term.trim().isEmpty) return;
    final clean = term.trim();
    final updated = List<String>.from(state)..remove(clean);
    updated.insert(0, clean);
    if (updated.length > 8) {
      updated.removeLast();
    }
    state = updated;
  }

  void remove(String term) {
    final updated = List<String>.from(state)..remove(term);
    state = updated;
  }

  void clearAll() {
    state = [];
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(() {
  return RecentSearchesNotifier();
});

final searchStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(storyRepositoryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  return repo.searchStories(query);
});
