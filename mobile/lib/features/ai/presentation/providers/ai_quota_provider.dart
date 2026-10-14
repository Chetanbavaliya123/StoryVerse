import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

class AiQuotaState {
  final int usedToday;
  final int maxFreeDaily;
  final String dateString;
  final bool isUnlimitedVip;

  const AiQuotaState({
    required this.usedToday,
    this.maxFreeDaily = 3,
    required this.dateString,
    required this.isUnlimitedVip,
  });

  int get remainingToday =>
      isUnlimitedVip ? 999 : (maxFreeDaily - usedToday).clamp(0, maxFreeDaily);

  bool get canGenerate => isUnlimitedVip || remainingToday > 0;

  AiQuotaState copyWith({
    int? usedToday,
    int? maxFreeDaily,
    String? dateString,
    bool? isUnlimitedVip,
  }) {
    return AiQuotaState(
      usedToday: usedToday ?? this.usedToday,
      maxFreeDaily: maxFreeDaily ?? this.maxFreeDaily,
      dateString: dateString ?? this.dateString,
      isUnlimitedVip: isUnlimitedVip ?? this.isUnlimitedVip,
    );
  }
}

class AiQuotaNotifier extends Notifier<AiQuotaState> {
  static String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  AiQuotaState build() {
    final isVip = ref.watch(isPremiumUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider).asData?.value;

    final usageMap = userProfile?.preferences['ai_daily_usage'] as Map<String, dynamic>?;
    final savedDate = usageMap?['date'] as String? ?? _todayKey;
    final savedCount = (savedDate == _todayKey) ? ((usageMap?['count'] as num?)?.toInt() ?? 0) : 0;

    return AiQuotaState(
      usedToday: savedCount,
      maxFreeDaily: 3,
      dateString: _todayKey,
      isUnlimitedVip: isVip,
    );
  }

  Future<bool> consumeQuota() async {
    final isVip = ref.read(isPremiumUserProvider);
    if (isVip) {
      return true;
    }

    final today = _todayKey;
    int currentUsed = (state.dateString == today) ? state.usedToday : 0;

    if (currentUsed >= state.maxFreeDaily) {
      return false; // Quota exhausted
    }

    final newCount = currentUsed + 1;
    state = state.copyWith(
      usedToday: newCount,
      dateString: today,
    );

    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateSinglePreference('ai_daily_usage', {
        'date': today,
        'count': newCount,
      });
    } catch (_) {
      // Keep optimistic local update if offline
    }

    return true;
  }
}

final aiQuotaProvider = NotifierProvider<AiQuotaNotifier, AiQuotaState>(() {
  return AiQuotaNotifier();
});
