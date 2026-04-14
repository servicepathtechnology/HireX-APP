import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';

/// Full-screen page shown when user2 taps a challenge_invite notification.
/// Route: /challenges/1v1/:matchId/invite
class ChallengeInvitePage extends ConsumerWidget {
  const ChallengeInvitePage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    // Fallback: if direct GET returns 404, look in the pending invites list
    final pendingAsync = ref.watch(pendingInvitesProvider);

    // Resolve effective match: live detail > from list > error
    AsyncValue<MatchEntity> effectiveAsync;
    if (matchAsync.hasValue) {
      effectiveAsync = matchAsync;
    } else if (matchAsync.hasError) {
      final fromList = pendingAsync.valueOrNull
          ?.where((m) => m.id == matchId)
          .firstOrNull;
      if (fromList != null) {
        effectiveAsync = AsyncData(fromList);
      } else {
        effectiveAsync = matchAsync;
      }
    } else {
      // Loading — check list as fast fallback
      final fromList = pendingAsync.valueOrNull
          ?.where((m) => m.id == matchId)
          .firstOrNull;
      effectiveAsync = fromList != null ? AsyncData(fromList) : matchAsync;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Challenge Invite', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/challenges/1v1');
            }
          },
        ),
      ),
      body: effectiveAsync.when(
        data: (match) => _InviteBody(match: match),
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) {
          final is404 = e.toString().contains('404') ||
              e.toString().contains('not found') ||
              e.toString().toLowerCase().contains('not found');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    is404
                        ? Icons.link_off_rounded
                        : Icons.error_outline,
                    color: AppColors.error,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    is404
                        ? 'Invite no longer available'
                        : 'Could not load invite',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    is404
                        ? 'This challenge invite has expired or was cancelled.'
                        : 'Check your connection and try again.',
                    style: const TextStyle(
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                        fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!is404)
                    TextButton(
                      onPressed: () {
                        ref.invalidate(matchDetailProvider(matchId));
                        ref.invalidate(pendingInvitesProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  TextButton(
                    onPressed: () => context.go('/challenges/1v1'),
                    child: const Text('Go to Challenges'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InviteBody extends ConsumerWidget {
  const _InviteBody({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final actionState = ref.watch(inviteActionProvider);
    final isLoading = actionState.isLoading;
    final isOpponent = match.opponentId == user?.id;

    // If already accepted/declined, show appropriate state
    if (match.status == MatchStatus.active) {
      return _AlreadyAcceptedView(match: match);
    }
    if (match.status == MatchStatus.cancelled || match.status == MatchStatus.expired) {
      return _InactiveView(match: match);
    }

    final challengerName = match.challengerName ?? 'Someone';
    final domain = match.domain.label;
    final duration = match.durationMinutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Challenger avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: match.challengerAvatarUrl != null
                ? NetworkImage(match.challengerAvatarUrl!)
                : null,
            child: match.challengerAvatarUrl == null
                ? Text(
                    challengerName.isNotEmpty ? challengerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontFamily: 'Inter'),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          Text(
            challengerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'challenged you to a 1v1!',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 15,
              fontFamily: 'Inter',
            ),
          ),

          const SizedBox(height: 32),

          // Challenge details card
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
                _DetailRow(
                  icon: Icons.category_rounded,
                  label: 'Domain',
                  value: domain,
                ),
                const Divider(color: AppColors.divider, height: 24),
                _DetailRow(
                  icon: Icons.bar_chart_rounded,
                  label: 'Difficulty',
                  value: match.difficulty.label,
                  valueColor: _difficultyColor(match.difficulty),
                ),
                const Divider(color: AppColors.divider, height: 24),
                _DetailRow(
                  icon: Icons.timer_rounded,
                  label: 'Duration',
                  value: '$duration minutes',
                ),
                if (match.taskTitle != null) ...[
                  const Divider(color: AppColors.divider, height: 24),
                  _DetailRow(
                    icon: Icons.assignment_rounded,
                    label: 'Task',
                    value: match.taskTitle!,
                  ),
                ],
                const Divider(color: AppColors.divider, height: 24),
                _EloRow(match: match),
              ],
            ),
          ),

          // Optional invite message
          if (match.inviteMessage != null && match.inviteMessage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.inviteMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          if (isOpponent && match.status == MatchStatus.pending) ...[            // Accept button
            HireXButton(
              label: 'Accept Challenge',
              isLoading: isLoading,
              onPressed: isLoading
                  ? null
                  : () async {
                      final accepted = await ref
                          .read(inviteActionProvider.notifier)
                          .accept(match.id);
                      if (!context.mounted) return;
                      if (accepted != null) {
                        await _handleAccepted(context, ref, accepted);
                      }
                    },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            ),
            const SizedBox(height: 12),

            // Decline button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final reason = await _showDeclineReasonSheet(context, ref, match.id);
                        if (reason != null && context.mounted) {
                          await ref
                              .read(inviteActionProvider.notifier)
                              .decline(match.id, reason: reason);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Challenge declined.'),
                                backgroundColor: AppColors.surfaceVariant,
                              ),
                            );
                            context.go('/challenges/1v1');
                          }
                        }
                      },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Decline',
                    style: TextStyle(fontFamily: 'Inter')),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (!isOpponent) ...[
            // Challenger view — waiting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for ${match.opponentName ?? "opponent"} to respond...',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontFamily: 'Inter',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAccepted(
      BuildContext context, WidgetRef ref, MatchEntity accepted) async {
    // Invalidate providers so hub refreshes
    ref.invalidate(myMatchesProvider);
    ref.invalidate(pendingInvitesProvider);
    ref.invalidate(myEloProvider);

    if (!context.mounted) return;

    final link = accepted.challengeLink;
    if (link != null && link.isNotEmpty) {
      // Open challenge room in browser for user2 (same as user1 gets via FCM)
      try {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
      // Also navigate to the room page as fallback
      if (context.mounted) {
        context.go('/challenges/1v1/${accepted.id}/room');
      }
    } else {
      // No link yet — go to room page which will fetch it
      context.go('/challenges/1v1/${accepted.id}/room');
    }
  }

  Future<void> _showLinkDialog(BuildContext context, String url) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Challenge Room Ready',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open this link in your browser to join the live challenge:',
              style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showDeclineReasonSheet(
      BuildContext context, WidgetRef ref, String matchId) async {
    // Fetch pre-defined reasons from backend (or use defaults)
    List<String> reasons = const [
      'Not available right now',
      'Maybe next time',
      "I'm in a hurry",
      'Not feeling confident',
      'Try me later',
    ];
    try {
      reasons = await ref.read(challengeRepositoryProvider).getDeclineReasons();
    } catch (_) {}

    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Why are you declining?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Inter', fontSize: 14)),
                  leading: const Icon(Icons.radio_button_unchecked,
                      color: AppColors.onSurface, size: 18),
                  onTap: () => Navigator.of(ctx).pop(r),
                )),
          ],
        ),
      ),
    );
  }
}

