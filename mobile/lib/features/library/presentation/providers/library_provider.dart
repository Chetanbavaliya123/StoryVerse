import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:storyverse/features/library/data/library_repository.dart';

final isFavoriteProvider = StreamProvider.family<bool, String>((ref, storyId) {
  return ref.watch(libraryRepositoryProvider).isFavorite(storyId);
});

final favoriteStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null) {
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final watchHistoryStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('watchHistory')
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    Set<String> processedStoryIds = {};
    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null && !processedStoryIds.contains(storyId)) {
        processedStoryIds.add(storyId);
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final libraryStoriesProvider = StreamProvider<List<StoryModel>>((ref) async* {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  final stream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('library')
      .snapshots();

  await for (final snapshot in stream) {
    final storyRepo = ref.read(storyRepositoryProvider);
    List<StoryModel> stories = [];
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aDate = (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bDate = (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final storyFutures = <Future<StoryModel?>>[];
    for (var doc in docs) {
      final storyId = doc.data()['storyId'] as String?;
      if (storyId != null) {
        storyFutures.add(storyRepo.getStory(storyId));
      }
    }
    final resolvedStories = await Future.wait(storyFutures);
    for (var story in resolvedStories) {
      if (story != null) {
        stories.add(story);
      }
    }
    yield stories;
  }
});

final savedStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final asyncStories = ref.watch(libraryStoriesProvider);
  return asyncStories.whenData((allStories) => 
      allStories.where((s) => s.categoryId != 'ai-generated').toList());
});

final aiStoriesProvider = Provider<AsyncValue<List<StoryModel>>>((ref) {
  final asyncStories = ref.watch(libraryStoriesProvider);
  return asyncStories.whenData((allStories) => 
      allStories.where((s) => s.categoryId == 'ai-generated').toList());
});
