import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementModel {
  final String id;
  final String title;
  final String subtitle;
  final String? ctaText;
  final String? imageUrl;
  final String? targetRoute;
  final bool isActive;
  final int priority;
  final bool isDemo;
  final DateTime? createdAt;

  AdvertisementModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.ctaText,
    this.imageUrl,
    this.targetRoute,
    this.isActive = true,
    this.priority = 0,
    this.isDemo = false,
    this.createdAt,
  });

  factory AdvertisementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdvertisementModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      ctaText: data['ctaText'],
      imageUrl: data['imageUrl'],
      targetRoute: data['targetRoute'],
      isActive: data['isActive'] ?? true,
      priority: data['priority']?.toInt() ?? 0,
      isDemo: data['isDemo'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'ctaText': ctaText,
      'imageUrl': imageUrl,
      'targetRoute': targetRoute,
      'isActive': isActive,
      'priority': priority,
      'isDemo': isDemo,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