class _AlreadyAcceptedView extends StatelessWidget {
  const _AlreadyAcceptedView({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final link = match.challengeLink;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text('Challenge Accepted!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            const Text('The match is active.',
                style: TextStyle(
                    color: AppColors.onSurface, fontFamily: 'Inter')),
            const SizedBox(height: 32),
            if (link != null && link.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => context.go('/challenges/1v1/${match.id}/room'),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open Challenge Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              )
            else
              ElevatedButton(
                onPressed: () => context.go('/challenges/1v1/${match.id}/room'),
                child: const Text('Go to Match'),
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

class _InactiveView extends StatelessWidget {
  const _InactiveView({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final label = match.status == MatchStatus.expired ? 'Expired' : 'Cancelled';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              match.status == MatchStatus.expired
                  ? Icons.timer_off_rounded
                  : Icons.cancel_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('Invite $label',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text(
              match.status == MatchStatus.expired
                  ? 'This challenge invite has expired.'
                  : 'This challenge was declined or cancelled.',
              style: const TextStyle(
                  color: AppColors.onSurface, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.onSurface,
                fontFamily: 'Inter',
                fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}

Color _difficultyColor(ChallengeDifficulty d) {
  switch (d) {
    case ChallengeDifficulty.easy: return const Color(0xFF22C55E);
    case ChallengeDifficulty.medium: return const Color(0xFFF59E0B);
    case ChallengeDifficulty.hard: return const Color(0xFFEF4444);
  }
}

class _EloRow extends StatelessWidget {
  const _EloRow({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        const Text('ELO',
            style: TextStyle(
                color: AppColors.onSurface,
                fontFamily: 'Inter',
                fontSize: 13)),
        const Spacer(),
        Text(
          '${match.challengerEloBefore} vs ${match.opponentEloBefore}',
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
      ],
    );
  }
}
