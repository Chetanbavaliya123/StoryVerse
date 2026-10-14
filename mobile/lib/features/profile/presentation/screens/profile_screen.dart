import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/models/user_model.dart';
import 'package:storyverse/core/localization/locale_provider.dart';
import 'package:storyverse/core/theme/theme_provider.dart';
import 'package:storyverse/features/authentication/data/auth_repository.dart';
import 'package:storyverse/features/authentication/presentation/providers/auth_provider.dart';
import 'package:storyverse/features/profile/data/user_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  static const List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Apollo&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka&backgroundColor=d1d4f9',
    'https://api.dicebear.com/7.x/bottts/png?seed=Cyber&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Luna&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/bottts/png?seed=Valkyrie&backgroundColor=c0aede',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getInitials(String name, String email) {
    if (name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).value ?? FirebaseAuth.instance.currentUser;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.value;

    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : (authUser?.displayName?.isNotEmpty == true
            ? authUser!.displayName!
            : (authUser?.email?.split('@').first ?? 'StoryVerse User'));

    final displayEmail = profile?.email.isNotEmpty == true
        ? profile!.email
        : (authUser?.email ?? '');

    final photoUrl = (profile?.photoUrl?.isNotEmpty == true)
        ? profile!.photoUrl
        : authUser?.photoURL;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    final selectedLanguage = (profile?.preferences['language'] as String?) ?? 'en';
    final languageName = _getLanguageDisplayName(selectedLanguage);

    final selectedTheme = (profile?.preferences['theme'] as String?) ?? 'OLED Pure Black';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Quick Preferences',
            onPressed: () => _showPreferencesSheet(context, profile),
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
              padding: const EdgeInsets.only(top: 100, bottom: 32),
              decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryAccent.withValues(alpha: 0.18),
                            AppColors.primaryBackground,
                          ],
                        ),
                      ),
                      child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showEditProfileModal(context, profile, authUser),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryAccent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent.withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                            child: !hasPhoto
                                ? Text(
                                    _getInitials(displayName, displayEmail),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryAccent,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
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
                        _buildListTile(
                          Icons.person_outline_rounded,
                          'Personal Information',
                          subtitle: 'Edit name & profile photo',
                          onTap: () => _showEditProfileModal(context, profile, authUser),
                        ),
                        _buildListTile(
                          Icons.security_outlined,
                          'Security & Privacy',
                          subtitle: 'Password reset & account safety',
                          onTap: () => _showSecurityPrivacyModal(context, authUser),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildAnimatedSection(
                    index: 1,
                    child: _buildSectionGroup(
                      title: 'Preferences',
                      children: [
                        _buildListTile(
                          Icons.notifications_outlined,
                          'Notifications',
                          subtitle: 'Alerts, new episodes & messages',
                          onTap: () => _showNotificationsModal(context, profile),
                        ),
                        _buildListTile(
                          Icons.language_outlined,
                          'Language & Region',
                          subtitle: languageName,
                          onTap: () => _showLanguageModal(context, profile),
                        ),
                        _buildListTile(
                          Icons.dark_mode_outlined,
                          'Theme Settings',
                          subtitle: selectedTheme,
                          onTap: () => _showThemeModal(context, profile),
                        ),
                        _buildListTile(
                          Icons.tune_rounded,
                          'Content & Onboarding Preferences',
                          subtitle: 'Preferred language & story genres',
                          onTap: () => context.push('/onboarding'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildAnimatedSection(
                    index: 2,
                    child: _buildSectionGroup(
                      title: 'Library & Shortcuts',
                      children: [
                        _buildListTile(
                          Icons.auto_awesome,
                          'AI Story Hub',
                          subtitle: 'Generate & create micro-stories',
                          isAccent: true,
                          onTap: () => context.push('/ai'),
                        ),
                        _buildListTile(
                          Icons.history_rounded,
                          'Viewing History',
                          subtitle: 'Episodes & stories you watched',
                          onTap: () => context.push('/library?tab=0'),
                        ),
                        _buildListTile(
                          Icons.favorite_outline_rounded,
                          'Favorites',
                          subtitle: 'Liked and recommended stories',
                          onTap: () => context.push('/library?tab=1'),
                        ),
                        _buildListTile(
                          Icons.bookmark_outline_rounded,
                          'My List / Saved Stories',
                          subtitle: 'Saved for later watching',
                          onTap: () => context.push('/library?tab=2'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildAnimatedSection(
                    index: 3,
                    child: _buildSectionGroup(
                      title: 'Support & Info',
                      children: [
                        _buildListTile(
                          Icons.help_outline_rounded,
                          'Help Center & FAQs',
                          subtitle: 'Frequently asked questions & support',
                          onTap: () => _showHelpCenterModal(context),
                        ),
                        _buildListTile(
                          Icons.info_outline_rounded,
                          'About StoryVerse',
                          subtitle: 'v1.0.0 • Terms & Privacy Policy',
                          onTap: () => _showAboutModal(context),
                        ),
                        _buildListTile(
                          Icons.logout_rounded,
                          'Log Out',
                          subtitle: 'Sign out of this device',
                          isDestructive: true,
                          onTap: () => _confirmLogout(context),
                        ),
                        _buildListTile(
                          Icons.delete_forever_rounded,
                          'Delete Account',
                          subtitle: 'Permanently remove your account and all data',
                          isDestructive: true,
                          onTap: () => _confirmDeleteAccount(context),
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

  // --- ACTIONS & MODAL SHEETS ---

  void _showEditProfileModal(
    BuildContext context,
    UserModel? userModel,
    User? authUser,
  ) {
    final currentName = userModel?.name.isNotEmpty == true
        ? userModel!.name
        : (authUser?.displayName ?? '');
    final currentPhoto = (userModel?.photoUrl?.isNotEmpty == true)
        ? userModel!.photoUrl!
        : (authUser?.photoURL ?? '');

    final nameController = TextEditingController(text: currentName);
    final photoController = TextEditingController(text: currentPhoto);
    String selectedAvatar = currentPhoto;
    bool isSaving = false;
    bool isUploadingPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Update your personal information and cinema avatar',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar Preview & Presets
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: selectedAvatar.isNotEmpty
                                ? NetworkImage(selectedAvatar)
                                : null,
                            child: selectedAvatar.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose an Avatar Preset',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: _presetAvatars.map((url) {
                              final isSelected = selectedAvatar == url;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedAvatar = url;
                                    photoController.text = url;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryAccent
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(url),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Display Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.primarySurface,
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: AppColors.mutedText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryAccent),
                        ),
                        prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Custom Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primarySurface,
                        ),
                        icon: isUploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryAccent,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: AppColors.primaryAccent,
                                size: 20,
                              ),
                        label: Text(
                          isUploadingPhoto
                              ? 'Uploading to Storage...'
                              : 'Choose Photo from Gallery',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: isUploadingPhoto
                            ? null
                            : () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 600,
                                  maxHeight: 600,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setModalState(() => isUploadingPhoto = true);
                                  try {
                                    final bytes = await image.readAsBytes();
                                    final mime =
                                        image.mimeType ?? 'image/jpeg';
                                    final uploadedUrl = await ref
                                        .read(userRepositoryProvider)
                                        .uploadProfileImageBytes(
                                          bytes: bytes,
                                          contentType: mime,
                                        );
                                    if (uploadedUrl != null) {
                                      setModalState(() {
                                        selectedAvatar = uploadedUrl;
                                        photoController.text = uploadedUrl;
                                        isUploadingPhoto = false;
                                      });
                                    }
                                  } catch (e) {
                                    setModalState(
                                        () => isUploadingPhoto = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Upload failed: $e'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Display name cannot be empty'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  await ref.read(userRepositoryProvider).updateProfile(
                                        name: newName,
                                        photoUrl: selectedAvatar,
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profile updated successfully'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _showSecurityPrivacyModal(BuildContext context, User? authUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Security & Privacy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account: ${authUser?.email ?? "Not signed in"}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryAccent),
                  title: const Text(
                    'Reset Password',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Receive a secure password reset link via email',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (authUser?.email == null || authUser!.email!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No email associated with this account'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(authControllerProvider.notifier)
                          .sendPasswordResetEmail(authUser.email!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset link sent to ${authUser.email}',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to send reset email: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your viewing history and personal preferences are stored securely and isolated to your private account.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsModal(BuildContext context, UserModel? userModel) {
    final prefs = userModel?.preferences['notifications'] as Map<String, dynamic>? ?? {};
    bool notifyNewEpisodes = prefs['newEpisodes'] ?? true;
    bool notifyTrending = prefs['trending'] ?? true;
    bool notifyAiHub = prefs['aiHub'] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Notification Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure what notifications and alerts you receive',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),

                  SwitchListTile(
                    title: const Text(
                      'New Episode Releases',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Get notified when continuing stories release episodes',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    value: notifyNewEpisodes,
                    activeThumbColor: AppColors.primaryAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() => notifyNewEpisodes = val);
                      _saveNotificationPrefs(notifyNewEpisodes, notifyTrending, notifyAiHub);
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Trending & Popular Stories',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Weekly digest of top-ranked micro-dramas',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    value: notifyTrending,
                    activeThumbColor: AppColors.primaryAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() => notifyTrending = val);
                      _saveNotificationPrefs(notifyNewEpisodes, notifyTrending, notifyAiHub);
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'AI Story Hub Recommendations',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'AI generated micro-drama suggestions',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    value: notifyAiHub,
                    activeThumbColor: AppColors.primaryAccent,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() => notifyAiHub = val);
                      _saveNotificationPrefs(notifyNewEpisodes, notifyTrending, notifyAiHub);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/notifications');
                      },
                      icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                      label: const Text(
                        'Open Notification Center',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveNotificationPrefs(bool episodes, bool trending, bool ai) {
    ref.read(userRepositoryProvider).updateSinglePreference('notifications', {
      'newEpisodes': episodes,
      'trending': trending,
      'aiHub': ai,
    });
  }

  void _showLanguageModal(BuildContext context, UserModel? userModel) {
    final current = (userModel?.preferences['language'] as String?) ?? 'en';
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
      {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
      {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Language & Region',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred language for stories and UI',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ...languages.map((lang) {
                    final isSelected = current == lang['code'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryAccent.withValues(alpha: 0.12)
                            : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryAccent : AppColors.border,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          lang['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          lang['native']!,
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent)
                            : null,
                        onTap: () {
                          ref
                              .read(userRepositoryProvider)
                              .updateSinglePreference('language', lang['code']);
                          ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(lang['code']!);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language set to ${lang['name']}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showThemeModal(BuildContext context, UserModel? userModel) {
    final current = (userModel?.preferences['theme'] as String?) ?? 'OLED Pure Black';
    final themes = [
      {
        'name': 'OLED Pure Black',
        'desc': 'Deep pitch black for high contrast & maximum OLED battery efficiency',
        'color': const Color(0xFF000000),
      },
      {
        'name': 'Cinematic Charcoal',
        'desc': 'Moody dark studio tone with soft charcoal accents',
        'color': const Color(0xFF151515),
      },
      {
        'name': 'Dark Crimson',
        'desc': 'StoryVerse dark crimson tint with subtle red ambient undertones',
        'color': const Color(0xFF1C0A0A),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Theme Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize the dark surface tone of StoryVerse',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...themes.map((theme) {
                final isSelected = current == theme['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryAccent.withValues(alpha: 0.12)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryAccent : AppColors.border,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                    ),
                    title: Text(
                      theme['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      theme['desc'] as String,
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent)
                        : null,
                    onTap: () {
                      ref
                          .read(userRepositoryProvider)
                          .updateSinglePreference('theme', theme['name']);
                      ref
                          .read(appThemeProvider.notifier)
                          .setTheme(theme['name'] as String);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theme set to ${theme['name']}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPreferencesSheet(BuildContext context, UserModel? profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Quick Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: Colors.white),
                title: const Text('Notifications', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                onTap: () {
                  Navigator.pop(ctx);
                  _showNotificationsModal(context, profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined, color: Colors.white),
                title: const Text('Language & Region', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLanguageModal(context, profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined, color: Colors.white),
                title: const Text('Theme Settings', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                onTap: () {
                  Navigator.pop(ctx);
                  _showThemeModal(context, profile);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showHelpCenterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Help Center & Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find answers or get direct assistance',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/ai');
                  },
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  label: const Text(
                    'Chat with AI Assistant',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: const [
                    _FaqTile(
                      question: 'How do I resume watching where I left off?',
                      answer:
                          'StoryVerse automatically saves your exact timestamp every few seconds and stores it in your private Watch History. Visit the Home screen "Continue Watching" row or your Library to jump straight back in.',
                    ),
                    _FaqTile(
                      question: 'How do Shorts connect to full stories?',
                      answer:
                          'Every Short in the Shorts discovery feed features a "Watch Now" button. Tapping it pauses the short and directs you straight to that story\'s details and starting episode.',
                    ),
                    _FaqTile(
                      question: 'What benefits are included in Premium?',
                      answer:
                          'Premium members enjoy ad-free viewing, early access to new episode drops, unlimited AI micro-drama generations, and 4K cinema quality playback.',
                    ),
                    _FaqTile(
                      question: 'How do I contact customer support?',
                      answer:
                          'You can reach our dedicated support team directly at support@storyverse.app. We respond to all queries within 24 hours.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.movie_filter_rounded,
                  color: AppColors.primaryAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'StoryVerse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0 (Build 2026.10)',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'StoryVerse is the next-generation OTT micro-drama and AI-powered storytelling platform designed for mobile-first cinematic immersion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _showLegalDialog(
                      context,
                      'Terms of Service',
                      'Welcome to StoryVerse. By accessing or using our services, micro-dramas, and AI storytelling tools, you agree to comply with our community terms, respect intellectual property, and enjoy content responsibly.',
                    ),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Colors.white38)),
                  TextButton(
                    onPressed: () => _showLegalDialog(
                      context,
                      'Privacy Policy',
                      'Your privacy is essential to us. StoryVerse uses Firestore and Firebase Auth to securely isolate your viewing history, favorites, and profile preferences. We never share or sell personal data to third parties.',
                    ),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showLegalDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          body,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of StoryVerse? Your private watch history and library will be securely saved.',
          style: TextStyle(color: AppColors.secondaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // Invalidate user-specific state for strict data isolation
              ref.invalidate(continueWatchingProvider);
              ref.invalidate(watchHistoryStoriesProvider);
              ref.invalidate(favoriteStoriesProvider);
              ref.invalidate(libraryStoriesProvider);
              ref.invalidate(savedStoriesProvider);
              ref.invalidate(aiStoriesProvider);

              await ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final isPasswordUser =
        authUser?.providerData.any((p) => p.providerId == 'password') ?? false;
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you sure you want to permanently delete your account? This action is irreversible and complies with Google Play Store data safety standards.\n\nAll your data will be immediately and permanently removed:',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('• Personal profile and avatar',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text('• Complete watch history and playback progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text('• Favorites and saved library stories',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text('• Generated AI stories and custom scripts',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text('• Notifications and active session credentials',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    if (isPasswordUser) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Enter your password to verify:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Current Password',
                          hintStyle: const TextStyle(color: AppColors.mutedText),
                          filled: true,
                          fillColor: AppColors.primarySurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (isPasswordUser &&
                              passwordController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorMessage =
                                  'Password is required to confirm deletion.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isDeleting = true;
                            errorMessage = null;
                          });

                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .deleteAccount(
                                  password: isPasswordUser
                                      ? passwordController.text.trim()
                                      : null,
                                );

                            ref.invalidate(continueWatchingProvider);
                            ref.invalidate(watchHistoryStoriesProvider);
                            ref.invalidate(favoriteStoriesProvider);
                            ref.invalidate(libraryStoriesProvider);
                            ref.invalidate(savedStoriesProvider);
                            ref.invalidate(aiStoriesProvider);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Your account and data have been permanently deleted.',
                                  ),
                                  backgroundColor: AppColors.primarySurface,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              context.go('/onboarding');
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isDeleting = false;
                              if (e.code == 'wrong-password') {
                                errorMessage =
                                    'Incorrect password. Please verify and try again.';
                              } else if (e.code == 'requires-recent-login') {
                                errorMessage =
                                    'Please log out and log back in before deleting your account for security verification.';
                              } else {
                                errorMessage =
                                    e.message ?? 'Failed to delete account.';
                              }
                            });
                          } catch (e) {
                            setDialogState(() {
                              isDeleting = false;
                              errorMessage = 'Error: $e';
                            });
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Permanently Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'hi':
        return 'Hindi (हिन्दी)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      case 'mr':
        return 'Marathi (मराठी)';
      case 'bn':
        return 'Bengali (বাংলা)';
      case 'ta':
        return 'Tamil (தமிழ்)';
      case 'te':
        return 'Telugu (తెలుగు)';
      case 'en':
      default:
        return 'English';
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final delay = index * 0.1;
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _buildSectionGroup({
    required String title,
    required List<Widget> children,
  }) {
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
        Material(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 56,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isAccent = false,
  }) {
    final color = isDestructive
        ? AppColors.primaryAccent
        : (isAccent ? Colors.amber : Colors.white);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.primaryAccent.withValues(alpha: 0.1)
              : (isAccent
                  ? Colors.amber.withValues(alpha: 0.1)
                  : AppColors.secondarySurface),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: isAccent ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
              size: 20,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primaryAccent,
          collapsedIconColor: Colors.white54,
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
              child: Text(
                answer,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
