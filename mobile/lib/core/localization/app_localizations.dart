import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('hi', ''),
    Locale('gu', ''),
    Locale('mr', ''),
    Locale('bn', ''),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'StoryVerse',
      'home': 'Home',
      'shorts': 'Shorts',
      'library': 'Library',
      'profile': 'Profile',
      'ai_hub': 'AI Hub',
      'discover': 'Discover',
      'search': 'Search',
      'search_hint': 'Search stories, genres, authors...',
      'voice_search': 'Voice Search',
      'voice_listening': 'Listening...',
      'voice_hint': 'Speak a story title, genre or keyword',
      'popular': 'Popular',
      'trending': 'Trending',
      'new_arrivals': 'New Arrivals',
      'romance': 'Romance',
      'horror': 'Horror',
      'comedy': 'Comedy',
      'see_all': 'See All',
      'watch_now': 'Watch Now',
      'continue_watching': 'Continue Watching',
      'browse_by_language': 'Browse by Language',
      'top_10': 'Top 10 in StoryVerse',
      'watching': 'Watching',
      'favorites': 'Favorites',
      'saved': 'Saved',
      'ai_stories': 'AI Stories',
      'clear_history': 'Clear History',
      'delete_account': 'Delete Account',
      'log_out': 'Log Out',
      'theme_settings': 'Theme Settings',
      'language_region': 'Language & Region',
      'help_center': 'Help Center & FAQs',
      'about': 'About StoryVerse',
      'terms': 'Terms & Privacy Policy',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'retry': 'Retry',
      'error_occurred': 'An error occurred',
      'offline_banner': 'You are offline. Showing cached stories.',
    },
    'hi': {
      'app_name': 'स्टोरीवर्स',
      'home': 'होम',
      'shorts': 'शॉर्ट्स',
      'library': 'लाइब्रेरी',
      'profile': 'प्रोफ़ाइल',
      'ai_hub': 'एआई हब',
      'discover': 'खोजें',
      'search': 'सर्च',
      'search_hint': 'कहानियां, विधाएं, लेखक खोजें...',
      'voice_search': 'वॉयस सर्च',
      'voice_listening': 'सुन रहे हैं...',
      'voice_hint': 'कहानी का नाम या विधा बोलें',
      'popular': 'लोकप्रिय',
      'trending': 'ट्रेंडिंग',
      'new_arrivals': 'नई कहानियां',
      'romance': 'रोमांस',
      'horror': 'हॉरर',
      'comedy': 'कॉमेडी',
      'see_all': 'सभी देखें',
      'watch_now': 'अभी देखें',
      'continue_watching': 'देखना जारी रखें',
      'browse_by_language': 'भाषा के अनुसार ब्राउज़ करें',
      'top_10': 'स्टोरीवर्स में शीर्ष 10',
      'watching': 'देख रहे हैं',
      'favorites': 'पसंदीदा',
      'saved': 'सहेजे गए',
      'ai_stories': 'एआई कहानियां',
      'clear_history': 'इतिहास हटाएं',
      'delete_account': 'खाता हटाएं',
      'log_out': 'लॉग आउट',
      'theme_settings': 'थीम सेटिंग्स',
      'language_region': 'भाषा और क्षेत्र',
      'help_center': 'सहायता केंद्र व प्रश्न',
      'about': 'स्टोरीवर्स के बारे में',
      'terms': 'नियम और गोपनीयता नीति',
      'confirm': 'पुष्टि करें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'retry': 'पुनः प्रयास करें',
      'error_occurred': 'एक त्रुटि उत्पन्न हुई',
      'offline_banner': 'आप ऑफ़लाइन हैं। सहेजी गई कहानियां दिखाई जा रही हैं।',
    },
    'gu': {
      'app_name': 'સ્ટોરીવર્સ',
      'home': 'હોમ',
      'shorts': 'શોર્ટ્સ',
      'library': 'લાઇબ્રેરી',
      'profile': 'પ્રોફાઇલ',
      'ai_hub': 'એઆઈ હબ',
      'discover': 'શોધો',
      'search': 'સર્ચ',
      'search_hint': 'વાર્તાઓ, શૈલીઓ, લેખકો શોધો...',
      'voice_search': 'વૉઇસ સર્ચ',
      'voice_listening': 'સાંભળી રહ્યા છીએ...',
      'voice_hint': 'વાર્તાનું નામ અથવા વિષય બોલો',
      'popular': 'લોકપ્રિય',
      'trending': 'ટ્રેન્ડિંગ',
      'new_arrivals': 'નવી વાર્તાઓ',
      'romance': 'રોમાન્સ',
      'horror': 'હોરર',
      'comedy': 'કોમેડી',
      'see_all': 'બધા જુઓ',
      'watch_now': 'હમણાં જુઓ',
      'continue_watching': 'જોવાનું ચાલુ રાખો',
      'browse_by_language': 'ભાષા અનુસાર બ્રાઉઝ કરો',
      'top_10': 'સ્ટોરીવર્સમાં ટોપ 10',
      'watching': 'જોઈ રહ્યા છો',
      'favorites': 'મનપસંદ',
      'saved': 'સાચવેલ',
      'ai_stories': 'એઆઈ વાર્તાઓ',
      'clear_history': 'ઇતિહાસ સાફ કરો',
      'delete_account': 'ખાતું કાઢી નાખો',
      'log_out': 'લૉગ આઉટ',
      'theme_settings': 'થીમ સેટિંગ્સ',
      'language_region': 'ભાષા અને પ્રદેશ',
      'help_center': 'મદદ કેન્દ્ર અને પ્રશ્નો',
      'about': 'સ્ટોરીવર્સ વિશે',
      'terms': 'શરતો અને ગોપનીયતા નીતિ',
      'confirm': 'પુષ્ટિ કરો',
      'cancel': 'રદ કરો',
      'delete': 'કાઢી નાખો',
      'retry': 'ફરી પ્રયાસ કરો',
      'error_occurred': 'એક ભૂલ આવી',
      'offline_banner': 'તમે ઑફલાઇન છો. સાચવેલી વાર્તાઓ દર્શાવવામાં આવી રહી છે.',
    },
    'mr': {
      'app_name': 'स्टोरीव्हर्स',
      'home': 'होम',
      'shorts': 'शॉर्ट्स',
      'library': 'लायब्ररी',
      'profile': 'प्रोफाइल',
      'ai_hub': 'एआय हब',
      'discover': 'शोधा',
      'search': 'सर्च',
      'search_hint': 'कथा, प्रकार, लेखक शोधा...',
      'voice_search': 'व्हॉइस सर्च',
      'voice_listening': 'ऐकत आहे...',
      'voice_hint': 'कथेचे नाव किंवा प्रकार बोला',
      'popular': 'लोकप्रिय',
      'trending': 'ट्रेंडिंग',
      'new_arrivals': 'नवीन कथा',
      'romance': 'रोमान्स',
      'horror': 'हॉरर',
      'comedy': 'कॉमेडी',
      'see_all': 'सर्व पहा',
      'watch_now': 'आता पहा',
      'continue_watching': 'पाहणे चालू ठेवा',
      'browse_by_language': 'भाषेनुसार शोधा',
      'top_10': 'स्टोरीव्हर्स टॉप 10',
      'watching': 'पाहत असलेले',
      'favorites': 'आवडते',
      'saved': 'जतन केलेले',
      'ai_stories': 'एआय कथा',
      'clear_history': 'इतिहास पुसा',
      'delete_account': 'खाते हटवा',
      'log_out': 'लॉग आउट',
      'theme_settings': 'थीम सेटिंग्ज',
      'language_region': 'भाषा आणि प्रदेश',
      'help_center': 'मदत केंद्र आणि प्रश्न',
      'about': 'स्टोरीव्हर्स बद्दल',
      'terms': 'नियम आणि गोपनीयता धोरण',
      'confirm': 'पुष्टी करा',
      'cancel': 'रद्द करा',
      'delete': 'हटवा',
      'retry': 'पुन्हा प्रयत्न करा',
      'error_occurred': 'त्रुटी आढळली',
      'offline_banner': 'तुम्ही ऑफलाइन आहात. सेव्ह केलेल्या कथा दाखवत आहोत.',
    },
    'bn': {
      'app_name': 'স্টোরিভার্স',
      'home': 'হোম',
      'shorts': 'শর্টস',
      'library': 'লাইব্রেরি',
      'profile': 'প্রোফাইল',
      'ai_hub': 'এআই হাব',
      'discover': 'আবিষ্কার করুন',
      'search': 'সন্ধান',
      'search_hint': 'গল্প, ধারা, লেখক খুঁজুন...',
      'voice_search': 'ভয়েস অনুসন্ধান',
      'voice_listening': 'শুনছি...',
      'voice_hint': 'গল্পের নাম বা ধারা বলুন',
      'popular': 'জনপ্রিয়',
      'trending': 'ট্রেন্ডিং',
      'new_arrivals': 'নতুন গল্প',
      'romance': 'রোম্যান্স',
      'horror': 'হরর',
      'comedy': 'কমেডি',
      'see_all': 'সব দেখুন',
      'watch_now': 'এখনই দেখুন',
      'continue_watching': 'দেখা চালিয়ে যান',
      'browse_by_language': 'ভাষার ভিত্তিতে খুঁজুন',
      'top_10': 'স্টোরিভার্সে শীর্ষ ১০',
      'watching': 'দেখছেন',
      'favorites': 'পছন্দের',
      'saved': 'সংরক্ষিত',
      'ai_stories': 'এআই গল্প',
      'clear_history': 'ইতিহাস মুছুন',
      'delete_account': 'অ্যাকাউন্ট মুছুন',
      'log_out': 'লগ আউট',
      'theme_settings': 'থিম সেটিংস',
      'language_region': 'ভাষা ও অঞ্চল',
      'help_center': 'সহায়তা কেন্দ্র ও প্রশ্ন',
      'about': 'স্টোরিভার্স সম্পর্কে',
      'terms': 'শর্তাবলী ও গোপনীয়তা নীতি',
      'confirm': 'নিশ্চিত করুন',
      'cancel': 'বাতিল করুন',
      'delete': 'মুছুন',
      'retry': 'আবার চেষ্টা করুন',
      'error_occurred': 'একটি ত্রুটি ঘটেছে',
      'offline_banner': 'আপনি অফলাইনে আছেন। সংরক্ষিত গল্প দেখানো হচ্ছে।',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get appName => translate('app_name');
  String get home => translate('home');
  String get shorts => translate('shorts');
  String get library => translate('library');
  String get profile => translate('profile');
  String get aiHub => translate('ai_hub');
  String get discover => translate('discover');
  String get search => translate('search');
  String get searchHint => translate('search_hint');
  String get voiceSearch => translate('voice_search');
  String get voiceListening => translate('voice_listening');
  String get voiceHint => translate('voice_hint');
  String get popular => translate('popular');
  String get trending => translate('trending');
  String get newArrivals => translate('new_arrivals');
  String get romance => translate('romance');
  String get horror => translate('horror');
  String get comedy => translate('comedy');
  String get seeAll => translate('see_all');
  String get watchNow => translate('watch_now');
  String get continueWatching => translate('continue_watching');
  String get browseByLanguage => translate('browse_by_language');
  String get top10 => translate('top_10');
  String get watching => translate('watching');
  String get favorites => translate('favorites');
  String get saved => translate('saved');
  String get aiStories => translate('ai_stories');
  String get clearHistory => translate('clear_history');
  String get deleteAccount => translate('delete_account');
  String get logOut => translate('log_out');
  String get themeSettings => translate('theme_settings');
  String get languageRegion => translate('language_region');
  String get helpCenter => translate('help_center');
  String get about => translate('about');
  String get terms => translate('terms');
  String get confirm => translate('confirm');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get retry => translate('retry');
  String get errorOccurred => translate('error_occurred');
  String get offlineBanner => translate('offline_banner');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'gu', 'mr', 'bn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
