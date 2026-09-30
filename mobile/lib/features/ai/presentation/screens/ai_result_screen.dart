import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AiResultScreen extends ConsumerStatefulWidget {
  final String generationId;

  const AiResultScreen({super.key, required this.generationId});

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  bool _isPaused = false;
  String _ttsState = 'stopped'; // playing, paused, stopped
  
  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() { _ttsState = 'playing'; });
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() { _ttsState = 'stopped'; });
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() { _ttsState = 'stopped'; });
    });

    _flutterTts.setPauseHandler(() {
      if (mounted) setState(() { _ttsState = 'paused'; });
    });

    _flutterTts.setContinueHandler(() {
      if (mounted) setState(() { _ttsState = 'playing'; });
    });
    
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() { _ttsState = 'stopped'; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('TTS Error: $msg')));
    });
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _speak(String text, String language) async {
    if (_ttsState == 'playing') return; // already playing
    
    try {
      final availableLanguages = List<String>.from(await _flutterTts.getLanguages);
      String targetLang = language.toLowerCase().contains('hindi') ? 'hi-IN' : 'en-US';
      
      if (!availableLanguages.contains(targetLang)) {
         if (targetLang == 'hi-IN' && availableLanguages.contains('hin-IND')) {
           targetLang = 'hin-IND';
         } else if (targetLang == 'hi-IN' && availableLanguages.contains('hi_IN')) {
           targetLang = 'hi_IN';
         } else if (availableLanguages.contains('en-US')) {
           targetLang = 'en-US';
         } else if (availableLanguages.isNotEmpty) {
           targetLang = availableLanguages.first;
         }
      }
      
      await _flutterTts.setLanguage(targetLang);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      // If paused, just resume
      if (_ttsState == 'paused') {
        // Many flutter_tts implementations on Android support pause/resume natively
        // Unfortunately standard resume isn't universally supported in a perfectly reliable way across all plugins.
        // We will try standard speak which often resumes, or we just restart.
        // Actually flutterTts has pause() but resume doesn't exist, we must use speak() on iOS, but Android has wait.
        // We will just do a standard play from start or let it handle pause state.
      }
      
      // Play the text
      // Note: flutter_tts automatically chunks long text on Android.
      await _flutterTts.speak(text);
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to play audio.')));
    }
  }

  Future<void> _pause() async {
    await _flutterTts.pause();
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) setState(() { _ttsState = 'stopped'; });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.generationId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: Text('Invalid Generation ID', style: TextStyle(color: Colors.white))),
      );
    }

    final generationAsync = ref.watch(aiGenerationProvider(widget.generationId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            try {
              if (_ttsState == 'playing' || _ttsState == 'paused') {
                _flutterTts.stop();
              }
            } catch (_) {}
            context.pop();
          },
        ),
        title: const Text('Generated Story', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: generationAsync.when(
        data: (gen) {
          if (gen == null) {
            return const Center(child: Text('Generation not found', style: TextStyle(color: Colors.white)));
          }

          if (gen.status == 'processing') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(color: AppColors.primaryAccent, strokeWidth: 3),
                  ),
                  const SizedBox(height: 32),
                  const Text('AI is crafting your story...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text('Prompt: "${gen.prompt}"', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            );
          }

          if (gen.status == 'failed') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text('Generation Failed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
                    child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final storyText = gen.storyContent ?? 'No content generated.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        gen.genre.toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_ttsState == 'stopped' || _ttsState == 'paused')
                      ElevatedButton.icon(
                        onPressed: () => _speak(storyText, gen.language),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Listen to Story', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySurface,
                          foregroundColor: AppColors.primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.primaryAccent)),
                        ),
                      )
                    else 
                      Row(
                        children: [
                          IconButton(
                            onPressed: _pause,
                            icon: const Icon(Icons.pause_circle_filled, color: AppColors.primaryAccent, size: 36),
                          ),
                          IconButton(
                            onPressed: _stop,
                            icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 36),
                          ),
                        ],
                      )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  gen.title ?? 'Untitled Story',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    storyText,
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 16, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || _isSaved) ? null : () async {
                      setState(() => _isSaving = true);
                      try {
                        await ref.read(aiRepositoryProvider).saveToLibrary(gen);
                        ref.invalidate(libraryStoriesProvider);
                        if (context.mounted) {
                          setState(() {
                            _isSaving = false;
                            _isSaved = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to your Library!')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Story could not be saved. Please try again.')));
                        }
                      }
                    },
                    icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : _isSaved ? const Icon(Icons.check_circle) : const Icon(Icons.bookmark_add),
                    label: Text(
                      _isSaving ? 'Saving...' : _isSaved ? 'Saved to Library' : 'Save to Library', 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? Colors.green : AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: _isSaved ? Colors.green.withValues(alpha: 0.8) : AppColors.primaryAccent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
