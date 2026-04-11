import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';
import '../widgets/match_card.dart';

class ChallengeHubPage extends ConsumerStatefulWidget {
  const ChallengeHubPage({super.key});

  @override
  ConsumerState<ChallengeHubPage> createState() => _ChallengeHubPageState();
}

class _ChallengeHubPageState extends ConsumerState<ChallengeHubPage>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh immediately on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Poll every 15 seconds for new pending invites
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(myEloProvider);
    ref.invalidate(myMatchesProvider);
    ref.invalidate(pendingInvitesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final eloAsync = ref.watch(myEloProvider);
    final matchesAsync = ref.watch(myMatchesProvider);
    final pendingAsync = ref.watch(pendingInvitesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('1v1 Challenges', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Match History',
            onPressed: () => context.push('/profile/${user?.id}/matches'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/1v1/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Challenge',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ELO Card
            eloAsync.when(
              data: (elo) => _EloCard(elo: elo),
              loading: () => const _EloCardSkeleton(),
              error: (_, __) => const _EloCardSkeleton(),
            ),
            const SizedBox(height: 24),

            // Pending invites section
            pendingAsync.when(
              data: (pending) {
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Pending Invites',
                            style: AppTextStyles.headlineMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pending.map((m) => _PendingInviteCard(
                          match: m,
                          currentUserId: user?.id ?? '',
                          ref: ref,
                        )),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Recent matches
            const Text('Recent Matches', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            matchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) {
                  return _EmptyState(
                    onChallenge: () => context.push('/challenges/1v1/new'),
                  );
                }
                final recent = matches.take(10).toList();
                return Column(
                  children: recent
                      .map((m) => MatchCard(
                            match: m,
                            currentUserId: user?.id ?? '',
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: HireXLoader()),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Invite Card ───────────────────────────────────────────────────────

class _PendingInviteCard extends StatelessWidget {
  const _PendingInviteCard({
    required this.match,
    required this.currentUserId,
    required this.ref,
  });

  final MatchEntity match;
  final String currentUserId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(inviteActionProvider);
    final isLoading = actionState.isLoading;

    return MatchCard(
      match: match,
      currentUserId: currentUserId,
      onAccept: isLoading
          ? null
          : () async {
              final acceptedMatch = await ref.read(inviteActionProvider.notifier).accept(match.id);
              if (context.mounted && acceptedMatch != null) {
                // PRD Section 3.3 & 4: Open external challenge link in browser/webview
                if (acceptedMatch.challengeLink != null && acceptedMatch.challengeLink!.isNotEmpty) {
                  // Open external challenge room URL
                  await _launchChallengeLink(context, acceptedMatch.challengeLink!);
                } else {
                  // Fallback: navigate to in-app room (for backward compatibility)
                  context.push('/challenges/1v1/${match.id}');
                }
              }
            },
      onDecline: isLoading
          ? null
          : () => ref.read(inviteActionProvider.notifier).decline(match.id),
    );
  }

  Future<void> _launchChallengeLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      
      // PRD Section 4: Open external challenge room in browser
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in external browser
        );
      } else {
        throw 'Cannot launch URL: $url';
      }
    } catch (e) {
      if (context.mounted) {
        // Show error dialog with manual link
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Challenge Room Ready'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please open this link in your browser to join the live challenge:',
                  style: TextStyle(color: AppColors.onSurface),
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
            ],
          ),
        );
      }
    }
  }
}

// ── ELO Card ──────────────────────────────────────────────────────────────────

class _EloCard extends StatelessWidget {
  const _EloCard({required this.elo});
  final UserEloEntity elo;

  @override
  Widget build(BuildContext context) {
    final color = EloBadge.tierColor(elo.tier);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EloBadge(tier: elo.tier, elo: elo.elo),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${elo.elo}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'ELO Rating',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: 'Matches', value: '${elo.matchesPlayed}'),
              _StatItem(
                label: 'Win Rate',
                value: '${(elo.winRate * 100).toStringAsFixed(0)}%',
              ),
              _StatItem(label: 'Peak ELO', value: '${elo.peakElo}'),
              _StatItem(
                label: 'Streak',
                value: elo.currentStreak >= 0
                    ? '+${elo.currentStreak}'
                    : '${elo.currentStreak}',
                valueColor: elo.currentStreak > 0
                    ? AppColors.success
                    : elo.currentStreak < 0
                        ? AppColors.error
                        : AppColors.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EloCardSkeleton extends StatelessWidget {
  const _EloCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: HireXLoader()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onChallenge});
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.sports_esports_rounded,
                size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No matches yet', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Challenge a candidate to a 1v1 skill battle',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onChallenge,
                child: const Text('Start a Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
