import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/continue_watching_item.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/section_header.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
          _showTitle = _scrollOffset > 100;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingStoriesProvider);
    final historyAsync = ref.watch(continueWatchingProvider);
    final recommendedAsync = ref.watch(allStoriesProvider);
    final latestAsync = ref.watch(latestStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _showTitle
            ? AppColors.primaryBackground.withValues(alpha: 0.95)
            : Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            'StoryVerse',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      floatingActionButton: const _AnimatedAIFab(),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          bottom: 120,
        ), // Leave room for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO SECTION
            trendingAsync.when(
              data: (stories) {
                if (stories.isEmpty) return const SizedBox.shrink();
                return _HeroSection(story: stories.first);
              },
              loading: () => const SkeletonLoader(height: 500, borderRadius: 0),
              error: (_, _) => const SizedBox(height: 100),
            ),

            const SizedBox(height: 24),

            // QUICK LINKS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QuickLink(
                      icon: Icons.explore,
                      label: 'Discover',
                      onTap: () => context.push('/discover'),
                    ),
                    const SizedBox(width: 12),
                    _QuickLink(
                      icon: Icons.trending_up,
                      label: 'Trending',
                      onTap: () => context.push('/discover'),
                    ),
                    const SizedBox(width: 12),
                    _QuickLink(
                      icon: Icons.category,
                      label: 'Genres',
                      onTap: () => context.push('/discover'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CONTINUE WATCHING
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Continue Watching',
                      onAction: () => context.push('/library'),
                      actionLabel: 'See All',
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: history.length > 5 ? 5 : history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return _HistoryCard(item: item);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => _buildHorizontalSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // TRENDING NOW (Skip the first one since it's in Hero)
            trendingAsync.when(
              data: (stories) {
                if (stories.length <= 1) return const SizedBox.shrink();
                final remaining = stories.skip(1).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Trending Now',
                      onAction: () => context.push('/discover'),
                      actionLabel: 'See All',
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => _buildHorizontalSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // LATEST STORIES
            latestAsync.when(
              data: (stories) {
                if (stories.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Recently Added',
                      onAction: () => context.push('/discover'),
                      actionLabel: 'See All',
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => _buildHorizontalSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // RECOMMENDED (Vertical list)
            recommendedAsync.when(
              data: (stories) {
                if (stories.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Recommended for You',
                      onAction: () => context.push('/discover'),
                      actionLabel: 'See All',
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stories.length > 5 ? 5 : stories.length,
                      itemBuilder: (context, index) {
                        return StoryCard(
                          story: stories[index],
                          isHorizontal: true,
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: SkeletonLoader(height: 120, borderRadius: 16),
                    ),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSkeleton() {
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
}

class _HeroSection extends StatelessWidget {
  final StoryModel story;
  const _HeroSection({required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Stack(
        children: [
          // Background Image
          SizedBox(
            height: 500,
            width: double.infinity,
            child: NetworkImageWithFallback(
              imageUrl: story.bannerUrl ?? story.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Container(
            height: 500,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBackground.withValues(alpha: 0.4),
                  Colors.transparent,
                  AppColors.primaryBackground.withValues(alpha: 0.8),
                  AppColors.primaryBackground,
                ],
                stops: const [0.0, 0.3, 0.8, 1.0],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      story.categoryId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.circle,
                        size: 4,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    Text(
                      story.genreId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  story.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/story/${story.id}'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Watch Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {}, // Add to library icon
                      icon: const Icon(Icons.add, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: NetworkImageWithFallback(
                    imageUrl: item.episode.thumbnailUrl.isNotEmpty
                        ? item.episode.thumbnailUrl
                        : item.story.thumbnailUrl,
                    width: double.infinity,
                    height: 110,
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
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.story.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ep ${item.episode.episodeNumber} • ${item.episode.title}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
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

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedAIFab extends StatefulWidget {
  const _AnimatedAIFab();

  @override
  State<_AnimatedAIFab> createState() => _AnimatedAIFabState();
}

class _AnimatedAIFabState extends State<_AnimatedAIFab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 130.0, right: 12.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/ai'),
          backgroundColor: AppColors.primaryAccent,
          elevation: _isHovered ? 8 : 6,
          isExtended: _isHovered,
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text(
            'AI Hub',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
