import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:storyverse/core/routing/app_router.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const ProviderScope(child: RootApp()));
}

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // Underlying app mounts immediately with the splash screen
          // preventing lag spikes caused by dynamic mounting later.
          const StoryVerseApp(),

          // Splash Overlay coordinates the animation and waits for data
          const BrandSplash(),
        ],
      ),
    );
  }
}

class StoryVerseApp extends ConsumerWidget {
  const StoryVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'StoryVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}

class BrandSplash extends ConsumerStatefulWidget {
  const BrandSplash({super.key});
  @override
  ConsumerState<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends ConsumerState<BrandSplash>
    with TickerProviderStateMixin {
  // Intro animation: 1300ms (+0.3s added as requested for smooth cinematic entrance)
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  // Dedicated exit animation: 400ms for buttery-smooth dissolve
  late final AnimationController _exitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  bool _isAnimatingOut = false;
  bool _isCompletelyDone = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _checkCompletion();
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _isCompletelyDone = true);
      }
    });

    // Safety timeout fallback: if network/auth stalls, don't keep user blocked forever
    _fallbackTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && !_isAnimatingOut) {
        _triggerExit();
      }
    });

    _introController.forward();
  }

  void _triggerExit() {
    if (_isAnimatingOut) return;
    _isAnimatingOut = true;
    _fallbackTimer?.cancel();
    if (mounted) {
      _exitController.forward();
    }
  }

  void _checkCompletion() {
    if (_introController.isCompleted && !_isAnimatingOut) {
      final authState = ref.read(authStateChangesProvider);

      if (authState.isLoading) {
        return; // Brief wait for local auth state
      }

      _triggerExit();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompletelyDone) {
      return const SizedBox.shrink();
    }

    ref.listen(authStateChangesProvider, (_, _) => _checkCompletion());

    return IgnorePointer(
      ignoring: _isAnimatingOut,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _exitController]),
          child: Image.asset(
            'assets/brand/icon_fg_1024.png',
            width: 140,
            filterQuality: FilterQuality.medium,
          ),
          builder: (context, iconChild) {
            final introVal = _introController.value;
            final logoIntro = Curves.easeOutCubic.transform(
              (introVal / 0.55).clamp(0.0, 1.0),
            );
            final textIntro = Curves.easeOutCubic.transform(
              ((introVal - 0.40) / 0.50).clamp(0.0, 1.0),
            );

            final exitProgress = Curves.easeOutCubic.transform(
              _exitController.value,
            );
            final exitOpacity = (1.0 - exitProgress).clamp(0.0, 1.0);
            final exitScale = 1.0 + (0.04 * exitProgress);

            return Opacity(
              opacity: exitOpacity,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF000000), Color(0xFF2A0509)],
                  ),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: (0.92 + 0.08 * logoIntro) * exitScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: logoIntro,
                          child: Container(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x35E53935),
                                  blurRadius: 32,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: iconChild,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: textIntro,
                          child: const Text(
                            'STORYVERSE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: textIntro * 0.7,
                          child: const Text(
                            'Stories Beyond Limits',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
