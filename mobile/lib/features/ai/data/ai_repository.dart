import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storyverse/core/models/ai_generation_model.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final aiGenerationProvider = StreamProvider.family<AiGenerationModel?, String>((ref, id) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('aiGenerations').doc(id).snapshots().map((doc) {
    if (doc.exists) return AiGenerationModel.fromFirestore(doc);
    return null;
  });
});

class AiRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AiRepository(this._firestore, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  /// Generate a story using mock backend (ready for Cloud Functions integration)
  Future<String> generateStory({
    required String userId,
    required String prompt,
    required String genre,
  }) async {
    final uid = _uid ?? userId;
    if (uid.isEmpty) throw Exception('Must be logged in');

    // Create pending generation document
    final docRef = await _firestore.collection('aiGenerations').add({
      'userId': uid,
      'prompt': prompt,
      'result': null,
      'status': 'generating',
      'type': 'story',
      'genre': genre,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Simulate AI generation with mock response
    // In production, this would trigger a Cloud Function
    await Future.delayed(const Duration(seconds: 2));

    final mockResult = _generateMockResult(prompt, 'story');

    await docRef.update({
      'result': mockResult,
      'status': 'completed',
    });

    final doc = await docRef.get();
    return doc.id;
  }

  /// Send a message to AI assistant
  Future<String> sendMessage({
    required String userId,
    required String message,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return "This is a demo response to: '$message'. In production, this would be connected to the Gemini API via Firebase Cloud Functions to provide character backgrounds, story lore, and conversational AI assistance.";
  }

  /// Get user's generation history
  Future<List<AiGenerationModel>> getGenerations() async {
    final uid = _uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('aiGenerations')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => AiGenerationModel.fromFirestore(doc)).toList();
  }

  /// Delete a generation
  Future<void> deleteGeneration(String generationId) async {
    await _firestore.collection('aiGenerations').doc(generationId).delete();
  }

  String _generateMockResult(String prompt, String type) {
    switch (type) {
      case 'story':
        return '''**Generated Story Based on: "$prompt"**

Once upon a time, in a world where stories came alive, there lived a storyteller who possessed an extraordinary gift. Every word they spoke would manifest into reality, painting vivid scenes across the sky.

The journey began on a misty morning when the storyteller discovered an ancient book hidden beneath the roots of the oldest tree in the village. Its pages were blank, waiting for new tales to be written.

As the storyteller opened the book, a warm golden light spilled from its pages, illuminating the path ahead. Each chapter would bring new challenges, new friends, and new adventures that would test the very fabric of imagination.

"Every story has the power to change the world," whispered the book. "But only if the storyteller believes."

And so the adventure began...

---
*This is a demo AI-generated story. Connect to Gemini API via Firebase Cloud Functions for production-quality generation.*''';
      case 'plot':
        return '''**Plot Outline for: "$prompt"**

**Act 1 - Setup:**
• Introduce the protagonist in their ordinary world
• Establish the central conflict and stakes
• Present the inciting incident that disrupts normalcy

**Act 2 - Confrontation:**
• The protagonist faces escalating challenges
• Key allies and antagonists are introduced
• A major setback forces the protagonist to adapt

**Act 3 - Resolution:**
• The climax brings all threads together
• The protagonist makes a decisive choice
• Resolution reveals how the journey transformed them

**Themes:** Courage, self-discovery, the power of stories
**Tone:** Adventurous with emotional depth
**Target Audience:** All ages

---
*Demo plot outline. Connect Gemini API for AI-powered generation.*''';
      case 'character':
        return '''**Character Profile for: "$prompt"**

**Name:** To be determined by the storyteller
**Role:** Protagonist

**Background:**
A curious soul with an insatiable thirst for knowledge and adventure. Raised in a small village but always dreaming of the world beyond the horizon.

**Personality Traits:**
• Brave but sometimes reckless
• Compassionate and loyal to friends
• Quick-witted with a sharp sense of humor
• Struggles with self-doubt in quiet moments

**Motivation:** To uncover the truth about their mysterious past
**Fear:** Being forgotten or losing those they love
**Strength:** Ability to inspire others through storytelling
**Weakness:** Tendency to take on too much alone

---
*Demo character profile. Connect Gemini API for richer generation.*''';
      default:
        return '''**AI Generation for: "$prompt"**

This is a demonstration of the StoryVerse AI generation system. In the production version, this would connect to Google Gemini via Firebase Cloud Functions to generate creative content.

The system supports:
• Story generation
• Plot outlines
• Character profiles
• Dialogue suggestions

---
*Demo output. Configure Firebase Cloud Functions + Gemini API for production use.*''';
    }
  }
}
