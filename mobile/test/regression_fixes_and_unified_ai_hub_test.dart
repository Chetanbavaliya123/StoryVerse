import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/routing/app_router.dart';
import 'package:storyverse/features/home/presentation/widgets/home_components.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_hub_screen.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';

void main() {
  final sampleStory = StoryModel(
    id: 'story_1',
    title: 'Neon Odyssey',
    description: 'A sci-fi adventure through the neon underworld.',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    genreId: 'sci-fi',
    categoryId: 'popular',
    language: 'English',
    tags: ['cyberpunk', 'adventure'],
    author: 'StoryVerse Creator',
    status: 'published',
    episodeCount: 10,
    views: 12000,
    rating: 4.8,
    isTrending: true,
    isDemo: false,
    isPublished: true,
  );

  group('Part 1 - Home Category Tabs & Hero Slider Visibility', () {
    testWidgets('HeroCarousel renders when stories are provided and displays Play Now', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HeroCarousel(
                stories: [sampleStory],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify HeroCarousel renders the story title and Play Now button
      expect(find.byType(HeroCarousel), findsOneWidget);
      expect(find.text('Neon Odyssey'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);
    });

    testWidgets('HeroCarousel supports 12 stories without being capped to 5', (tester) async {
      final twelveStories = List.generate(
        12,
        (i) => sampleStory.copyWith(id: 'story_$i', title: 'Story $i'),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HeroCarousel(
                stories: twelveStories,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final PageView pageView = tester.widget(pageViewFinder);
      final SliverChildDelegate delegate = pageView.childrenDelegate;
      expect(delegate.estimatedChildCount, 12);
    });

    test('HomeActiveTabNotifier transitions tabs correctly without keeping Popular hero active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(homeActiveTabProvider), 'Popular');

      container.read(homeActiveTabProvider.notifier).setTab('Trending');
      expect(container.read(homeActiveTabProvider), 'Trending');

      container.read(homeActiveTabProvider.notifier).setTab('New');
      expect(container.read(homeActiveTabProvider), 'New');

      container.read(homeActiveTabProvider.notifier).setTab('Romance');
      expect(container.read(homeActiveTabProvider), 'Romance');

      container.read(homeActiveTabProvider.notifier).setTab('Popular');
      expect(container.read(homeActiveTabProvider), 'Popular');
    });
  });

  group('Part 2 & 3 - AI Hub Screen & Floating Action Experience', () {
    testWidgets('AiHubScreen renders unified header with Generator and AI Stories tabs and slider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiStoriesProvider.overrideWith((ref) => Stream.value([sampleStory])),
          ],
          child: const MaterialApp(
            home: AiHubScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check header and tabs
      expect(find.text('AI HUB'), findsOneWidget);
      expect(find.text('Generator'), findsOneWidget);
      expect(find.text('AI Stories'), findsOneWidget);

      // Verify initial page is Generator
      expect(find.byType(PageView), findsOneWidget);

      // Tap on AI Stories tab to switch
      await tester.tap(find.text('AI Stories'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Verify AI Stories page content is displayed
      expect(find.text('Neon Odyssey'), findsOneWidget);
      expect(find.text('Generated AI Story'), findsOneWidget);
    });

    testWidgets('AiHubScreen displays empty state when no AI stories are generated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiStoriesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: AiHubScreen(initialPage: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No AI Stories Yet'), findsOneWidget);
      expect(find.text('Start Generating'), findsOneWidget);

      // Tap Start Generating should switch to Generator page
      await tester.tap(find.text('Start Generating'));
      await tester.pumpAndSettle();

      expect(find.text('Generator'), findsOneWidget);
    });
  });

  group('Part 7 - Android System Back Navigation Architecture', () {
    test('getBranchNavigatorKey returns distinct non-null navigator keys for all branches', () {
      final key0 = getBranchNavigatorKey(0);
      final key1 = getBranchNavigatorKey(1);
      final key2 = getBranchNavigatorKey(2);
      final key3 = getBranchNavigatorKey(3);
      final key4 = getBranchNavigatorKey(4);
      final keyInvalid = getBranchNavigatorKey(5);

      expect(key0, isNotNull);
      expect(key1, isNotNull);
      expect(key2, isNotNull);
      expect(key3, isNotNull);
      expect(key4, isNotNull);
      expect(keyInvalid, isNull);

      // Ensure distinct keys
      final allKeys = {key0, key1, key2, key3, key4};
      expect(allKeys.length, 5);
    });
  });
}
