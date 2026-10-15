import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class AppLocaleCodeNotifier extends Notifier<String> {
  static String? _activeCode;

  @override
  String build() {
    if (_activeCode != null) {
      return _activeCode!;
    }
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null && profile.preferences.containsKey('language')) {
      return profile.preferences['language'] as String? ?? 'en';
    }
    return 'en';
  }

  void setLocaleCode(String code) {
    _activeCode = code.toLowerCase();
    state = _activeCode!;
  }
}

final appLocaleCodeProvider =
    NotifierProvider<AppLocaleCodeNotifier, String>(AppLocaleCodeNotifier.new);

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.watch(appLocaleCodeProvider);
    return _mapCodeToLocale(code);
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
    ref.read(appLocaleCodeProvider.notifier).setLocaleCode(langCode.toLowerCase());
    state = _mapCodeToLocale(langCode);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateSinglePreference('language', langCode.toLowerCase());
    } catch (_) {}
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(() {
  return AppLocaleNotifier();
});
