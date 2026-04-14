import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// SCR-09 — Badge Earned Overlay
/// Full-screen animated overlay shown when the winner earns a badge.
/// Route: /challenges/1v1/:matchId/badge?badge=coding_warrior&points=50
class BadgeEarnedOverlayPage extends StatefulWidget {
  const BadgeEarnedOverlayPage({
    super.key,
    required this.matchId,
    required this.badge,
    required this.points,
  });

  final String matchId;
  final String badge;
  final int points;

  @override
  State<BadgeEarnedOverlayPage> createState() => _BadgeEarnedOverlayPageState();
}

class _BadgeEarnedOverlayPageState extends State<BadgeEarnedOverlayPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _badgeEmoji {
    switch (widget.badge) {
      case 'coding_warrior': return '🏅';
      case 'code_crusher': return '💪';
      case 'algorithm_master': return '🧠';
      case 'first_blood': return '🩸';
      case 'win_streak_3': return '🎩';
      case 'win_streak_5': return '⚡';
      case 'speed_demon': return '🚀';
      case 'domain_master': return '👑';
      default: return '🏆';
    }
  }

  String get _badgeName {
    switch (widget.badge) {
      case 'coding_warrior': return 'Coding Warrior';
      case 'code_crusher': return 'Code Crusher';
      case 'algorithm_master': return 'Algorithm Master';
      case 'first_blood': return 'First Blood';
      case 'win_streak_3': return 'Hat Trick';
      case 'win_streak_5': return 'Unstoppable';
      case 'speed_demon': return 'Speed Demon';
      case 'domain_master': return 'Domain Master';
      default: return 'Challenge Winner';
    }
  }

  String get _badgeDesc {
    switch (widget.badge) {
      case 'coding_warrior': return 'Won an Easy 1v1 coding challenge';
      case 'code_crusher': return 'Won a Medium 1v1 coding challenge';
      case 'algorithm_master': return 'Won a Hard 1v1 coding challenge';
      case 'first_blood': return 'Your very first 1v1 win!';
      case 'win_streak_3': return '3 consecutive wins — on fire!';
      case 'win_streak_5': return '5 consecutive wins — unstoppable!';
      case 'speed_demon': return 'Won with >80% score in under 10 minutes';
      case 'domain_master': return '10 total wins in coding';
      default: return 'You earned a new badge!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sparkle header
                  const Text(
                    '✨ New Badge Unlocked! ✨',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Badge emoji
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _badgeEmoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Badge name
                  Text(
                    _badgeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _badgeDesc,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Points earned
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '+${widget.points} XP earned',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dismiss button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go('/challenges/1v1/${widget.matchId}/result'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Awesome! 🎉',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
