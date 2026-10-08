import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularStoriesProvider);
    final trendingAsync = ref.watch(trendingStoriesProvider);
    final latestAsync = ref.watch(latestStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Premium Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.diamond_outlined,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STORYVERSE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2.0,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Premium CTA Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3D1C11),
                            Color(0xFF1A0E08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Unlock All Stories',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Get unlimited access to all premium stories, exclusive originals, and ad-free experience.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Premium Originals Section
            SliverToBoxAdapter(
              child: _PremiumSection(
                title: 'Premium Originals',
                icon: Icons.workspace_premium,
                gradientColors: const [
                  Color(0xFF2B1504),
                  Color(0xFF141414),
                  Colors.black,
                ],
                child: trendingAsync.when(
                  data: (stories) {
                    if (stories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No premium originals available yet.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
                          return StoryCard(
                            story: stories[index],
                            width: 150,
                            height: 220,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => _buildHorizontalSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Exclusive Collection
            SliverToBoxAdapter(
              child: _PremiumSection(
                title: 'Exclusive Collection',
                icon: Icons.collections_bookmark,
                gradientColors: const [
                  Color(0xFF0A1828),
                  Color(0xFF101418),
                  Colors.black,
                ],
                child: popularAsync.when(
                  data: (stories) {
                    if (stories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No exclusive stories available yet.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        itemCount: stories.length > 6 ? 6 : stories.length,
                        itemBuilder: (context, index) {
                          final story = stories[index];
                          return _PremiumGridCard(story: story);
                        },
                      ),
                    );
                  },
                  loading: () => _buildGridSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Top Picks
            SliverToBoxAdapter(
              child: _PremiumSection(
                title: 'Top Picks For You',
                icon: Icons.auto_awesome,
                gradientColors: const [
                  Color(0xFF1C0A28),
                  Color(0xFF141418),
                  Colors.black,
                ],
                child: latestAsync.when(
                  data: (stories) {
                    if (stories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No recommendations available yet.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
                          return StoryCard(
                            story: stories[index],
                            width: 130,
                            height: 200,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => _buildHorizontalSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Bottom padding for nav bar
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSkeleton() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(right: 16),
          child: SkeletonLoader(width: 130, height: 200, borderRadius: 12),
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return Padding(
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
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget child;

  const _PremiumSection({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFD700), size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PremiumGridCard extends StatelessWidget {
  final StoryModel story;

  const _PremiumGridCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageWithFallback(
                      imageUrl: story.thumbnailUrl,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.black,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${story.genreId.toUpperCase()} • ${story.language}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
