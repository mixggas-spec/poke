import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final String type;

  static const _typeColors = <String, Color>{
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'grass': Color(0xFF78C850),
    'electric': Color(0xFFF8D030),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[type.toLowerCase()] ?? AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        _formatType(type),
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatType(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
