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

class MatchHistoryPage extends ConsumerWidget {
  const MatchHistoryPage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isOwnProfile = user?.id == userId;
    final matchesAsync = ref.watch(myMatchesProvider);
    final eloAsync = ref.watch(myEloProvider);
    final filters = ref.watch(matchHistoryFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isOwnProfile ? 'My Match History' : 'Match History',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: Column(
        children: [
          // Stats card
          if (isOwnProfile)
            eloAsync.when(
              data: (elo) => _StatsCard(elo: elo),
              loading: () => const SizedBox(height: 80, child: Center(child: HireXLoader())),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Filters
          _FilterBar(filters: filters),

          // Match list
          Expanded(
            child: matchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matches found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(myMatchesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: matches.length,
                    itemBuilder: (context, i) => _MatchHistoryRow(
                      match: matches[i],
                      currentUserId: user?.id ?? '',
                    ),
                  ),
                );
              },
              loading: () => const Center(child: HireXLoader()),
              error: (e, _) => Center(
                child: Text(e.toString(), style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.elo});
  final UserEloEntity elo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          EloBadge(tier: elo.tier, elo: elo.elo),
          const Spacer(),
          _Stat(label: 'Matches', value: '${elo.matchesPlayed}'),
          _Stat(
            label: 'Win Rate',
            value: '${(elo.winRate * 100).toStringAsFixed(0)}%',
          ),
          _Stat(label: 'Peak', value: '${elo.peakElo}'),
          _Stat(
            label: 'Streak',
            value: elo.currentStreak >= 0
                ? '+${elo.currentStreak}'
                : '${elo.currentStreak}',
            color: elo.currentStreak > 0
                ? AppColors.success
                : elo.currentStreak < 0
                    ? AppColors.error
                    : null,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.white,
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

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters});
  final MatchHistoryFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(matchHistoryFiltersProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Domain filter
          _FilterChip(
            label: filters.domain ?? 'All Domains',
            isActive: filters.domain != null,
            onTap: () => _showDomainPicker(context, ref, notifier),
          ),
          const SizedBox(width: 8),
          // Result filter
          _FilterChip(
            label: filters.result ?? 'All Results',
            isActive: filters.result != null,
            onTap: () => _showResultPicker(context, ref, notifier),
          ),
          const SizedBox(width: 8),
          if (filters.domain != null || filters.result != null)
            TextButton(
              onPressed: () => notifier.state = const MatchHistoryFilters(),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Inter'),
              ),
            ),
        ],
      ),
    );
  }

  void _showDomainPicker(
    BuildContext context,
    WidgetRef ref,
    StateController<MatchHistoryFilters> notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Domain', style: AppTextStyles.headlineMedium),
          ),
          ...ChallengeDomain.values.map(
            (d) => ListTile(
              title: Text(d.label, style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
              onTap: () {
                notifier.state = notifier.state.copyWith(domain: d.value);
                ref.invalidate(myMatchesProvider);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showResultPicker(
    BuildContext context,
    WidgetRef ref,
    StateController<MatchHistoryFilters> notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filter by Result', style: AppTextStyles.headlineMedium),
          ),
          ...['win', 'loss', 'draw'].map(
            (r) => ListTile(
              title: Text(
                r[0].toUpperCase() + r.substring(1),
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              ),
              onTap: () {
                notifier.state = notifier.state.copyWith(result: r);
                ref.invalidate(myMatchesProvider);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.onSurface,
                fontFamily: 'Inter',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHistoryRow extends StatelessWidget {
  const _MatchHistoryRow({required this.match, required this.currentUserId});
  final MatchEntity match;
  final String currentUserId;

  bool get _isChallenger => match.challengerId == currentUserId;
  String get _opponentName =>
      _isChallenger ? (match.opponentName ?? 'Opponent') : (match.challengerName ?? 'Challenger');

  String _resultLabel() {
    if (match.status != MatchStatus.completed) return match.status.value.toUpperCase();
    if (match.isDraw) return 'D';
    return match.isWinner(currentUserId) ? 'W' : 'L';
  }

  Color _resultColor() {
    if (match.status != MatchStatus.completed) return AppColors.onSurface;
    if (match.isDraw) return AppColors.warning;
    return match.isWinner(currentUserId) ? AppColors.success : AppColors.error;
  }

  int? _myEloChange() {
    if (match.status != MatchStatus.completed) return null;
    final before = _isChallenger ? match.challengerEloBefore : match.opponentEloBefore;
    final after = _isChallenger ? match.challengerEloAfter : match.opponentEloAfter;
    if (after == null) return null;
    return after - before;
  }

  @override
  Widget build(BuildContext context) {
    final eloChange = _myEloChange();
    final eloSign = eloChange != null && eloChange >= 0 ? '+' : '';

    return GestureDetector(
      onTap: () {
        if (match.status == MatchStatus.completed) {
          context.push('/challenges/1v1/${match.id}/result');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Result badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _resultColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _resultLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _resultColor(),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Match info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _opponentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.domain.label} · ${match.durationMinutes}m · '
                    '${DateFormat('MMM d').format(match.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // ELO change
            if (eloChange != null)
              Text(
                '$eloSign$eloChange',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: eloChange >= 0 ? AppColors.success : AppColors.error,
                  fontFamily: 'Inter',
                ),
              ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.onSurface, size: 18),
          ],
        ),
      ),
    );
  }
}
