import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PokedexLens extends StatelessWidget {
  const PokedexLens({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            AppColors.accent,
            AppColors.secondary,
            AppColors.surface,
          ],
          stops: [0.15, 0.55, 1],
        ),
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.35),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.onPrimary.withValues(alpha: 0.92),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
