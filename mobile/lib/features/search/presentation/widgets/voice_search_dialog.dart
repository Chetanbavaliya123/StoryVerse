import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/search/presentation/providers/search_provider.dart';

class VoiceSearchDialog extends ConsumerStatefulWidget {
  const VoiceSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceSearchDialog(),
    );
  }

  @override
  ConsumerState<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends ConsumerState<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _currentStatus = 'Listening for stories...';

  final List<String> _suggestions = [
    'Action & Thriller',
    'Romance Specials',
    'Sci-Fi Episodes',
    'Comedy & Drama',
    'Hindi Stories',
    'Trending Shorts',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _submitVoiceQuery(String query) {
    ref.read(searchQueryProvider.notifier).setImmediate(query);
    if (mounted) {
      Navigator.of(context).pop();
      context.push('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Color(0xFF16161A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Voice Search',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentStatus,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Glowing Pulsing Mic
          GestureDetector(
            onTap: () {
              setState(() {
                _currentStatus = 'Listening closely...';
              });
            },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90 * _scaleAnimation.value,
                      height: 90 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryAccent.withValues(
                          alpha: 0.25 / _scaleAnimation.value,
                        ),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF334B), Color(0xFFB71C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Or tap a quick search suggestion:',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                ),
                label: Text(
                  suggestion,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: () => _submitVoiceQuery(suggestion),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
