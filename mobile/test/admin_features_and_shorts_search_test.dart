import 'package:flutter_test/flutter_test.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/shorts/data/shorts_repository.dart';
import 'package:storyverse/features/search/presentation/providers/search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('StoryModel Feature Badges & Flags Tests', () {
    test('StoryModel fromMap correctly parses isNew, isPopular, isTopTen, and isTrending', () {
      final map = {
        'title': 'Test Story',
        'description': 'Description',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'genreId': 'romance',
        'categoryId': 'romance',
        'language': 'Hindi',
        'tags': ['love', 'drama'],
        'author': 'Author Name',
        'status': 'published',
        'totalEpisodes': 5,
        'views': 1200,
        'rating': 4.8,
        'isTrending': true,
        'isNew': true,
        'isPopular': true,
        'isTopTen': true,
      };

      final story = StoryModel.fromMap(map, 'story_123');
      expect(story.id, 'story_123');
      expect(story.isTrending, isTrue);
      expect(story.isNew, isTrue);
      expect(story.isPopular, isTrue);
      expect(story.isTopTen, isTrue);
      expect(story.genreId, 'romance');
      expect(story.categoryId, 'romance');
      expect(story.language, 'Hindi');
    });

    test('StoryModel fromMap correctly parses legacy aliases isNewArrival and isHero', () {
      final map = {
        'title': 'Legacy Story',
        'description': 'Legacy Description',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'genreId': 'horror',
        'categoryId': 'horror',
        'language': 'en',
        'tags': ['ghost'],
        'author': 'Author',
        'status': 'published',
        'episodeCount': 3,
        'views': 500,
        'rating': 4.5,
        'isNewArrival': true,
        'isHero': true,
      };

      final story = StoryModel.fromMap(map, 'legacy_story');
      expect(story.isNew, isTrue);
      expect(story.isPopular, isTrue);
      expect(story.isTopTen, isFalse);
    });

    test('StoryModel toMap preserves all flags including aliases', () {
      final story = StoryModel(
        id: 'story_toMap',
        title: 'Mapped Story',
        description: 'Desc',
        thumbnailUrl: 'https://example.com/t.jpg',
        genreId: 'comedy',
        categoryId: 'comedy',
        language: 'Gujarati',
        tags: ['funny'],
        author: 'Admin',
        status: 'published',
        episodeCount: 10,
        views: 2000,
        rating: 4.9,
        isTrending: true,
        isNew: true,
        isPopular: true,
        isTopTen: true,
      );

      final map = story.toMap();
      expect(map['isTrending'], isTrue);
      expect(map['isNew'], isTrue);
      expect(map['isNewArrival'], isTrue);
      expect(map['isPopular'], isTrue);
      expect(map['isTopTen'], isTrue);
      expect(map['language'], 'Gujarati');
      expect(map['genreId'], 'comedy');
      expect(map['categoryId'], 'comedy');
    });
  });

  group('Shorts Continuous Infinite Random Stream Tests', () {
    test('ShortsRepository getFallbackShortsBatch returns populated random episodes', () {
      final repo = ShortsRepository();
      final batch = repo.getFallbackShortsBatch(6);
      expect(batch.isNotEmpty, isTrue);
      expect(batch.length, lessThanOrEqualTo(6));
      for (final item in batch) {
        expect(item.story.id, isNotEmpty);
        expect(item.episode.id, isNotEmpty);
        expect(item.episode.videoUrl, isNotEmpty);
      }
    });

    test('ShortsRepository fetchRandomShortsBatch provides continuous stream without halting', () async {
      final repo = ShortsRepository();
      final batch1 = await repo.fetchRandomShortsBatch(batchSize: 5);
      expect(batch1.isNotEmpty, isTrue);

      final batch2 = await repo.fetchRandomShortsBatch(batchSize: 5);
      expect(batch2.isNotEmpty, isTrue);

      final batch3 = await repo.fetchRandomShortsBatch(batchSize: 5);
      expect(batch3.isNotEmpty, isTrue);
    });
  });

  group('Search Query Provider Tests', () {
    test('searchQueryProvider updates and clears properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchQueryProvider), isEmpty);

      container.read(searchQueryProvider.notifier).setImmediate('Romance');
      expect(container.read(searchQueryProvider), 'Romance');

      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(searchQueryProvider), isEmpty);
    });
  });
}
