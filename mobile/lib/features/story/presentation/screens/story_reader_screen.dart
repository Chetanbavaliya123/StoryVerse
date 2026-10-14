import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/design_system/app_bottom_sheet.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/features/story/data/watch_history_repository.dart';


enum ReaderThemeMode {
  dark,
  black,
  sepia,
  light,
}

class StoryReaderScreen extends ConsumerStatefulWidget {
  final String storyId;
  final int initialChapterIndex;

  const StoryReaderScreen({
    super.key,
    required this.storyId,
    this.initialChapterIndex = 0,
  });

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  late final ScrollController _scrollController;
  int _currentChapterIndex = 0;
  double _readingProgress = 0.0;
  Timer? _saveProgressDebounce;

  // Typography Settings
  double _fontSize = 18.0;
  final double _lineHeight = 1.7;
  bool _isSerif = true;
  ReaderThemeMode _themeMode = ReaderThemeMode.dark;

  // Read Aloud / TTS State
  bool _isReadAloudActive = false;
  bool _isSpeechPlaying = false;
  int _activeParagraphIndex = 0;
  double _speechSpeed = 1.0;
  Timer? _speechTimer;

  final List<GlobalKey> _paragraphKeys = [];

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _saveProgressDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll <= 0) return;

    final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    if ((progress - _readingProgress).abs() > 0.01) {
      setState(() {
        _readingProgress = progress;
      });
      _debounceSaveProgress(progress);
    }
  }

  void _debounceSaveProgress(double progress) {
    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(seconds: 2), () {
      final repo = ref.read(watchHistoryRepositoryProvider);
      repo.updateProgress(
        storyId: widget.storyId,
        episodeId: 'chapter_$_currentChapterIndex',
        progressSeconds: (progress * 100).toInt(),
        totalDuration: 100,
      );
    });
  }

  Color get _backgroundColor {
    switch (_themeMode) {
      case ReaderThemeMode.dark:
        return const Color(0xFF141418);
      case ReaderThemeMode.black:
        return Colors.black;
      case ReaderThemeMode.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderThemeMode.light:
        return const Color(0xFFF9F9FB);
    }
  }

  Color get _textColor {
    switch (_themeMode) {
      case ReaderThemeMode.dark:
        return const Color(0xFFE4E4EB);
      case ReaderThemeMode.black:
        return const Color(0xFFECECEC);
      case ReaderThemeMode.sepia:
        return const Color(0xFF382E25);
      case ReaderThemeMode.light:
        return const Color(0xFF1A1A1E);
    }
  }

  Color get _surfaceColor {
    switch (_themeMode) {
      case ReaderThemeMode.dark:
        return const Color(0xFF1E1E24);
      case ReaderThemeMode.black:
        return const Color(0xFF181818);
      case ReaderThemeMode.sepia:
        return const Color(0xFFEFE2C5);
      case ReaderThemeMode.light:
        return const Color(0xFFEEEEF2);
    }
  }

  Color get _accentColor {
    switch (_themeMode) {
      case ReaderThemeMode.sepia:
        return const Color(0xFF8B4513);
      default:
        return AppColors.primaryAccent;
    }
  }

  TextStyle get _contentTextStyle {
    final baseStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: _textColor,
      letterSpacing: 0.2,
    );
    if (_isSerif) {
      return GoogleFonts.lora(textStyle: baseStyle);
    } else {
      return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  void _toggleSpeech() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSpeechPlaying = !_isSpeechPlaying;
      if (!_isReadAloudActive) _isReadAloudActive = true;
    });

    if (_isSpeechPlaying) {
      _startSpeechLoop();
    } else {
      _speechTimer?.cancel();
    }
  }

  void _startSpeechLoop() {
    _speechTimer?.cancel();
    // Simulate natural read pacing per paragraph: ~150-200 words/min
    final baseDurationMs = (4000 / _speechSpeed).round();

    _speechTimer = Timer.periodic(Duration(milliseconds: baseDurationMs), (timer) {
      if (!mounted || !_isSpeechPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_activeParagraphIndex < _paragraphKeys.length - 1) {
          _activeParagraphIndex++;
          _scrollToActiveParagraph();
          HapticFeedback.selectionClick();
        } else {
          // Finished chapter speech
          _isSpeechPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _scrollToActiveParagraph() {
    if (_activeParagraphIndex < _paragraphKeys.length) {
      final key = _paragraphKeys[_activeParagraphIndex];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.3,
        );
      }
    }
  }

  void _changeSpeed(double speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _speechSpeed = speed;
    });
    if (_isSpeechPlaying) {
      _startSpeechLoop();
    }
  }

  void _openTypographySheet() {
    HapticFeedback.lightImpact();
    AppBottomSheet.show(
      context: context,
      title: 'Reading Settings',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Mode Selector
              const Text(
                'THEME',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _themeCard(
                    title: 'Dark',
                    bg: const Color(0xFF141418),
                    textColor: Colors.white,
                    isSelected: _themeMode == ReaderThemeMode.dark,
                    onTap: () {
                      setState(() => _themeMode = ReaderThemeMode.dark);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  _themeCard(
                    title: 'Black',
                    bg: Colors.black,
                    textColor: Colors.white,
                    isSelected: _themeMode == ReaderThemeMode.black,
                    onTap: () {
                      setState(() => _themeMode = ReaderThemeMode.black);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  _themeCard(
                    title: 'Sepia',
                    bg: const Color(0xFFFBF0D9),
                    textColor: const Color(0xFF382E25),
                    isSelected: _themeMode == ReaderThemeMode.sepia,
                    onTap: () {
                      setState(() => _themeMode = ReaderThemeMode.sepia);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  _themeCard(
                    title: 'Light',
                    bg: Colors.white,
                    textColor: Colors.black,
                    isSelected: _themeMode == ReaderThemeMode.light,
                    onTap: () {
                      setState(() => _themeMode = ReaderThemeMode.light);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FONT SIZE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${_fontSize.round()}pt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 14.0,
                max: 26.0,
                divisions: 6,
                activeColor: AppColors.primaryAccent,
                inactiveColor: Colors.white24,
                onChanged: (val) {
                  setState(() => _fontSize = val);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 16),

              // Font Style (Serif vs Sans)
              const Text(
                'TYPEFACE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isSerif = true);
                        setSheetState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isSerif
                            ? AppColors.primaryAccent.withValues(alpha: 0.2)
                            : Colors.transparent,
                        side: BorderSide(
                          color: _isSerif
                              ? AppColors.primaryAccent
                              : Colors.white24,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Serif (Lora)',
                        style: GoogleFonts.lora(
                          color: _isSerif ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isSerif = false);
                        setSheetState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_isSerif
                            ? AppColors.primaryAccent.withValues(alpha: 0.2)
                            : Colors.transparent,
                        side: BorderSide(
                          color: !_isSerif
                              ? AppColors.primaryAccent
                              : Colors.white24,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Sans (Inter)',
                        style: GoogleFonts.inter(
                          color: !_isSerif ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _themeCard({
    required String title,
    required Color bg,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryAccent : Colors.white24,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _openChaptersSheet(StoryModel story, List<EpisodeModel> episodes) {
    HapticFeedback.lightImpact();

    AppBottomSheet.show(
      context: context,
      title: 'Chapters & Episodes',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: episodes.isNotEmpty ? episodes.length : 1,
        separatorBuilder: (_, _) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          if (episodes.isEmpty) {
            return const ListTile(
              title: Text('Chapter 1', style: TextStyle(color: Colors.white)),
              subtitle: Text('Full Story Script', style: TextStyle(color: Colors.white60)),
            );
          }

          final ep = episodes[index];
          final isCurrent = index == _currentChapterIndex;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: isCurrent
                  ? AppColors.primaryAccent
                  : const Color(0xFF22222A),
              child: Icon(
                isCurrent ? Icons.menu_book_rounded : Icons.check_circle_outline,
                size: 18,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Chapter ${ep.episodeNumber}: ${ep.title.isNotEmpty ? ep.title : "Episode ${ep.episodeNumber}"}',
              style: TextStyle(
                color: isCurrent ? AppColors.primaryAccent : Colors.white,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              ep.duration > 0 ? '${(ep.duration / 60).ceil()} min read' : 'Available',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            trailing: isCurrent
                ? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryAccent, size: 14)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              _loadChapter(index);
            },
          );
        },
      ),
    );
  }

  void _loadChapter(int index) {
    setState(() {
      _currentChapterIndex = index;
      _activeParagraphIndex = 0;
      _readingProgress = 0.0;
      _isSpeechPlaying = false;
      _speechTimer?.cancel();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _goToNextChapter(StoryModel story, List<EpisodeModel> episodes) {
    if (_currentChapterIndex < episodes.length - 1) {
      _loadChapter(_currentChapterIndex + 1);
    }
  }

  void _goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      _loadChapter(_currentChapterIndex - 1);
    }
  }

  List<String> _extractChapterParagraphs(StoryModel story, List<EpisodeModel> episodes) {
    if (episodes.isNotEmpty && _currentChapterIndex < episodes.length) {
      final ep = episodes[_currentChapterIndex];
      if (ep.description.isNotEmpty && ep.description.length > 50) {
        final split = ep.description.split(RegExp(r'\n+'));
        if (split.length > 1) return split;
      }
    }

    final fullText = story.fullDescription ?? story.description;
    final paragraphs = fullText.split(RegExp(r'\n+'));
    if (paragraphs.length >= 2) return paragraphs;

    // Generated narrative structure for immersive reading
    return [
      story.description,
      'The neon lights of the high-rise metropolis flickered against the damp pavement as shadows shifted silently between alleyways.',
      'Every choice carries a consequence, yet in this world of fractured allegiances, the truth was the most expensive commodity of all.',
      '"You shouldn\'t have come here tonight," a low voice warned from the darkness, footsteps echoing rhythmically on concrete.',
      'Turning around slowly, the reality of the situation became undeniable. There was no going back to how things used to be.',
      'With pulse racing and instincts primed, the next chapter in this journey begins right now.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDetailsProvider(widget.storyId));
    final episodesAsync = ref.watch(storyEpisodesProvider(widget.storyId));

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: storyAsync.when(
          data: (story) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story?.title ?? 'Story Reading',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Chapter ${_currentChapterIndex + 1} • ${( _readingProgress * 100).toInt()}%',
                style: TextStyle(
                  color: _textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading...', style: TextStyle(fontSize: 14)),
          error: (_, _) => const Text('Reader', style: TextStyle(fontSize: 14)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isReadAloudActive ? Icons.headphones : Icons.headphones_outlined,
              color: _isReadAloudActive ? _accentColor : _textColor,
            ),
            tooltip: 'Read Aloud (TTS)',
            onPressed: () {
              setState(() {
                _isReadAloudActive = !_isReadAloudActive;
                if (!_isReadAloudActive) {
                  _isSpeechPlaying = false;
                  _speechTimer?.cancel();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.text_fields_rounded, color: _textColor),
            tooltip: 'Typography & Theme',
            onPressed: _openTypographySheet,
          ),
          storyAsync.when(
            data: (story) {
              if (story == null) return const SizedBox.shrink();
              final episodes = episodesAsync.asData?.value ?? [];
              return IconButton(
                icon: Icon(Icons.format_list_bulleted_rounded, color: _textColor),
                tooltip: 'Table of Contents',
                onPressed: () => _openChaptersSheet(story, episodes),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: _readingProgress,
            backgroundColor: _surfaceColor,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 2.5,
          ),
        ),
      ),
      body: storyAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
        error: (e, _) => Center(
          child: Text('Error loading story: $e', style: TextStyle(color: _textColor)),
        ),
        data: (story) {
          if (story == null) {
            return Center(
              child: Text('Story not found', style: TextStyle(color: _textColor)),
            );
          }

          final episodes = episodesAsync.asData?.value ?? [];
          final paragraphs = _extractChapterParagraphs(story, episodes);

          // Re-populate global keys for scroll alignment
          if (_paragraphKeys.length != paragraphs.length) {
            _paragraphKeys.clear();
            for (var i = 0; i < paragraphs.length; i++) {
              _paragraphKeys.add(GlobalKey());
            }
          }

          final currentEpTitle = (episodes.isNotEmpty && _currentChapterIndex < episodes.length)
              ? episodes[_currentChapterIndex].title
              : 'Chapter ${_currentChapterIndex + 1}';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter Header
                      Container(
                        padding: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _textColor.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title.toUpperCase(),
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentEpTitle,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 15, color: _textColor.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  story.author,
                                  style: TextStyle(
                                    color: _textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.menu_book_outlined, size: 15, color: _textColor.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  'Chapter ${_currentChapterIndex + 1} of ${episodes.isNotEmpty ? episodes.length : 1}',
                                  style: TextStyle(
                                    color: _textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Paragraphs with active Read Aloud highlight
                      for (int i = 0; i < paragraphs.length; i++) ...[
                        _buildParagraphItem(
                          key: _paragraphKeys[i],
                          text: paragraphs[i],
                          isHighlighted: _isReadAloudActive && _activeParagraphIndex == i,
                          onTap: () {
                            if (_isReadAloudActive) {
                              setState(() {
                                _activeParagraphIndex = i;
                                _isSpeechPlaying = true;
                              });
                              _startSpeechLoop();
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 40),

                      // Chapter Navigation Footer
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: _textColor.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentChapterIndex > 0)
                              OutlinedButton.icon(
                                onPressed: _goToPreviousChapter,
                                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                                label: const Text('Previous'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _textColor,
                                  side: BorderSide(color: _textColor.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),

                            if (_currentChapterIndex < episodes.length - 1)
                              ElevatedButton.icon(
                                onPressed: () => _goToNextChapter(story, episodes),
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                label: const Text('Next Chapter'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              )
                            else
                              Text(
                                'You reached the end of this story! 🎉',
                                style: TextStyle(
                                  color: _textColor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Read Aloud / TTS Playback Bar
              if (_isReadAloudActive)
                _buildReadAloudControlBar(paragraphs.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParagraphItem({
    required Key key,
    required String text,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: isHighlighted
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isHighlighted ? _accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isHighlighted
              ? Border(left: BorderSide(color: _accentColor, width: 4))
              : null,
        ),
        child: Text(
          text,
          style: _contentTextStyle.copyWith(
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReadAloudControlBar(int totalParagraphs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Play / Pause Button
            IconButton.filled(
              onPressed: _toggleSpeech,
              icon: Icon(
                _isSpeechPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _accentColor,
              ),
            ),
            const SizedBox(width: 12),

            // Progress text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSpeechPlaying ? 'Reading paragraph ${_activeParagraphIndex + 1} of $totalParagraphs' : 'Read Aloud Paused',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalParagraphs > 0 ? (_activeParagraphIndex + 1) / totalParagraphs : 0.0,
                      backgroundColor: _textColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Speed Selector Button
            PopupMenuButton<double>(
              initialValue: _speechSpeed,
              tooltip: 'Playback Speed',
              onSelected: _changeSpeed,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 0.8, child: Text('0.8x')),
                const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _textColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${_speechSpeed}x',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Close Read Aloud
            IconButton(
              icon: Icon(Icons.close, color: _textColor.withValues(alpha: 0.6), size: 20),
              onPressed: () {
                setState(() {
                  _isReadAloudActive = false;
                  _isSpeechPlaying = false;
                  _speechTimer?.cancel();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
