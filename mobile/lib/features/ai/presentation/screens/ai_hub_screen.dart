import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_generator_screen.dart';
import 'package:storyverse/features/library/data/library_repository.dart';

class AiHubScreen extends ConsumerStatefulWidget {
  const AiHubScreen({super.key});

  @override
  ConsumerState<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends ConsumerState<AiHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryAccent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  'INTELLIGENCE SUITE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'AI Hub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        toolbarHeight: 90,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppColors.primaryAccent,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(22),
                tabs: const [
                  Tab(text: 'Generator'),
                  Tab(text: 'My Stories'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            const AiGeneratorScreen(isEmbedded: true),
            _buildAiLibrary(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiLibrary() {
    final aiStoriesAsync = ref.watch(aiStoriesProvider);

    return aiStoriesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_awesome,
            title: 'No AI Stories',
            message: 'Generate and save AI stories to see them here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryCard(
              story: story,
              isHorizontal: true,
              subtitle: 'Generated AI Story',
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.primarySurface,
                    title: const Text('Delete Story', style: TextStyle(color: Colors.white)),
                    content: const Text('Remove this story from your saved stories?', style: TextStyle(color: AppColors.secondaryText)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(libraryRepositoryProvider).toggleLibrary(story.id, false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story removed')));
                  }
                }
              },
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonLoader(height: 120, borderRadius: 16),
          );
        },
      ),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading AI Stories',
        message: e.toString(),
      ),
    );
  }
}
