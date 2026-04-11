import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/challenge_entities.dart';

/// Displays an ELO tier badge with color and icon.
class EloBadge extends StatelessWidget {
  const EloBadge({super.key, required this.tier, required this.elo, this.compact = false});

  final EloTier tier;
  final int elo;
  final bool compact;

  static Color tierColor(EloTier tier) {
    switch (tier) {
      case EloTier.bronze: return const Color(0xFFCD7F32);
      case EloTier.silver: return const Color(0xFFC0C0C0);
      case EloTier.gold: return const Color(0xFFFFD700);
      case EloTier.platinum: return const Color(0xFF00CED1);
      case EloTier.diamond: return const Color(0xFF9B59B6);
      case EloTier.elite: return AppColors.primary;
    }
  }

  static IconData tierIcon(EloTier tier) {
    switch (tier) {
      case EloTier.bronze: return Icons.shield_outlined;
      case EloTier.silver: return Icons.shield;
      case EloTier.gold: return Icons.star_rounded;
      case EloTier.platinum: return Icons.diamond_outlined;
      case EloTier.diamond: return Icons.diamond;
      case EloTier.elite: return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = tierColor(tier);
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tierIcon(tier), size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              tier.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tierIcon(tier), size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '$elo ELO',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
