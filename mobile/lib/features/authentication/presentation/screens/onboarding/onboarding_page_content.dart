import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Animated onboarding text content: title with word-by-word stagger reveal,
/// ShaderMask highlight on key words, and subtitle fade-in.
class OnboardingPageContent extends StatefulWidget {
  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.highlightWords,
    required this.isVisible,
    this.reduceMotion = false,
  });

  final String title;
  final String subtitle;
  /// Words in the title to highlight with red gradient
  final List<String> highlightWords;
  final bool isVisible;
  final bool reduceMotion;

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = widget.title.split(' ');
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 350 + (_words.length * 60) + 400,
      ),
    );
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
    if (widget.title != oldWidget.title) {
      _words = widget.title.split(' ');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isHighlightWord(String word) {
    final clean = word.replaceAll(RegExp(r'[,.\-!?]'), '').toLowerCase();
    return widget.highlightWords
        .any((hw) => hw.toLowerCase() == clean);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return _buildStatic();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word-by-word title reveal
            Wrap(
              children: List.generate(_words.length, (i) {
                final wordStart = (i * 60) / _controller.duration!.inMilliseconds;
                final wordEnd = wordStart + (350 / _controller.duration!.inMilliseconds);
                final clampedEnd = wordEnd.clamp(0.0, 1.0);

                final progress = Interval(
                  wordStart.clamp(0.0, 1.0),
                  clampedEnd,
                  curve: OBTokens.entryDefault,
                );

                final value = progress.transform(_controller.value);
                final isHighlight = _isHighlightWord(_words[i]);

                Widget wordWidget = Text(
                  '${_words[i]} ',
                  style: OBTokens.titleStyle,
                );

                if (isHighlight) {
                  wordWidget = ShaderMask(
                    shaderCallback: (bounds) =>
                        OBTokens.redTextGradient.createShader(bounds),
                    child: Text(
                      '${_words[i]} ',
                      style: OBTokens.titleStyle.copyWith(
                        color: OBTokens.textPrimary,
                      ),
                    ),
                  );
                }

                return Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: wordWidget,
                  ),
                );
              }),
            ),

            const SizedBox(height: OBTokens.spaceSM),

            // Subtitle fade
            Builder(
              builder: (context) {
                final subtitleStart = (_words.length * 60 + 100) /
                    _controller.duration!.inMilliseconds;
                final subtitleEnd = subtitleStart +
                    (400 / _controller.duration!.inMilliseconds);
                final progress = Interval(
                  subtitleStart.clamp(0.0, 1.0),
                  subtitleEnd.clamp(0.0, 1.0),
                  curve: OBTokens.entryDefault,
                );
                final value = progress.transform(_controller.value);

                return Opacity(
                  opacity: value,
                  child: Text(
                    widget.subtitle,
                    style: OBTokens.subtitleStyle,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          children: _words.map((word) {
            final isHighlight = _isHighlightWord(word);
            if (isHighlight) {
              return ShaderMask(
                shaderCallback: (bounds) =>
                    OBTokens.redTextGradient.createShader(bounds),
                child: Text(
                  '$word ',
                  style: OBTokens.titleStyle.copyWith(
                    color: OBTokens.textPrimary,
                  ),
                ),
              );
            }
            return Text('$word ', style: OBTokens.titleStyle);
          }).toList(),
        ),
        const SizedBox(height: OBTokens.spaceSM),
        Text(widget.subtitle, style: OBTokens.subtitleStyle),
      ],
    );
  }
}
