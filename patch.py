import re

with open(r'd:\project\StoryVerse\mobile\lib\features\video_player\presentation\screens\video_player_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add import
text = text.replace(\"import 'package:video_player/video_player.dart';\", \"import 'package:video_player/video_player.dart';\nimport 'package:youtube_player_flutter/youtube_player_flutter.dart';\")

# Add YT variables
text = text.replace(\"VideoPlayerController? _controller;\", \"VideoPlayerController? _controller;\n  YoutubePlayerController? _ytController;\n  bool _isYoutube = false;\")

# Update initialize
init_target = \"\"\"  Future<void> _initializePlayer(String videoUrl, int? startPosition) async {
    _controller?.dispose();

    print('PLAYER INIT\\\\nEpisode ID: \\\\\\\\nVideo URL: ');

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));\"\"\"
    
init_replace = \"\"\"  Future<void> _initializePlayer(String videoUrl, int? startPosition) async {
    _controller?.dispose();
    _ytController?.dispose();
    _isYoutube = false;

    print('PLAYER INIT\\\\nEpisode ID: \\\\\\\\nVideo URL: ');

    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      _isYoutube = true;
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId == null) throw Exception("Invalid YouTube URL");
      
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          startAt: startPosition ?? 0,
        ),
      );
      
      _ytController!.addListener(_onPlayerStateChange);
      _startProgressSaveTimer();
      
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));\"\"\"
text = text.replace(init_target, init_replace)

# Update _onPlayerStateChange
state_change_target = \"\"\"  void _onPlayerStateChange() {
    if (!mounted) return;
    setState(() {});

    final controller = _controller;
    if (controller == null) return;\"\"\"

state_change_replace = \"\"\"  void _onPlayerStateChange() {
    if (!mounted) return;
    setState(() {});
    
    if (_isYoutube && _ytController != null) {
      final position = _ytController!.value.position;
      final duration = _ytController!.metadata.duration;
      if (position >= duration - const Duration(seconds: 1) && duration > Duration.zero) {
        if (!_isCompleted) {
          _saveProgress();
          setState(() { _isCompleted = true; });
        }
      } else if (_isCompleted && position < duration - const Duration(seconds: 2)) {
        setState(() { _isCompleted = false; });
      }
      return;
    }

    final controller = _controller;
    if (controller == null) return;\"\"\"
text = text.replace(state_change_target, state_change_replace)

# Update buildVideoArea
build_target = \"\"\"  Widget _buildVideoArea() {
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

    return GestureDetector(\"\"\"
    
build_replace = \"\"\"  Widget _buildVideoArea() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_isYoutube && _ytController != null) {
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: AppColors.primaryAccent,
                handleColor: AppColors.primaryAccent,
              ),
            ),
            if (_isCompleted) _buildCompletionOverlay(),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _buildLoadingState();
    }

    return GestureDetector(\"\"\"
text = text.replace(build_target, build_replace)

# Update dispose
dispose_target = \"\"\"  @override
  void dispose() {
    _saveProgress();
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();\"\"\"

dispose_replace = \"\"\"  @override
  void dispose() {
    _saveProgress();
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    _ytController?.removeListener(_onPlayerStateChange);
    _ytController?.dispose();\"\"\"
text = text.replace(dispose_target, dispose_replace)

# Update _saveProgress
save_target = \"\"\"  void _saveProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position.inSeconds;
    final total = controller.value.duration.inSeconds;\"\"\"
    
save_replace = \"\"\"  void _saveProgress() {
    if (_isYoutube && _ytController != null) {
      final position = _ytController!.value.position.inSeconds;
      final total = _ytController!.metadata.duration.inSeconds;
      if (total <= 0) return;
      ref.read(watchHistoryRepositoryProvider).updateProgress(
        storyId: widget.storyId,
        episodeId: widget.episodeId,
        progressSeconds: position,
        totalDuration: total,
      );
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position.inSeconds;
    final total = controller.value.duration.inSeconds;\"\"\"
text = text.replace(save_target, save_replace)

with open(r'd:\project\StoryVerse\mobile\lib\features\video_player\presentation\screens\video_player_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print('Done!')
