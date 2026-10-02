import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

final favoriteStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .get();

  final storyRepo = ref.read(storyRepositoryProvider);
  List<StoryModel> stories = [];

  var docs = snapshot.docs;
  docs.sort((a, b) {
    final aDate =
        (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    final bDate =
        (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    return bDate.compareTo(aDate);
  });

  for (var doc in docs) {
    final storyId = doc.data()['storyId'] as String?;
    if (storyId != null) {
      final story = await storyRepo.getStory(storyId);
      if (story != null) {
        stories.add(story);
      }
    }
  }
  return stories;
});

final watchHistoryStoriesProvider = FutureProvider<List<StoryModel>>((
  ref,
) async {
  // For demo purposes, we will return some trending stories as history
  // since real tracking isn't fully implemented yet
  return ref.watch(storyRepositoryProvider).getStories(limit: 5);
});

final libraryStoriesProvider = FutureProvider<List<StoryModel>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('library')
      .get();

  final storyRepo = ref.read(storyRepositoryProvider);
  List<StoryModel> stories = [];

  var docs = snapshot.docs;
  docs.sort((a, b) {
    final aDate =
        (a.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    final bDate =
        (b.data()['addedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    return bDate.compareTo(aDate);
  });

  for (var doc in docs) {
    final storyId = doc.data()['storyId'] as String?;
    if (storyId != null) {
      final story = await storyRepo.getStory(storyId);
      if (story != null) {
        stories.add(story);
      }
    }
  }
  return stories;
});
