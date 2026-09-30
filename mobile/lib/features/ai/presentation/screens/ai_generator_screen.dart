import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiGeneratorScreen extends ConsumerStatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  ConsumerState<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends ConsumerState<AiGeneratorScreen> with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  String _selectedGenre = 'Fantasy';
  String _selectedLanguage = 'English';
  bool _isGenerating = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final _genres = ['Fantasy', 'Sci-Fi', 'Mystery', 'Romance', 'Horror', 'Adventure'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine),
    );
  }

  void _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    _animationController.repeat(reverse: true);

    try {
      final genId = await ref.read(aiRepositoryProvider).generateStory(
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        prompt: prompt,
        genre: _selectedGenre,
        language: _selectedLanguage,
      );
      
      if (mounted) {
        context.pushReplacement('/ai/result?id=$genId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _animationController.stop();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
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
            Text('AI Story Hub', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isGenerating ? _buildGeneratingState() : _buildWelcomeState(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
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
              child: const Icon(Icons.auto_awesome, color: AppColors.primaryAccent, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'What story should we tell today?',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Describe the story, characters, or world you want to explore. I will generate a unique interactive experience for you.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5),
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
            Row(
              children: [
                _buildDropdown('Genre', _selectedGenre, _genres, (val) => setState(() => _selectedGenre = val!)),
                const SizedBox(width: 12),
                _buildDropdown('Language', _selectedLanguage, ['English', 'Hindi'], (val) => setState(() => _selectedLanguage = val!)),
              ],
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      color: _isGenerating ? AppColors.mutedText : AppColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText, size: 16),
          dropdownColor: AppColors.primarySurface,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryAccent.withValues(alpha: 0.8),
                        AppColors.primaryAccent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.7, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 40),
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
}
