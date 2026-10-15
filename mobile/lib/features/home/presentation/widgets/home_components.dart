import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/features/library/data/library_repository.dart';
import 'package:storyverse/core/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/features/notifications/data/notification_repository.dart';
import 'package:storyverse/features/search/presentation/widgets/voice_search_dialog.dart';

class HomeActiveTabNotifier extends Notifier<String> {
  @override
  String build() => 'Popular';

  void setTab(String tab) {
    state = tab;
  }
}

final homeActiveTabProvider =
    NotifierProvider<HomeActiveTabNotifier, String>(() {
  return HomeActiveTabNotifier();
});

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).value ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Search stories, shows...',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => VoiceSearchDialog.show(context),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.primaryAccent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryAccent,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCategoryTabs extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  const HomeCategoryTabs({super.key, required this.controller});

  static const List<String> categories = [
    'Popular',
    'Trending',
    'New',
    'Romance',
    'Horror',
    'Comedy',
  ];

  String _getCategoryLabel(BuildContext context, String cat) {
    switch (cat) {
      case 'Popular':
        return context.loc.popular;
      case 'Trending':
        return context.loc.trending;
      case 'New':
        return context.loc.newArrivals;
      case 'Romance':
        return context.loc.romance;
      case 'Horror':
        return context.loc.horror;
      case 'Comedy':
        return context.loc.comedy;
      default:
        return cat;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        indicatorColor: AppColors.primaryAccent,
        indicatorWeight: 3.0,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: categories
            .map((cat) => Tab(
                  text: _getCategoryLabel(context, cat),
                  height: 42,
                ))
            .toList(),
      ),
    );
  }
}

class HeroCarousel extends StatefulWidget {
  final List<StoryModel> stories;
  const HeroCarousel({super.key, required this.stories});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.stories.isNotEmpty) {
      _startAutoRotation();
    }
  }

  void _startAutoRotation() {
    _timer?.cancel();
    if (widget.stories.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients) {
        final maxCount = widget.stories.length;
        if (maxCount == 0) return;
        int nextIndex = _currentIndex + 1;
        if (nextIndex >= maxCount) {
          nextIndex = 0;
        }
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();

    final count = widget.stories.length;

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _startAutoRotation(),
            onPointerCancel: (_) => _startAutoRotation(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _startAutoRotation(); // Reset timer on manual swipe
              },
              itemCount: count,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                    }
                    return Transform.scale(
                      scale: value,
                      child: _HeroCard(story: story),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              count,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == index ? (count > 8 ? 18 : 24) : (count > 8 ? 6 : 8),
                height: count > 8 ? 6 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppColors.primaryAccent
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final StoryModel story;
  const _HeroCard({required this.story});

  Future<void> _handlePlayNow(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    // 1. Check if user already has watch history for this story
    final continueWatching = ref.read(continueWatchingProvider).value ?? [];
    final existing = continueWatching.where((c) => c.story.id == story.id).firstOrNull;
    if (existing != null) {
      context.push('/player/${story.id}/${existing.episode.id}');
      return;
    }

    // 2. Fetch episodes and play episode 1 directly
    try {
      final storyRepo = ref.read(storyRepositoryProvider);
      final episodes = await storyRepo.getEpisodes(story.id);
      if (context.mounted) {
        if (episodes.isNotEmpty) {
          context.push('/player/${story.id}/${episodes.first.id}');
        } else {
          context.push('/story/${story.id}');
        }
      }
    } catch (_) {
      if (context.mounted) {
        context.push('/story/${story.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkImageWithFallback(
                imageUrl: (story.bannerUrl != null && story.bannerUrl!.isNotEmpty)
                    ? story.bannerUrl!
                    : story.thumbnailUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            story.genreId.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (story.categoryId.isNotEmpty &&
                            story.categoryId.toUpperCase() !=
                                story.genreId.toUpperCase()) ...[
                          const SizedBox(width: 8),
                          Text(
                            story.categoryId.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          story.language.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePlayNow(context, ref),
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Play Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Consumer(
                          builder: (context, ref, child) {
                            final isFavoriteAsync = ref.watch(
                              isFavoriteProvider(story.id),
                            );
                            final isFavorite = isFavoriteAsync.value ?? false;
                            return IconButton(
                              onPressed: () async {
                                await ref
                                    .read(libraryRepositoryProvider)
                                    .toggleFavorite(story.id, !isFavorite);
                                ref.invalidate(favoriteStoriesProvider);
                              },
                              icon: Icon(
                                isFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white24,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridStoryCard extends StatelessWidget {
  final StoryModel story;
  const GridStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: NetworkImageWithFallback(
                  imageUrl: story.thumbnailUrl,
                  fit: BoxFit.cover,
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

class LanguageChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const LanguageChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A3A), Color(0xFF1A1A24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class GenreCard extends StatelessWidget {
  final String genre;
  final VoidCallback onTap;
  final Color color;
  const GenreCard({
    super.key,
    required this.genre,
    required this.onTap,
    this.color = const Color(0xFF1A1A24),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            genre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class TopRankedCard extends StatelessWidget {
  final StoryModel story;
  final int rank;
  const TopRankedCard({super.key, required this.story, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story/${story.id}'),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.05),
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
                child: NetworkImageWithFallback(
                  imageUrl: story.thumbnailUrl,
                  fit: BoxFit.cover,
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

class AiHubCtaCard extends StatelessWidget {
  const AiHubCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF1A0A22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create your own interactive story',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class HeroCarouselSkeleton extends StatelessWidget {
  const HeroCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.03),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StorySectionSkeleton extends StatelessWidget {
  final String title;
  final double height;
  final double cardWidth;

  const StorySectionSkeleton({
    super.key,
    required this.title,
    this.height = 220,
    this.cardWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 130,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class StoryGridSkeleton extends StatelessWidget {
  final String title;

  const StoryGridSkeleton({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TopRankedSkeleton extends StatelessWidget {
  const TopRankedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.only(bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContinueWatchingSkeleton extends StatelessWidget {
  const ContinueWatchingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
