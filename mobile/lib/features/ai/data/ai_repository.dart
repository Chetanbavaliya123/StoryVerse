import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:storyverse/core/config/app_config.dart';
import 'package:storyverse/core/models/ai_generation_model.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final aiGenerationProvider = StreamProvider.family<AiGenerationModel?, String>((
  ref,
  id,
) {
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

  /// Generate a story using Standalone AI Backend
  Future<String> generateStory({
    required String userId,
    required String prompt,
    required String genre,
    String language = 'English',
  }) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[AI] generateStory called');
    final uid = _uid ?? userId;
    if (uid.isEmpty) throw Exception('Must be logged in');

    debugPrint('[AI] API URL configured: ${AppConfig.aiBackendUrl}');
    if (AppConfig.aiBackendUrl.isEmpty) {
      throw Exception(
        'AI service is not configured. Please configure API_URL properly.',
      );
    }

    try {
      debugPrint(
        '[AI] Fetching auth token... elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      final token = await _auth.currentUser?.getIdToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Auth token fetch timed out (Play Services issue)',
        ),
      );
      debugPrint(
        '[AI] Auth token fetched. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      if (token == null) throw Exception('Authentication token unavailable.');

      final urlString = '${AppConfig.aiBackendUrl}/generate-story';
      final url = Uri.parse(urlString);

      debugPrint(
        '[AI] Request starting to $urlString. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'prompt': prompt,
              'category': genre,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint(
        '[AI] Response received, status: ${response.statusCode}. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[AI] Parsing response...');
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('docId')) {
            debugPrint('[AI] Generation successful. docId: ${data['docId']}');
            return data['docId'] as String;
          }
          throw Exception(
            data['error'] ?? 'Unexpected response format: missing docId',
          );
        } catch (e) {
          if (e.toString().contains('Unexpected response')) rethrow;
          throw Exception('Invalid JSON response from AI server');
        }
      } else {
        throw Exception('Server returned error ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint(
        '[AI] TimeoutException. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      debugPrint(
        '[AI] SocketException: $e. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint(
        '[AI] Exception: $e. elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      throw Exception('$e');
    }
  }

  /// Send a message to AI assistant
  Future<String> sendMessage({
    required String userId,
    required String message,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return "This is a demo response to: '$message'. In production, this would be connected to the Gemini API via Firebase Cloud Functions to provide character backgrounds, story lore, and conversational AI assistance.";
  }

  /// Save generated story to user's library as a draft
  Future<String> saveToLibrary(AiGenerationModel gen) async {
    final uid = _uid;
    if (uid == null) throw Exception('Must be logged in');

    // Actually add the saved story to the user's library collection so it shows up in UI
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(gen.id)
        .set({'addedAt': FieldValue.serverTimestamp(), 'storyId': gen.id});

    return gen.id;
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

    return snapshot.docs
        .map((doc) => AiGenerationModel.fromFirestore(doc))
        .toList();
  }

  /// Delete a generation
  Future<void> deleteGeneration(String generationId) async {
    await _firestore.collection('aiGenerations').doc(generationId).delete();
  }
}
