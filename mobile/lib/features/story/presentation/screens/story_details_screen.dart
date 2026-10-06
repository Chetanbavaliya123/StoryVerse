import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/comment_model.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/features/library/data/library_repository.dart';
import 'package:storyverse/features/story/data/comment_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart'
    as storyverse_skeleton;

class StoryDetailsScreen extends ConsumerStatefulWidget {
  final String storyId;
  const StoryDetailsScreen({super.key, required this.storyId});

  @override
  ConsumerState<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends ConsumerState<StoryDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isFavorite = false;
  bool _isInLibrary = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadLibraryStatus();
  }

  void _loadFavoriteStatus() {
    ref.read(libraryRepositoryProvider).isFavorite(widget.storyId).listen((
      val,
    ) {
      if (mounted) setState(() => _isFavorite = val);
    });
  }

  void _loadLibraryStatus() {
    ref.read(libraryRepositoryProvider).isInLibrary(widget.storyId).listen((
      val,
    ) {
      if (mounted) setState(() => _isInLibrary = val);
    });
  }

  void _toggleFavorite() {
    ref
        .read(libraryRepositoryProvider)
        .toggleFavorite(widget.storyId, !_isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _toggleLibrary() {
    ref
        .read(libraryRepositoryProvider)
        .toggleLibrary(widget.storyId, !_isInLibrary);
    setState(() => _isInLibrary = !_isInLibrary);
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref
          .read(commentRepositoryProvider)
          .addComment(storyId: widget.storyId, text: text);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDetailsProvider(widget.storyId));
    final episodesAsync = ref.watch(storyEpisodesProvider(widget.storyId));
    final commentsAsync = ref.watch(storyCommentsProvider(widget.storyId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: storyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primaryAccent,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Story unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your connection and try again.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(storyDetailsProvider(widget.storyId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (story) {
          if (story == null) {
            return const Center(
              child: Text(
                'Story not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              // Hero cover image
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: AppColors.primaryBackground,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWithFallback(
                        imageUrl: story.bannerUrl ?? story.thumbnailUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primaryBackground.withValues(
                                alpha: 0.2,
                              ),
                              AppColors.primaryBackground.withValues(
                                alpha: 0.8,
                              ),
                              AppColors.primaryBackground,
                            ],
                            stops: const [0.0, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Story info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre + Category
                      Row(
                        children: [
                          _chip(story.genreId.toUpperCase(), isPrimary: true),
                          const SizedBox(width: 8),
                          _chip(story.categoryId.toUpperCase()),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${story.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Author + stats
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _statItem(Icons.person_outline, story.author),
                          _statItem(
                            Icons.visibility_outlined,
                            _formatViews(story.views),
                          ),
                          _statItem(
                            Icons.video_library_outlined,
                            '${story.episodeCount} ep',
                          ),
                          _statItem(
                            Icons.timer_outlined,
                            _formatDuration(story.totalDuration),
                          ),
                          if (story.ageCategory != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                story.ageCategory!.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        story.fullDescription ?? story.description,
                        style: TextStyle(
                          color: story.categoryId == 'ai-generated'
                              ? Colors.white
                              : AppColors.secondaryText,
                          fontSize: story.categoryId == 'ai-generated'
                              ? 16
                              : 14,
                          height: story.categoryId == 'ai-generated'
                              ? 1.8
                              : 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tags
                      if (story.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: story.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 20),
                      // Action buttons
                      Row(
                        children: [
                          if (story.categoryId == 'ai-generated')
                            const Spacer(),
                          if (story.categoryId != 'ai-generated') ...[
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935), // StoryVerse Red
                                      Color(0xFFB71C1C), // Deep Red
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE53935,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    final episodes =
                                        episodesAsync.asData?.value;
                                    if (episodes != null &&
                                        episodes.isNotEmpty) {
                                      context.push(
                                        '/player/${widget.storyId}/${episodes.first.id}',
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Watching',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          _actionIcon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            _toggleFavorite,
                            _isFavorite
                                ? AppColors.primaryAccent
                                : Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _actionIcon(
                            _isInLibrary
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            _toggleLibrary,
                            _isInLibrary
                                ? AppColors.primaryAccent
                                : Colors.white,
                          ),
                        ],
                      ),
                      if (story.categoryId != 'ai-generated') ...[
                        const SizedBox(height: 24),
                        // Episodes section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Episodes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                '/story/${widget.storyId}/episodes',
                              ),
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (story.categoryId != 'ai-generated')
                episodesAsync.when(
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: storyverse_skeleton.SkeletonLoader(
                          height: 100,
                          borderRadius: 16,
                        ),
                      ),
                      childCount: 3,
                    ),
                  ),
                  error: (e, st) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Something went wrong loading episodes.',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (episodes) {
                    if (episodes.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No episodes yet',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Consumer(
                          builder: (context, ref, _) {
                            final ep = episodes[index];
                            final progressAsync = ref.watch(
                              watchHistoryProgressProvider(
                                '${widget.storyId}||${ep.id}',
                              ),
                            );

                            return InkWell(
                              onTap: () => context.push(
                                '/player/${widget.storyId}/${ep.id}',
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF181818),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: NetworkImageWithFallback(
                                        imageUrl: ep.thumbnailUrl,
                                        width: 120,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Episode ${ep.episodeNumber}',
                                            style: const TextStyle(
                                              color: AppColors.primaryAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ep.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            ep.description,
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                ep.formattedDuration,
                                                style: const TextStyle(
                                                  color: AppColors.mutedText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              progressAsync.when(
                                                data: (history) {
                                                  if (history == null ||
                                                      history.percentage <= 0) {
                                                    return const SizedBox.shrink();
                                                  }
                                                  return Expanded(
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2,
                                                                ),
                                                            child: LinearProgressIndicator(
                                                              value: history
                                                                  .percentage,
                                                              backgroundColor:
                                                                  Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                              color: AppColors
                                                                  .primaryAccent,
                                                              minHeight: 4,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          '${(history.percentage * 100).toInt()}%',
                                                          style: const TextStyle(
                                                            color: AppColors
                                                                .primaryAccent,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                loading: () =>
                                                    const SizedBox.shrink(),
                                                error: (_, _) =>
                                                    const SizedBox.shrink(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }, childCount: episodes.length > 5 ? 5 : episodes.length),
                    );
                  },
                ),
              // Comments section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add comment input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                hintStyle: const TextStyle(
                                  color: AppColors.mutedText,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF181818),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addComment,
                            icon: const Icon(
                              Icons.send,
                              color: AppColors.primaryAccent,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primarySurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Comments list
              commentsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
                error: (e, st) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Failed to load comments',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCommentItem(comments[index]),
                      childCount: comments.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primaryAccent.withValues(alpha: 0.15)
            : const Color(0xFF181818),
        border: Border.all(
          color: isPrimary
              ? AppColors.primaryAccent.withValues(alpha: 0.3)
              : Colors.white24,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppColors.primaryAccent : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.secondaryText, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwn = comment.userId == currentUserId;
    final timeAgo = comment.createdAt != null
        ? _timeAgo(comment.createdAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: comment.userPhoto != null
                ? NetworkImage(comment.userPhoto!)
                : null,
            child: comment.userPhoto == null
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                    if (isOwn) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref
                            .read(commentRepositoryProvider)
                            .deleteComment(widget.storyId, comment.id),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.mutedText,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '$views';
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
