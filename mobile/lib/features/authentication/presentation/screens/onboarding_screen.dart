import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:storyverse/core/localization/locale_provider.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';

import 'onboarding/design_tokens.dart';
import 'onboarding/ken_burns_background.dart';
import 'onboarding/particles_painter.dart';
import 'onboarding/animated_gradient_background.dart';
import 'onboarding/onboarding_top_bar.dart';
import 'onboarding/onboarding_page_content.dart';
import 'onboarding/animated_page_indicator.dart';
import 'onboarding/premium_cta_button.dart';

class _PageData {
  const _PageData({
    required this.title,
    required this.subtitle,
    required this.highlightWords,
  });
  final String title;
  final String subtitle;
  final List<String> highlightWords;
}

const _pages = [
  _PageData(
    title: 'Discover infinite worlds',
    subtitle:
        'Immerse yourself in cinematic micro-dramas and episodic shorts crafted for your screen.',
    highlightWords: ['infinite', 'worlds'],
  ),
  _PageData(
    title: 'Choose your language',
    subtitle:
        'Select your preferred story language. You can change this anytime from your profile.',
    highlightWords: ['language'],
  ),
  _PageData(
    title: 'Pick favorite genres',
    subtitle:
        'Pick up to 3 genres to personalize your recommendations and home feed.',
    highlightWords: ['genres'],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  late final ValueNotifier<double> _pageOffset;
  int _currentPage = 0;
  bool _isExiting = false;

  String _selectedLanguage = 'en';
  final Set<String> _selectedGenres = {'romance', 'thriller', 'horror'};

  static const List<Map<String, String>> _languages = [
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
  ];

  static const List<Map<String, dynamic>> _genres = [
    {'id': 'romance', 'name': 'Romance', 'icon': Icons.favorite_rounded},
    {'id': 'horror', 'name': 'Horror', 'icon': Icons.nightlight_round},
    {'id': 'thriller', 'name': 'Thriller', 'icon': Icons.flash_on_rounded},
    {'id': 'sci-fi', 'name': 'Sci-Fi', 'icon': Icons.rocket_launch_rounded},
    {'id': 'comedy', 'name': 'Comedy', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'id': 'fantasy', 'name': 'Fantasy', 'icon': Icons.auto_awesome_rounded},
    {'id': 'drama', 'name': 'Drama', 'icon': Icons.theater_comedy_rounded},
    {'id': 'action', 'name': 'Action', 'icon': Icons.local_fire_department_rounded},
  ];

  static const String _page1ImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBEK1XA36MYrEzmsfpqmWPIezqFAfe0yw2nqrzWEHFOUOIES3muePQ6jqYo9mlnH-5WImT17li-XauhNHgPLcwcGTNndH0iklEF_-ITv4sZWUAYrNwXHV8P3r3C4HXXjqXf7g-EkfmkUq8IiZ3JVyZ013tp7FndF2GS9LhAsCnqt5zqBYghcWRafvQYOjo5yw8a90QU-6yndlWz2YWrkptGavR1XIo-Th0qetAY49pDpqP5LBheBlep5w';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();
    _pageOffset = ValueNotifier<double>(0.0);

    _pageController.addListener(() {
      if (_pageController.page != null) {
        _pageOffset.value = _pageController.page!;
      }
    });

    _entryController = AnimationController(
      vsync: this,
      duration: OBTokens.entryTotal,
    );

    _exitController = AnimationController(
      vsync: this,
      duration: OBTokens.exitDuration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: OBTokens.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const NetworkImage(_page1ImageUrl), context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _pageOffset.dispose();
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  void _onSkip() {
    HapticFeedback.lightImpact();
    _saveAndNavigate();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: OBTokens.pageTransition,
        curve: OBTokens.pageSwipe,
      );
    } else {
      _saveAndNavigate();
    }
  }

  Future<void> _saveAndNavigate() async {
    if (_isExiting) return;
    _isExiting = true;

    // Apply selected language globally
    ref.read(appLocaleProvider.notifier).setLocale(_selectedLanguage);

    // Persist to user profile doc if logged in
    try {
      await ref.read(userRepositoryProvider).updatePreferences({
        'language': _selectedLanguage,
        'preferredGenres': _selectedGenres.toList(),
        'onboardingCompleted': true,
      });
    } catch (_) {}

    final isAuth = ref.read(authStateChangesProvider).value != null;

    if (_reduceMotion) {
      if (mounted) context.go(isAuth ? '/home' : '/login');
      return;
    }

    _exitController.forward().then((_) {
      if (mounted) {
        context.go(isAuth ? '/home' : '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OBTokens.bgDeep,
      body: ValueListenableBuilder<double>(
        valueListenable: _pageOffset,
        builder: (context, pageOffset, _) {
          final isLastPage = _currentPage >= _pages.length - 1;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background
              AnimatedGradientBackground(
                pageOffset: pageOffset,
                isActive: !_isExiting,
                reduceMotion: _reduceMotion,
              ),

              // PageView
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (!_reduceMotion) {
                    HapticFeedback.selectionClick();
                  }
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(index, pageOffset);
                },
              ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OnboardingTopBar(
                  showSkip: true,
                  onSkip: _onSkip,
                  entryAnimation: _entryController,
                ),
              ),

              // Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControls(pageOffset, isLastPage),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPage(int index, double pageOffset) {
    final parallax = pageOffset - index;
    final isVisible = (pageOffset - index).abs() < 1.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (index == 0) ...[
          // Step 1: Cinematic Intro Hero
          KenBurnsBackground(
            imageUrl: _page1ImageUrl,
            parallaxOffset: parallax,
            isActive: isVisible && !_isExiting,
            reduceMotion: _reduceMotion,
          ),
          ParticlesOverlay(isActive: isVisible && !_isExiting),
        ] else if (index == 1) ...[
          // Step 2: Language Selection
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: OBTokens.topBarHeight + 20,
                bottom: 230,
                left: 20,
                right: 20,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _languages.map((lang) {
                      final isSelected = _selectedLanguage == lang['code'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedLanguage = lang['code']!);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? OBTokens.crimsonStart.withValues(alpha: 0.25)
                                    : const Color(0x18FFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? OBTokens.crimsonStart
                                      : const Color(0x22FFFFFF),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected
                                        ? OBTokens.crimsonStart
                                        : Colors.white12,
                                    child: Text(
                                      lang['code']!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang['name']!,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          lang['native']!,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: OBTokens.crimsonStart,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ] else if (index == 2) ...[
          // Step 3: Genre Selection (up to 3)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: OBTokens.topBarHeight + 20,
                bottom: 230,
                left: 16,
                right: 16,
              ),
              child: Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: _genres.map((g) {
                    final id = g['id'] as String;
                    final isSelected = _selectedGenres.contains(id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isSelected) {
                              if (_selectedGenres.length > 1) {
                                _selectedGenres.remove(id);
                              }
                            } else {
                              if (_selectedGenres.length < 3) {
                                _selectedGenres.add(id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You can choose up to 3 genres.'),
                                    duration: Duration(milliseconds: 1200),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? OBTokens.crimsonStart.withValues(alpha: 0.35)
                                : const Color(0x18FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? OBTokens.crimsonStart
                                  : const Color(0x24FFFFFF),
                              width: isSelected ? 1.8 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: OBTokens.crimsonStart
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                g['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                g['name'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],

        // Bottom Text Description
        Positioned(
          bottom: 155,
          left: OBTokens.spaceLG,
          right: OBTokens.spaceLG,
          child: Transform.translate(
            offset: Offset(parallax * -70, 0),
            child: Opacity(
              opacity: (1.0 - parallax.abs() * 1.5).clamp(0.0, 1.0),
              child: OnboardingPageContent(
                title: _pages[index].title,
                subtitle: index == 2
                    ? 'Selected ${_selectedGenres.length}/3: ${_selectedGenres.map((g) => g.toUpperCase()).join(', ')}'
                    : _pages[index].subtitle,
                highlightWords: _pages[index].highlightWords,
                isVisible: isVisible && _currentPage == index,
                reduceMotion: _reduceMotion,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(double pageOffset, bool isLastPage) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 1.0, curve: OBTokens.entryDefault),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.6, 0.9),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OBTokens.spaceLG,
            vertical: OBTokens.spaceLG,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedPageIndicator(
                pageCount: _pages.length,
                pageOffset: pageOffset,
              ),
              PremiumCtaButton(
                isLastPage: isLastPage,
                onPressed: _onNext,
                pageOffset: pageOffset,
                pageCount: _pages.length,
                reduceMotion: _reduceMotion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
