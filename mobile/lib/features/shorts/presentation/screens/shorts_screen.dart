import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:storyverse/core/models/player_playback_state.dart';
import 'package:storyverse/core/utils/video_url_helper.dart';
import 'package:storyverse/core/utils/share_helper.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/features/shorts/data/shorts_repository.dart';
import 'package:storyverse/features/shorts/presentation/providers/shorts_provider.dart';
import 'package:storyverse/features/shorts/presentation/widgets/shorts_overlay.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/features/library/data/library_repository.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';
import 'package:storyverse/features/video_player/presentation/widgets/vertical_video_view.dart';

class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  VideoPlayerController? _controller;
  VideoPlayerController? _preloadedController;
  int? _preloadedIndex;

  PlayerPlaybackState _playbackState = PlayerPlaybackState.initializing;
  String _errorMessage = '';

  // Transient tap feedback
  bool _showTapFeedback = false;
  bool _isPlayingFeedback = false;
  Timer? _tapFeedbackTimer;

  // End-of-video peek animation
  late AnimationController _peekAnimationController;
  late Animation<double> _peekOffsetAnimation;
  bool _hasSavedThisLoop = false;

  Timer? _progressSaveTimer;
  late final WatchHistoryRepository _historyRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);

    _peekAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _peekOffsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -120.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(-120.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -120.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45,
      ),
    ]).animate(_peekAnimationController);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveProgress();
      _controller?.pause();
    }
  }

  void _onFeedDataLoaded(List<ShortsItem> feed) {
    if (_controller == null &&
        feed.isNotEmpty &&
        _playbackState != PlayerPlaybackState.error) {
      _initializeCurrentShort(feed);
    }
  }

  Future<void> _initializeCurrentShort(List<ShortsItem> feed) async {
    if (_currentIndex < 0 || _currentIndex >= feed.length) return;

    final item = feed[_currentIndex];
    final isMuted = ref.read(shortsMuteProvider);

    _progressSaveTimer?.cancel();
    _saveProgress(item: item);

    // If preloaded controller matches current index and is initialized, promote it
    if (_preloadedController != null &&
        _preloadedIndex == _currentIndex &&
        _preloadedController!.value.isInitialized) {
      if (_controller != null) {
        _controller!.removeListener(_onControllerUpdate);
        _controller!.dispose();
      }

      _controller = _preloadedController;
      _preloadedController = null;
      _preloadedIndex = null;

      _controller!.addListener(_onControllerUpdate);
      await _controller!.setLooping(true);
      await _controller!.setVolume(isMuted ? 0.0 : 1.0);
      await _controller!.play();

      _startProgressSaveTimer(item);

      if (mounted) {
        setState(() {
          _hasSavedThisLoop = false;
          _playbackState = PlayerPlaybackState.playing;
          _errorMessage = '';
        });
      }

      // Preload next short in the background
      _preloadNextShort(feed, _currentIndex + 1);
      return;
    }

    // Clean up active controller
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _hasSavedThisLoop = false;
      _playbackState = PlayerPlaybackState.initializing;
      _errorMessage = '';
    });

    final rawVideoUrl = item.episode.videoUrl.trim();
    if (rawVideoUrl.isEmpty) {
      setState(() {
        _playbackState = PlayerPlaybackState.error;
        _errorMessage = 'Video source is missing for this episode.';
      });
      return;
    }

    final normalizedUrl = VideoUrlHelper.normalize(rawVideoUrl);

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(normalizedUrl));
      _controller = controller;

      await controller.initialize().timeout(const Duration(seconds: 15));
      await controller.setLooping(true);
      await controller.setVolume(isMuted ? 0.0 : 1.0);

      controller.addListener(_onControllerUpdate);
      await controller.play();

      _startProgressSaveTimer(item);

      if (mounted) {
        setState(() {
          _playbackState = PlayerPlaybackState.playing;
        });
      }

      // Preload next short in background
      _preloadNextShort(feed, _currentIndex + 1);
    } catch (e) {
      if (mounted) {
        setState(() {
          _playbackState = PlayerPlaybackState.error;
          _errorMessage = 'Unable to play this short. Please try again.';
        });
      }
    }
  }

  Future<void> _preloadNextShort(List<ShortsItem> feed, int nextIndex) async {
    if (nextIndex < 0 || nextIndex >= feed.length) return;
    if (_preloadedIndex == nextIndex && _preloadedController != null) return;

    try {
      if (_preloadedController != null) {
        await _preloadedController!.dispose();
        _preloadedController = null;
        _preloadedIndex = null;
      }

      final nextItem = feed[nextIndex];
      final rawUrl = nextItem.episode.videoUrl.trim();
      if (rawUrl.isEmpty) return;

      final normalizedUrl = VideoUrlHelper.normalize(rawUrl);
      final nextController =
          VideoPlayerController.networkUrl(Uri.parse(normalizedUrl));
      _preloadedController = nextController;
      _preloadedIndex = nextIndex;

      await nextController.initialize();
      await nextController.setVolume(0.0);
    } catch (_) {
      // Preload failures silently drop without interrupting user experience
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;

    // Detect near end: save watch progress and trigger peek animation suggestion
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 700)) {
      if (!_hasSavedThisLoop) {
        _hasSavedThisLoop = true;
        _saveProgress(markCompleted: true);

        // Trigger prominent upward peek suggestion
        if (!_peekAnimationController.isAnimating) {
          _peekAnimationController.forward(from: 0.0);
        }
      }
    } else if (position < const Duration(seconds: 2)) {
      // Looped back to start seamlessly
      _hasSavedThisLoop = false;
    }

    if (_playbackState != PlayerPlaybackState.initializing &&
        _playbackState != PlayerPlaybackState.error) {
      final newState = controller.value.isPlaying
          ? PlayerPlaybackState.playing
          : PlayerPlaybackState.paused;
      if (_playbackState != newState) {
        setState(() {
          _playbackState = newState;
        });
      }
    }
  }

  void _startProgressSaveTimer(ShortsItem item) {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _saveProgress(item: item);
    });
  }

  void _saveProgress({ShortsItem? item, bool markCompleted = false}) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final feed = ref.read(shortsFeedProvider).asData?.value;
    final currentItem = item ??
        (feed != null && _currentIndex < feed.length
            ? feed[_currentIndex]
            : null);
    if (currentItem == null) return;

    final position = controller.value.position.inSeconds;
    final total = controller.value.duration.inSeconds;
    if (total <= 0) return;

    _historyRepo.updateProgress(
      storyId: currentItem.story.id,
      episodeId: currentItem.episode.id,
      progressSeconds: markCompleted ? total : position,
      totalDuration: total,
    );
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (_playbackState == PlayerPlaybackState.completed) {
      // Replay from start
      controller.seekTo(Duration.zero);
      controller.play();
      setState(() {
        _playbackState = PlayerPlaybackState.playing;
      });
      _showBriefFeedback(isPlaying: true);
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
      _saveProgress();
      setState(() {
        _playbackState = PlayerPlaybackState.paused;
      });
      _showBriefFeedback(isPlaying: false);
    } else {
      controller.play();
      setState(() {
        _playbackState = PlayerPlaybackState.playing;
      });
      _showBriefFeedback(isPlaying: true);
    }
  }

  void _showBriefFeedback({required bool isPlaying}) {
    _tapFeedbackTimer?.cancel();
    setState(() {
      _showTapFeedback = true;
      _isPlayingFeedback = isPlaying;
    });
    _tapFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showTapFeedback = false;
        });
      }
    });
  }

  void _toggleMute() {
    final currentMute = ref.read(shortsMuteProvider);
    final nextMute = !currentMute;
    ref.read(shortsMuteProvider.notifier).setMuted(nextMute);
    _controller?.setVolume(nextMute ? 0.0 : 1.0);
    _preloadedController?.setVolume(0.0);
    ref
        .read(userRepositoryProvider)
        .updateSinglePreference('isMuted', nextMute);
  }

  void _onPageChanged(int index, List<ShortsItem> feed) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });

    if (index >= feed.length - 3) {
      ref.read(shortsFeedProvider.notifier).loadMore();
    }

    _initializeCurrentShort(feed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _tapFeedbackTimer?.cancel();
    _progressSaveTimer?.cancel();
    _peekAnimationController.dispose();
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
    }
    _preloadedController?.dispose();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(shortsFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedAsync.when(
        data: (feed) {
          if (feed.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_library_outlined,
                      color: DesignTokens.textMuted,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Shorts Available',
                      style: DesignTokens.titleStyle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Published episodes from stories will appear here.',
                      style: DesignTokens.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(shortsFeedProvider.notifier).refreshFeed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          _onFeedDataLoaded(feed);

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: feed.length,
            onPageChanged: (idx) => _onPageChanged(idx, feed),
            itemBuilder: (context, index) {
              final item = feed[index];
              final isCurrent = index == _currentIndex;

              return Consumer(
                builder: (context, ref, _) {
                  final isFavAsync =
                      ref.watch(isFavoriteProvider(item.story.id));
                  final isSavedAsync =
                      ref.watch(isInLibraryProvider(item.story.id));
                  final isFavorite = isFavAsync.value ?? false;
                  final isSaved = isSavedAsync.value ?? false;

                  final hasGenuineError = isCurrent &&
                      _playbackState == PlayerPlaybackState.error;
                  final isLoading = isCurrent &&
                      _playbackState == PlayerPlaybackState.initializing;
                  final isCompleted = isCurrent && _hasSavedThisLoop;

                  return AnimatedBuilder(
                    animation: _peekAnimationController,
                    builder: (context, child) {
                      double offset = 0.0;
                      if (isCurrent) {
                        offset = _peekOffsetAnimation.value;
                      } else if (index == _currentIndex + 1) {
                        offset = _peekOffsetAnimation.value;
                      }
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: child,
                      );
                    },
                    child: VerticalVideoView(
                      controller: isCurrent ? _controller : null,
                      thumbnailUrl: item.episode.thumbnailUrl.isNotEmpty
                          ? item.episode.thumbnailUrl
                          : item.story.thumbnailUrl,
                      isLoading: isLoading,
                      hasError: hasGenuineError,
                      errorMessage: _errorMessage,
                      onRetry: () => _initializeCurrentShort(feed),
                      overlay: isCurrent
                          ? ShortsOverlay(
                              story: item.story,
                              episode: item.episode,
                              controller: _controller,
                              isMuted: ref.watch(shortsMuteProvider),
                              isFavorite: isFavorite,
                              isInLibrary: isSaved,
                              isCompleted: isCompleted,
                              showTapFeedback: _showTapFeedback,
                              isPlayingFeedback: _isPlayingFeedback,
                              onToggleMute: _toggleMute,
                              onToggleFavorite: () async {
                                await ref
                                    .read(libraryRepositoryProvider)
                                    .toggleFavorite(
                                      item.story.id,
                                      !isFavorite,
                                    );
                              },
                              onToggleBookmark: () async {
                                await ref
                                    .read(libraryRepositoryProvider)
                                    .toggleLibrary(
                                      item.story.id,
                                      !isSaved,
                                    );
                              },
                              onShare: () {
                                ShareHelper.shareStory(
                                  context: context,
                                  storyId: item.story.id,
                                  title: item.story.title,
                                  episodeTitle: item.episode.title,
                                );
                              },
                              onViewStory: () {
                                _saveProgress(item: item);
                                _controller?.pause();
                                context.push('/story/${item.story.id}');
                              },
                              onWatchNow: () {
                                _saveProgress(item: item);
                                _controller?.pause();
                                context.push(
                                  '/story/${item.story.id}?episodeId=${item.episode.id}',
                                );
                              },
                              onTapVideo: _togglePlayPause,
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: DesignTokens.primaryAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shorts feed',
                style: DesignTokens.titleStyle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(shortsFeedProvider.notifier).refreshFeed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
