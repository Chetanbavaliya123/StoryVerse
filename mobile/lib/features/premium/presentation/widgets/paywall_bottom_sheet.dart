import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/premium/presentation/providers/unlocked_episodes_provider.dart';

class PaywallBottomSheet extends ConsumerStatefulWidget {
  final StoryModel? story;
  final EpisodeModel? episode;
  final VoidCallback? onUnlocked;

  const PaywallBottomSheet({
    super.key,
    this.story,
    this.episode,
    this.onUnlocked,
  });

  static Future<void> show({
    required BuildContext context,
    StoryModel? story,
    EpisodeModel? episode,
    VoidCallback? onUnlocked,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => PaywallBottomSheet(
        story: story,
        episode: episode,
        onUnlocked: onUnlocked,
      ),
    );
  }

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet> {
  bool _isWatchingAd = false;
  int _adCountdown = 5;
  Timer? _adTimer;

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  void _startWatchAd() {
    setState(() {
      _isWatchingAd = true;
      _adCountdown = 5;
    });

    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_adCountdown > 1) {
        setState(() => _adCountdown--);
      } else {
        timer.cancel();
        if (widget.episode != null) {
          ref
              .read(unlockedEpisodesProvider.notifier)
              .unlockEpisode(widget.episode!.id);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.episode != null
                    ? 'Episode ${widget.episode!.episodeNumber} unlocked for this session!'
                    : 'Reward granted! Thank you for watching.',
              ),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onUnlocked?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF14070A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppColors.primaryAccent.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: _isWatchingAd ? _buildAdProgress() : _buildPaywallContent(),
        ),
      ),
    );
  }

  Widget _buildAdProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Icon(
          Icons.play_circle_outline_rounded,
          size: 54,
          color: AppColors.primaryAccent,
        ),
        const SizedBox(height: 16),
        const Text(
          'Sponsored Sponsor Ad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.episode != null
              ? 'Unlocking Episode ${widget.episode!.episodeNumber} in $_adCountdown seconds...'
              : 'Unlocking access in $_adCountdown seconds...',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (5 - _adCountdown) / 5.0,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryAccent,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            _adTimer?.cancel();
            setState(() => _isWatchingAd = false);
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildPaywallContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFFB800),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.episode != null
                        ? 'VIP Episode Locked'
                        : 'VIP Access Required',
                    style: const TextStyle(
                      color: Color(0xFFFFB800),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.episode != null
                        ? 'Unlock Episode ${widget.episode!.episodeNumber}'
                        : 'Unlock Unlimited Stories & AI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        Text(
          'Episodes 1-3 are complimentary. Unlock Episode 4+ and the entire series with StoryVerse VIP or watch a quick sponsor message.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 20),

        // Benefits
        _buildBenefitRow(Icons.all_inclusive, 'Unlimited access to all series episodes'),
        _buildBenefitRow(Icons.hd_outlined, 'Ad-free 1080p and 4K master playback'),
        _buildBenefitRow(Icons.download_for_offline_outlined, 'Download episodes for offline viewing'),
        _buildBenefitRow(Icons.auto_awesome, 'Priority AI story generation & custom scripts'),

        const SizedBox(height: 24),

        // Primary Upgrade Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium, size: 20),
                SizedBox(width: 8),
                Text(
                  'Upgrade to VIP Membership',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary "Watch Ad" Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _startWatchAd,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.slow_motion_video_rounded, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  widget.episode != null
                      ? 'Watch Ad to Unlock Ep ${widget.episode!.episodeNumber}'
                      : 'Watch Ad to Unlock Access',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFFB800)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
