import 'package:cloud_firestore/cloud_firestore.dart';

class EpisodeModel {
  final String id;
  final String storyId;
  final int episodeNumber;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration; // in seconds
  final int views;
  final String status;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  EpisodeModel({
    required this.id,
    required this.storyId,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.views,
    required this.status,
    this.isPublished = true,
    this.publishedAt,
    this.createdAt,
  });

  factory EpisodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EpisodeModel(
      id: doc.id,
      storyId: data['storyId'] ?? '',
      episodeNumber: data['episodeNumber']?.toInt() ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      duration: data['duration']?.toInt() ?? 0,
      views: data['views']?.toInt() ?? 0,
      status: data['status'] ?? 'draft',
      isPublished: data['isPublished'] ?? (data['status'] == 'published'),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory EpisodeModel.fromMap(Map<String, dynamic> data, String docId) {
    return EpisodeModel(
      id: docId,
      storyId: data['storyId'] ?? '',
      episodeNumber: data['episodeNumber']?.toInt() ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      duration: data['duration']?.toInt() ?? 0,
      views: data['views']?.toInt() ?? 0,
      status: data['status'] ?? 'draft',
      isPublished: data['isPublished'] ?? (data['status'] == 'published'),
      publishedAt: data['publishedAt'] is Timestamp
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'views': views,
      'status': status,
      'isPublished': isPublished,
      'publishedAt': publishedAt != null
          ? Timestamp.fromDate(publishedAt!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}
