import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/primary_button.dart';
import 'package:storyverse/core/widgets/storyverse_logo.dart';

import 'package:storyverse/core/widgets/network_image_with_fallback.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Discover infinite worlds',
      'subtitle':
          'Immerse yourself in cinematic storytelling crafted for the modern screen.',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBEK1XA36MYrEzmsfpqmWPIezqFAfe0yw2nqrzWEHFOUOIES3muePQ6jqYo9mlnH-5WImT17li-XauhNHgPLcwcGTNndH0iklEF_-ITv4sZWUAYrNwXHV8P3r3C4HXXjqXf7g-EkfmkUq8IiZ3JVyZ013tp7FndF2GS9LhAsCnqt5zqBYghcWRafvQYOjo5yw8a90QU-6yndlWz2YWrkptGavR1XIo-Th0qetAY49pDpqP5LBheBlep5w',
    },
    {
      'title': 'Engaging visual series',
      'subtitle':
          'Follow episodic content that keeps you coming back for the next chapter.',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC1_Y0QdE8N-3w18Z3fWn2vDkYx_g4q79YVjK1sL0Jq_v4zZ1jG9tX_x-R0H6pW5dYyK6q8z4E_7X9Vp8q_o3d7G6k_q9x8p5d_x_1Fw4q_x3D6vL9H_z5qY3tK7y-R2gD_0kY8q3w_v2H9c4', // Fallback or placeholder for page 2 if needed
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go('/login');
  }

  void _onNext() {
    if (_currentIndex < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // Background Imagery & Gradients
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageWithFallback(
                    imageUrl:
                        _onboardingData[index]['image'] ??
                        _onboardingData[0]['image']!,
                    fit: BoxFit.cover,
                  ),
                  // Dark Gradients for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          Colors.black,
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Mini Wordmark
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const StoryVerseLogo(size: 28),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'STORYVERSE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.4, // 0.2em
                              color: AppColors.primaryText,
                            ),
                          ),
                          const Text(
                            '.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.4,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),

                      // Skip Button
                      if (_currentIndex < _onboardingData.length - 1)
                        TextButton(
                          onPressed: _onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48), // Placeholder to balance row
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _onboardingData[_currentIndex]['title']!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _onboardingData[_currentIndex]['subtitle']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Indicators & Next Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              _onboardingData.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 8),
                                height: 4,
                                width: _currentIndex == index ? 24 : 12,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? AppColors.primaryAccent
                                      : AppColors.secondaryText.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: PrimaryButton(
                              text: _currentIndex == _onboardingData.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              onPressed: _onNext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
