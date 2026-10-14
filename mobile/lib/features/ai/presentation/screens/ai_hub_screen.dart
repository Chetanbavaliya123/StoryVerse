import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/theme/app_colors.dart';
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
  double _conflictScope = 0.68;
  final TextEditingController _promptController = TextEditingController();

  final List<String> _sparks = [
    'Noir Detective',
    'Cyber-Dystopia',
    'Bioluminescent Sci-Fi',
    'Time-Loop Romance',
    'Psychological Thriller',
    'Dark Fantasy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
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
                  Tab(text: 'Overview'),
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
            _buildOverviewTab(),
            const AiGeneratorScreen(isEmbedded: true),
            _buildAiLibrary(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final int conflictPct = (_conflictScope * 100).round();
    final String conflictLabel = _conflictScope < 0.4
        ? 'Internal / Personal ($conflictPct%)'
        : _conflictScope < 0.75
            ? 'Psychological Intimate ($conflictPct%)'
            : 'Existential / Cosmic ($conflictPct%)';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Natural Language Prompt Bar with Sparks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Story Spark Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'v3.2 Neural',
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe a tone, plot twist, era, or mood...',
                  hintStyle:
                      const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.primaryBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.primaryAccent),
                    onPressed: () {
                      final text = _promptController.text.trim();
                      if (text.isNotEmpty) {
                        _tabController.animateTo(1);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Sparks Horizontal Carousel
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sparks.length,
                  itemBuilder: (context, index) {
                    final spark = _sparks[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          spark,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primaryBackground,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _promptController.text =
                              'A narrative centered on $spark with atmospheric tension and cinematic depth.';
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3 ORIGINAL FEATURE CARDS
        _buildFeatureCard(
          context: context,
          title: 'Story Assistant',
          description:
              'Ask questions about any story, get character backgrounds, or explore lore.',
          icon: Icons.chat_bubble_outline_rounded,
          color: Colors.blueAccent,
          route: '/ai/assistant',
        ),
        const SizedBox(height: 14),
        _buildFeatureCard(
          context: context,
          title: 'AI Story Generator',
          description:
              'Generate your own short stories using our advanced AI models.',
          icon: Icons.auto_awesome,
          color: AppColors.primaryAccent,
          route: '/ai/generator',
        ),
        const SizedBox(height: 14),
        _buildFeatureCard(
          context: context,
          title: 'Smart Recommendations',
          description:
              'Get highly personalized story recommendations based on your taste.',
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFFFFB800),
          route: '/discover',
        ),

        const SizedBox(height: 24),

        // RESTORED SLIDER / CAROUSEL SECTION: SCREENPLAY SANDBOX
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Screenplay Sandbox',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    conflictLabel,
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Calibrate story tension across intimate character psychology and cosmic scale.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              // Conflict Scale Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryAccent,
                  inactiveTrackColor: AppColors.primaryBackground,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _conflictScope,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() {
                      _conflictScope = val;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Intimate / Internal',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 11),
                    ),
                    Text(
                      'Cosmic / Existential',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Active Draft Synopsis Preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Active Storyboard Draft',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Act I Preview',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The Clockmaker\'s daughter discovers an anomalous brass gear that ticks backwards whenever the district siren sounds. Across seven rainy blocks, chronometers gradually synchronize to her pulse.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _tabController.animateTo(1);
                        },
                        icon: const Icon(Icons.bolt, size: 18),
                        label: const Text(
                          'Open Generator with Settings',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              AppColors.primarySurface,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.mutedText,
              size: 14,
            ),
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
                    title: const Text('Delete Story',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        'Remove this story from your saved stories?',
                        style: TextStyle(color: AppColors.secondaryText)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(libraryRepositoryProvider)
                      .toggleLibrary(story.id, false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Story removed')));
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
