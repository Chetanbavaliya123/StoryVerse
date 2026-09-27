import 'package:cloud_firestore/cloud_firestore.dart';

class WatchHistoryModel {
  final String id;
  final String userId;
  final String storyId;
  final String episodeId;
  final int progressSeconds;
  final int totalDuration;
  final double percentage;
  final bool isCompleted;
  final DateTime? lastWatchedAt;

  WatchHistoryModel({
    required this.id,
    required this.userId,
    required this.storyId,
    required this.episodeId,
    required this.progressSeconds,
    required this.totalDuration,
    required this.percentage,
    required this.isCompleted,
    this.lastWatchedAt,
  });

  factory WatchHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WatchHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      storyId: data['storyId'] ?? '',
      episodeId: data['episodeId'] ?? '',
      progressSeconds: data['progressSeconds']?.toInt() ?? 0,
      totalDuration: data['totalDuration']?.toInt() ?? 0,
      percentage: (data['percentage'] ?? 0).toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      lastWatchedAt: (data['lastWatchedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storyId': storyId,
      'episodeId': episodeId,
      'progressSeconds': progressSeconds,
      'totalDuration': totalDuration,
      'percentage': percentage,
      'isCompleted': isCompleted,
      'lastWatchedAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeLeftFormatted {
    final left = totalDuration - progressSeconds;
    if (left <= 0) return 'Completed';
    final m = left ~/ 60;
    final s = left % 60;
    return '${m}m ${s}s left';
  }

  String get progressFormatted {
    return '${(percentage * 100).round()}% completed';
  }
}
