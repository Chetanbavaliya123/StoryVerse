import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/app_colors.dart';

class StoryVerseLogo extends StatelessWidget {
  final double size;

  const StoryVerseLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(size * (12.0 / 36.0)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.1),
            blurRadius: size * (6.0 / 36.0),
            spreadRadius: size * (2.0 / 36.0),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'SV',
          style: TextStyle(
            fontSize: size * (16.0 / 36.0),
            fontWeight: FontWeight.w900,
            color: AppColors.primaryAccent,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }
}
