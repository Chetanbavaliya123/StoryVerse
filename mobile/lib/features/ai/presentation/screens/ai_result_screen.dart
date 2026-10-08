import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';
import 'package:storyverse/features/library/data/library_repository.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';

class AiResultScreen extends ConsumerStatefulWidget {
  final String generationId;

  const AiResultScreen({super.key, required this.generationId});

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(libraryRepositoryProvider)
        .isInLibrary(widget.generationId)
        .listen((val) {
      if (mounted) {
        setState(() => _isSaved = val);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.generationId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Text(
            'Invalid Generation ID',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final generationAsync = ref.watch(
      aiGenerationProvider(widget.generationId),
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'Generated Story',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: generationAsync.when(
        data: (gen) {
          if (gen == null) {
            return const Center(
              child: Text(
                'Generation not found',
                style: TextStyle(color: Colors.white),
              ),
            );
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
                          color: AppColors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: AppColors.primaryAccent,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AI is crafting your story...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This usually takes 15-30 seconds. Please wait...',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Prompt: "${gen.prompt}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
                  const Text(
                    'Generation Failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final storyText = gen.storyContent ?? 'No content generated.';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          gen.genre.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    gen.title ?? 'Untitled Story',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
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
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isSaved)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: null, // Disabled because already saved
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySurface,
                          disabledBackgroundColor: AppColors.primarySurface,
                          disabledForegroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.primaryAccent),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, color: AppColors.primaryAccent),
                        label: const Text(
                          'Saved to My Stories',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  await ref.read(aiRepositoryProvider).saveToLibrary(gen);
                                  ref.invalidate(libraryStoriesProvider);
                                  if (mounted) {
                                    setState(() {
                                      _isSaving = false;
                                      _isSaved = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Saved to your Library!')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to save. Try again.')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            : const Icon(Icons.bookmark_add, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save to My Stories',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
