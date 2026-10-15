import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/theme/app_theme.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class AppThemeNameNotifier extends Notifier<String> {
  static String? _activeTheme;

  @override
  String build() {
    if (_activeTheme != null) {
      return _activeTheme!;
    }
    final profile = ref.watch(currentUserProfileProvider).value;
    return (profile?.preferences['theme'] as String?) ?? 'OLED Pure Black';
  }

  void setThemeName(String name) {
    _activeTheme = name;
    state = name;
  }
}

final appThemeNameProvider =
    NotifierProvider<AppThemeNameNotifier, String>(AppThemeNameNotifier.new);

class AppThemeNotifier extends Notifier<ThemeData> {
  @override
  ThemeData build() {
    final themeName = ref.watch(appThemeNameProvider);
    return AppTheme.getThemeByName(themeName);
  }

  Future<void> setTheme(String themeName) async {
    ref.read(appThemeNameProvider.notifier).setThemeName(themeName);
    state = AppTheme.getThemeByName(themeName);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateSinglePreference('theme', themeName);
    } catch (_) {}
  }
}

final appThemeProvider = NotifierProvider<AppThemeNotifier, ThemeData>(() {
  return AppThemeNotifier();
});
