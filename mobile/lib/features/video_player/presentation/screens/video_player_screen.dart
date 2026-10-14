import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:storyverse/core/models/player_playback_state.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/utils/video_url_helper.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';
import 'package:storyverse/features/video_player/presentation/widgets/vertical_video_view.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_player_controls.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_selector_sheet.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String storyId;
  final String episodeId;

  const VideoPlayerScreen({
    super.key,
    required this.storyId,
    required this.episodeId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  PageController? _pageController;
  int _currentIndex = 0;
  StoryModel? _story;
  List<EpisodeModel> _episodes = [];

  VideoPlayerController? _controller;
  PlayerPlaybackState _playbackState = PlayerPlaybackState.initializing;
  String _errorMessage = '';
  bool _showControls = false;
  bool _isMuted = false;
  bool _isAutoplayEnabled = true;

  bool _isCountdownActive = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;
  Timer? _tapFeedbackTimer;
  bool _showTapFeedback = false;
  bool _isPlayingFeedback = false;
  late final WatchHistoryRepository _historyRepo;
  bool _isAutoAdvancing = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _loadStoryAndEpisodes();
  }

  Future<void> _loadStoryAndEpisodes() async {
    setState(() {
      _playbackState = PlayerPlaybackState.initializing;
      _errorMessage = '';
    });

    try {
      final storyRepo = ref.read(storyRepositoryProvider);
      final story = await storyRepo.getStory(widget.storyId);
      final episodes = await storyRepo.getEpisodes(widget.storyId);
      episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      if (episodes.isEmpty) {
        setState(() {
          _playbackState = PlayerPlaybackState.error;
          _errorMessage = 'No episodes available for this story.';
        });
        return;
      }

      int initialIndex = episodes.indexWhere((e) => e.id == widget.episodeId);
      if (initialIndex < 0) initialIndex = 0;

      if (!mounted) return;

      setState(() {
        _story = story;
        _episodes = episodes;
        _currentIndex = initialIndex;
        _pageController = PageController(initialPage: initialIndex);
      });

      await _initializeCurrentEpisode();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _playbackState = PlayerPlaybackState.error;
        _errorMessage = 'Failed to load episodes: $e';
      });
    }
  }

  Future<void> _initializeCurrentEpisode() async {
    if (_episodes.isEmpty) return;

    final episode = _episodes[_currentIndex];

    _cancelCountdown();
    _progressSaveTimer?.cancel();
    _hideControlsTimer?.cancel();
    _saveProgress();

    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _isAutoAdvancing = false;
      _playbackState = PlayerPlaybackState.initializing;
      _errorMessage = '';
      _showControls = false;
    });

    final rawVideoUrl = episode.videoUrl.trim();
    if (rawVideoUrl.isEmpty) {
      setState(() {
        _playbackState = PlayerPlaybackState.error;
        _errorMessage = 'Video source is missing for this episode.';
      });
      return;
    }

    if (VideoUrlHelper.isYouTube(rawVideoUrl)) {
      setState(() {
        _playbackState = PlayerPlaybackState.error;
        _errorMessage =
            'This episode requires a direct video stream source.\nYouTube links are not supported in native playback.';
      });
      return;
    }

    final normalizedUrl = VideoUrlHelper.normalize(rawVideoUrl);

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(normalizedUrl));
      _controller = controller;

      await controller.initialize().timeout(const Duration(seconds: 15));
      await controller.setVolume(_isMuted ? 0.0 : 1.0);

      // Check WatchHistory for resume position
      final history = await _historyRepo.getEpisodeProgress(
        widget.storyId,
        episode.id,
      );

      if (history != null &&
          !history.isCompleted &&
          history.progressSeconds > 3 &&
          controller.value.duration.inSeconds > 0 &&
          history.progressSeconds < controller.value.duration.inSeconds - 5) {
        await controller.seekTo(Duration(seconds: history.progressSeconds));
      }

      controller.addListener(_onControllerUpdate);
      await controller.play();

      _startProgressSaveTimer();
      _startHideControlsTimer();

      if (mounted) {
        setState(() {
          _playbackState = PlayerPlaybackState.playing;
          _showControls = true; // Show functions initially for 3 seconds
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playbackState = PlayerPlaybackState.error;
          if (e is TimeoutException) {
            _errorMessage = 'Playback timed out. Please check your internet.';
          } else {
            _errorMessage = 'Unable to play this episode. Please try again.';
          }
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final duration = controller.value.duration;
    final position = controller.value.position;

    // Detect natural completion: auto-advance with 5s countdown or exit on last episode
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 600)) {
      if (!_isAutoAdvancing && !_isCountdownActive) {
        _saveProgress(markCompleted: true);
        if (_currentIndex < _episodes.length - 1) {
          if (_isAutoplayEnabled) {
            _startAutoplayCountdown();
          }
        } else {
          // Last episode ended -> return to Story Details ("Watch Now") screen
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
      return;
    }

    if (_playbackState != PlayerPlaybackState.completed &&
        _playbackState != PlayerPlaybackState.initializing &&
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

  void _startAutoplayCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = 5;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isCountdownActive = false;
        });
        _goToEpisodeIndex(_currentIndex + 1);
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    if (_isCountdownActive) {
      setState(() {
        _isCountdownActive = false;
        _countdownSeconds = 5;
      });
    }
  }

  void _toggleAutoplay() {
    setState(() {
      _isAutoplayEnabled = !_isAutoplayEnabled;
      if (!_isAutoplayEnabled && _isCountdownActive) {
        _cancelCountdown();
      }
    });
  }

  void _startProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _saveProgress();
    });
  }

  void _saveProgress({bool markCompleted = false}) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_episodes.isEmpty) return;

    final currentEp = _episodes[_currentIndex];
    final position = controller.value.position.inSeconds;
    final total = controller.value.duration.inSeconds;
    if (total <= 0) return;

    _historyRepo.updateProgress(
      storyId: widget.storyId,
      episodeId: currentEp.id,
      progressSeconds: markCompleted ? total : position,
      totalDuration: total,
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  /// Screen Tap Handler:
  /// Taps toggle play/pause immediately with brief 500ms feedback,
  /// keeps controls visible when paused, and auto-hides after 3 seconds when playing.
  void _onTapVideoScreen() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
      _saveProgress();
      _hideControlsTimer?.cancel();
      setState(() {
        _playbackState = PlayerPlaybackState.paused;
        _showControls = true;
      });
      _showBriefFeedback(isPlaying: false);
    } else {
      controller.play();
      setState(() {
        _playbackState = PlayerPlaybackState.playing;
        _showControls = true;
      });
      _startHideControlsTimer();
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
    setState(() {
      _isMuted = !_isMuted;
    });
    _controller?.setVolume(_isMuted ? 0.0 : 1.0);
    if (_showControls) _startHideControlsTimer();
  }

  void _seekTo(Duration target) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    controller.seekTo(target);
    _saveProgress();
    _startHideControlsTimer();
  }

  void _goToEpisodeIndex(int index) {
    if (index < 0 || index >= _episodes.length) return;
    _cancelCountdown();

    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    _cancelCountdown();
    setState(() {
      _currentIndex = index;
    });
    _initializeCurrentEpisode();
  }

  @override
  void dispose() {
    _saveProgress();
    _cancelCountdown();
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _tapFeedbackTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
    }
    _pageController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _openEpisodeSelector() {
    if (_story == null || _episodes.isEmpty) return;
    EpisodeSelectorSheet.show(
      context: context,
      story: _story!,
      episodes: _episodes,
      currentIndex: _currentIndex,
      onSelectEpisode: (index) {
        _goToEpisodeIndex(index);
      },
    );
  }

  Widget _buildAutoplayCountdownOverlay(EpisodeModel nextEp) {
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xE614141E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: _countdownSeconds / 5.0,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                ),
                Text(
                  '$_countdownSeconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Up Next in 5s',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ep ${nextEp.episodeNumber}: ${nextEp.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _cancelCountdown();
                _goToEpisodeIndex(_currentIndex + 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Play Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: _cancelCountdown,
              tooltip: 'Cancel Autoplay',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGenuineError = _playbackState == PlayerPlaybackState.error;
    final isLoading = _playbackState == PlayerPlaybackState.initializing;

    if (_episodes.isEmpty && hasGenuineError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _loadStoryAndEpisodes,
                      child: const Text('Retry'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_episodes.isEmpty || _story == null || _pageController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _episodes.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final episode = _episodes[index];
              final isCurrent = index == _currentIndex;

              return VerticalVideoView(
                controller: isCurrent ? _controller : null,
                thumbnailUrl: episode.thumbnailUrl,
                isLoading: isCurrent ? isLoading : false,
                hasError: isCurrent ? hasGenuineError : false,
                errorMessage: _errorMessage,
                isCinematicLetterbox: true,
                onRetry: _initializeCurrentEpisode,
                overlay: isCurrent
                    ? EpisodePlayerControls(
                        story: _story!,
                        episode: episode,
                        controller: _controller,
                        showControls: _showControls,
                        isMuted: _isMuted,
                        isAutoplayEnabled: _isAutoplayEnabled,
                        onToggleAutoplay: _toggleAutoplay,
                        isInitialized: _controller != null && _controller!.value.isInitialized,
                        showTapFeedback: _showTapFeedback,
                        isPlayingFeedback: _isPlayingFeedback,
                        onTapVideo: _onTapVideoScreen,
                        onToggleMute: _toggleMute,
                        onBack: () {
                          _saveProgress();
                          Navigator.of(context).pop();
                        },
                        onSeek: _seekTo,
                        onOpenEpisodesSheet: _openEpisodeSelector,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          if (_isCountdownActive && _currentIndex < _episodes.length - 1)
            _buildAutoplayCountdownOverlay(_episodes[_currentIndex + 1]),
        ],
      ),
    );
  }
}
