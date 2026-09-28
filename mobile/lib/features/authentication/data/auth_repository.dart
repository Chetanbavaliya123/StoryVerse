import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      print('AUTH LOGIN SUCCESS\nuid: ${user.uid}\nemail: ${user.email}');
      final userRef = _firestore.collection('users').doc(user.uid);
      print('UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt');
      try {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('LOGIN TIMESTAMP UPDATE SUCCESS\nuid: ${user.uid}');
      } catch (e, stackTrace) {
        print('LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace');
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
      print('AUTH LOGIN SUCCESS\nuid: ${user.uid}\nemail: ${user.email}');
      print('UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt');
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
        print('LOGIN TIMESTAMP UPDATE SUCCESS\nuid: ${user.uid}');
      } catch (e, stackTrace) {
        print('LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace');
      }
    }

    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
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
        print('AUTH LOGIN SUCCESS\nuid: ${user.uid}\nemail: ${user.email}');
        final userRef = _firestore.collection('users').doc(user.uid);
        print('UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt');
        try {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email,
            'photoUrl': user.photoURL,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'role': 'user',
          }, SetOptions(merge: true));
          print('LOGIN TIMESTAMP UPDATE SUCCESS\nuid: ${user.uid}');
        } catch (e, stackTrace) {
          print('LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace');
        }
      }
      return userCredential;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
