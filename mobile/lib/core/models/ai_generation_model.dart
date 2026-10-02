import 'package:cloud_firestore/cloud_firestore.dart';

class AiGenerationModel {
  final String id;
  final String userId;
  final String prompt;
  final dynamic result;
  final String status; // 'pending', 'generating', 'completed', 'failed'
  final String type; // 'story', 'plot', 'character', 'dialogue'
  final String genre;
  final String language;
  final DateTime? createdAt;

  AiGenerationModel({
    required this.id,
    required this.userId,
    required this.prompt,
    this.result,
    required this.status,
    required this.type,
    this.genre = 'Fantasy',
    this.language = 'en',
    this.createdAt,
  });

  factory AiGenerationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AiGenerationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      prompt: data['prompt'] ?? '',
      result: data['result'],
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'story',
      genre: data['genre'] ?? 'Fantasy',
      language: data['language'] ?? 'en',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'result': result,
      'status': status,
      'type': type,
      'genre': genre,
      'language': language,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isGenerating => status == 'generating';
  bool get isFailed => status == 'failed';

  String? get title {
    if (result == null) return null;
    if (result is Map) {
      return result['title'] as String?;
    }
    if (result is String) {
      if ((result as String).isEmpty) return null;
      final lines = (result as String).split('\n');
      return lines.first.replaceAll('**', '').trim();
    }
    return null;
  }

  String? get storyContent {
    if (result == null) return null;
    if (result is Map) {
      final baseStory = result['story'] as String? ?? '';

      final chaptersRaw = result['chapters'];
      if (chaptersRaw != null && chaptersRaw is List) {
        final chaptersText = chaptersRaw
            .map((c) {
              if (c is Map) {
                final title = c['title'] ?? '';
                final content = c['content'] ?? '';
                return '\n\n### $title\n\n$content';
              }
              return '';
            })
            .join('');

        return '$baseStory$chaptersText'.trim();
      }
      return baseStory;
    }
    if (result is String) {
      if ((result as String).isEmpty) return null;
      final lines = (result as String).split('\n');
      if (lines.length <= 1) return result as String;
      return lines.sublist(1).join('\n').trim();
    }
    return null;
  }
}
