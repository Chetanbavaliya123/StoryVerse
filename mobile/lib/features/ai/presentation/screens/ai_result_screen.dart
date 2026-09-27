import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/ai/data/ai_repository.dart';

class AiResultScreen extends ConsumerWidget {
  final String generationId;

  const AiResultScreen({super.key, required this.generationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (generationId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: Text('Invalid Generation ID', style: TextStyle(color: Colors.white))),
      );
    }

    final generationAsync = ref.watch(aiGenerationProvider(generationId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
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
                  const CircularProgressIndicator(color: AppColors.primaryAccent),
                  const SizedBox(height: 24),
                  const Text('AI is crafting your story...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Prompt: "${gen.prompt}"', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                  const SizedBox(height: 32),
                  const Text('This usually takes 15-30 seconds', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    gen.storyContent ?? 'No content generated.',
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 16, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to your Library!')));
                    },
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Save to Library', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
