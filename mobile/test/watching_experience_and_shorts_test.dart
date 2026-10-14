import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/player_playback_state.dart';
import 'package:storyverse/core/utils/video_url_helper.dart';
import 'package:storyverse/features/shorts/data/shorts_repository.dart';
import 'package:storyverse/features/shorts/presentation/widgets/shorts_overlay.dart';
import 'package:storyverse/features/video_player/presentation/widgets/vertical_seek_bar.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_selector_sheet.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_player_controls.dart';

// Fake Firestore for unit testing fallback behavior
class _TestShortsRepository extends ShortsRepository {
  _TestShortsRepository() : super();

  @override
  Future<List<ShortsItem>> fetchRandomShortsBatch({int batchSize = 10}) async {
    return Future.value(getFallbackShortsBatch(batchSize));
  }
}

void main() {
  group('VideoUrlHelper Tests', () {
    test('normalizes direct URLs correctly', () {
      const direct = 'https://example.com/video.mp4';
      expect(VideoUrlHelper.normalize(direct), direct);
    });

    test('normalizes Google Drive URLs correctly', () {
      const drive =
          'https://drive.google.com/file/d/1a2b3c4d5e/view?usp=sharing';
      final normalized = VideoUrlHelper.normalize(drive);
      expect(normalized, contains('id=1a2b3c4d5e'));
      expect(normalized, contains('export=download'));
      expect(normalized, contains('confirm=t'));
    });

    test('detects YouTube links correctly', () {
      expect(VideoUrlHelper.isYouTube('https://youtube.com/watch?v=123'), isTrue);
      expect(VideoUrlHelper.isYouTube('https://youtu.be/123'), isTrue);
      expect(VideoUrlHelper.isYouTube('https://example.com/stream.mp4'), isFalse);
    });

    test('normalizes defunct Google Sample URLs to reliable CDN streams', () {
      const gtv =
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
      final normalized = VideoUrlHelper.normalize(gtv);
      expect(normalized, contains('View_From_A_Blue_Moon_Trailer'));
      expect(normalized, isNot(contains('commondatastorage.googleapis.com')));
    });
  });

  group('ShortsRepository Random Feed Tests', () {
    test('produces randomized story and episode pairs without nulls', () async {
      final repo = _TestShortsRepository();
      final batch = await repo.fetchRandomShortsBatch(batchSize: 5);

      expect(batch.isNotEmpty, isTrue);
      for (final item in batch) {
        expect(item.story.id.isNotEmpty, isTrue);
        expect(item.story.title.isNotEmpty, isTrue);
        expect(item.episode.id.isNotEmpty, isTrue);
        expect(item.episode.title.isNotEmpty, isTrue);
        expect(item.episode.videoUrl.isNotEmpty, isTrue);
      }
    });

    test('ShortsItem uniqueKey and equality work', () {
      final story = StoryModel(
        id: 's1',
        title: 'Story 1',
        description: 'Desc',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'en',
        tags: [],
        author: 'Author',
        status: 'published',
        episodeCount: 1,
        views: 0,
        rating: 4.5,
      );
      final ep1 = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Episode 1',
        description: 'Desc',
        videoUrl: 'vid.mp4',
        thumbnailUrl: 'thumb.jpg',
        duration: 120,
        views: 0,
        status: 'published',
      );
      final ep2 = EpisodeModel(
        id: 'ep2',
        storyId: 's1',
        episodeNumber: 2,
        title: 'Episode 2',
        description: 'Desc',
        videoUrl: 'vid.mp4',
        thumbnailUrl: 'thumb.jpg',
        duration: 120,
        views: 0,
        status: 'published',
      );

      final itemA = ShortsItem(story: story, episode: ep1);
      final itemB = ShortsItem(story: story, episode: ep1);
      final itemC = ShortsItem(story: story, episode: ep2);

      expect(itemA, equals(itemB));
      expect(itemA, isNot(equals(itemC)));
      expect(itemA.uniqueKey, 's1_ep1');
      expect(itemC.uniqueKey, 's1_ep2');
    });
  });

  group('PlayerPlaybackState Enum Tests', () {
    test('has distinct states for completed and error', () {
      expect(PlayerPlaybackState.completed, isNot(equals(PlayerPlaybackState.error)));
      expect(PlayerPlaybackState.values.contains(PlayerPlaybackState.completed), isTrue);
      expect(PlayerPlaybackState.values.contains(PlayerPlaybackState.error), isTrue);
    });
  });

  group('VerticalSeekBar Widget Tests', () {
    testWidgets('renders current position and total duration labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerticalSeekBar(
              position: const Duration(seconds: 45),
              duration: const Duration(minutes: 3, seconds: 15),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('03:15'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  group('EpisodeSelectorSheet Tests', () {
    testWidgets('renders episodes and triggers callback on selection',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'Test Story',
        description: 'Desc',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'drama',
        categoryId: 'series',
        language: 'en',
        tags: [],
        author: 'Author',
        status: 'published',
        episodeCount: 2,
        views: 0,
        rating: 4.8,
      );

      final episodes = [
        EpisodeModel(
          id: 'ep1',
          storyId: 's1',
          episodeNumber: 1,
          title: 'Pilot',
          description: 'Desc',
          videoUrl: 'vid1.mp4',
          thumbnailUrl: 'thumb1.jpg',
          duration: 180,
          views: 0,
          status: 'published',
        ),
        EpisodeModel(
          id: 'ep2',
          storyId: 's1',
          episodeNumber: 2,
          title: 'The Twist',
          description: 'Desc',
          videoUrl: 'vid2.mp4',
          thumbnailUrl: 'thumb2.jpg',
          duration: 210,
          views: 0,
          status: 'published',
        ),
      ];

      int? selectedIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EpisodeSelectorSheet(
                story: story,
                episodes: episodes,
                currentIndex: 0,
                onSelectEpisode: (idx) => selectedIndex = idx,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Story'), findsOneWidget);
      expect(find.text('All Episodes (2)'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('The Twist'), findsOneWidget);

      await tester.tap(find.text('The Twist'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });
  });

  group('ShortsOverlay Widget Tests (Strict Discovery Mode)', () {
    testWidgets('renders discovery controls without seekbar timeline',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'The Clever Fox',
        description: 'Story about a clever fox',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'English',
        tags: [],
        author: 'Aesop',
        status: 'published',
        episodeCount: 3,
        views: 100,
        rating: 4.7,
      );

      final episode = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Meeting the Crow',
        description: 'Episode 1 synopsis',
        videoUrl: 'vid1.mp4',
        thumbnailUrl: 'thumb1.jpg',
        duration: 240,
        views: 0,
        status: 'published',
      );

      bool tapToggled = false;
      bool favoriteToggled = false;
      bool bookmarkToggled = false;
      bool shareToggled = false;
      bool viewStoryToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortsOverlay(
              story: story,
              episode: episode,
              isMuted: false,
              isFavorite: false,
              isInLibrary: false,
              isCompleted: false,
              showTapFeedback: false,
              isPlayingFeedback: false,
              onToggleMute: () {},
              onToggleFavorite: () => favoriteToggled = true,
              onToggleBookmark: () => bookmarkToggled = true,
              onShare: () => shareToggled = true,
              onViewStory: () => viewStoryToggled = true,
              onTapVideo: () => tapToggled = true,
            ),
          ),
        ),
      );

      // NO seekbar/slider in Shorts
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(VerticalSeekBar), findsNothing);

      // Verify discovery actions
      expect(find.text('The Clever Fox'), findsOneWidget);
      expect(find.text('EP 1 • Meeting the Crow'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);

      await tester.tap(find.text('Like'));
      expect(favoriteToggled, isTrue);

      await tester.tap(find.text('Save'));
      expect(bookmarkToggled, isTrue);

      await tester.tap(find.text('Share'));
      expect(shareToggled, isTrue);

      await tester.tap(find.text('Story'));
      expect(viewStoryToggled, isTrue);

      // Tap on video background
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapToggled, isTrue);
    });

    testWidgets('shows subtle swipe up suggestion on completed short',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'The Clever Fox',
        description: 'Story',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'English',
        tags: [],
        author: 'Aesop',
        status: 'published',
        episodeCount: 3,
        views: 100,
        rating: 4.7,
      );

      final episode = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Meeting the Crow',
        description: 'Episode 1',
        videoUrl: 'vid1.mp4',
        thumbnailUrl: 'thumb1.jpg',
        duration: 240,
        views: 0,
        status: 'published',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortsOverlay(
              story: story,
              episode: episode,
              isMuted: false,
              isFavorite: false,
              isInLibrary: false,
              isCompleted: true,
              showTapFeedback: false,
              isPlayingFeedback: false,
              onToggleMute: () {},
              onToggleFavorite: () {},
              onToggleBookmark: () {},
              onShare: () {},
              onViewStory: () {},
              onTapVideo: () {},
            ),
          ),
        ),
      );

      expect(find.text('Swipe up for next short'), findsOneWidget);
      // Ensure NO error or Retry widget is present
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('EpisodePlayerControls Widget Tests (Controlled Episode Player)', () {
    testWidgets(
        'renders exactly 4 main controls and no Shorts social buttons',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'The Clever Fox',
        description: 'Story about a clever fox',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'en',
        tags: [],
        author: 'Aesop',
        status: 'published',
        episodeCount: 3,
        views: 100,
        rating: 4.7,
      );

      final episode = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Meeting the Crow',
        description: 'Episode 1 synopsis',
        videoUrl: 'vid1.mp4',
        thumbnailUrl: 'thumb1.jpg',
        duration: 240,
        views: 0,
        status: 'published',
      );

      bool backToggled = false;
      bool muteToggled = false;
      bool tapToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpisodePlayerControls(
              story: story,
              episode: episode,
              controller: null,
              showControls: true,
              isMuted: false,
              isInitialized: true,
              onTapVideo: () => tapToggled = true,
              onToggleMute: () => muteToggled = true,
              onBack: () => backToggled = true,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // Verify the controls exist:
      // 1. Back button
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      // 2. Mute button
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      // 3. Playback timeline
      expect(find.byType(VerticalSeekBar), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Verify NO Shorts social buttons exist on this screen!
      expect(find.text('Like'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Story'), findsNothing);

      // Test Back action
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(backToggled, isTrue);

      // Test Mute action
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      expect(muteToggled, isTrue);

      // Test screen tap pauses/plays video
      await tester.tap(find.byKey(const Key('episode_screen_tap_detector')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tapToggled, isTrue);
    });

    testWidgets(
        'does not render blocking completion modal dialog on natural completion',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'Story',
        description: 'Desc',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'en',
        tags: [],
        author: 'Aesop',
        status: 'published',
        episodeCount: 2,
        views: 100,
        rating: 4.7,
      );

      final episode = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Episode 1',
        description: 'Desc',
        videoUrl: 'vid1.mp4',
        thumbnailUrl: 'thumb1.jpg',
        duration: 240,
        views: 0,
        status: 'published',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpisodePlayerControls(
              story: story,
              episode: episode,
              controller: null,
              showControls: false,
              isMuted: false,
              onTapVideo: () {},
              onToggleMute: () {},
              onBack: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // Verify NO modal blocking the screen
      expect(find.text('Episode Completed'), findsNothing);
      expect(find.text('Next Episode'), findsNothing);
      expect(find.text('Watch Again'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets(
        'renders transient feedback icon only when showTapFeedback is true and hides static button',
        (tester) async {
      final story = StoryModel(
        id: 's1',
        title: 'Story',
        description: 'Desc',
        thumbnailUrl: 'thumb.jpg',
        genreId: 'fable',
        categoryId: 'classic',
        language: 'en',
        tags: [],
        author: 'Aesop',
        status: 'published',
        episodeCount: 2,
        views: 100,
        rating: 4.7,
      );

      final episode = EpisodeModel(
        id: 'ep1',
        storyId: 's1',
        episodeNumber: 1,
        title: 'Episode 1',
        description: 'Desc',
        videoUrl: 'vid1.mp4',
        thumbnailUrl: 'thumb1.jpg',
        duration: 240,
        views: 0,
        status: 'published',
      );

      // 1. When showTapFeedback is false: no feedback icon rendered
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpisodePlayerControls(
              story: story,
              episode: episode,
              controller: null,
              showControls: false,
              isMuted: false,
              showTapFeedback: false,
              onTapVideo: () {},
              onToggleMute: () {},
              onBack: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      // 2. When showTapFeedback is true: transient icon is rendered
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpisodePlayerControls(
              story: story,
              episode: episode,
              controller: null,
              showControls: false,
              isMuted: false,
              showTapFeedback: true,
              isPlayingFeedback: false, // showing pause feedback
              onTapVideo: () {},
              onToggleMute: () {},
              onBack: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600)); // drain animate timers
    });
  });
}
