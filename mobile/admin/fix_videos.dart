import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:storyverse/firebase_options.dart';

const _videos = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Fixing Episode URLs in Firestore...');
  final firestore = FirebaseFirestore.instance;

  final stories = await firestore.collection('stories').get();
  int updatedCount = 0;
  int videoIndex = 0;

  for (var story in stories.docs) {
    final episodes = await story.reference.collection('episodes').get();
    for (var ep in episodes.docs) {
      final data = ep.data();
      final String videoUrl = data['videoUrl'] ?? '';

      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        final newUrl = _videos[videoIndex % _videos.length];
        await ep.reference.update({'videoUrl': newUrl});
        updatedCount++;
        videoIndex++;
        print('Updated episode ${ep.id} in story ${story.id} to $newUrl');
      }
    }
  }

  print('Finished updating $updatedCount episodes.');
  exit(0);
}
