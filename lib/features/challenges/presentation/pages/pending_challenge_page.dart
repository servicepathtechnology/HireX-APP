import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';

/// SCR-03 — Pending Challenge Status
/// Shown to the challenger after sending an invite.
/// Polls every 10s for status changes.
class PendingChallengePage extends ConsumerStatefulWidget {
  const PendingChallengePage({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<PendingChallengePage> createState() => _PendingChallengePageState();
}

class _PendingChallengePageState extends ConsumerState<PendingChallengePage>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    // Poll every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(matchDetailProvider(widget.matchId));
        // Also refresh the list so cache gets updated
        ref.invalidate(pendingInvitesProvider);
        ref.invalidate(myMatchesProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use cached match from creation first to avoid immediate 404 race condition.
    final cachedMatch = ref.watch(createdMatchCacheProvider);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    // When matchDetailProvider returns 404, fall back to finding the match in the list
    final listAsync = ref.watch(pendingInvitesProvider);

    // Priority: live match detail > match from list > cached match
    AsyncValue<MatchEntity> effectiveAsync;
    if (matchAsync.hasValue) {
      effectiveAsync = matchAsync;
    } else if (matchAsync.hasError) {
      // 404 or other error — try to find in the pending list
      final fromList = listAsync.valueOrNull?.where((m) => m.id == widget.matchId).firstOrNull;
      if (fromList != null) {
        effectiveAsync = AsyncData(fromList);
      } else if (cachedMatch != null) {
        effectiveAsync = AsyncData(cachedMatch);
      } else {
        effectiveAsync = matchAsync;
      }
    } else {
      // Still loading — show cache if available
      effectiveAsync = cachedMatch != null ? AsyncData(cachedMatch) : matchAsync;
    }

    // React to status changes
    ref.listen(matchDetailProvider(widget.matchId), (_, next) {
      next.whenData((match) {
        // Update cache with latest data
        ref.read(createdMatchCacheProvider.notifier).setMatch(match.status == MatchStatus.pending ? match : null);
        if (match.status == MatchStatus.active && match.challengeLink != null) {
          if (mounted) context.go('/challenges/1v1/${widget.matchId}/room');
        } else if (match.status == MatchStatus.cancelled ||
            match.status == MatchStatus.expired) {
          ref.invalidate(pendingInvitesProvider);
        }
      });
    });

    // Also react to list updates (catches status changes when direct GET returns 404)
    ref.listen(pendingInvitesProvider, (_, next) {
      next.whenData((list) {
        final match = list.where((m) => m.id == widget.matchId).firstOrNull;
        if (match == null) {
          // Match no longer pending — refresh and go back
          ref.invalidate(myMatchesProvider);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Challenge Sent', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/challenges/1v1'),
        ),
      ),
      body: effectiveAsync.when(
        data: (match) => _PendingBody(
          match: match,
          pulseAnim: _pulseAnim,
          onCancel: () => _cancelChallenge(context, ref, match),
        ),
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(matchDetailProvider(widget.matchId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelChallenge(
      BuildContext context, WidgetRef ref, MatchEntity match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Challenge?',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text(
          'The opponent will be notified that you cancelled.',
          style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Challenge'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(challengeRepositoryProvider).cancelInvite(match.id);
        ref.invalidate(pendingInvitesProvider);
        ref.invalidate(myMatchesProvider);
        if (context.mounted) context.go('/challenges/1v1');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody({
    required this.match,
    required this.pulseAnim,
    required this.onCancel,
  });

  final MatchEntity match;
  final Animation<double> pulseAnim;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final opponentName = match.opponentName ?? 'Opponent';
    final opponentAvatar = match.opponentAvatarUrl;

    // Declined / expired state
    if (match.status == MatchStatus.cancelled || match.status == MatchStatus.expired) {
      return _DeclinedView(match: match);
    }

    // Accepted state
    if (match.status == MatchStatus.active) {
      return _AcceptedView(match: match);
    }

    // Pending state
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Animated checkmark
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Challenge Sent!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 32),

          // Opponent info
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: opponentAvatar != null ? NetworkImage(opponentAvatar) : null,
            child: opponentAvatar == null
                ? Text(
                    opponentName.isNotEmpty ? opponentName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Inter'),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            opponentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),

          // Pulsing status
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Opacity(
              opacity: pulseAnim.value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Waiting for them to respond...',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontFamily: 'Inter',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Challenge summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.code_rounded,
                  label: 'Domain',
                  value: 'Coding',
                ),
                const Divider(color: AppColors.divider, height: 20),
                _SummaryRow(
                  icon: Icons.bar_chart_rounded,
                  label: 'Difficulty',
                  value: match.difficulty.label,
                ),
                const Divider(color: AppColors.divider, height: 20),
                _SummaryRow(
                  icon: Icons.timer_rounded,
                  label: 'Duration',
                  value: '${match.durationMinutes} minutes',
                ),
                if (match.inviteMessage != null && match.inviteMessage!.isNotEmpty) ...[
                  const Divider(color: AppColors.divider, height: 20),
                  _SummaryRow(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    value: match.inviteMessage!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Challenge', style: TextStyle(fontFamily: 'Inter')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                foregroundColor: AppColors.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/challenges/1v1'),
            child: const Text(
              'Back to Challenges',
              style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.onSurface, fontFamily: 'Inter', fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}

class _DeclinedView extends StatelessWidget {
  const _DeclinedView({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final isExpired = match.status == MatchStatus.expired;
    final opponentName = match.opponentName ?? 'Opponent';
    final reason = match.declineReason;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpired ? Icons.timer_off_rounded : Icons.cancel_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isExpired ? 'Challenge Expired' : 'Challenge Declined',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            if (!isExpired && reason != null && reason.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: AppColors.onSurface, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$opponentName: "$reason"',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                isExpired
                    ? '$opponentName did not respond in time.'
                    : '$opponentName declined your challenge.',
                style: const TextStyle(
                    color: AppColors.onSurface, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => context.push('/challenges/1v1/new'),
              child: const Text('Send New Challenge'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/challenges/1v1'),
              child: const Text('Back to Challenges'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedView extends StatelessWidget {
  const _AcceptedView({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final link = match.challengeLink;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Challenge Accepted!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${match.opponentName ?? "Opponent"} accepted your challenge. The match is live!',
              style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (link != null && link.isNotEmpty) {
                  try {
                    final uri = Uri.parse(link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {}
                }
                if (context.mounted) {
                  context.go('/challenges/1v1/${match.id}/room');
                }
              },
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text('Start Challenge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/challenges/1v1'),
              child: const Text('Back to Hub'),
            ),
          ],
        ),
      ),
    );
  }
}
