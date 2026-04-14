import 'package:flutter/material.dart';

class TierBadge extends StatelessWidget {
  final String tier;
  final double size;
  final bool showGlow;

  const TierBadge({
    super.key,
    required this.tier,
    this.size = 24,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final tierData = _getTierData(tier);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tierData.color,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: tierData.color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          tierData.icon,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  _TierData _getTierData(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return _TierData(
          color: const Color(0xFFCD7F32),
          icon: Icons.shield,
        );
      case 'silver':
        return _TierData(
          color: const Color(0xFFC0C0C0),
          icon: Icons.shield_outlined,
        );
      case 'gold':
        return _TierData(
          color: const Color(0xFFFFD700),
          icon: Icons.emoji_events,
        );
      case 'platinum':
        return _TierData(
          color: const Color(0xFFE5E4E2),
          icon: Icons.diamond_outlined,
        );
      case 'diamond':
        return _TierData(
          color: const Color(0xFFB9F2FF),
          icon: Icons.diamond,
        );
      case 'elite':
        return _TierData(
          color: const Color(0xFFFF6B6B),
          icon: Icons.workspace_premium,
        );
      default:
        return _TierData(
          color: Colors.grey,
          icon: Icons.shield,
        );
    }
  }
}

class _TierData {
  final Color color;
  final IconData icon;

  _TierData({required this.color, required this.icon});
}
