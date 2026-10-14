import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/design_system/story_card.dart' as ds;
import 'package:storyverse/core/widgets/story_card.dart' as wc;
import 'package:storyverse/features/premium/presentation/screens/premium_screen.dart';
import 'package:storyverse/features/profile/presentation/screens/profile_screen.dart';

void main() {
  final testStoryLong = StoryModel(
    id: 's_long',
    title: 'A Very Long Story Title That Takes Two Or Three Lines On Small Screens',
    description: 'A detailed description that is quite long and complex.',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    genreId: 'psychological-thriller',
    categoryId: 'featured-trending-now',
    language: 'English (US)',
    tags: ['psychological', 'mystery', 'thriller', 'suspense'],
    author: 'Author With A Very Long Name',
    status: 'published',
    episodeCount: 120,
    views: 999999,
    rating: 4.95,
    isTrending: true,
    isDemo: true,
    isPublished: true,
  );

  group('Zero Overflow Tests (360x640 Viewport, 1.3x Text Scale)', () {
    testWidgets('StoryCard (design system) renders with zero overflow on small screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 140,
                height: 220,
                child: ds.StoryCard(
                  story: testStoryLong,
                  width: 140,
                  height: 220,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('StoryCard (core widget) renders with zero overflow on small screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 140,
                height: 225,
                child: wc.StoryCard(
                  story: testStoryLong,
                  width: 140,
                  height: 225,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PremiumScreen Coming Soon renders with zero overflow on small screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              home: PremiumScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('COMING SOON'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders with edge-to-edge gradient and zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
