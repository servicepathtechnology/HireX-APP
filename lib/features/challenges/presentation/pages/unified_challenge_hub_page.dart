import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../recruiter/presentation/providers/recruiter_providers.dart';
import '../../../solo_challenges/presentation/providers/solo_challenge_providers.dart';
import '../../../solo_challenges/presentation/widgets/challenge_card.dart';
import '../../../solo_challenges/presentation/widgets/streak_card.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';
import '../widgets/match_card.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import 'dart:async';

/// Unified Challenge Hub with tabs for 1v1 and Solo challenges
class UnifiedChallengeHubPage extends ConsumerStatefulWidget {
  const UnifiedChallengeHubPage({super.key});

  @override
  ConsumerState<UnifiedChallengeHubPage> createState() => _UnifiedChallengeHubPageState();
}

class _UnifiedChallengeHubPageState extends ConsumerState<UnifiedChallengeHubPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted) return;
    // Refresh 1v1 data
    ref.invalidate(myEloProvider);
    ref.invalidate(myMatchesProvider);
    ref.invalidate(pendingInvitesProvider);
    // Refresh solo challenge data
    ref.invalidate(challengeHubProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Challenges', style: AppTextStyles.headlineMedium),
        actions: [
          _NotificationBell(),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Match History',
            onPressed: () => context.push('/profile/${user?.id}/matches'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurface,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '1v1 Challenges'),
            Tab(text: 'Daily/Weekly/Monthly'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/challenges/1v1/new'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Challenge',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _OneVsOneTab(user: user, ref: ref, onRefresh: _refresh),
          _SoloChallengesTab(ref: ref, onRefresh: _refresh),
        ],
      ),
    );
  }
}



// ── 1v1 Tab Content ───────────────────────────────────────────────────────────

class _OneVsOneTab extends StatelessWidget {
  const _OneVsOneTab({
    required this.user,
    required this.ref,
    required this.onRefresh,
  });

  final dynamic user;
  final WidgetRef ref;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final eloAsync = ref.watch(myEloProvider);
    final matchesAsync = ref.watch(myMatchesProvider);
    final pendingAsync = ref.watch(pendingInvitesProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
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
              final incoming = pending.where((m) => m.opponentId == user?.id).toList();
              if (incoming.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Incoming Challenges',
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
                          '${incoming.length}',
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
                  ...incoming.map((m) => _PendingInviteCard(
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

          // Sent challenges section
          pendingAsync.when(
            data: (pending) {
              final sent = pending.where((m) => m.challengerId == user?.id).toList();
              final cached = ref.watch(createdMatchCacheProvider);
              final allSent = [
                ...sent,
                if (cached != null && !sent.any((m) => m.id == cached.id)) cached,
              ];
              if (allSent.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sent Challenges', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  ...allSent.map((m) => _SentChallengeCard(match: m)),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () {
              final cached = ref.watch(createdMatchCacheProvider);
              if (cached == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sent Challenges', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  _SentChallengeCard(match: cached),
                  const SizedBox(height: 24),
                ],
              );
            },
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
    );
  }
}

// ── Solo Challenges Tab Content ──────────────────────────────────────────────

class _SoloChallengesTab extends StatelessWidget {
  const _SoloChallengesTab({
    required this.ref,
    required this.onRefresh,
  });

  final WidgetRef ref;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hubAsync = ref.watch(challengeHubProvider);

    return hubAsync.when(
      data: (hub) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak card
              StreakCard(streak: hub.streak),
              const SizedBox(height: 24),

              // Daily challenge
              Text(
                'Daily Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ChallengeCard(
                type: 'daily',
                title: hub.daily.questionTitle ?? 'No challenge today',
                difficulty: hub.daily.difficulty,
                xpReward: hub.daily.xpReward,
                status: hub.daily.status,
                completed: hub.daily.completed,
                onTap: () => context.push('/challenges/solo/daily'),
              ),
              const SizedBox(height: 24),

              // Weekly challenge
              Text(
                'Weekly Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ChallengeCard(
                type: 'weekly',
                title: hub.weekly.questionTitle ?? 'No challenge this week',
                difficulty: hub.weekly.difficulty,
                xpReward: hub.weekly.xpReward,
                status: hub.weekly.status,
                completed: hub.weekly.completed,
                onTap: () => context.push('/challenges/solo/weekly'),
              ),
              const SizedBox(height: 24),

              // Monthly challenge
              Text(
                'Monthly Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ChallengeCard(
                type: 'monthly',
                title: hub.monthly.questionTitle ?? 'No challenge this month',
                difficulty: hub.monthly.difficulty,
                xpReward: hub.monthly.xpReward,
                status: hub.monthly.status,
                completed: hub.monthly.completed,
                onTap: () => context.push('/challenges/solo/monthly'),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: HireXLoader()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onRefresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets from ChallengeHubPage ───────────────────────────────────

class _PendingInviteCard extends StatelessWidget {
  const _PendingInviteCard({
    required this.match,
    required this.currentUserId,
    required this.ref,
  });

  final MatchEntity match;
  final String currentUserId;
  final WidgetRef ref;

  bool get _isOpponent => match.opponentId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(inviteActionProvider);
    final isLoading = actionState.isLoading;

    if (_isOpponent) {
      return GestureDetector(
        onTap: () => context.push('/challenges/1v1/${match.id}/invite'),
        child: MatchCard(
          match: match,
          currentUserId: currentUserId,
          onAccept: isLoading
              ? null
              : () => context.push('/challenges/1v1/${match.id}/invite'),
          onDecline: isLoading
              ? null
              : () async {
                  final reason = await _showDeclineReasonSheet(context, ref, match.id);
                  if (reason != null && context.mounted) {
                    await ref.read(inviteActionProvider.notifier).decline(match.id, reason: reason);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Challenge declined.'),
                          backgroundColor: AppColors.surfaceVariant,
                        ),
                      );
                    }
                  }
                },
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/challenges/1v1/${match.id}/invite'),
      child: MatchCard(
        match: match,
        currentUserId: currentUserId,
      ),
    );
  }

  Future<String?> _showDeclineReasonSheet(BuildContext context, WidgetRef ref, String matchId) async {
    final reasons = const [
      'Not available right now',
      'Maybe next time',
      "I'm in a hurry",
      'Not feeling confident',
      'Try me later',
    ];
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
            const Text('Why are you declining?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter')),
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

class _SentChallengeCard extends StatelessWidget {
  const _SentChallengeCard({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final opponentName = match.opponentName ?? 'Opponent';
    final opponentAvatar = match.opponentAvatarUrl;

    return GestureDetector(
      onTap: () => context.push('/challenges/1v1/${match.id}/pending'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage:
                  opponentAvatar != null ? NetworkImage(opponentAvatar) : null,
              child: opponentAvatar == null
                  ? Text(
                      opponentName.isNotEmpty ? opponentName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${match.difficulty.label} · ${match.durationMinutes}m',
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurface, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
    );
  }
}
