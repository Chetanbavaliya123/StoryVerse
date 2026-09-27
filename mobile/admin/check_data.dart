import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final snap = await FirebaseFirestore.instance.collection('stories').get();
  print('Total stories in Firestore: ${snap.docs.length}');
  
  if (snap.docs.isNotEmpty) {
    print('First story: ${snap.docs.first.data()}');
  } else {
    print('No stories found!');
  }
}
