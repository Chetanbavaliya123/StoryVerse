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
      print(
        'UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt',
      );
      try {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('LOGIN TIMESTAMP UPDATE SUCCESS\nuid: ${user.uid}');
      } catch (e, stackTrace) {
        print(
          'LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace',
        );
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
      print(
        'UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt',
      );
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
        print(
          'LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace',
        );
      }
    }

    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    print('DIAGNOSTIC: signInWithGoogle started');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '754804931190-ljpu7qrtp34tavg14vf9th1057sm34ps.apps.googleusercontent.com',
      );
      print('DIAGNOSTIC: Calling googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print(
        'DIAGNOSTIC: googleSignIn.signIn() completed. User: ${googleUser?.email}',
      );

      if (googleUser != null) {
        print('DIAGNOSTIC: Fetching authentication tokens...');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        print('DIAGNOSTIC: Tokens fetched successfully.');

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('DIAGNOSTIC: Calling _auth.signInWithCredential...');
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        print('DIAGNOSTIC: Firebase Auth succeeded. UID: ${user?.uid}');

        if (user != null) {
          print('AUTH LOGIN SUCCESS\nuid: ${user.uid}\nemail: ${user.email}');
          final userRef = _firestore.collection('users').doc(user.uid);
          print(
            'UPDATING LOGIN TIMESTAMP\ncollection: users\ndocument: ${user.uid}\nfield: lastLoginAt',
          );
          try {
            print('DIAGNOSTIC: Fetching Firestore profile...');
            final docSnapshot = await userRef.get();
            print('DIAGNOSTIC: Profile exists: ${docSnapshot.exists}');
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
              print('DIAGNOSTIC: Profile created with role=user');
            } else {
              await userRef.set({
                'lastLoginAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              print('DIAGNOSTIC: Profile lastLoginAt updated securely');
            }
            print('LOGIN TIMESTAMP UPDATE SUCCESS\nuid: ${user.uid}');
          } catch (e, stackTrace) {
            print(
              'LOGIN TIMESTAMP UPDATE FAILED\nuid: ${user.uid}\nerror: $e\nstackTrace: $stackTrace',
            );
          }
        }
        return userCredential;
      }
      print('DIAGNOSTIC: googleUser is null (user cancelled sign-in)');
      return null;
    } catch (e, stack) {
      print('DIAGNOSTIC: Error caught in signInWithGoogle!');
      print('DIAGNOSTIC: Error type: ${e.runtimeType}');
      print('DIAGNOSTIC: Error details: $e');
      print('DIAGNOSTIC: Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
