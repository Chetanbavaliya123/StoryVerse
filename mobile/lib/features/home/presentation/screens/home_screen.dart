import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/section_header.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
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
    final allStoriesAsync = ref.watch(allStoriesProvider);
    final latestAsync = ref.watch(latestStoriesProvider);
    final popularAsync = ref.watch(popularStoriesProvider);
    final topTenAsync = ref.watch(topTenStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          heroTag: 'ai_hub_fab',
          onPressed: () => context.push('/ai'),
          backgroundColor: AppColors.primaryAccent,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
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
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  bottom: 120,
                ), // Bottom nav padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HERO FEATURED CAROUSEL (Now safely below header)
                    trendingAsync.when(
                      data: (stories) {
                        if (stories.isEmpty) return const SizedBox(height: 100);
                        return HeroCarousel(stories: stories);
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: SkeletonLoader(height: 400, borderRadius: 16),
                      ),
                      error: (_, _) => const SizedBox(height: 100),
                    ),

                    const SizedBox(height: 28),

                    // 2. TRENDING NOW
                    trendingAsync.when(
                      data: (stories) {
                        if (stories.length <= 1) return const SizedBox.shrink();
                        final remaining = stories.skip(1).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Trending Now',
                              icon: Icons.trending_up,
                              onAction: () => context.push('/discover'),
                              actionLabel: 'See All',
                            ),
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: remaining.length,
                                itemBuilder: (context, index) {
                                  return StoryCard(
                                    story: remaining[index],
                                    width: 150,
                                    height: 220,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      },
                      loading: () => _buildHorizontalCardSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // 3. CONTINUE WATCHING
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
                              height: 160,
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
                      loading: () => _buildHorizontalCardSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // 4. POPULAR ON STORYVERSE (Dark Burgundy Container)
                    popularAsync.when(
                      data: (stories) {
                        if (stories.length < 3) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(
                                  0xFF2B0B11,
                                ), // Dark Red/StoryVerse influence
                                Color(0xFF141414), // Dark Charcoal
                                Color(0xFF0A0204), // Slightly red-tinted black
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Popular on StoryVerse',
                                icon: Icons.local_fire_department,
                                onAction: () => context.push('/discover'),
                                actionLabel: 'See All',
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.65,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: stories.length > 6
                                      ? 6
                                      : stories.length,
                                  itemBuilder: (context, index) {
                                    return GridStoryCard(story: stories[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => _buildGridSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // 5. BROWSE BY LANGUAGE
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 6. TOP 10 IN STORYVERSE (No giant numbers)
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
                              const SectionHeader(
                                title: 'Top 10 on StoryVerse',
                                icon: Icons.military_tech,
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
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // 7. NEW ON STORYVERSE
                    latestAsync.when(
                      data: (stories) {
                        if (stories.isEmpty) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0A1828), // Deep Blue/Teal
                                Color(0xFF101418), // Dark Charcoal
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
                                title: 'New on StoryVerse',
                                icon: Icons.new_releases,
                                onAction: () => context.push('/discover'),
                                actionLabel: 'See All',
                              ),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: stories.length,
                                  itemBuilder: (context, index) {
                                    return StoryCard(
                                      story: stories[index],
                                      width: 120,
                                      height: 180,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => _buildHorizontalCardSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // 8. POPULAR GENRES
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

                    // 9. AI HUB CTA
                    const AiHubCtaCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCardSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(width: 150, height: 24),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SkeletonLoader(width: 120, height: 180, borderRadius: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonLoader(width: 150, height: 24),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 8,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
                  Text(
                    'Ep ${item.episode.episodeNumber} • ${item.episode.title}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
