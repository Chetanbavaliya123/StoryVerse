import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';

import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/features/video_player/presentation/widgets/premium_video_player.dart';
import 'package:storyverse/features/video_player/presentation/widgets/player_controls_overlay.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_info_section.dart';
import 'package:storyverse/features/video_player/presentation/widgets/episode_tile.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;
  EpisodeModel? _episode;
  List<EpisodeModel> _allEpisodes = [];
  bool _isCompleted = false;
  late final WatchHistoryRepository _historyRepo;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _loadEpisode();
  }

  Future<void> _loadEpisode() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final repo = ref.read(storyRepositoryProvider);
      final episode = await repo.getEpisode(widget.storyId, widget.episodeId);
      final allEpisodes = await repo.getEpisodes(widget.storyId);
      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      if (episode == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Episode not found';
          _isLoading = false;
        });
        return;
      }

      if (episode.videoUrl.trim().isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video unavailable for this episode.';
          _isLoading = false;
        });
        return;
      }

      _episode = episode;
      _allEpisodes = allEpisodes;

      // Restore previous position
      final history = await _historyRepo.getEpisodeProgress(
        widget.storyId,
        widget.episodeId,
      );

      await _initializePlayer(episode.videoUrl, history?.progressSeconds);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializePlayer(String rawVideoUrl, int? startPosition) async {
    _controller?.dispose();

    String videoUrl = rawVideoUrl;
    String provider = 'direct/supabase';

    if (videoUrl.contains('drive.google.com')) {
      provider = 'google_drive';
      final driveMatch = RegExp(
        r'(?:file\/d\/|id=)([a-zA-Z0-9_-]+)',
      ).firstMatch(videoUrl);
      if (driveMatch != null && driveMatch.group(1) != null) {
        final fileId = driveMatch.group(1);
        // Add confirm=t to bypass the Google Drive virus scan warning page for large files
        videoUrl =
            'https://drive.google.com/uc?export=download&confirm=t&id=$fileId';

        // On web, Google Drive blocks direct streaming due to CORS.
        // We use a CORS proxy to bypass this restriction.
        if (const bool.fromEnvironment('dart.library.html') ||
            const bool.fromEnvironment('dart.library.js_util')) {
          videoUrl = 'https://corsproxy.io/?${Uri.encodeComponent(videoUrl)}';
        }
      }
    } else if (videoUrl.contains('youtube.com') ||
        videoUrl.contains('youtu.be')) {
      provider = 'youtube';
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage =
              'This episode needs a direct video source.\nYouTube URLs are not supported as in-app video sources.';
        });
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _controller = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 15));

      print('PLAYER READY');

      if (startPosition != null && startPosition > 0) {
        await controller.seekTo(Duration(seconds: startPosition));
      }

      controller.addListener(_onPlayerStateChange);
      controller.play();

      _startProgressSaveTimer();
      _startHideControlsTimer();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      assert(() {
        print('================ VIDEO PLAYER DIAGNOSTIC ================');
        print('Provider: $provider');
        print('Original URL: $rawVideoUrl');
        print('Normalized URL: $videoUrl');
        print('Error: $e');
        print('=======================================================');
        return true;
      }());

      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          if (e is TimeoutException) {
            _errorMessage = 'Video is taking too long to load.';
          } else if (provider == 'google_drive') {
            _errorMessage =
                'Unable to play this Google Drive video. It may be private, restricted, or exceeded sharing limits.';
          } else {
            _errorMessage = 'Unable to play this episode.';
          }
        });
      }
    }
  }

  void _onPlayerStateChange() {
    if (!mounted) return;
    setState(() {});

    final controller = _controller;
    if (controller == null) return;

    if (controller.value.position >=
            controller.value.duration - const Duration(seconds: 1) &&
        controller.value.duration > Duration.zero) {
      if (!_isCompleted) {
        _saveProgress();
        setState(() {
          _isCompleted = true;
          _showControls = false;
        });
      }
    } else if (_isCompleted &&
        controller.value.position <
            controller.value.duration - const Duration(seconds: 2)) {
      setState(() {
        _isCompleted = false;
      });
    }
  }

  void _startProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position.inSeconds;
    final total = controller.value.duration.inSeconds;
    if (total <= 0) return;

    _historyRepo.updateProgress(
      storyId: widget.storyId,
      episodeId: widget.episodeId,
      progressSeconds: position,
      totalDuration: total,
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startHideControlsTimer();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      _saveProgress();
      setState(() {
        _showControls = true;
      });
    } else {
      // If at end, replay from start
      if (controller.value.position >=
          controller.value.duration - const Duration(seconds: 1)) {
        controller.seekTo(Duration.zero);
      }
      controller.play();
      _startHideControlsTimer();
    }
  }

  void _seekForward() {
    final controller = _controller;
    if (controller == null) return;
    final newPos = controller.value.position + const Duration(seconds: 10);
    controller.seekTo(
      newPos > controller.value.duration ? controller.value.duration : newPos,
    );
    _startHideControlsTimer();
  }

  void _seekBackward() {
    final controller = _controller;
    if (controller == null) return;
    final newPos = controller.value.position - const Duration(seconds: 10);
    controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
    _startHideControlsTimer();
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _switchEpisode(EpisodeModel episode) async {
    _saveProgress();
    _controller?.pause();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _episode = episode;
      _isCompleted = false;
    });

    final history = await _historyRepo.getEpisodeProgress(
      widget.storyId,
      episode.id,
    );
    await _initializePlayer(episode.videoUrl, history?.progressSeconds);
  }


  @override
  void dispose() {
    _saveProgress();
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area
            if (_isFullscreen)
              Expanded(child: _buildPremiumVideoArea())
            else
              _buildPremiumVideoArea(),

            // Episode Info & List (hidden in fullscreen)
            if (!_isFullscreen) Expanded(child: _buildBottomSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumVideoArea() {
    return PremiumVideoPlayer(
      controller: _controller,
      thumbnailUrl: _episode?.thumbnailUrl ?? '',
      isLoading: _isLoading,
      hasError: _hasError,
      errorWidget: _buildErrorState(),
      completionOverlay: _isCompleted ? _buildCompletionOverlay() : null,
      controlsOverlay: _controller != null
          ? PlayerControlsOverlay(
              controller: _controller!,
              title: _episode?.title ?? 'Video Player',
              showControls: _showControls,
              isFullscreen: _isFullscreen,
              onToggleControls: _toggleControls,
              onTogglePlayPause: _togglePlayPause,
              onSeekForward: _seekForward,
              onSeekBackward: _seekBackward,
              onToggleFullscreen: _toggleFullscreen,
              onBack: () {
                _saveProgress();
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }

  Widget _buildBottomSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignTokens.backgroundTop,
            DesignTokens.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLarge, vertical: DesignTokens.spaceLarge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_episode != null)
                  EpisodeInfoSection(
                    episode: _episode!,
                    duration: _controller?.value.isInitialized == true
                        ? _controller!.value.duration
                        : null,
                  ),
                const SizedBox(height: DesignTokens.spaceXLarge),
                // Other episodes
                if (_allEpisodes.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Episodes',
                        style: DesignTokens.sectionHeadingStyle,
                      ),
                      const SizedBox(width: DesignTokens.spaceSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceGlass,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_allEpisodes.length}',
                          style: DesignTokens.bodyStyle.copyWith(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 500.ms),
                  const SizedBox(height: DesignTokens.spaceMedium),
                  ..._allEpisodes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ep = entry.value;
                    return EpisodeTile(
                      episode: ep,
                      isActive: ep.id == _episode?.id,
                      onTap: () => _switchEpisode(ep),
                    ).animate().fade(delay: Duration(milliseconds: 600 + (index * 100))).slideY(begin: 0.2, end: 0, duration: 400.ms);
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    final currentIndex = _allEpisodes.indexWhere((ep) => ep.id == _episode?.id);
    final isLastEpisode = currentIndex == -1 || currentIndex == _allEpisodes.length - 1;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastEpisode ? 'Story Completed' : 'Episode Completed',
              style: DesignTokens.titleStyle.copyWith(fontSize: 24),
            ).animate().scale(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLastEpisode)
                  ElevatedButton.icon(
                    onPressed: () => _switchEpisode(_allEpisodes[currentIndex + 1]),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Next Episode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
                    ),
                  ),
                if (isLastEpisode)
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller?.seekTo(Duration.zero);
                      _controller?.play();
                      setState(() {
                        _isCompleted = false;
                      });
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Watch Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
                    ),
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _saveProgress();
                    if (_isFullscreen) _toggleFullscreen();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Story'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSmall)),
                  ),
                ),
              ],
            ).animate().fade(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DesignTokens.primaryAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: DesignTokens.bodyStyle.copyWith(color: DesignTokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadEpisode,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
