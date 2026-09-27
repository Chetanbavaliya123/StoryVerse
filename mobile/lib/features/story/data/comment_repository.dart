import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storyverse/core/models/comment_model.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class CommentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentRepository(this._firestore, this._auth);

  /// Stream comments for a story in real time
  Stream<List<CommentModel>> streamComments(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  /// Add a comment to a story
  Future<void> addComment({
    required String storyId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to comment');

    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Comment cannot be empty');
    if (trimmed.length > 500) throw Exception('Comment too long (max 500 characters)');

    await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email?.split('@').first ?? 'User',
      'userPhoto': user.photoURL,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a comment (only if user owns it)
  Future<void> deleteComment(String storyId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (doc.exists && doc.data()?['userId'] == user.uid) {
      await doc.reference.delete();
    }
  }
}
