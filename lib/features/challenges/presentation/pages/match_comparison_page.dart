import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';

class MatchComparisonPage extends ConsumerStatefulWidget {
  const MatchComparisonPage({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchComparisonPage> createState() => _MatchComparisonPageState();
}

class _MatchComparisonPageState extends ConsumerState<MatchComparisonPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const _maxPolls = 20;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Poll until match is completed
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
  }

  void _startPolling() {
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  void _poll() {
    if (_pollAttempts >= _maxPolls) {
      _pollTimer?.cancel();
      return;
    }
    _pollAttempts++;
    ref.invalidate(matchResultProvider(widget.matchId));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final resultAsync = ref.watch(matchResultProvider(widget.matchId));

    // Stop polling once completed
    ref.listen(matchResultProvider(widget.matchId), (_, next) {
      if (next.hasValue && next.value != null) {
        _pollTimer?.cancel();
        _animCtrl.forward();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Result', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/challenges/1v1'),
        ),
      ),
      body: resultAsync.when(
        loading: () => const Center(child: _EvaluatingState()),
        error: (e, _) => _EvaluatingState(message: e.toString()),
        data: (result) {
          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _ComparisonBody(
                result: result,
                currentUserId: user?.id ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Evaluating placeholder ────────────────────────────────────────────────────

class _EvaluatingState extends StatelessWidget {
  const _EvaluatingState({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HireXLoader(),
            const SizedBox(height: 20),
            const Text('Evaluating submissions…', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              message ?? 'This may take up to 30 seconds',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main comparison body ──────────────────────────────────────────────────────

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({required this.result, required this.currentUserId});
  final MatchResultEntity result;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final match = result.match;
    final isWinner = match.isWinner(currentUserId);
    final isDraw = match.isDraw;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Winner banner
        _WinnerBanner(isWinner: isWinner, isDraw: isDraw),
        const SizedBox(height: 20),

        // Side-by-side stats
        _SideBySideStats(result: result, currentUserId: currentUserId),
        const SizedBox(height: 20),

        // ELO delta card
        _EloDeltaCard(result: result, currentUserId: currentUserId),
        const SizedBox(height: 20),

        // AI feedback (private — only current user's)
        if (result.mySubmission?.aiFeedback != null) ...[
          _FeedbackCard(feedback: result.mySubmission!.aiFeedback!),
          const SizedBox(height: 20),
        ],

        // Score breakdown
        if (result.mySubmission?.scoreBreakdown != null) ...[
          _BreakdownCard(breakdown: result.mySubmission!.scoreBreakdown!),
          const SizedBox(height: 20),
        ],

        // Action row
        _ActionRow(matchId: match.id, currentUserId: currentUserId, match: match),
      ],
    );
  }
}

// ── Winner banner ─────────────────────────────────────────────────────────────

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.isWinner, required this.isDraw});
  final bool isWinner;
  final bool isDraw;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String emoji;
    final String title;
    final String subtitle;

    if (isDraw) {
      color = AppColors.warning;
      emoji = '🤝';
      title = "It's a Draw!";
      subtitle = 'Both players performed equally well';
    } else if (isWinner) {
      color = AppColors.success;
      emoji = '🏆';
      title = 'You Won!';
      subtitle = 'Outstanding performance!';
    } else {
      color = AppColors.error;
      emoji = '💪';
      title = 'Better Luck Next Time';
      subtitle = 'Keep practicing and challenge again';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.7),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Side-by-side stats ────────────────────────────────────────────────────────

class _SideBySideStats extends StatelessWidget {
  const _SideBySideStats({required this.result, required this.currentUserId});
  final MatchResultEntity result;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final match = result.match;
    final isChallenger = match.challengerId == currentUserId;

    final myName = isChallenger ? (match.challengerName ?? 'You') : (match.opponentName ?? 'You');
    final oppName = isChallenger ? (match.opponentName ?? 'Opponent') : (match.challengerName ?? 'Opponent');

    final myScore = result.mySubmission?.score;
    final oppScore = result.opponentSubmission?.score;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    myName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Text(
                  'vs',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                Expanded(
                  child: Text(
                    oppName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          _StatRow(
            label: 'Score',
            myValue: myScore != null ? '$myScore / 100' : '—',
            oppValue: oppScore != null ? '$oppScore / 100' : '—',
            myHighlight: (myScore ?? 0) > (oppScore ?? 0),
          ),
          _StatRow(
            label: 'ELO Before',
            myValue: '${isChallenger ? match.challengerEloBefore : match.opponentEloBefore}',
            oppValue: '${isChallenger ? match.opponentEloBefore : match.challengerEloBefore}',
          ),
          _StatRow(
            label: 'ELO After',
            myValue: '${result.myNewElo}',
            oppValue: '${result.opponentNewElo}',
            myHighlight: result.myNewElo > result.opponentNewElo,
          ),
          _StatRow(
            label: 'ELO Change',
            myValue: result.myEloChange >= 0
                ? '+${result.myEloChange}'
                : '${result.myEloChange}',
            oppValue: result.opponentEloChange >= 0
                ? '+${result.opponentEloChange}'
                : '${result.opponentEloChange}',
            myValueColor: result.myEloChange >= 0 ? AppColors.success : AppColors.error,
            oppValueColor: result.opponentEloChange >= 0 ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.myValue,
    required this.oppValue,
    this.myHighlight = false,
    this.myValueColor,
    this.oppValueColor,
  });

  final String label;
  final String myValue;
  final String oppValue;
  final bool myHighlight;
  final Color? myValueColor;
  final Color? oppValueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              myValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: myValueColor ??
                    (myHighlight ? AppColors.success : Colors.white),
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              oppValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: oppValueColor ?? AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ELO delta card ────────────────────────────────────────────────────────────

class _EloDeltaCard extends StatelessWidget {
  const _EloDeltaCard({required this.result, required this.currentUserId});
  final MatchResultEntity result;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final tierColor = EloBadge.tierColor(result.myNewTier);
    final change = result.myEloChange;
    final changeColor = change >= 0 ? AppColors.success : AppColors.error;
    final changeStr = change >= 0 ? '+$change' : '$change';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          EloBadge(tier: result.myNewTier, elo: result.myNewElo),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.myNewElo} ELO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                if (result.tierChanged)
                  Text(
                    '🎉 Tier upgraded to ${result.myNewTier.label}!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: changeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              changeStr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: changeColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Feedback card ──────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              const Text(
                'AI Feedback',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Private',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                  ),
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

// ── Score breakdown card ──────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});
  final Map<String, dynamic> breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Inter',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...breakdown.entries.map((e) {
            final pts = (e.value as num).toInt();
            final pct = pts / 25.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '$pts / 25',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 0.7
                            ? AppColors.success
                            : pct >= 0.4
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.matchId,
    required this.currentUserId,
    required this.match,
  });
  final String matchId;
  final String currentUserId;
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final opponentId = match.challengerId == currentUserId
        ? match.opponentId
        : match.challengerId;    return Column(
      children: [
        // Rematch
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/challenges/1v1/new'),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text(
              'Rematch',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile/$opponentId'),
                icon: const Icon(Icons.person_outline_rounded, size: 16),
                label: const Text(
                  'View Profile',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/challenges/1v1'),
                icon: const Icon(Icons.dashboard_outlined, size: 16),
                label: const Text(
                  'Dashboard',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
