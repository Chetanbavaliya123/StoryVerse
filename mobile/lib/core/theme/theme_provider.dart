import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/theme/app_theme.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class AppThemeNotifier extends Notifier<ThemeData> {
  @override
  ThemeData build() {
    final profile = ref.watch(currentUserProfileProvider).value;
    final themeName = (profile?.preferences['theme'] as String?) ?? 'OLED Pure Black';
    return AppTheme.getThemeByName(themeName);
  }

  Future<void> setTheme(String themeName) async {
    state = AppTheme.getThemeByName(themeName);
    final repo = ref.read(userRepositoryProvider);
    await repo.updateSinglePreference('theme', themeName);
  }
}

final appThemeProvider = NotifierProvider<AppThemeNotifier, ThemeData>(() {
  return AppThemeNotifier();
});
