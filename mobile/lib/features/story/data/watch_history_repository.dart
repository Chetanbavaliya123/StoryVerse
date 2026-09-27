import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storyverse/core/models/watch_history_model.dart';

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  return WatchHistoryRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class WatchHistoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WatchHistoryRepository(this._firestore, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  /// Save or update watch progress for an episode
  Future<void> updateProgress({
    required String storyId,
    required String episodeId,
    required int progressSeconds,
    required int totalDuration,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final percentage = totalDuration > 0 ? progressSeconds / totalDuration : 0.0;
      final isCompleted = percentage >= 0.9; // 90% = completed

      // Use deterministic ID so we don't create duplicates
      final docId = '${storyId}_$episodeId';

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('watchHistory')
          .doc(docId)
          .set({
        'userId': uid,
        'storyId': storyId,
        'episodeId': episodeId,
        'progressSeconds': progressSeconds,
        'totalDuration': totalDuration,
        'percentage': percentage,
        'isCompleted': isCompleted,
        'lastWatchedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to update watch progress: $e');
    }
  }

  /// Get watch history entry for a specific episode
  Future<WatchHistoryModel?> getEpisodeProgress(String storyId, String episodeId) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final docId = '${storyId}_$episodeId';
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('watchHistory')
          .doc(docId)
          .get();

      if (doc.exists) {
        return WatchHistoryModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Failed to get episode progress: $e');
    }
    return null;
  }

  /// Get all in-progress episodes (for Continue Watching)
  Future<List<WatchHistoryModel>> getContinueWatching() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('watchHistory')
          .where('isCompleted', isEqualTo: false)
          .where('percentage', isGreaterThan: 0)
          .orderBy('percentage', descending: true)
          .orderBy('lastWatchedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => WatchHistoryModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Failed to get continue watching: $e');
      return [];
    }
  }

  /// Get all watch history (for History tab)
  Future<List<WatchHistoryModel>> getWatchHistory() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('watchHistory')
          .orderBy('lastWatchedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => WatchHistoryModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Failed to get watch history: $e');
      return [];
    }
  }

  /// Clear all watch history
  Future<void> clearHistory() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('watchHistory')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Failed to clear history: $e');
    }
  }
}
