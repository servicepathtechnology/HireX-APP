import 'package:flutter/material.dart';

/// Colored domain badge used on task cards and detail pages.
class DomainBadge extends StatelessWidget {
  const DomainBadge({super.key, required this.domain, this.small = false, this.size});

  final String domain;
  final bool small;
  final String? size; // 'small' string also accepted

  static const _colors = {
    'engineering': Color(0xFF3B82F6),
    'design': Color(0xFF8B5CF6),
    'product': Color(0xFFF59E0B),
    'business': Color(0xFF10B981),
    'marketing': Color(0xFFEC4899),
    'writing': Color(0xFF6366F1),
  };

  static const _textColors = {
    'product': Color(0xFF1A1A2E),
  };

  static Color colorFor(String domain) =>
      _colors[domain.toLowerCase()] ?? const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final bg = colorFor(domain);
    final fg = _textColors[domain.toLowerCase()] ?? Colors.white;
    final isSmall = small || size == 'small';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        domain[0].toUpperCase() + domain.substring(1),
        style: TextStyle(
          color: fg,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Difficulty badge with muted styling.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty, this.small = false});

  final String difficulty;
  final bool small;

  static const _colors = {
    'beginner': Color(0xFF4CAF50),
    'intermediate': Color(0xFFFF9800),
    'advanced': Color(0xFFE94560),
    'expert': Color(0xFF9C27B0),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[difficulty.toLowerCase()] ?? const Color(0xFF6B7280);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        difficulty[0].toUpperCase() + difficulty.substring(1),
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
