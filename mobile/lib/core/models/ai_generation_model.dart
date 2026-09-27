import 'package:cloud_firestore/cloud_firestore.dart';

class AiGenerationModel {
  final String id;
  final String userId;
  final String prompt;
  final String? result;
  final String status; // 'pending', 'generating', 'completed', 'failed'
  final String type; // 'story', 'plot', 'character', 'dialogue'
  final String genre;
  final DateTime? createdAt;

  AiGenerationModel({
    required this.id,
    required this.userId,
    required this.prompt,
    this.result,
    required this.status,
    required this.type,
    this.genre = 'Fantasy',
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
    if (result == null || result!.isEmpty) return null;
    final lines = result!.split('\n');
    return lines.first.replaceAll('**', '').trim();
  }

  String? get storyContent {
    if (result == null || result!.isEmpty) return null;
    final lines = result!.split('\n');
    if (lines.length <= 1) return result;
    return lines.sublist(1).join('\n').trim();
  }
}
