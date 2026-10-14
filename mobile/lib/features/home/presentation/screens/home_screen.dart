import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/section_header.dart';
import 'package:storyverse/features/home/presentation/widgets/home_components.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingStoriesProvider);
    final historyAsync = ref.watch(continueWatchingProvider);
    final latestAsync = ref.watch(latestStoriesProvider);
    final topTenAsync = ref.watch(topTenStoriesProvider);

    final activeTab = ref.watch(homeActiveTabProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TOP HEADER
            const HomeHeader(),

            // CATEGORY TABS
            const HomeCategoryTabs(),

            // MAIN SCROLLABLE CONTENT
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryAccent,
                backgroundColor: const Color(0xFF1E1E24),
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  ref.invalidate(trendingStoriesProvider);
                  ref.invalidate(continueWatchingProvider);
                  ref.invalidate(latestStoriesProvider);
                  ref.invalidate(popularStoriesProvider);
                  ref.invalidate(topTenStoriesProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ), // Bottom nav padding
                  child: activeTab != 'Popular'
                      ? _buildCategoryView(context, activeTab)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. HERO FEATURED CAROUSEL
                            trendingAsync.when(
                              data: (stories) {
                                if (stories.isEmpty) return const SizedBox(height: 100);
                                return HeroCarousel(stories: stories);
                              },
                              loading: () => const HeroCarouselSkeleton(),
                              error: (_, _) => const SizedBox(height: 100),
                            ),

                            const SizedBox(height: 24),

                            // 2. CONTINUE WATCHING (progress bar + time remaining)
                            historyAsync.when(
                              data: (history) {
                                if (history.isEmpty) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Continue Watching',
                                      icon: Icons.play_circle_outline,
                                      onAction: () => context.push('/library'),
                                      actionLabel: 'See All',
                                    ),
                                    SizedBox(
                                      height: 170,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        itemCount: history.length > 5
                                            ? 5
                                            : history.length,
                                        itemBuilder: (context, index) {
                                          return _HistoryCard(item: history[index]);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            // 3. BECAUSE YOU WATCHED [Last Story Title] (genre-based recommendations)
                            historyAsync.when(
                              data: (history) {
                                if (history.isEmpty) return const SizedBox.shrink();
                                final lastWatched = history.first;
                                return _BecauseYouWatchedSection(lastWatched: lastWatched);
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            // 4. TRENDING NOW (Ranked Badges #1-#10)
                            topTenAsync.when(
                              data: (stories) {
                                if (stories.isEmpty) return const SizedBox.shrink();
                                final top10 = stories.take(10).toList();
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  margin: const EdgeInsets.only(bottom: 28),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1C1304), // Dark Gold / Amber
                                        Color(0xFF141414), // Dark Charcoal
                                        Colors.black, // Deep Black
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SectionHeader(
                                        title: 'Trending Now',
                                        icon: Icons.military_tech,
                                        onAction: () => context.push('/discover?category=trending'),
                                        actionLabel: 'See All',
                                      ),
                                      SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          itemCount: top10.length,
                                          itemBuilder: (context, index) {
                                            return TopRankedCard(
                                              story: top10[index],
                                              rank: index + 1,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const TopRankedSkeleton(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            // 5. NEW ARRIVALS
                            latestAsync.when(
                              data: (stories) {
                                if (stories.isEmpty) return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'New Arrivals',
                                      icon: Icons.new_releases,
                                      onAction: () => context.push('/discover?category=new'),
                                      actionLabel: 'See All',
                                    ),
                                    SizedBox(
                                      height: 220,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        itemCount: stories.length,
                                        itemBuilder: (context, index) {
                                          return StoryCard(
                                            story: stories[index],
                                            width: 140,
                                            height: 200,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                  ],
                                );
                              },
                              loading: () => const StorySectionSkeleton(
                                title: 'New Arrivals',
                                height: 200,
                                cardWidth: 140,
                              ),
                              error: (_, _) => const SizedBox.shrink(),
                            ),

                            // 6. BROWSE BY LANGUAGE
                            const SectionHeader(
                              title: 'Browse by Language',
                              icon: Icons.language,
                            ),
                            SizedBox(
                              height: 45,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  LanguageChip(
                                    label: 'Hindi',
                                    onTap: () =>
                                        context.push('/discover?language=hindi'),
                                  ),
                                  LanguageChip(
                                    label: 'English',
                                    onTap: () =>
                                        context.push('/discover?language=english'),
                                  ),
                                  LanguageChip(
                                    label: 'Gujarati',
                                    onTap: () =>
                                        context.push('/discover?language=gujarati'),
                                  ),
                                  LanguageChip(
                                    label: 'Marathi',
                                    onTap: () =>
                                        context.push('/discover?language=marathi'),
                                  ),
                                  LanguageChip(
                                    label: 'Bengali',
                                    onTap: () =>
                                        context.push('/discover?language=bengali'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // 7. POPULAR GENRES
                            const SectionHeader(
                              title: 'Popular Genres',
                              icon: Icons.category,
                            ),
                            SizedBox(
                              height: 80,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  GenreCard(
                                    genre: 'Horror',
                                    color: const Color(0xFF2A153D),
                                    onTap: () => context.push('/discover?genre=horror'),
                                  ),
                                  GenreCard(
                                    genre: 'Romance',
                                    color: const Color(0xFF3D1515),
                                    onTap: () =>
                                        context.push('/discover?genre=romance'),
                                  ),
                                  GenreCard(
                                    genre: 'Thriller',
                                    color: const Color(0xFF15263D),
                                    onTap: () =>
                                        context.push('/discover?genre=thriller'),
                                  ),
                                  GenreCard(
                                    genre: 'Comedy',
                                    color: const Color(0xFF3D2715),
                                    onTap: () => context.push('/discover?genre=comedy'),
                                  ),
                                  GenreCard(
                                    genre: 'Fantasy',
                                    color: const Color(0xFF153D2A),
                                    onTap: () =>
                                        context.push('/discover?genre=fantasy'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // 8. AI HUB PROMOTIONAL CARD
                            const AiHubCtaCard(),
                            const SizedBox(height: 40),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryView(BuildContext context, String tab) {
    AsyncValue<List<StoryModel>> storiesAsync;
    if (tab == 'Trending') {
      storiesAsync = ref.watch(trendingStoriesProvider);
    } else if (tab == 'New') {
      storiesAsync = ref.watch(latestStoriesProvider);
    } else {
      storiesAsync = ref.watch(
        storiesByMultiFilterProvider({'genre': tab.toLowerCase()}),
      );
    }

    return storiesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.movie_filter_outlined,
                    size: 48,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No $tab stories yet',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(homeActiveTabProvider.notifier).setTab('Popular'),
                    child: const Text('Back to All Stories'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroCarousel(stories: stories.take(5).toList()),
            const SizedBox(height: 24),
            SectionHeader(
              title: '$tab Stories',
              icon: Icons.auto_awesome,
              actionLabel: 'See All',
              onAction: () {
                final route = (tab == 'Trending')
                    ? '/discover?category=trending'
                    : (tab == 'New')
                        ? '/discover?category=new'
                        : '/discover?genre=${tab.toLowerCase()}';
                context.push(route);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  return StoryCard(
                    story: stories[index],
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Column(
        children: [
          HeroCarouselSkeleton(),
          SizedBox(height: 24),
          StoryGridSkeleton(title: 'Loading...'),
        ],
      ),
      error: (e, _) => Center(
        child: Text(
          'Error loading stories: $e',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ContinueWatchingItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/player/${item.story.id}/${item.episode.id}'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: NetworkImageWithFallback(
                    imageUrl: item.episode.thumbnailUrl.isNotEmpty
                        ? item.episode.thumbnailUrl
                        : item.story.thumbnailUrl,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: item.history.percentage,
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryAccent,
                    ),
                    minHeight: 4,
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.story.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final timeRemaining = item.history.timeLeftFormatted.isNotEmpty
                          ? ' • ${item.history.timeLeftFormatted}'
                          : '';
                      return Text(
                        'Ep ${item.episode.episodeNumber}$timeRemaining • ${item.episode.title}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BecauseYouWatchedSection extends ConsumerWidget {
  final ContinueWatchingItem lastWatched;
  const _BecauseYouWatchedSection({required this.lastWatched});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genre = lastWatched.story.genreId.toLowerCase();
    final recsAsync = ref.watch(storiesByMultiFilterProvider({'genre': genre}));

    return recsAsync.when(
      data: (stories) {
        final recs =
            stories.where((s) => s.id != lastWatched.story.id).toList();
        if (recs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Because You Watched "${lastWatched.story.title}"',
              icon: Icons.auto_awesome,
              onAction: () => context.push('/discover?genre=$genre'),
              actionLabel: 'See All',
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  return StoryCard(
                    story: recs[index],
                    width: 140,
                    height: 200,
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

