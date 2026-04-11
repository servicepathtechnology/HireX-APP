import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';

/// Match detail / replay page.
/// Route: /challenges/1v1/[matchId]/detail
class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(matchResultProvider(matchId));
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Detail', style: AppTextStyles.headlineMedium),
      ),
      body: resultAsync.when(
        data: (result) => _DetailContent(
          result: result,
          currentUserId: user?.id ?? '',
        ),
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(
          child: Text(e.toString(), style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.result, required this.currentUserId});
  final MatchResultEntity result;
  final String currentUserId;

  bool get _isChallenger => result.match.challengerId == currentUserId;

  String get _opponentName => _isChallenger
      ? (result.match.opponentName ?? 'Opponent')
      : (result.match.challengerName ?? 'Challenger');

  String get _opponentId => _isChallenger
      ? result.match.opponentId
      : result.match.challengerId;

  @override
  Widget build(BuildContext context) {
    final match = result.match;
    final mySubmission = result.mySubmission;
    final oppSubmission = result.opponentSubmission;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match summary header
          _MatchSummaryCard(match: match, currentUserId: currentUserId),
          const SizedBox(height: 20),

          // ELO changes
          _EloSummaryRow(result: result),
          const SizedBox(height: 20),

          // My submission replay
          if (mySubmission != null) ...[
            const Text('Your Submission', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            _SubmissionReplay(submission: mySubmission, domain: match.domain),
            const SizedBox(height: 20),
          ],

          // Score breakdown
          if (mySubmission?.scoreBreakdown != null) ...[
            const Text('Score Breakdown', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            _ScoreBreakdownCard(
              breakdown: mySubmission!.scoreBreakdown!,
              totalScore: mySubmission.score,
            ),
            const SizedBox(height: 20),
          ],

          // AI Feedback
          if (mySubmission?.aiFeedback != null) ...[
            const Text('AI Feedback', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            _FeedbackCard(feedback: mySubmission!.aiFeedback!),
            const SizedBox(height: 20),
          ],

          // Opponent score (public — score only, not content)
          if (oppSubmission != null) ...[
            Text('$_opponentName\'s Score', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            _OpponentScoreCard(
              opponentName: _opponentName,
              score: oppSubmission.score,
            ),
            const SizedBox(height: 20),
          ],

          // View opponent profile
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/recruiter/candidates/$_opponentId'),
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text(
                'View $_opponentName\'s Profile',
                style: const TextStyle(fontFamily: 'Inter'),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({required this.match, required this.currentUserId});
  final MatchEntity match;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isWinner = match.isWinner(currentUserId);
    final isDraw = match.isDraw;
    final resultColor = isDraw
        ? AppColors.warning
        : isWinner
            ? AppColors.success
            : AppColors.error;
    final resultLabel = isDraw ? 'Draw' : isWinner ? 'Won' : 'Lost';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resultLabel,
                  style: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  match.domain.label,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${match.durationMinutes}m',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (match.taskTitle != null)
            Text(
              match.taskTitle!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM d, yyyy · h:mm a').format(match.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EloSummaryRow extends StatelessWidget {
  const _EloSummaryRow({required this.result});
  final MatchResultEntity result;

  @override
  Widget build(BuildContext context) {
    final myChange = result.myEloChange;
    final mySign = myChange >= 0 ? '+' : '';
    final myColor = myChange >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$mySign$myChange',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: myColor,
                    fontFamily: 'Inter',
                  ),
                ),
                const Text(
                  'Your ELO',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                EloBadge(tier: result.myNewTier, elo: result.myNewElo, compact: true),
                const SizedBox(height: 4),
                const Text(
                  'New Tier',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionReplay extends StatelessWidget {
  const _SubmissionReplay({required this.submission, required this.domain});
  final ChallengeSubmissionEntity submission;
  final ChallengeDomain domain;

  @override
  Widget build(BuildContext context) {
    final isCoding = domain == ChallengeDomain.coding || domain == ChallengeDomain.data;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCoding ? const Color(0xFF0D1117) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (submission.language != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    submission.language!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (submission.isAuto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Auto-submitted',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                DateFormat('h:mm a').format(submission.submittedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            submission.content.isEmpty ? '(No content submitted)' : submission.content,
            style: TextStyle(
              fontFamily: isCoding ? 'monospace' : 'Inter',
              fontSize: 13,
              color: isCoding ? const Color(0xFFE6EDF3) : AppColors.onSurface,
              height: 1.6,
            ),
            maxLines: 20,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  const _ScoreBreakdownCard({required this.breakdown, required this.totalScore});
  final Map<String, dynamic> breakdown;
  final int? totalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ...breakdown.entries.map((e) {
            final score = (e.value as num?)?.toInt() ?? 0;
            final pct = score / 25.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '$score / 25',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '${totalScore ?? 0} / 100',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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

class _OpponentScoreCard extends StatelessWidget {
  const _OpponentScoreCard({required this.opponentName, required this.score});
  final String opponentName;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(
            opponentName,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Text(
            score != null ? '$score pts' : 'Not submitted',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: score != null ? Colors.white : AppColors.onSurface,
              fontFamily: 'Inter',
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'AI Feedback',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
