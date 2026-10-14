import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/watch_history_model.dart';
import 'package:storyverse/core/design_system/app_buttons.dart';
import 'package:storyverse/core/design_system/genre_chip.dart';
import 'package:storyverse/core/design_system/story_card.dart';
import 'package:storyverse/features/ai/presentation/providers/ai_quota_provider.dart';
import 'package:storyverse/features/story/presentation/screens/story_reader_screen.dart';

void main() {
  group('WatchHistoryModel Unit Tests', () {
    test('calculates timeLeftFormatted correctly when duration > progress', () {
      final history = WatchHistoryModel(
        id: 'h1',
        storyId: 's1',
        episodeId: 'e1',
        userId: 'u1',
        progressSeconds: 60,
        totalDuration: 180,
        percentage: 0.33,
        isCompleted: false,
        lastWatchedAt: DateTime.now(),
      );

      // 180 - 60 = 120s = 2m 0s left
      expect(history.timeLeftFormatted, '2m 0s left');
    });

    test('calculates timeLeftFormatted when less than 60s remaining', () {
      final history = WatchHistoryModel(
        id: 'h2',
        storyId: 's1',
        episodeId: 'e1',
        userId: 'u1',
        progressSeconds: 155,
        totalDuration: 180,
        percentage: 0.86,
        isCompleted: false,
        lastWatchedAt: DateTime.now(),
      );

      // 180 - 155 = 25s = 0m 25s left
      expect(history.timeLeftFormatted, '0m 25s left');
    });

    test('returns Completed when progress >= duration', () {
      final history = WatchHistoryModel(
        id: 'h3',
        storyId: 's1',
        episodeId: 'e1',
        userId: 'u1',
        progressSeconds: 180,
        totalDuration: 180,
        percentage: 1.0,
        isCompleted: true,
        lastWatchedAt: DateTime.now(),
      );

      expect(history.timeLeftFormatted, 'Completed');
    });
  });

  group('AiQuotaState Unit Tests', () {
    test('computes remaining stories accurately for free users', () {
      const quota = AiQuotaState(
        usedToday: 1,
        maxFreeDaily: 3,
        dateString: '2026-10-14',
        isUnlimitedVip: false,
      );

      expect(quota.remainingToday, 2);
      expect(quota.canGenerate, true);
    });

    test('exhausts quota when usedToday equals maxFreeDaily', () {
      const quota = AiQuotaState(
        usedToday: 3,
        maxFreeDaily: 3,
        dateString: '2026-10-14',
        isUnlimitedVip: false,
      );

      expect(quota.remainingToday, 0);
      expect(quota.canGenerate, false);
    });

    test('VIP users have unlimited quota regardless of usedToday', () {
      const quota = AiQuotaState(
        usedToday: 15,
        maxFreeDaily: 3,
        dateString: '2026-10-14',
        isUnlimitedVip: true,
      );

      expect(quota.remainingToday, 999);
      expect(quota.canGenerate, true);
    });
  });

  group('Design System AppButtons Widget Tests', () {
    testWidgets('PrimaryButton renders label and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Start Watching',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Watching'), findsOneWidget);
      await tester.tap(find.text('Start Watching'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('PrimaryButton displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Generate',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generate'), findsNothing);
    });

    testWidgets('SecondaryButton renders with border and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Read Novel',
              icon: const Icon(Icons.menu_book),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Read Novel'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);

      await tester.tap(find.text('Read Novel'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('Design System GenreChip Widget Tests', () {
    testWidgets('renders label and toggles selection style', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreChip(
              label: 'Thriller',
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Thriller'), findsOneWidget);
      await tester.tap(find.text('Thriller'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('Design System StoryCard Widget Tests', () {
    final testStory = StoryModel(
      id: 'story_card_1',
      title: 'Neon Shadows',
      description: 'A cyberpunk thriller',
      thumbnailUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400',
      genreId: 'thriller',
      categoryId: 'premium',
      language: 'English',
      tags: ['cyberpunk', 'crime'],
      author: 'Aiden Vance',
      status: 'published',
      episodeCount: 12,
      views: 54000,
      rating: 4.9,
    );

    testWidgets('StoryCard poster variant displays title, rating, and VIP badge', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: StoryCard(
                story: testStory,
                variant: StoryCardVariant.poster,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Neon Shadows'), findsOneWidget);
      expect(find.text('12 Episodes'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);

      await tester.tap(find.text('Neon Shadows'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tapped, true);
    });

    testWidgets('StoryCard compact variant displays episode count and language', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 120,
              child: StoryCard.compact(
                story: testStory,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Neon Shadows'), findsOneWidget);
      expect(find.text('THRILLER • English'), findsOneWidget);
      expect(find.text('12 Episodes'), findsOneWidget);
    });
  });

  group('StoryReaderScreen Enum Tests', () {
    test('ReaderThemeMode contains all 4 required reading themes', () {
      expect(ReaderThemeMode.values, contains(ReaderThemeMode.dark));
      expect(ReaderThemeMode.values, contains(ReaderThemeMode.black));
      expect(ReaderThemeMode.values, contains(ReaderThemeMode.sepia));
      expect(ReaderThemeMode.values, contains(ReaderThemeMode.light));
      expect(ReaderThemeMode.values.length, 4);
    });
  });
}
