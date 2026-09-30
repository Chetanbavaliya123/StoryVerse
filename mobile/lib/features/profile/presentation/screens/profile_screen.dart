import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // Header / Avatar Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryAccent.withOpacity(0.2),
                    AppColors.primaryBackground,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryAccent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 47,
                      backgroundColor: AppColors.primarySurface,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? Text(
                              (user?.displayName ?? user?.email ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? user?.email?.split('@').first ?? 'Storyverse User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text('Premium Member', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildAnimatedSection(
                    index: 0,
                    child: _buildSectionGroup(
                      title: 'Account',
                      children: [
                        _buildListTile(Icons.person_outline, 'Personal Information'),
                        _buildListTile(Icons.payment_outlined, 'Subscription & Billing'),
                        _buildListTile(Icons.security_outlined, 'Security & Privacy'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildAnimatedSection(
                    index: 1,
                    child: _buildSectionGroup(
                      title: 'Preferences',
                      children: [
                        _buildListTile(Icons.notifications_outlined, 'Notifications'),
                        _buildListTile(Icons.language_outlined, 'Language & Region'),
                        _buildListTile(Icons.dark_mode_outlined, 'Theme Settings'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildAnimatedSection(
                    index: 2,
                    child: _buildSectionGroup(
                      title: 'Tools',
                      children: [
                        _buildListTile(
                          Icons.auto_awesome, 
                          'AI Story Hub', 
                          isAccent: true,
                          onTap: () => context.push('/ai'),
                        ),
                        _buildListTile(Icons.history_rounded, 'Viewing History', onTap: () => context.push('/library')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildAnimatedSection(
                    index: 3,
                    child: _buildSectionGroup(
                      title: 'About',
                      children: [
                        _buildListTile(Icons.help_outline, 'Help Center'),
                        _buildListTile(Icons.info_outline, 'About StoryVerse'),
                        _buildListTile(
                          Icons.logout_rounded, 
                          'Log Out', 
                          isDestructive: true,
                          onTap: () async {
                            await ref.read(authControllerProvider.notifier).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  Widget _buildSectionGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, thickness: 1, color: AppColors.border, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap, bool isDestructive = false, bool isAccent = false}) {
    final color = isDestructive 
        ? AppColors.primaryAccent 
        : (isAccent ? Colors.amber : Colors.white);
        
    return ListTile(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title is coming soon!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.primaryAccent.withOpacity(0.1) : (isAccent ? Colors.amber.withOpacity(0.1) : AppColors.secondarySurface),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: isAccent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isDestructive ? null : const Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
