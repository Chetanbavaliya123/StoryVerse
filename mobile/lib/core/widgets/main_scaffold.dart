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
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnimatedNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: navigationShell.currentIndex == 0,
                onTap: () => _goBranch(0),
              ),
              _AnimatedNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isSelected: navigationShell.currentIndex == 1,
                onTap: () => _goBranch(1),
              ),
              _AnimatedNavItem(
                icon: Icons.bookmark_rounded,
                label: 'Library',
                isSelected: navigationShell.currentIndex == 2,
                onTap: () => _goBranch(2),
              ),
              _AnimatedNavItem(
                isProfile: true,
                label: 'Profile',
                isSelected: navigationShell.currentIndex == 3,
                onTap: () => _goBranch(3),
              ),
            ],
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

class _AnimatedNavItem extends StatelessWidget {
  final IconData? icon;
  final bool isProfile;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    this.icon,
    this.isProfile = false,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: EdgeInsets.only(left: isSelected ? 8 : 0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : Colors.transparent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (isProfile) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primaryAccent, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: const NetworkImageWithFallback(
          imageUrl:
              'https://lh3.googleusercontent.com/aida/AEtjO1UHL1gIxZsXiKRQwhsoOpCyWPi8kbatjf8cA-Y9MxsFuTcBsA5wf2c4tl1c12IF6cVhnYu8dMJ2s_T9DC2x8ofc1PRLyD_ROBA0IWU0spHoO1XmBUDULngA6Se9La5tR7KXIfBfMv-EvK6z1kjPcMQCcbBQLObDgM097TIeIBE9sovWJ4PbhpclONwiX5N56Bxj1LgW-splkzUULgDjYAiX8J5-GotlgnGn4SNofmk_A2VcJE0Eq_IFJMxr',
        ),
      );
    }

    return Icon(
      icon,
      color: isSelected ? AppColors.primaryAccent : AppColors.secondaryText,
      size: 24,
    );
  }
}
