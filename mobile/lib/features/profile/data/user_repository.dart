import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/user_model.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).streamCurrentUser();
});

final isPremiumUserProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) return false;
  return profile.role == 'premium' ||
      profile.preferences['isPremium'] == true;
});

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  UserRepository(this._firestore, this._auth, [FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  Stream<UserModel?> streamCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return UserModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        role: 'user',
        createdAt: DateTime.now(),
        preferences: const {},
      );
    });
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      role: 'user',
      createdAt: DateTime.now(),
      preferences: const {},
    );
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (name != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      await user.updatePhotoURL(photoUrl.trim());
    }

    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) data['name'] = name.trim();
    if (photoUrl != null) data['photoUrl'] = photoUrl.trim();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
          'preferences': preferences,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> updateSinglePreference(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
          'preferences': {
            key: value,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<String?> uploadProfileImageBytes({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final ref = _storage.ref().child(
        'users/${user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext');
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    await updateProfile(photoUrl: downloadUrl);
    return downloadUrl;
  }
}
