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
import 'package:storyverse/features/home/presentation/providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HomeCategoryTabs.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(homeActiveTabProvider.notifier).setTab(
              HomeCategoryTabs.categories[_tabController.index],
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0, right: 8.0),
        child: FloatingActionButton(
          heroTag: 'ai_hub_fab',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/ai/assistant');
          },
          backgroundColor: AppColors.primaryAccent,
          elevation: 6,
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TOP HEADER
            const HomeHeader(),

            // CATEGORY TABS (Scrollable TabBar)
            HomeCategoryTabs(controller: _tabController),

            // MAIN TABBAR VIEW
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PopularFeedTab(),
                  _CategoryFeedTab(category: 'Trending'),
                  _CategoryFeedTab(category: 'New'),
                  _CategoryFeedTab(category: 'Romance'),
                  _CategoryFeedTab(category: 'Horror'),
                  _CategoryFeedTab(category: 'Comedy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularFeedTab extends ConsumerStatefulWidget {
  const _PopularFeedTab();

  @override
  ConsumerState<_PopularFeedTab> createState() => _PopularFeedTabState();
}

class _PopularFeedTabState extends ConsumerState<_PopularFeedTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(homeFeedProvider);
    ref.invalidate(trendingStoriesProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(latestStoriesProvider);
    ref.invalidate(popularStoriesProvider);
    ref.invalidate(topTenStoriesProvider);
    await ref.read(homeFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeFeedAsync = ref.watch(homeFeedProvider);

    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: const Color(0xFF1E1E24),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: homeFeedAsync.when(
          data: (feed) => Column(
            key: const ValueKey('home_feed_content'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO FEATURED CAROUSEL
              HeroCarousel(
                key: const ValueKey('hero_carousel'),
                stories: feed.heroStories,
              ),
              const SizedBox(height: 24),

              // 2. CONTINUE WATCHING (hide ONLY after loading complete if empty)
              if (feed.continueWatching.isNotEmpty) ...[
                Column(
                  key: const ValueKey('continue_watching_section'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: feed.continueWatching.length > 5
                            ? 5
                            : feed.continueWatching.length,
                        itemBuilder: (context, index) {
                          final item = feed.continueWatching[index];
                          return _HistoryCard(
                            key: ValueKey('history_${item.story.id}_${item.episode.id}'),
                            item: item,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
                _BecauseYouWatchedSection(
                  key: const ValueKey('because_you_watched_section'),
                  lastWatched: feed.continueWatching.first,
                ),
              ],

              // 3. TRENDING NOW (Ranked Badges #1-#10)
              if (feed.topTen.isNotEmpty)
                Container(
                  key: const ValueKey('trending_now_section'),
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
                        height: 215,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: feed.topTen.length,
                          itemBuilder: (context, index) {
                            return TopRankedCard(
                              story: feed.topTen[index],
                              rank: index + 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. NEW ARRIVALS
              if (feed.newArrivals.isNotEmpty)
                Column(
                  key: const ValueKey('new_arrivals_section'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'New Arrivals',
                      icon: Icons.new_releases,
                      onAction: () => context.push('/discover?category=new'),
                      actionLabel: 'See All',
                    ),
                    SizedBox(
                      height: 225,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: feed.newArrivals.length,
                        itemBuilder: (context, index) {
                          return StoryCard(
                            story: feed.newArrivals[index],
                            width: 140,
                            height: 215,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),

              // 5. BROWSE BY LANGUAGE
              const SectionHeader(
                key: ValueKey('browse_language_header'),
                title: 'Browse by Language',
                icon: Icons.language,
              ),
              SizedBox(
                key: const ValueKey('browse_language_list'),
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    LanguageChip(
                      label: 'Hindi',
                      onTap: () => context.push('/discover?language=hindi'),
                    ),
                    LanguageChip(
                      label: 'English',
                      onTap: () => context.push('/discover?language=english'),
                    ),
                    LanguageChip(
                      label: 'Gujarati',
                      onTap: () => context.push('/discover?language=gujarati'),
                    ),
                    LanguageChip(
                      label: 'Marathi',
                      onTap: () => context.push('/discover?language=marathi'),
                    ),
                    LanguageChip(
                      label: 'Bengali',
                      onTap: () => context.push('/discover?language=bengali'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 6. POPULAR GENRES
              const SectionHeader(
                key: ValueKey('popular_genres_header'),
                title: 'Popular Genres',
                icon: Icons.category,
              ),
              SizedBox(
                key: const ValueKey('popular_genres_list'),
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
                      onTap: () => context.push('/discover?genre=romance'),
                    ),
                    GenreCard(
                      genre: 'Thriller',
                      color: const Color(0xFF15263D),
                      onTap: () => context.push('/discover?genre=thriller'),
                    ),
                    GenreCard(
                      genre: 'Comedy',
                      color: const Color(0xFF3D2715),
                      onTap: () => context.push('/discover?genre=comedy'),
                    ),
                    GenreCard(
                      genre: 'Fantasy',
                      color: const Color(0xFF153D2A),
                      onTap: () => context.push('/discover?genre=fantasy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 7. AI HUB PROMOTIONAL CARD
              const AiHubCtaCard(key: ValueKey('ai_hub_cta')),
              const SizedBox(height: 40),
            ],
          ),
          loading: () => Column(
            key: const ValueKey('home_feed_skeleton'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeroCarouselSkeleton(key: ValueKey('hero_skeleton')),
              SizedBox(height: 24),
              ContinueWatchingSkeleton(key: ValueKey('continue_watching_skeleton')),
              TopRankedSkeleton(key: ValueKey('trending_skeleton')),
              StorySectionSkeleton(
                key: ValueKey('new_arrivals_skeleton'),
                title: 'New Arrivals',
                height: 215,
                cardWidth: 140,
              ),
              SectionHeader(
                key: ValueKey('browse_language_skeleton_header'),
                title: 'Browse by Language',
                icon: Icons.language,
              ),
              SizedBox(height: 45),
              SizedBox(height: 28),
              SectionHeader(
                key: ValueKey('popular_genres_skeleton_header'),
                title: 'Popular Genres',
                icon: Icons.category,
              ),
              SizedBox(height: 80),
              SizedBox(height: 28),
              AiHubCtaCard(key: ValueKey('ai_hub_cta_skeleton')),
              SizedBox(height: 40),
            ],
          ),
          error: (err, _) => Center(
            key: const ValueKey('home_feed_error'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.refresh, color: Colors.white54, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to load feed',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(homeFeedProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFeedTab extends ConsumerStatefulWidget {
  final String category;
  const _CategoryFeedTab({required this.category});

  @override
  ConsumerState<_CategoryFeedTab> createState() => _CategoryFeedTabState();
}

class _CategoryFeedTabState extends ConsumerState<_CategoryFeedTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    if (widget.category == 'Trending') {
      ref.invalidate(trendingStoriesProvider);
    } else if (widget.category == 'New') {
      ref.invalidate(latestStoriesProvider);
    } else {
      ref.invalidate(masterCatalogProvider);
      ref.invalidate(storiesByGenreProvider(widget.category.toLowerCase()));
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    AsyncValue<List<StoryModel>> storiesAsync;
    if (widget.category == 'Trending') {
      storiesAsync = ref.watch(trendingStoriesProvider);
    } else if (widget.category == 'New') {
      storiesAsync = ref.watch(latestStoriesProvider);
    } else {
      storiesAsync =
          ref.watch(storiesByGenreProvider(widget.category.toLowerCase()));
    }

    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: const Color(0xFF1E1E24),
      onRefresh: _onRefresh,
      child: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.movie_filter_outlined,
                      size: 56,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${widget.category} stories yet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check back soon or explore our full collection.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/discover');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Discover Stories'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroCarousel(stories: stories.take(5).toList()),
                const SizedBox(height: 24),
                SectionHeader(
                  title: '${widget.category} Stories',
                  icon: Icons.auto_awesome,
                  actionLabel: 'See All',
                  onAction: () {
                    final route = (widget.category == 'Trending')
                        ? '/discover?category=trending'
                        : (widget.category == 'New')
                            ? '/discover?category=new'
                            : '/discover?genre=${widget.category.toLowerCase()}';
                    context.push(route);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      return StoryCard(
                        story: stories[index],
                        width: double.infinity,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HeroCarouselSkeleton(),
              SizedBox(height: 24),
              StoryGridSkeleton(title: 'Loading...'),
            ],
          ),
        ),
        error: (e, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load ${widget.category} stories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HistoryCard extends StatelessWidget {
  final ContinueWatchingItem item;

  const _HistoryCard({super.key, required this.item});

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
  const _BecauseYouWatchedSection({super.key, required this.lastWatched});

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
              height: 225,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  return StoryCard(
                    story: recs[index],
                    width: 140,
                    height: 215,
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

