import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.home_filled,
                  label: 'Home',
                  index: 0,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _goBranch(0),
                ),
                _buildNavItem(
                  icon: Icons.search,
                  label: 'Search',
                  index: 1,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _goBranch(1),
                ),
                _buildNavItem(
                  icon: Icons.video_library_outlined,
                  label: 'Library',
                  index: 2,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _goBranch(2),
                ),
                _buildProfileItem(
                  index: 3,
                  currentIndex: navigationShell.currentIndex,
                  onTap: () => _goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primaryAccent : AppColors.mutedText,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primaryAccent : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: AppColors.primaryAccent, width: 1.5)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: const NetworkImageWithFallback(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida/AEtjO1UHL1gIxZsXiKRQwhsoOpCyWPi8kbatjf8cA-Y9MxsFuTcBsA5wf2c4tl1c12IF6cVhnYu8dMJ2s_T9DC2x8ofc1PRLyD_ROBA0IWU0spHoO1XmBUDULngA6Se9La5tR7KXIfBfMv-EvK6z1kjPcMQCcbBQLObDgM097TIeIBE9sovWJ4PbhpclONwiX5N56Bxj1LgW-splkzUULgDjYAiX8J5-GotlgnGn4SNofmk_A2VcJE0Eq_IFJMxr',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primaryAccent : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
