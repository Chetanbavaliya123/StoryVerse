import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_generator_screen.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';
import 'package:storyverse/features/library/data/library_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';

/// The canonical, unified StoryVerse AI Hub Screen.
/// Provides a seamless two-page experience:
/// Page 1: AI Story Generator
/// Page 2: User's Generated AI Stories
/// with interactive horizontal swiping, tabs, and visible page slider.
class AiHubScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const AiHubScreen({super.key, this.initialPage = 0});

  @override
  ConsumerState<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends ConsumerState<AiHubScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPage.clamp(0, 1);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    if (_currentPageIndex == page) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI HUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Column(
            children: [
              // 1. Interactive Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _animateToPage(0),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: _currentPageIndex == 0
                                    ? AppColors.primaryAccent
                                    : AppColors.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generator',
                                style: TextStyle(
                                  color: _currentPageIndex == 0
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                  fontSize: 15,
                                  fontWeight: _currentPageIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _animateToPage(1),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmarks_rounded,
                                size: 16,
                                color: _currentPageIndex == 1
                                    ? AppColors.primaryAccent
                                    : AppColors.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Stories',
                                style: TextStyle(
                                  color: _currentPageIndex == 1
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                  fontSize: 15,
                                  fontWeight: _currentPageIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Visible Slider Track & Progress Indicator (●━━━━━━━━━━━━━━━━○)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track line
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Animated sliding indicator
                    AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        double page = _currentPageIndex.toDouble();
                        if (_pageController.hasClients &&
                            _pageController.position.haveDimensions) {
                          page = _pageController.page ?? page;
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final halfWidth = constraints.maxWidth / 2;
                            final leftOffset = page * halfWidth;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(left: leftOffset),
                                width: halfWidth,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryAccent,
                                      Color(0xFFFF334B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAccent
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          // PAGE 1: AI Story Generator
          AiGeneratorScreen(
            isEmbedded: true,
            onStorySaved: () => _animateToPage(1),
          ),

          // PAGE 2: User's Generated AI Stories Library
          _buildAiStoriesTab(),
        ],
      ),
    );
  }

  Widget _buildAiStoriesTab() {
    final aiStoriesAsync = ref.watch(aiStoriesProvider);

    return aiStoriesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primaryAccent,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No AI Stories Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Generate and save unique AI stories to read and revisit them here anytime.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _animateToPage(0),
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('Start Generating'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryAccent,
          backgroundColor: const Color(0xFF1E1E24),
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(aiStoriesProvider);
            ref.invalidate(libraryStoriesProvider);
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCard(
                story: story,
                isHorizontal: true,
                subtitle: 'Generated AI Story',
                onDelete: () => _confirmDeleteStory(story),
              );
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonLoader(height: 120, borderRadius: 16),
          );
        },
      ),
      error: (e, _) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(height: 14),
              const Text(
                'Failed to load AI Stories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(aiStoriesProvider),
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
    );
  }

  Future<void> _confirmDeleteStory(StoryModel story) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primarySurface,
        title: const Text(
          'Delete Story',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove this story from your generated stories library?',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(libraryRepositoryProvider)
            .toggleLibrary(story.id, false);
      } catch (_) {}
      try {
        await ref.read(aiRepositoryProvider).deleteGeneration(story.id);
      } catch (_) {}
      ref.invalidate(aiStoriesProvider);
      ref.invalidate(libraryStoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story removed from AI Stories.')),
        );
      }
    }
  }
}
