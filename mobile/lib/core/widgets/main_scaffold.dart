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
      extendBody: false, // Solid navbar should not overlap body content
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        bottom: true,
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050505), // Matches the dark background
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NavItem(
                  activeIcon: Icons.home,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
                isSelected: navigationShell.currentIndex == 0,
                onTap: () => _goBranch(0),
              ),
              _NavItem(
                activeIcon: Icons.play_circle,
                inactiveIcon: Icons.play_circle_outline,
                label: 'Shorts',
                isSelected: navigationShell.currentIndex == 1,
                onTap: () => _goBranch(1),
              ),
              _NavItem(
                activeIcon: Icons.diamond,
                inactiveIcon: Icons.diamond_outlined,
                label: 'Premium',
                isSelected: navigationShell.currentIndex == 2,
                onTap: () => _goBranch(2),
              ),
              _NavItem(
                activeIcon: Icons.bookmark,
                inactiveIcon: Icons.bookmark_outline,
                label: 'My List',
                isSelected: navigationShell.currentIndex == 3,
                onTap: () => _goBranch(3),
              ),
              _NavItem(
                activeIcon: Icons.sentiment_satisfied_alt,
                inactiveIcon: Icons.sentiment_satisfied_alt,
                isProfile: true,
                label: 'Profile',
                isSelected: navigationShell.currentIndex == 4,
                onTap: () => _goBranch(4),
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
}

class _NavItem extends StatelessWidget {
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final bool isProfile;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    this.activeIcon,
    this.inactiveIcon,
    this.isProfile = false,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : const Color(0xFFAAAAAA);
    final iconData = isSelected ? activeIcon : inactiveIcon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(iconData, color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData? iconData, Color color) {
    return Icon(
      iconData,
      color: color,
      size: 26,
    );
  }
}
