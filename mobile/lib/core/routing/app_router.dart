import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:storyverse/core/widgets/main_scaffold.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';
import 'package:storyverse/features/authentication/presentation/screens/splash_screen.dart';
import 'package:storyverse/features/authentication/presentation/screens/onboarding_screen.dart';
import 'package:storyverse/features/authentication/presentation/screens/login_screen.dart';
import 'package:storyverse/features/authentication/presentation/screens/signup_screen.dart';
import 'package:storyverse/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:storyverse/features/home/presentation/screens/home_screen.dart';

import 'package:storyverse/features/discover/presentation/screens/discover_screen.dart';
import 'package:storyverse/features/search/presentation/screens/search_screen.dart';
import 'package:storyverse/features/story/presentation/screens/story_details_screen.dart';
import 'package:storyverse/features/story/presentation/screens/episodes_screen.dart';
import 'package:storyverse/features/video_player/presentation/screens/video_player_screen.dart';
import 'package:storyverse/features/library/presentation/screens/library_screen.dart';
import 'package:storyverse/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:storyverse/features/profile/presentation/screens/profile_screen.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_hub_screen.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_generator_screen.dart';
import 'package:storyverse/features/ai/presentation/screens/ai_result_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> _searchNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'search',
);
final GlobalKey<NavigatorState> _libraryNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'library');
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

CustomTransitionPage _buildPageWithTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool slideUp = false,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (slideUp) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      }
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading || !authState.hasValue) {
        return null;
      }

      final isAuth = authState.value != null;
      final isSplash = state.matchedLocation == '/';
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/onboarding';

      if (isSplash) {
        return isAuth ? '/home' : '/onboarding';
      }

      if (isLoggingIn) {
        return isAuth ? '/home' : null;
      }

      if (!isAuth) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Standalone routes (no bottom nav)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/story/:id',
        name: 'storyDetails',
        pageBuilder: (context, state) {
          final storyId = state.pathParameters['id']!;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: StoryDetailsScreen(storyId: storyId),
            slideUp: true,
          );
        },
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'episodes',
            name: 'episodes',
            pageBuilder: (context, state) {
              final storyId = state.pathParameters['id']!;
              return _buildPageWithTransition(
                context: context,
                state: state,
                child: EpisodesScreen(storyId: storyId),
                slideUp: true,
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/player/:storyId/:episodeId',
        name: 'videoPlayer',
        pageBuilder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          final episodeId = state.pathParameters['episodeId']!;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: VideoPlayerScreen(storyId: storyId, episodeId: episodeId),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ai',
        name: 'aiHub',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AiHubScreen(),
          slideUp: true,
        ),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'assistant',
            name: 'aiAssistant',
            builder: (context, state) => const AiAssistantScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'generator',
            name: 'aiGenerator',
            builder: (context, state) => const AiGeneratorScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'result',
            name: 'aiResult',
            pageBuilder: (context, state) {
              final generationId = state.uri.queryParameters['id'] ?? '';
              return _buildPageWithTransition(
                context: context,
                state: state,
                child: AiResultScreen(generationId: generationId),
                slideUp: true,
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/discover',
        name: 'discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                name: 'library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
