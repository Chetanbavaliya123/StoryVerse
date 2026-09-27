import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/features/story/data/story_repository.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';

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
    _historyRepo = ref.read(watchHistoryRepositoryProvider);
    _loadEpisode();
  }

  Future<void> _loadEpisode() async {
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final repo = ref.read(storyRepositoryProvider);
      final episode = await repo.getEpisode(widget.storyId, widget.episodeId);
      final allEpisodes = await repo.getEpisodes(widget.storyId);
      allEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      if (episode == null) {
        setState(() { _hasError = true; _errorMessage = 'Episode not found'; _isLoading = false; });
        return;
      }

      if (episode.videoUrl.trim().isEmpty) {
        setState(() { _hasError = true; _errorMessage = 'Video unavailable for this episode.'; _isLoading = false; });
        return;
      }

      _episode = episode;
      _allEpisodes = allEpisodes;

      // Restore previous position
      final history = await _historyRepo.getEpisodeProgress(widget.storyId, widget.episodeId);

      await _initializePlayer(episode.videoUrl, history?.progressSeconds);
    } catch (e) {
      setState(() { _hasError = true; _errorMessage = 'Failed to load: $e'; _isLoading = false; });
    }
  }

  Future<void> _initializePlayer(String videoUrl, int? startPosition) async {
    _controller?.dispose();

    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      if (mounted) {
        setState(() { 
          _hasError = true; 
          _isLoading = false;
          _errorMessage = 'This episode needs a direct video source.\nYouTube URLs are not supported as in-app video sources.';
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
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      print('PLAYER ERROR\\nEpisode: \${widget.episodeId}\\nURL: $videoUrl\\nError: $e');
      if (mounted) {
        setState(() { 
          _hasError = true; 
          _isLoading = false;
          if (e is TimeoutException) {
            _errorMessage = 'Video is taking too long to load.';
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

    if (controller.value.position >= controller.value.duration - const Duration(seconds: 1) && controller.value.duration > Duration.zero) {
      if (!_isCompleted) {
        _saveProgress();
        setState(() {
          _isCompleted = true;
          _showControls = false;
        });
      }
    } else if (_isCompleted && controller.value.position < controller.value.duration - const Duration(seconds: 2)) {
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
        setState(() { _showControls = false; });
      }
    });
  }

  void _toggleControls() {
    setState(() { _showControls = !_showControls; });
    if (_showControls) _startHideControlsTimer();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      _saveProgress();
      setState(() { _showControls = true; });
    } else {
      // If at end, replay from start
      if (controller.value.position >= controller.value.duration - const Duration(seconds: 1)) {
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
    controller.seekTo(newPos > controller.value.duration ? controller.value.duration : newPos);
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
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() { _isFullscreen = !_isFullscreen; });
  }

  void _switchEpisode(EpisodeModel episode) async {
    _saveProgress();
    _controller?.pause();

    setState(() { _isLoading = true; _hasError = false; _episode = episode; _isCompleted = false; });

    final history = await _historyRepo.getEpisodeProgress(widget.storyId, episode.id);
    await _initializePlayer(episode.videoUrl, history?.progressSeconds);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area
            if (_isFullscreen)
              Expanded(child: _buildVideoArea())
            else
              _buildVideoArea(),
              
            // Episode Info & List (hidden in fullscreen)
            if (!_isFullscreen)
              Expanded(
                child: _buildBottomSection(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
                // Buffering indicator
                if (controller.value.isBuffering && !_isCompleted)
                  const CircularProgressIndicator(color: AppColors.primaryAccent),
                // Completion overlay
                if (_isCompleted) _buildCompletionOverlay()
                // Controls overlay
                else if (_showControls) _buildControlsOverlay(controller),
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
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLastEpisode)
                  ElevatedButton.icon(
                    onPressed: () => _switchEpisode(_allEpisodes[currentIndex + 1]),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Next Episode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                if (isLastEpisode)
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller?.seekTo(Duration.zero);
                      _controller?.play();
                      setState(() { _isCompleted = false; });
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Watch Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _saveProgress();
                    if (_isFullscreen) _toggleFullscreen();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Story'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(VideoPlayerController controller) {
    final position = controller.value.position;
    final duration = controller.value.duration;
    final isPlaying = controller.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  onPressed: () {
                    _saveProgress();
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Text(
                    _episode?.title ?? 'Video Player',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 24),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),
          // Center controls
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.replay_10, _seekBackward, size: 36),
              const SizedBox(width: 32),
              _controlButton(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                _togglePlayPause,
                size: 56,
              ),
              const SizedBox(width: 32),
              _controlButton(Icons.forward_10, _seekForward, size: 36),
            ],
          ),
          const Spacer(),
          // Bottom progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(_formatDuration(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.primaryAccent,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble())
                          : 0,
                      max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                      onChanged: (value) {
                        controller.seekTo(Duration(milliseconds: value.toInt()));
                        _startHideControlsTimer();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 250,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryAccent),
            SizedBox(height: 16),
            Text('Loading video...', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 250,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primaryAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadEpisode,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: AppColors.primaryBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Episode title
                if (_episode != null) ...[
                  Text(
                    'Episode ${_episode!.episodeNumber}',
                    style: const TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _episode!.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if ((_controller?.value.isInitialized ?? false) && _controller!.value.duration.inSeconds > 0)
                    Text(
                      _formatDuration(_controller!.value.duration),
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.w500),
                    )
                  else if (_episode!.duration > 0)
                    Text(
                      _episode!.formattedDuration,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.w500),
                    )
                  else
                    const Text(
                      'Duration unavailable',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _episode!.description,
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 15, height: 1.6),
                  ),
                ],
                const SizedBox(height: 40),
                // Other episodes
                if (_allEpisodes.isNotEmpty) ...[
                  const Text(
                    'Episodes',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._allEpisodes
                      .map((ep) => _buildEpisodeItem(ep)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(EpisodeModel episode) {
    final isActive = episode.id == _episode?.id;
    return InkWell(
      onTap: isActive ? null : () => _switchEpisode(episode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryAccent.withValues(alpha: 0.1) : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primaryAccent : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(8),
                image: episode.thumbnailUrl.isNotEmpty 
                    ? DecorationImage(image: NetworkImage(episode.thumbnailUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: episode.thumbnailUrl.isEmpty 
                  ? const Center(child: Icon(Icons.image, color: AppColors.mutedText))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Episode ${episode.episodeNumber}',
                    style: TextStyle(
                      color: isActive ? AppColors.primaryAccent : AppColors.secondaryText, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70, 
                      fontSize: 15, 
                      fontWeight: FontWeight.w600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (episode.duration > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      episode.formattedDuration,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.pause_circle_filled, color: AppColors.primaryAccent, size: 28)
            else
              const Icon(Icons.play_circle_outline, color: AppColors.mutedText, size: 28),
          ],
        ),
      ),
    );
  }
}
