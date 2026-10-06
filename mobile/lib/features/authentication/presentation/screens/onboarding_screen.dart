import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'onboarding/design_tokens.dart';
import 'onboarding/ken_burns_background.dart';
import 'onboarding/particles_painter.dart';
import 'onboarding/animated_gradient_background.dart';
import 'onboarding/onboarding_top_bar.dart';
import 'onboarding/onboarding_page_content.dart';
import 'onboarding/animated_page_indicator.dart';
import 'onboarding/premium_cta_button.dart';
import 'onboarding/poster_fan_hero.dart';
import 'onboarding/orbiting_chips_hero.dart';

/// Onboarding page data model.
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
        'Immerse yourself in cinematic storytelling crafted for the modern screen.',
    highlightWords: ['infinite', 'worlds'],
  ),
  _PageData(
    title: 'Engaging visual series',
    subtitle:
        'Follow episodic content that keeps you coming back for the next chapter.',
    highlightWords: ['visual', 'series'],
  ),
  _PageData(
    title: 'Watch anywhere, binge your way',
    subtitle:
        'Vertical stories, offline downloads and a watchlist that remembers where you stopped.',
    highlightWords: ['anywhere'],
  ),
];

/// The existing onboarding screen — now with premium cinematic experience.
/// Business logic preserved: Skip → /login, Get Started → /login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  late final ValueNotifier<double> _pageOffset;
  int _currentPage = 0;
  bool _isExiting = false;

  // Network image URL for page 1 (existing asset)
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

    // Trigger entry animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });

    // System UI setup: transparent, edge-to-edge
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
    // Precache the page 1 network image
    precacheImage(NetworkImage(_page1ImageUrl), context);
    // Precache poster images
    for (final path in [
      'assets/images/stories/story_03.jpg',
      'assets/images/stories/story_05.jpg',
      'assets/images/stories/story_08.jpg',
      'assets/images/stories/story_12.jpg',
      'assets/images/stories/story_14.jpg',
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause/resume handled by individual widget isActive flags
    // We just mark the overall state
    if (state == AppLifecycleState.paused) {
      // Widgets will check isActive
    }
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

  bool get _reduceMotion {
    return MediaQuery.of(context).disableAnimations;
  }

  void _onSkip() {
    // Smooth animate to last page, then allow Get Started
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: OBTokens.pageSwipe,
    );
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: OBTokens.pageTransition,
        curve: OBTokens.pageSwipe,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() {
    if (_isExiting) return;
    _isExiting = true;

    if (_reduceMotion) {
      context.go('/login');
      return;
    }

    // Cinematic exit transition
    _exitController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              // Let GoRouter handle the actual page
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/login');
                }
              });
              return const SizedBox.shrink();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: OBTokens.entryDefault,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
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

          return AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) {
              // Exit animation: scale up + fade to black with red glow
              if (_exitController.value > 0) {
                final exitScale = 1.0 + _exitController.value * 0.08;
                final exitOpacity = 1.0 - _exitController.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Red light burst
                    Container(
                      color: Color.lerp(
                        OBTokens.bgDeep,
                        OBTokens.crimsonStart.withValues(alpha: 0.3),
                        (_exitController.value * 2).clamp(0.0, 1.0),
                      ),
                    ),
                    Transform.scale(
                      scale: exitScale,
                      child: Opacity(
                        opacity: exitOpacity.clamp(0.0, 1.0),
                        child: child!,
                      ),
                    ),
                    // Fade to black
                    IgnorePointer(
                      child: Container(
                        color: OBTokens.bgDeep.withValues(
                          alpha: (_exitController.value * 1.5).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return child!;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ─── Layer 1: Animated gradient background ───
                AnimatedGradientBackground(
                  pageOffset: pageOffset,
                  isActive: !_isExiting,
                  reduceMotion: _reduceMotion,
                ),

                // ─── Layer 2: PageView with hero content ───
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

                // ─── Layer 3: Persistent top bar ───
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OnboardingTopBar(
                    showSkip: _currentPage == 0, // only show on the first screen
                    onSkip: _onSkip,
                    entryAnimation: _entryController,
                  ),
                ),

                // ─── Layer 4: Bottom controls ───
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: _buildBottomControls(
                      pageOffset,
                      isLastPage,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(int index, double pageOffset) {
    // Parallax: difference between page offset and page index
    final parallax = pageOffset - index;
    final isVisible = (pageOffset - index).abs() < 1.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Page-specific hero visual
        if (index == 0) ...[
          // Page 1: Ken Burns cinematic image + particles
          KenBurnsBackground(
            imageUrl: _page1ImageUrl,
            parallaxOffset: parallax,
            isActive: isVisible && !_isExiting,
            reduceMotion: _reduceMotion,
          ),
          ParticlesOverlay(isActive: isVisible && !_isExiting),
        ] else if (index == 1) ...[
          // Page 2: Poster fan hero + episode chips
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: OBTokens.topBarHeight + OBTokens.spaceLG,
                bottom: 240,
              ),
              child: Transform.translate(
                offset: Offset(parallax * -50, 0),
                child: Stack(
                  children: [
                    PosterFanHero(
                      pageOffset: parallax,
                      isActive: isVisible && !_isExiting,
                      reduceMotion: _reduceMotion,
                    ),
                    FloatingEpisodeChips(
                      isVisible: isVisible && _currentPage == 1,
                      reduceMotion: _reduceMotion,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (index == 2) ...[
          // Page 3: Orbiting chips phone mockup
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: OBTokens.topBarHeight + OBTokens.spaceLG,
                bottom: 240,
              ),
              child: Transform.translate(
                offset: Offset(parallax * -50, 0),
                child: OrbitingChipsHero(
                  isActive: isVisible && !_isExiting,
                  reduceMotion: _reduceMotion,
                ),
              ),
            ),
          ),
        ],

        // ─── Bottom text content ───
        Positioned(
          bottom: 170, // lifted from 140 to give more breathing room
          left: OBTokens.spaceLG,
          right: OBTokens.spaceLG,
          child: Transform.translate(
            offset: Offset(parallax * -80, 0), // text parallax faster
            child: Opacity(
              opacity: (1.0 - parallax.abs() * 1.5).clamp(0.0, 1.0),
              child: OnboardingPageContent(
                title: _pages[index].title,
                subtitle: _pages[index].subtitle,
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
              // Page indicator
              AnimatedPageIndicator(
                pageCount: _pages.length,
                pageOffset: pageOffset,
              ),
              // CTA button
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
