import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      debugPrint('AUTH LOGIN SUCCESS: ${user.uid} (${user.email})');
      final userRef = _firestore.collection('users').doc(user.uid);
      try {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('LOGIN TIMESTAMP UPDATE SUCCESS: ${user.uid}');
      } catch (e, stackTrace) {
        debugPrint('LOGIN TIMESTAMP UPDATE FAILED: $e\n$stackTrace');
      }
    }

    return userCredential;
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;

    if (user != null) {
      debugPrint('AUTH CREATED USER: ${user.uid}');
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
        debugPrint('USER PROFILE CREATION SUCCESS: ${user.uid}');
      } catch (e, stackTrace) {
        debugPrint('USER PROFILE CREATION FAILED: $e\n$stackTrace');
      }
    }

    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    debugPrint('DIAGNOSTIC: signInWithGoogle started');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '754804931190-ljpu7qrtp34tavg14vf9th1057sm34ps.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          final userRef = _firestore.collection('users').doc(user.uid);
          try {
            final docSnapshot = await userRef.get();
            if (!docSnapshot.exists) {
              await userRef.set({
                'uid': user.uid,
                'name': user.displayName ?? '',
                'email': user.email,
                'photoUrl': user.photoURL,
                'createdAt': FieldValue.serverTimestamp(),
                'lastLoginAt': FieldValue.serverTimestamp(),
                'role': 'user',
              });
              debugPrint('Profile created with role=user');
            } else {
              await userRef.set({
                'lastLoginAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          } catch (e, stackTrace) {
            debugPrint('Error updating Google user profile: $e\n$stackTrace');
          }
        }
        return userCredential;
      }
      return null;
    } catch (e, stack) {
      debugPrint('Error caught in signInWithGoogle: $e\n$stack');
      rethrow;
    }
  }

  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    final uid = user.uid;

    // 1. Re-authenticate if password is provided
    if (password != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }

    // 2. Cascade delete subcollections: watchHistory, favorites, library, notifications
    final subcollections = [
      'watchHistory',
      'favorites',
      'library',
      'notifications',
    ];
    for (final subcol in subcollections) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(uid)
            .collection(subcol)
            .get();
        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('[AUTH] Error deleting subcollection $subcol for $uid: $e');
      }
    }

    // 3. Delete user profile document
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint('[AUTH] Error deleting user document $uid: $e');
    }

    // 4. Delete user account from Firebase Authentication
    await user.delete();

    // 5. Sign out GoogleSignIn session if active
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
