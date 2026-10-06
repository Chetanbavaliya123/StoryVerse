import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';

import 'onboarding/design_tokens.dart';
import 'login/login_background.dart';
import 'login/premium_text_field.dart';
import 'login/premium_primary_button.dart';
import 'login/google_sign_in_button.dart';
import 'login/glass_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entryController;
  late final AnimationController _exitController;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: OBTokens.bgDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      showGlassToast(context, message: 'Please enter both email and password.');
      return;
    }

    FocusScope.of(context).unfocus();

    ref
        .read(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _onGoogleSignIn() {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('invalid-credential') ||
        errorString.contains('wrong-password') ||
        errorString.contains('user-not-found')) {
      return 'Invalid email or password.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Try again later.';
    } else if (errorString.contains('user-disabled')) {
      return 'Account disabled. Contact support.';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    return 'An error occurred during sign in.';
  }

  void _navigateToSignUp() {
    context.pushReplacement('/signup');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        showGlassToast(
          context,
          message: _getFriendlyErrorMessage(next.error),
          actionLabel: 'RETRY',
          onAction: _onSignIn,
        );
      } else if (!next.hasError &&
          !next.isLoading &&
          previous?.isLoading == true) {
        if (!_isExiting && mounted) {
          setState(() => _isExiting = true);
          _exitController.forward();
        }
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // UI state based on keyboard
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    // On short screens (e.g. <640px) we treat it aggressively like keyboard open to save space
    final isShortScreen = MediaQuery.of(context).size.height < 640;
    final compactMode = isKeyboardOpen || isShortScreen;

    return ListenableBuilder(
      listenable: Listenable.merge([_emailController, _passwordController]),
      builder: (context, _) {
        final hasContent =
            _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty;

        return Scaffold(
          backgroundColor: OBTokens.bgDeep,
          // IMPORTANT: Let the column handle the layout flexibly when keyboard opens
          resizeToAvoidBottomInset: true,
          body: AnimatedBuilder(
            animation: _exitController,
            builder: (context, child) {
              if (_exitController.value > 0) {
                final exitScale = 1.0 + _exitController.value * 0.05;
                final exitOpacity = 1.0 - _exitController.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Color.lerp(
                        OBTokens.bgDeep,
                        OBTokens.crimsonStart.withValues(alpha: 0.2),
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
                  ],
                );
              }
              return child!;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Background
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.0, 0.4),
                  ),
                  child: const LoginBackground(),
                ),

                // Layer 2: Main Layout (Fixed, no scroll)
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OBTokens.spaceLG,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: OBTokens.spaceSM),

                            // 1. Top Brand Row
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _entryController,
                                curve: const Interval(0.0, 0.5),
                              ),
                              child: AnimatedScale(
                                scale: compactMode ? 0.8 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: _buildBrandRow(),
                              ),
                            ),

                            // 2. Flexible spacer (flex 1)
                            Spacer(flex: compactMode ? 1 : 1),

                            // 3. Heading + Subtitle
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _entryController,
                                      curve: const Interval(
                                        0.2,
                                        0.7,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _entryController,
                                  curve: const Interval(0.2, 0.7),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        style: TextStyle(
                                          fontSize: compactMode ? 26 : 32,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.6,
                                          color: OBTokens.textPrimary,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Welcome '),
                                            ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  const LinearGradient(
                                                    colors: [
                                                      OBTokens.crimsonStart,
                                                      OBTokens.crimsonEnd,
                                                    ],
                                                  ).createShader(bounds),
                                              child: const Text(
                                                'back',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topCenter,
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          opacity: compactMode ? 0.0 : 1.0,
                                          child: compactMode
                                              ? const SizedBox.shrink()
                                              : const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: Text(
                                                    'Sign in to continue your storytelling journey',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      height: 1.5,
                                                      color: OBTokens.textMuted,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: compactMode ? 16 : 32),

                            // 4. Fields
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _entryController,
                                      curve: const Interval(
                                        0.3,
                                        0.8,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _entryController,
                                  curve: const Interval(0.3, 0.8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    PremiumTextField(
                                      label: 'EMAIL ADDRESS',
                                      controller: _emailController,
                                      icon: Icons.mail_outline_rounded,
                                      hintText: 'Enter your email',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return null;
                                        }
                                        if (!val.contains('@') ||
                                            !val.contains('.')) {
                                          return 'Invalid email format';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    PremiumTextField(
                                      label: 'PASSWORD',
                                      controller: _passwordController,
                                      icon: Icons.lock_outline_rounded,
                                      hintText: 'Enter your password',
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _onSignIn(),
                                    ),
                                    const SizedBox(height: 12),
                                    // 5. Forgot Password
                                    GestureDetector(
                                      onTap: () =>
                                          context.push('/forgot-password'),
                                      behavior: HitTestBehavior.opaque,
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: OBTokens.crimsonStart,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: compactMode ? 24 : 32),

                            // 6. Sign In Button
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _entryController,
                                      curve: const Interval(
                                        0.4,
                                        0.9,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _entryController,
                                  curve: const Interval(0.4, 0.9),
                                ),
                                child: PremiumPrimaryButton(
                                  text: 'Sign In',
                                  isLoading: isLoading,
                                  isDisabled: !hasContent,
                                  onPressed: _onSignIn,
                                ),
                              ),
                            ),

                            // 7 & 8. Google section (Hide when compact)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: compactMode ? 0.0 : 1.0,
                                child: compactMode
                                    ? const SizedBox.shrink()
                                    : SlideTransition(
                                        position:
                                            Tween<Offset>(
                                              begin: const Offset(0, 0.5),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: _entryController,
                                                curve: const Interval(
                                                  0.5,
                                                  1.0,
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              ),
                                            ),
                                        child: FadeTransition(
                                          opacity: CurvedAnimation(
                                            parent: _entryController,
                                            curve: const Interval(0.5, 1.0),
                                          ),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 24),
                                              const GradientDivider(
                                                text: 'OR CONTINUE WITH',
                                              ),
                                              const SizedBox(height: 24),
                                              GoogleSignInButton(
                                                isLoading: isLoading,
                                                onPressed: _onGoogleSignIn,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            // 9. Flexible spacer
                            Spacer(flex: compactMode ? 1 : 1),

                            // 10. Footer
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _entryController,
                                curve: const Interval(0.7, 1.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Don't have an account?",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: OBTokens.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: _navigateToSignUp,
                                          behavior: HitTestBehavior.opaque,
                                          child: ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                                  colors: [
                                                    OBTokens.crimsonStart,
                                                    OBTokens.crimsonEnd,
                                                  ],
                                                ).createShader(bounds),
                                            child: const Text(
                                              'Create account',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Optional terms on tall screens
                                    if (MediaQuery.of(context).size.height >
                                            700 &&
                                        !isKeyboardOpen)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: Text(
                                          'By continuing, you agree to our Terms & Privacy Policy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(
                                              0xFF71717A,
                                            ), // zinc-500
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact glowing SV logo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: OBTokens.glassWhiteFill,
            border: Border.all(color: OBTokens.glassWhiteBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: OBTokens.crimsonStart.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [OBTokens.crimsonStart, OBTokens.crimsonEnd],
            ).createShader(bounds),
            child: const Text(
              'SV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Wordmark
        Text(
          'STORYVERSE',
          style: OBTokens.posterTitleStyle.copyWith(
            fontSize: 16,
            letterSpacing: 2.4,
          ),
        ),
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(left: 4, top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OBTokens.crimsonStart,
            boxShadow: [
              BoxShadow(
                color: OBTokens.crimsonStart.withValues(alpha: 0.8),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
