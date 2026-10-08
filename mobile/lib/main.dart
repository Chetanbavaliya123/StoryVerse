import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'package:storyverse/core/routing/app_router.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  bool _done = false;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _checkCompletion();
    });
    _c.forward();
  }

  void _checkCompletion() async {
    if (_c.isCompleted && !_isAnimatingOut) {
      final authState = ref.read(authStateChangesProvider);
      
      bool readyToTransition = false;
      if (authState.isLoading) {
        return; // Wait for auth state
      } else if (authState.value != null) {
        // Logged in. Check if data is loaded.
        final trending = ref.read(trendingStoriesProvider);
        if (trending.isLoading || !trending.hasValue) {
          return; // Wait for data to load
        }
        readyToTransition = true;
      } else {
        // Not logged in. Can transition immediately.
        readyToTransition = true;
      }

      if (readyToTransition) {
        _isAnimatingOut = true;
        // Small buffer to ensure rendering is smooth
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _done = true);
      }
    }
  }

  @override
  void dispose() { 
    _c.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (_, __) => _checkCompletion());
    ref.listen(trendingStoriesProvider, (_, __) => _checkCompletion());

    return IgnorePointer(
      ignoring: _done,
      child: AnimatedScale(
        scale: _done ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: _done ? 0 : 1,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF000000), Color(0xFF2A0509)]),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                child: Container(
                  decoration: const BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: Color(0x40E53935), // Fixed alpha (~0.25) for better performance
                      blurRadius: 40, // Reduced from 60
                      spreadRadius: 4,
                    ),
                  ]),
                  child: Image.asset(
                    'assets/brand/icon_fg_1024.png', 
                    width: 140,
                    filterQuality: FilterQuality.medium, // Optimize image rendering
                  ),
                ),
                builder: (context, child) {
                  final logo = Curves.easeOut.transform((_c.value / 0.5).clamp(0, 1));
                  final text = Curves.easeIn.transform(((_c.value - 0.5) / 0.4).clamp(0, 1));
                  
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(
                      opacity: logo,
                      child: Transform.scale(
                        scale: 0.9 + 0.1 * logo,
                        child: child, // Use pre-built child here
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: text, 
                      child: const Text('STORYVERSE',
                        style: TextStyle(color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w800, letterSpacing: 6,
                          decoration: TextDecoration.none))),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: text * 0.7, 
                      child: const Text('Stories Beyond Limits',
                        style: TextStyle(color: Colors.white70, fontSize: 13,
                          letterSpacing: 2, decoration: TextDecoration.none))),
                  ]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
