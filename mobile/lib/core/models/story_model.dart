import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String title;
  final String description;
  final String? fullDescription;
  final String thumbnailUrl;
  final String? bannerUrl;
  final String genreId;
  final String categoryId;
  final String language;
  final List<String> tags;
  final String author;
  final String status;
  final int episodeCount;
  final int views;
  final double rating;
  final bool isDemo;
  final bool isPublished;
  final bool isTrending;
  final bool isNew;
  final bool isPopular;
  final bool isTopTen;
  final String? ageCategory;
  final int totalDuration; // in seconds
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoryModel({
    required this.id,
    required this.title,
    required this.description,
    this.fullDescription,
    required this.thumbnailUrl,
    this.bannerUrl,
    required this.genreId,
    required this.categoryId,
    required this.language,
    required this.tags,
    required this.author,
    required this.status,
    required this.episodeCount,
    required this.views,
    required this.rating,
    this.isDemo = false,
    this.isPublished = true,
    this.isTrending = false,
    this.isNew = false,
    this.isPopular = false,
    this.isTopTen = false,
    this.ageCategory,
    this.totalDuration = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fullDescription: data['fullDescription'],
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      bannerUrl: data['bannerUrl'],
      genreId: data['genreId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      language: data['language'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      author: data['author'] ?? '',
      status: data['status'] ?? 'draft',
      episodeCount: (data['totalEpisodes'] ?? data['episodeCount'] ?? 0)
          .toInt(),
      views: (data['totalViews'] ?? data['views'] ?? 0).toInt(),
      rating: (data['rating'] ?? 0).toDouble(),
      isDemo: data['isDemo'] ?? false,
      isPublished: data['isPublished'] ?? (data['status'] == 'published'),
      isTrending: data['isTrending'] == true,
      isNew: data['isNew'] == true || data['isNewArrival'] == true,
      isPopular: data['isPopular'] == true || data['isHero'] == true,
      isTopTen: data['isTopTen'] == true,
      ageCategory: data['ageCategory'],
      totalDuration: data['totalDuration']?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory StoryModel.fromMap(Map<String, dynamic> data, String docId) {
    return StoryModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fullDescription: data['fullDescription'],
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      bannerUrl: data['bannerUrl'],
      genreId: data['genreId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      language: data['language'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      author: data['author'] ?? '',
      status: data['status'] ?? 'draft',
      episodeCount: (data['totalEpisodes'] ?? data['episodeCount'] ?? 0)
          .toInt(),
      views: (data['totalViews'] ?? data['views'] ?? 0).toInt(),
      rating: (data['rating'] ?? 0).toDouble(),
      isDemo: data['isDemo'] ?? false,
      isPublished: data['isPublished'] ?? (data['status'] == 'published'),
      isTrending: data['isTrending'] == true,
      isNew: data['isNew'] == true || data['isNewArrival'] == true,
      isPopular: data['isPopular'] == true || data['isHero'] == true,
      isTopTen: data['isTopTen'] == true,
      ageCategory: data['ageCategory'],
      totalDuration: data['totalDuration']?.toInt() ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  StoryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? fullDescription,
    String? thumbnailUrl,
    String? bannerUrl,
    String? genreId,
    String? categoryId,
    String? language,
    List<String>? tags,
    String? author,
    String? status,
    int? episodeCount,
    int? views,
    double? rating,
    bool? isDemo,
    bool? isPublished,
    bool? isTrending,
    bool? isNew,
    bool? isPopular,
    bool? isTopTen,
    String? ageCategory,
    int? totalDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fullDescription: fullDescription ?? this.fullDescription,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      genreId: genreId ?? this.genreId,
      categoryId: categoryId ?? this.categoryId,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      status: status ?? this.status,
      episodeCount: episodeCount ?? this.episodeCount,
      views: views ?? this.views,
      rating: rating ?? this.rating,
      isDemo: isDemo ?? this.isDemo,
      isPublished: isPublished ?? this.isPublished,
      isTrending: isTrending ?? this.isTrending,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      isTopTen: isTopTen ?? this.isTopTen,
      ageCategory: ageCategory ?? this.ageCategory,
      totalDuration: totalDuration ?? this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fullDescription': fullDescription,
      'thumbnailUrl': thumbnailUrl,
      'bannerUrl': bannerUrl,
      'genreId': genreId,
      'categoryId': categoryId,
      'language': language,
      'tags': tags,
      'author': author,
      'status': status,
      'episodeCount': episodeCount,
      'views': views,
      'rating': rating,
      'isDemo': isDemo,
      'isPublished': isPublished,
      'isTrending': isTrending,
      'isNew': isNew,
      'isNewArrival': isNew,
      'isPopular': isPopular,
      'isTopTen': isTopTen,
      'ageCategory': ageCategory,
      'totalDuration': totalDuration,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
