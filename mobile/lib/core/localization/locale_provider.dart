import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null && profile.preferences.containsKey('language')) {
      final code = profile.preferences['language'] as String? ?? 'en';
      return _mapCodeToLocale(code);
    }
    return const Locale('en');
  }

  static Locale _mapCodeToLocale(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
      case 'hindi':
        return const Locale('hi');
      case 'gu':
      case 'gujarati':
        return const Locale('gu');
      case 'mr':
      case 'marathi':
        return const Locale('mr');
      case 'bn':
      case 'bengali':
        return const Locale('bn');
      case 'en':
      case 'english':
      default:
        return const Locale('en');
    }
  }

  Future<void> setLocale(String langCode) async {
    state = _mapCodeToLocale(langCode);
    final repo = ref.read(userRepositoryProvider);
    await repo.updateSinglePreference('language', langCode.toLowerCase());
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(() {
  return AppLocaleNotifier();
});
