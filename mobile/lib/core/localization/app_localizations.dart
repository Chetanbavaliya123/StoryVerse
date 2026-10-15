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
      'account': 'Account',
      'preferences': 'Preferences',
      'personal_information': 'Personal Information',
      'personal_info_sub': 'Edit name & profile photo',
      'security_privacy': 'Security & Privacy',
      'security_privacy_sub': 'Password reset & account safety',
      'notifications': 'Notifications',
      'notifications_sub': 'Alerts, new episodes & messages',
      'content_onboarding': 'Content & Onboarding Preferences',
      'content_onboarding_sub': 'Preferred language & story genres',
      'library_shortcuts': 'Library & Shortcuts',
      'ai_hub_sub': 'Generate & explore AI stories',
      'viewing_history': 'Viewing History',
      'viewing_history_sub': 'Episodes & stories you watched',
      'favorites_sub': 'Liked and recommended stories',
      'my_list_saved': 'My List / Saved Stories',
      'my_list_sub': 'Saved for later watching',
      'support_info': 'Support & Info',
      'help_center_sub': 'Frequently asked questions & support',
      'about_sub': 'v1.0.0 • Terms & Privacy Policy',
      'log_out_sub': 'Sign out of this device',
      'delete_account_sub': 'Permanently remove your account and all data',
      'quick_settings': 'Quick Settings',
      'select_theme': 'Theme Settings',
      'customize_theme': 'Customize the dark surface tone of StoryVerse',
      'select_language': 'Language & Region',
      'select_lang_sub': 'Choose your preferred language for stories and UI',
      'edit_profile': 'Edit Profile',
      'save_changes': 'Save Changes',
      'reset_password': 'Reset Password',
      'trending_now': 'Trending Now',
      'popular_genres': 'Popular Genres',
      'because_you_watched': 'Because You Watched',
      'recent_searches': 'Recent Searches',
      'clear_all': 'Clear All',
      'no_results': 'No results found',
      'no_results_sub': 'Try adjusting your search terms.',
      'stories_found': 'Stories',
      'undo': 'Undo',
      'no_history_title': 'No watch history',
      'no_history_sub': 'Start watching any micro-drama to pick up where you left off.',
      'no_fav_title': 'No favorites yet',
      'no_fav_sub': 'Tap the heart icon on any story to save your favorites here.',
      'no_saved_title': 'Your list is empty',
      'no_saved_sub': 'Bookmark stories to quickly access them anytime.',
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
      'account': 'खाता',
      'preferences': 'प्राथमिकताएं',
      'personal_information': 'व्यक्तिगत जानकारी',
      'personal_info_sub': 'नाम और प्रोफ़ाइल फ़ोटो बदलें',
      'security_privacy': 'सुरक्षा और गोपनीयता',
      'security_privacy_sub': 'पासवर्ड रीसेट और खाता सुरक्षा',
      'notifications': 'सूचनाएं',
      'notifications_sub': 'अलर्ट, नए एपिसोड और संदेश',
      'content_onboarding': 'सामग्री और ऑनबोर्डिंग प्राथमिकताएं',
      'content_onboarding_sub': 'पसंदीदा भाषा और कहानी की शैलियां',
      'library_shortcuts': 'लाइब्रेरी और शॉर्टकट',
      'ai_hub_sub': 'एआई कहानियां बनाएं और देखें',
      'viewing_history': 'देखने का इतिहास',
      'viewing_history_sub': 'आपके देखे गए एपिसोड और कहानियां',
      'favorites_sub': 'पसंद की गई और सुझाई गई कहानियां',
      'my_list_saved': 'मेरी सूची / सहेजी गई कहानियां',
      'my_list_sub': 'बाद में देखने के लिए सहेजा गया',
      'support_info': 'सहायता और जानकारी',
      'help_center_sub': 'अक्सर पूछे जाने वाले प्रश्न और सहायता',
      'about_sub': 'v1.0.0 • नियम और गोपनीयता नीति',
      'log_out_sub': 'इस डिवाइस से साइन आउट करें',
      'delete_account_sub': 'अपना खाता और सारा डेटा स्थायी रूप से हटाएं',
      'quick_settings': 'त्वरित सेटिंग्स',
      'select_theme': 'थीम सेटिंग्स',
      'customize_theme': 'स्टोरीवर्स का डार्क थीम चुनें',
      'select_language': 'भाषा और क्षेत्र',
      'select_lang_sub': 'कहानियों और ऐप के लिए पसंदीदा भाषा चुनें',
      'edit_profile': 'प्रोफ़ाइल बदलें',
      'save_changes': 'बदलाव सहेजें',
      'reset_password': 'पासवर्ड रीसेट करें',
      'trending_now': 'ट्रेंडिंग नाउ',
      'popular_genres': 'लोकप्रिय शैलियां',
      'because_you_watched': 'क्योंकि आपने देखा',
      'recent_searches': 'हाल की खोजें',
      'clear_all': 'सभी हटाएं',
      'no_results': 'कोई परिणाम नहीं मिला',
      'no_results_sub': 'कृपया अन्य शब्द खोज कर देखें।',
      'stories_found': 'कहानियां',
      'undo': 'पूर्ववत करें',
      'no_history_title': 'कोई इतिहास नहीं',
      'no_history_sub': 'कहानियां देखना शुरू करें और यहीं से जारी रखें।',
      'no_fav_title': 'कोई पसंदीदा कहानी नहीं',
      'no_fav_sub': 'पसंदीदा में जोड़ने के लिए दिल के आइकन पर टैप करें।',
      'no_saved_title': 'आपकी सूची खाली है',
      'no_saved_sub': 'बाद में देखने के लिए कहानियों को बुकमार्क करें।',
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
      'account': 'એકાઉન્ટ',
      'preferences': 'પસંદગીઓ',
      'personal_information': 'વ્યક્તિગત માહિતી',
      'personal_info_sub': 'નામ અને પ્રોફાઇલ ફોટો બદલો',
      'security_privacy': 'સુરક્ષા અને ગોપનીયતા',
      'security_privacy_sub': 'પાસવર્ડ રીસેટ અને એકાઉન્ટ સુરક્ષા',
      'notifications': 'સૂચનાઓ',
      'notifications_sub': 'ચેતવણીઓ, નવા એપિસોડ અને સંદેશાઓ',
      'content_onboarding': 'સામગ્રી અને ઑનબોર્ડિંગ પસંદગીઓ',
      'content_onboarding_sub': 'પસંદગીની ભાષા અને વાર્તાની શૈલીઓ',
      'library_shortcuts': 'લાઇબ્રેરી અને શોર્ટકટ્સ',
      'ai_hub_sub': 'એઆઈ વાર્તાઓ બનાવો અને જુઓ',
      'viewing_history': 'જોવાનો ઇતિહાસ',
      'viewing_history_sub': 'તમે જોયેલા એપિસોડ અને વાર્તાઓ',
      'favorites_sub': 'પસંદ કરેલી અને ભલામણ કરેલી વાર્તાઓ',
      'my_list_saved': 'મારી યાદી / સાચવેલી વાર્તાઓ',
      'my_list_sub': 'પછી જોવા માટે સાચવેલ',
      'support_info': 'સહાય અને માહિતી',
      'help_center_sub': 'વારંવાર પૂછાતા પ્રશ્નો અને મદદ',
      'about_sub': 'v1.0.0 • શરતો અને ગોપનીયતા નીતિ',
      'log_out_sub': 'આ ઉપકરણમાંથી સાઇન આઉટ કરો',
      'delete_account_sub': 'તમારું એકાઉન્ટ અને બધો ડેટા કાયમ માટે કાઢી નાખો',
      'quick_settings': 'ઝડપી સેટિંગ્સ',
      'select_theme': 'થીમ સેટિંગ્સ',
      'customize_theme': 'સ્ટોરીવર્સ માટે ડાર્ક થીમ પસંદ કરો',
      'select_language': 'ભાષા અને પ્રદેશ',
      'select_lang_sub': 'વાર્તાઓ અને એપ્લિકેશન માટે મનપસંદ ભાષા પસંદ કરો',
      'edit_profile': 'પ્રોફાઇલ સંપાદિત કરો',
      'save_changes': 'ફેરફારો સાચવો',
      'reset_password': 'પાસવર્ડ રીસેટ કરો',
      'trending_now': 'ટ્રેન્ડિંગ નાઉ',
      'popular_genres': 'લોકપ્રિય શૈલીઓ',
      'because_you_watched': 'કારણ કે તમે જોયું',
      'recent_searches': 'તાજેતરની શોધો',
      'clear_all': 'બધું સાફ કરો',
      'no_results': 'કોઈ પરિણામ મળ્યું નથી',
      'no_results_sub': 'કૃપા કરીને અન્ય શબ્દો શોધીને પ્રયાસ કરો.',
      'stories_found': 'વાર્તાઓ',
      'undo': 'રદ કરો',
      'no_history_title': 'હજુ સુધી કોઈ ઇતિહાસ નથી',
      'no_history_sub': 'વાર્તાઓ જોવાનું શરૂ કરો અને અહીંથી ફરી ચાલુ કરો.',
      'no_fav_title': 'હજુ સુધી કોઈ મનપસંદ વાર્તા નથી',
      'no_fav_sub': 'મનપસંદમાં ઉમેરવા માટે હાર્ટ આઇકન પર ટેપ કરો.',
      'no_saved_title': 'તમારી યાદી ખાલી છે',
      'no_saved_sub': 'પછી જોવા માટે વાર્તાઓને બુકમાર્ક કરો.',
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
      'account': 'खाते',
      'preferences': 'प्राधान्ये',
      'personal_information': 'वैयक्तिक माहिती',
      'personal_info_sub': 'नाव आणि प्रोफाइल फोटो बदला',
      'security_privacy': 'सुरक्षा आणि गोपनीयता',
      'security_privacy_sub': 'पासवर्ड रीसेट आणि खाते सुरक्षा',
      'notifications': 'सूचना',
      'notifications_sub': 'अलर्ट, नवीन भाग आणि संदेश',
      'content_onboarding': 'सामग्री आणि ऑनबोर्डिंग प्राधान्ये',
      'content_onboarding_sub': 'पसंतीची भाषा आणि कथा प्रकार',
      'library_shortcuts': 'लायब्ररी आणि शॉर्टकट',
      'ai_hub_sub': 'एआय कथा तयार करा आणि शोधा',
      'viewing_history': 'पाहण्याचा इतिहास',
      'viewing_history_sub': 'तुम्ही पाहिलेले भाग आणि कथा',
      'favorites_sub': 'आवडलेल्या आणि शिफारस केलेल्या कथा',
      'my_list_saved': 'माझी यादी / जतन केलेल्या कथा',
      'my_list_sub': 'नंतर पाहण्यासाठी जतन केलेले',
      'support_info': 'मदत आणि माहिती',
      'help_center_sub': 'वारंवार विचारले जाणारे प्रश्न आणि मदत',
      'about_sub': 'v1.0.0 • नियम आणि गोपनीयता धोरण',
      'log_out_sub': 'या डिव्हाइसवरून साइन आउट करा',
      'delete_account_sub': 'तुमचे खाते आणि सर्व डेटा कायमचा हटवा',
      'quick_settings': 'द्रुत सेटिंग्ज',
      'select_theme': 'थीम सेटिंग्ज',
      'customize_theme': 'स्टोरीव्हर्सची डार्क थीम निवडा',
      'select_language': 'भाषा आणि प्रदेश',
      'select_lang_sub': 'कथा आणि ॲपसाठी पसंतीची भाषा निवडा',
      'edit_profile': 'प्रोफाइल संपादित करा',
      'save_changes': 'बदल जतन करा',
      'reset_password': 'पासवर्ड रीसेट करा',
      'trending_now': 'ट्रेंडिंग नाऊ',
      'popular_genres': 'लोकप्रिय प्रकार',
      'because_you_watched': 'कारण तुम्ही पाहिले',
      'recent_searches': 'अलीकडील शोध',
      'clear_all': 'सर्व पुसा',
      'no_results': 'कोणतेही निकाल आढळले नाहीत',
      'no_results_sub': 'कृपया इतर शब्द शोधून पहा.',
      'stories_found': 'कथा',
      'undo': 'पूर्ववत करा',
      'no_history_title': 'अद्याप पाहण्याचा इतिहास नाही',
      'no_history_sub': 'कथा पाहणे सुरू करा आणि येथून पुढे चालू ठेवा.',
      'no_fav_title': 'अद्याप आवडती कथा नाही',
      'no_fav_sub': 'आवडत्या कथांमध्ये जोडण्यासाठी हार्ट चिन्हावर टॅप करा.',
      'no_saved_title': 'तुमची यादी रिकामी आहे',
      'no_saved_sub': 'नंतर पाहण्यासाठी कथा बुकमार्क करा.',
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
      'account': 'অ্যাকাউন্ট',
      'preferences': 'পছন্দসমূহ',
      'personal_information': 'ব্যক্তিগত তথ্য',
      'personal_info_sub': 'নাম এবং প্রোফাইল ছবি পরিবর্তন করুন',
      'security_privacy': 'নিরাপত্তা ও গোপনীয়তা',
      'security_privacy_sub': 'পাসওয়ার্ড রিসেট এবং অ্যাকাউন্ট সুরক্ষা',
      'notifications': 'বিজ্ঞপ্তি',
      'notifications_sub': 'সতর্কতা, নতুন পর্ব এবং বার্তা',
      'content_onboarding': 'বিষয়বস্তু এবং অনবোর্ডিং পছন্দসমূহ',
      'content_onboarding_sub': 'পছন্দের ভাষা এবং গল্পের ধারা',
      'library_shortcuts': 'লাইব্রেরি এবং শর্টকাট',
      'ai_hub_sub': 'এআই গল্প তৈরি এবং আবিষ্কার করুন',
      'viewing_history': 'দেখার ইতিহাস',
      'viewing_history_sub': 'আপনার দেখা পর্ব এবং গল্পসমূহ',
      'favorites_sub': 'পছন্দের এবং সুপারিশকৃত গল্প',
      'my_list_saved': 'আমার তালিকা / সংরক্ষিত গল্প',
      'my_list_sub': 'পরে দেখার জন্য সংরক্ষিত',
      'support_info': 'সহায়তা ও তথ্য',
      'help_center_sub': 'প্রায়শই জিজ্ঞাসিত প্রশ্ন ও সহায়তা',
      'about_sub': 'v1.0.0 • শর্তাবলী এবং গোপনীয়তা নীতি',
      'log_out_sub': 'এই ডিভাইস থেকে সাইন আউট করুন',
      'delete_account_sub': 'আপনার অ্যাকাউন্ট এবং সমস্ত ডেটা স্থায়ীভাবে মুছুন',
      'quick_settings': 'দ্রুত সেটিংস',
      'select_theme': 'থিম সেটিংস',
      'customize_theme': 'স্টোরিভার্সের ডার্ক থিম কাস্টমাইজ করুন',
      'select_language': 'ভাষা ও অঞ্চল',
      'select_lang_sub': 'গল্প এবং অ্যাপের জন্য আপনার পছন্দের ভাষা নির্বাচন করুন',
      'edit_profile': 'প্রোফাইল সম্পাদনা',
      'save_changes': 'পরিবর্তন সংরক্ষণ করুন',
      'reset_password': 'পাসওয়ার্ড রিসেট',
      'trending_now': 'ট্রেন্ডিং নাও',
      'popular_genres': 'জনপ্রিয় ধারা',
      'because_you_watched': 'যেহেতু আপনি দেখেছেন',
      'recent_searches': 'সাম্প্রতিক অনুসন্ধান',
      'clear_all': 'সব মুছুন',
      'no_results': 'কোন ফলাফল পাওয়া যায়নি',
      'no_results_sub': 'অনুসন্ধানের শব্দ পরিবর্তন করে চেষ্টা করুন।',
      'stories_found': 'গল্প',
      'undo': 'পূর্বাবস্থায় ফেরান',
      'no_history_title': 'এখনও কোনো ইতিহাস নেই',
      'no_history_sub': 'গল্প দেখা শুরু করুন এবং এখান থেকেই পুনরায় চালু করুন।',
      'no_fav_title': 'এখনও কোনো পছন্দের গল্প নেই',
      'no_fav_sub': 'পছন্দের তালিকায় যোগ করতে হার্ট আইকনে ট্যাপ করুন।',
      'no_saved_title': 'আপনার তালিকা খালি',
      'no_saved_sub': 'পরে দেখার জন্য গল্প বুকমার্ক করুন।',
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

  String get account => translate('account');
  String get preferences => translate('preferences');
  String get personalInformation => translate('personal_information');
  String get personalInfoSub => translate('personal_info_sub');
  String get securityPrivacy => translate('security_privacy');
  String get securityPrivacySub => translate('security_privacy_sub');
  String get notifications => translate('notifications');
  String get notificationsSub => translate('notifications_sub');
  String get contentOnboarding => translate('content_onboarding');
  String get contentOnboardingSub => translate('content_onboarding_sub');
  String get libraryShortcuts => translate('library_shortcuts');
  String get aiHubSub => translate('ai_hub_sub');
  String get viewingHistory => translate('viewing_history');
  String get viewingHistorySub => translate('viewing_history_sub');
  String get favoritesSub => translate('favorites_sub');
  String get myListSaved => translate('my_list_saved');
  String get myListSub => translate('my_list_sub');
  String get supportInfo => translate('support_info');
  String get helpCenterSub => translate('help_center_sub');
  String get aboutSub => translate('about_sub');
  String get logOutSub => translate('log_out_sub');
  String get deleteAccountSub => translate('delete_account_sub');
  String get quickSettings => translate('quick_settings');
  String get selectTheme => translate('select_theme');
  String get customizeTheme => translate('customize_theme');
  String get selectLanguage => translate('select_language');
  String get selectLangSub => translate('select_lang_sub');
  String get editProfile => translate('edit_profile');
  String get saveChanges => translate('save_changes');
  String get resetPassword => translate('reset_password');
  String get trendingNow => translate('trending_now');
  String get popularGenres => translate('popular_genres');
  String get becauseYouWatched => translate('because_you_watched');
  String get recentSearches => translate('recent_searches');
  String get clearAll => translate('clear_all');
  String get noResults => translate('no_results');
  String get noResultsSub => translate('no_results_sub');
  String get storiesFound => translate('stories_found');
  String get undo => translate('undo');
  String get noHistoryTitle => translate('no_history_title');
  String get noHistorySub => translate('no_history_sub');
  String get noFavTitle => translate('no_fav_title');
  String get noFavSub => translate('no_fav_sub');
  String get noSavedTitle => translate('no_saved_title');
  String get noSavedSub => translate('no_saved_sub');
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
