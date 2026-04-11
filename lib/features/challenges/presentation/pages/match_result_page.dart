import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/deep_link/deep_link_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';

class MatchResultPage extends ConsumerWidget {
  const MatchResultPage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(matchResultProvider(matchId));
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: resultAsync.when(
        data: (result) => _ResultContent(
          result: result,
          currentUserId: user?.id ?? '',
          matchId: matchId,
        ),
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.onSurface),
              const SizedBox(height: 16),
              const Text(
                'Result not ready yet',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Evaluation is in progress. Check back in a moment.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(matchResultProvider(matchId)),
                child: const Text('Refresh'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/challenges/1v1'),
                child: const Text('Back to Hub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({
    required this.result,
    required this.currentUserId,
    required this.matchId,
  });

  final MatchResultEntity result;
  final String currentUserId;
  final String matchId;

  bool get _isWinner => result.match.isWinner(currentUserId);
  bool get _isDraw => result.match.isDraw;

  String get _headline {
    if (_isDraw) return 'Draw!';
    if (_isWinner) return 'You Won!';
    return 'You Lost';
  }

  Color get _headlineColor {
    if (_isDraw) return AppColors.warning;
    if (_isWinner) return AppColors.success;
    return AppColors.error;
  }

  IconData get _headlineIcon {
    if (_isDraw) return Icons.handshake_rounded;
    if (_isWinner) return Icons.emoji_events_rounded;
    return Icons.sentiment_dissatisfied_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final myScore = result.mySubmission?.score;
    final oppScore = result.opponentSubmission?.score;
    final match = result.match;
    final opponentName = currentUserId == match.challengerId
        ? (match.opponentName ?? 'Opponent')
        : (match.challengerName ?? 'Challenger');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Result headline
            Icon(_headlineIcon, size: 72, color: _headlineColor),
            const SizedBox(height: 12),
            Text(
              _headline,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _headlineColor,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              match.domain.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),

            const SizedBox(height: 32),

            // Score comparison
            Row(
              children: [
                Expanded(
                  child: _ScoreCard(
                    label: 'You',
                    score: myScore,
                    isWinner: _isWinner,
                    highlight: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Expanded(
                  child: _ScoreCard(
                    label: opponentName,
                    score: oppScore,
                    isWinner: !_isWinner && !_isDraw,
                    highlight: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ELO change
            _EloChangeCard(
              eloChange: result.myEloChange,
              newElo: result.myNewElo,
              newTier: result.myNewTier,
              tierChanged: result.tierChanged,
            ),

            const SizedBox(height: 24),

            // AI Feedback (private)
            if (result.mySubmission?.aiFeedback != null)
              _FeedbackCard(feedback: result.mySubmission!.aiFeedback!),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/challenges/1v1/new'),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Rematch', style: TextStyle(fontFamily: 'Inter')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResult(context),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share', style: TextStyle(fontFamily: 'Inter')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // View opponent profile
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/recruiter/candidates/${currentUserId == match.challengerId ? match.opponentId : match.challengerId}',
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: Text(
                  'View $opponentName\'s Profile',
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // View full detail / replay
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.push('/challenges/1v1/$matchId/detail'),
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.onSurface),
                label: const Text(
                  'View Full Submission & Replay',
                  style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/challenges/1v1'),
                child: const Text(
                  'Back to Hub',
                  style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    final outcome = _isDraw ? 'draw' : (_isWinner ? 'win' : 'loss');
    final eloChange = result.myEloChange >= 0
        ? '+${result.myEloChange}'
        : '${result.myEloChange}';
    AnalyticsService.instance.matchResultShared(matchId, outcome);
    if (result.tierChanged) {
      AnalyticsService.instance.eloTierChanged(
        result.opponentNewTier.value,
        result.myNewTier.value,
        result.myNewElo,
      );
    }
    // Try to create a Branch deep link, fall back to plain text
    DeepLinkHandler.instance
        .createMatchResultLink(matchId, result.match.domain.label, outcome)
        .then((link) {
      final shareText = link != null
          ? 'I just ${_isDraw ? 'drew' : (_isWinner ? 'won' : 'lost')} a 1v1 '
              '${result.match.domain.label} challenge on HireX! '
              'ELO: $eloChange (${result.myNewElo}) — ${result.myNewTier.label} tier. '
              'Challenge me: $link'
          : 'I just ${_isDraw ? 'drew' : (_isWinner ? 'won' : 'lost')} a 1v1 '
              '${result.match.domain.label} challenge on HireX! '
              'ELO: $eloChange (${result.myNewElo}) — ${result.myNewTier.label} tier. '
              'Challenge me: https://hirex.app/challenges';
      Share.share(shareText);
    });
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.isWinner,
    required this.highlight,
  });

  final String label;
  final int? score;
  final bool isWinner;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppColors.success : AppColors.divider,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            score != null ? '$score' : '—',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isWinner ? AppColors.success : Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            'pts',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurface.withValues(alpha: 0.6),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EloChangeCard extends StatelessWidget {
  const _EloChangeCard({
    required this.eloChange,
    required this.newElo,
    required this.newTier,
    required this.tierChanged,
  });

  final int eloChange;
  final int newElo;
  final EloTier newTier;
  final bool tierChanged;

  @override
  Widget build(BuildContext context) {
    final isPositive = eloChange >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ELO Change',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$sign$eloChange',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              EloBadge(tier: newTier, elo: newElo),
              if (tierChanged) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🎉 Tier Up!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Feedback (Private)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
