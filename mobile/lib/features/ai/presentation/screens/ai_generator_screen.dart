import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storyverse/core/models/ai_generation_model.dart';

class AiGeneratorScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const AiGeneratorScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends ConsumerState<AiGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  String _selectedGenre = 'Fantasy';
  String _selectedLanguage = 'English';
  bool _isGenerating = false;
  AiGenerationModel? _generatedStory;
  bool _isSaving = false;
  bool _isSaved = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final _genres = [
    'Fantasy',
    'Sci-Fi',
    'Mystery',
    'Romance',
    'Horror',
    'Adventure',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  void _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    if (_isGenerating) return;

    FocusScope.of(context).unfocus(); // Close keyboard

    debugPrint('[AI] SEND pressed');
    final stopwatch = Stopwatch()..start();

    setState(() => _isGenerating = true);
    _animationController.repeat(reverse: true);

    try {
      debugPrint('[AI] Calling generateStory in repository');
      debugPrint(
        '[AI] Generation successful. Elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );

      final storyModel = await ref.read(aiRepositoryProvider).generateStory(
            userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
            prompt: prompt,
            genre: _selectedGenre,
            language: _selectedLanguage,
          );
      
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _animationController.stop();
          _generatedStory = storyModel;
          _isSaved = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint(
        '[AI] Generation failed: $e. Elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      debugPrint(
        '[AI] Resetting loading state. Elapsed: ${stopwatch.elapsedMilliseconds}ms',
      );
      if (mounted && _generatedStory == null) {
        setState(() {
          _isGenerating = false;
          _animationController.stop();
        });
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = PopScope(
      canPop: _generatedStory == null && !_isGenerating,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_generatedStory != null) {
          setState(() {
            _generatedStory = null;
            _promptController.clear();
          });
        } else if (_isGenerating) {
          // If we want to allow cancel, we can do it here. 
          // For now just ignore back button while generating.
        }
      },
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _generatedStory != null
                  ? _buildResultState()
                  : (_isGenerating
                        ? _buildGeneratingState()
                        : _buildWelcomeState()),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: _isGenerating || _generatedStory != null
                ? const SizedBox(width: double.infinity)
                : _buildInputArea(),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primarySurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Story Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      key: const ValueKey('welcome'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What story should we tell today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Describe the story, characters, or world you want to explore. I will generate a unique interactive experience for you.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSelectionButton(
                    label: 'Genre',
                    value: _selectedGenre,
                    icon: Icons.movie_filter_outlined,
                    onTap: () => _showSelectionSheet(
                      title: 'Select Genre',
                      items: _genres,
                      selectedValue: _selectedGenre,
                      onSelected: (val) => setState(() => _selectedGenre = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSelectionButton(
                    label: 'Language',
                    value: _selectedLanguage,
                    icon: Icons.language,
                    onTap: () => _showSelectionSheet(
                      title: 'Select Language',
                      items: ['English', 'Hindi'],
                      selectedValue: _selectedLanguage,
                      onSelected: (val) =>
                          setState(() => _selectedLanguage = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _promptController,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type your prompt here...',
                        hintStyle: TextStyle(color: AppColors.mutedText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isGenerating ? null : _generate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isGenerating
                          ? AppColors.mutedText
                          : AppColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == selectedValue;
                    return GestureDetector(
                      onTap: () {
                        onSelected(item);
                        context.pop();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent.withValues(alpha: 0.1)
                              : AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryAccent
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryAccent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      key: const ValueKey('generating'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '"${_promptController.text}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryAccent.withValues(alpha: 0.9),
                        AppColors.primaryAccent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.6, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Creating your story...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'The AI is weaving magic. This usually takes a few seconds.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    final gen = _generatedStory!;
    final storyText = gen.storyContent ?? 'No content generated.';

    return Container(
      key: const ValueKey('result'),
      width: double.infinity,
      color: AppColors.primaryBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        gen.genre.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _generatedStory = null;
                        _promptController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gen.title ?? 'Untitled Story',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      storyText,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_isSaved) return;
                              setState(() => _isSaving = true);
                              try {
                                await ref
                                    .read(aiRepositoryProvider)
                                    .saveToLibrary(gen);
                                ref.invalidate(libraryStoriesProvider);
                                if (mounted) {
                                  setState(() {
                                    _isSaving = false;
                                    _isSaved = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved to your Library!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to save.'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved
                            ? AppColors.primarySurface
                            : AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: _isSaved
                              ? const BorderSide(color: AppColors.primaryAccent)
                              : BorderSide.none,
                        ),
                        elevation: _isSaved ? 0 : 8,
                        shadowColor: AppColors.primaryAccent.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isSaved
                                  ? Icons.check_circle
                                  : Icons.bookmark_add,
                              color: _isSaved
                                  ? AppColors.primaryAccent
                                  : Colors.white,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : _isSaved
                            ? 'Saved to Library'
                            : 'Save to Library',
                        style: TextStyle(
                          color: _isSaved
                              ? AppColors.primaryAccent
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
