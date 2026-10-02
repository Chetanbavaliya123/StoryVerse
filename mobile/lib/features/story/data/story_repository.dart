import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/advertisement_model.dart';
import 'package:storyverse/core/data/demo_story_catalog.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository(FirebaseFirestore.instance);
});

class StoryRepository {
  final FirebaseFirestore _firestore;

  StoryRepository(this._firestore) {
    initializeDemoCatalog();
  }

  List<StoryModel> getDemoStories() {
    return demoStoryCatalog;
  }

  Stream<List<StoryModel>> streamStories({int limit = 100}) {
    return _firestore
        .collection('stories')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          var stories = snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList();
          stories.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
          return stories.take(limit).toList();
        })
        .handleError((error) {
          print('Firebase Stream Error: $error');
          return getDemoStories(); // Fallback on network/permission error
        });
  }

  Future<List<StoryModel>> getStories({
    int limit = 10,
    String? categoryId,
    String? genreId,
    bool? isTrending,
  }) async {
    try {
      Query query = _firestore
          .collection('stories')
          .where('status', isEqualTo: 'published');

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      if (genreId != null) {
        query = query.where('genreId', isEqualTo: genreId);
      }
      if (isTrending == true) {
        query = query.where('isTrending', isEqualTo: true);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 5));
      var stories = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();

      // Sort locally to avoid Firestore composite index requirements
      stories.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return stories.take(limit).toList();
    } catch (e) {
      // Fallback to local catalog
      var stories = demoStoryCatalog.toList();
      if (categoryId != null) {
        stories = stories.where((s) => s.categoryId == categoryId).toList();
      }
      if (genreId != null) {
        stories = stories.where((s) => s.genreId == genreId).toList();
      }
      if (isTrending == true) {
        stories = stories.where((s) => s.isTrending).toList();
      }
      return stories.take(limit).toList();
    }
  }

  Future<StoryModel?> getStory(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get().timeout(const Duration(seconds: 5));
      if (doc.exists) {
        return StoryModel.fromFirestore(doc);
      }

      // If not found in stories, check aiGenerations (for AI stories saved to library)
      final aiDoc = await _firestore
          .collection('aiGenerations')
          .doc(storyId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (aiDoc.exists) {
        final data = aiDoc.data()!;
        return StoryModel(
          id: aiDoc.id,
          title: data['title'] ?? 'Untitled AI Story',
          description: data['result'] != null && data['result'] is Map
              ? data['result']['description'] ?? ''
              : '',
          fullDescription: data['storyContent'] ?? '',
          thumbnailUrl:
              'https://firebasestorage.googleapis.com/v0/b/storyverse-465bd.appspot.com/o/placeholders%2Fai_story_cover.png?alt=media',
          bannerUrl: null,
          genreId: (data['genre'] ?? 'ai').toString().toLowerCase(),
          categoryId: 'ai-generated',
          language: data['language'] ?? 'English',
          tags: ['ai', (data['genre'] ?? '').toString().toLowerCase()],
          author: data['userId'] ?? 'ai',
          status: 'published',
          episodeCount: 1,
          views: 0,
          rating: 0.0,
          isDemo: false,
          isPublished: true,
          isTrending: false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
    } catch (e) {
      // Fallback
    }
    return demoStoryCatalog.where((s) => s.id == storyId).firstOrNull;
  }

  Stream<List<EpisodeModel>> streamEpisodes(String storyId) {
    return _firestore
        .collection('stories')
        .doc(storyId)
        .collection('episodes')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          var episodes = snapshot.docs
              .map((doc) => EpisodeModel.fromFirestore(doc))
              .toList();
          episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
          return episodes;
        })
        .handleError((error) {
          print('Firebase Stream Error (Episodes): $error');
          return demoEpisodesCatalog[storyId] ?? []; // Fallback
        });
  }

  Future<List<EpisodeModel>> getEpisodes(String storyId) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .doc(storyId)
          .collection('episodes')
          .where('isPublished', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 5));

      var episodes = snapshot.docs
          .map((doc) => EpisodeModel.fromFirestore(doc))
          .toList();
      if (episodes.isNotEmpty) {
        episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
        return episodes;
      }
    } catch (e) {
      // Fallback
    }
    return demoEpisodesCatalog[storyId] ?? [];
  }

  /// Get a single episode by its ID (searches across all stories)
  Future<EpisodeModel?> getEpisode(String storyId, String episodeId) async {
    try {
      final doc = await _firestore
          .collection('stories')
          .doc(storyId)
          .collection('episodes')
          .doc(episodeId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        return EpisodeModel.fromFirestore(doc);
      }
    } catch (e) {
      // Fallback
    }
    final episodes = demoEpisodesCatalog[storyId];
    return episodes?.where((e) => e.id == episodeId).firstOrNull;
  }

  /// Get stories by a list of IDs
  Future<List<StoryModel>> getStoriesByIds(List<String> storyIds) async {
    if (storyIds.isEmpty) return [];

    // Firestore 'whereIn' supports max 30 items
    final chunks = <List<String>>[];
    for (var i = 0; i < storyIds.length; i += 30) {
      chunks.add(
        storyIds.sublist(
          i,
          i + 30 > storyIds.length ? storyIds.length : i + 30,
        ),
      );
    }

    final results = <StoryModel>[];
    try {
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('stories')
            .where(FieldPath.documentId, whereIn: chunk)
            .get()
            .timeout(const Duration(seconds: 5));
        results.addAll(
          snapshot.docs.map((doc) => StoryModel.fromFirestore(doc)),
        );
      }
      return results;
    } catch (e) {
      // Fallback
      return demoStoryCatalog.where((s) => storyIds.contains(s.id)).toList();
    }
  }

  /// Search stories with client-side filtering (reliable for demo)
  Future<List<StoryModel>> searchStories(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    // 1. Search local catalog instantly
    final results = demoStoryCatalog.where((story) {
      return story.title.toLowerCase().contains(lowerQuery) ||
          story.description.toLowerCase().contains(lowerQuery) ||
          story.genreId.toLowerCase().contains(lowerQuery) ||
          story.categoryId.toLowerCase().contains(lowerQuery) ||
          story.author.toLowerCase().contains(lowerQuery) ||
          story.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();

    // 2. Search Firebase and merge
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('status', isEqualTo: 'published')
          .get();
      final fbStories = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .where((story) {
            return story.title.toLowerCase().contains(lowerQuery) ||
                story.description.toLowerCase().contains(lowerQuery) ||
                story.genreId.toLowerCase().contains(lowerQuery) ||
                story.categoryId.toLowerCase().contains(lowerQuery) ||
                story.author.toLowerCase().contains(lowerQuery) ||
                story.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          });

      for (var fbStory in fbStories) {
        if (!results.any((s) => s.id == fbStory.id)) {
          results.add(fbStory);
        }
      }
    } catch (e) {
      // Fallback: ignore error
    }

    return results;
  }

  /// Get advertisements
  Future<List<AdvertisementModel>> getAdvertisements() async {
    try {
      final snapshot = await _firestore
          .collection('advertisements')
          .where('isActive', isEqualTo: true)
          .get();

      var ads = snapshot.docs
          .map((doc) => AdvertisementModel.fromFirestore(doc))
          .toList();
      if (ads.isNotEmpty) {
        ads.sort((a, b) => b.priority.compareTo(a.priority));
        return ads.take(6).toList();
      }
    } catch (e) {
      // Fallback
    }

    final demoAds = [
      AdvertisementModel(
        id: 'ad_01',
        title: 'Discover New Stories',
        subtitle: 'Explore thousands of original stories',
        ctaText: 'Browse Now',
        imageUrl: 'assets/images/ads/ad_01.jpg',
        targetRoute: '/discover',
        isActive: true,
        priority: 6,
        isDemo: true,
        createdAt: DateTime.now(),
      ),
      AdvertisementModel(
        id: 'ad_02',
        title: 'Weekend Story Marathon',
        subtitle: 'Binge-watch the best episodic stories',
        ctaText: 'Start Watching',
        imageUrl: 'assets/images/ads/ad_02.jpg',
        targetRoute: '/home',
        isActive: true,
        priority: 5,
        isDemo: true,
        createdAt: DateTime.now(),
      ),
      AdvertisementModel(
        id: 'ad_03',
        title: 'New Adventures',
        subtitle: 'Fresh episodes drop every Friday',
        ctaText: 'Explore',
        imageUrl: 'assets/images/ads/ad_03.jpg',
        targetRoute: '/discover',
        isActive: true,
        priority: 4,
        isDemo: true,
        createdAt: DateTime.now(),
      ),
    ];
    return demoAds;
  }

  /// Get distinct genres from stories
  Future<List<String>> getGenres() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('status', isEqualTo: 'published')
          .get();

      final genres = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final genre = data['genreId'] as String?;
        if (genre != null && genre.isNotEmpty) {
          genres.add(genre);
        }
      }
      return genres.toList()..sort();
    } catch (e) {
      final genres = demoStoryCatalog.map((s) => s.genreId).toSet().toList();
      genres.sort();
      return genres;
    }
  }

  /// Get distinct categories from stories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('status', isEqualTo: 'published')
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cat = data['categoryId'] as String?;
        if (cat != null && cat.isNotEmpty) {
          categories.add(cat);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      final categories = demoStoryCatalog
          .map((s) => s.categoryId)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    }
  }
}
