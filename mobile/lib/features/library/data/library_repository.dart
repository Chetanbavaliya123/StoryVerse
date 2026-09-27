import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class LibraryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LibraryRepository(this._firestore, this._auth);

  Stream<bool> isFavorite(String storyId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore.collection('users').doc(user.uid).collection('favorites').doc(storyId).snapshots().map((doc) => doc.exists);
  }

  Future<void> toggleFavorite(String storyId, bool isAdding) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid).collection('favorites').doc(storyId);
    if (isAdding) {
      await ref.set({'addedAt': FieldValue.serverTimestamp(), 'storyId': storyId});
    } else {
      await ref.delete();
    }
  }

  Stream<bool> isInLibrary(String storyId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore.collection('users').doc(user.uid).collection('library').doc(storyId).snapshots().map((doc) => doc.exists);
  }

  Future<void> toggleLibrary(String storyId, bool isAdding) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid).collection('library').doc(storyId);
    if (isAdding) {
      await ref.set({'addedAt': FieldValue.serverTimestamp(), 'storyId': storyId});
    } else {
      await ref.delete();
    }
  }
}
