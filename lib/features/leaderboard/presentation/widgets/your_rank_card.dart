import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hirex_app/features/leaderboard/data/models/user_rank.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/tier_badge.dart';
import 'package:intl/intl.dart';

class YourRankCard extends ConsumerWidget {
  final UserRank userRank;
  final VoidCallback onTap;

  const YourRankCard({
    super.key,
    required this.userRank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    // Calculate progress to next tier
    final tierThresholds = _getTierThresholds();
    final currentTierIndex = tierThresholds.indexWhere(
      (t) => t.name.toLowerCase() == userRank.tier.toLowerCase(),
    );
    final nextTier = currentTierIndex > 0 ? tierThresholds[currentTierIndex - 1] : null;
    final currentTierMin = tierThresholds[currentTierIndex].minElo;
    final nextTierMin = nextTier?.minElo ?? userRank.elo;
    
    final progress = nextTier != null
        ? (userRank.elo - currentTierMin) / (nextTierMin - currentTierMin)
        : 1.0;
    final eloNeeded = nextTier != null ? nextTierMin - userRank.elo : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTierColor(userRank.tier).withOpacity(0.1),
              _getTierColor(userRank.tier).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getTierColor(userRank.tier).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            Row(
              children: [
                TierBadge(
                  tier: userRank.tier,
                  size: 64,
                  showGlow: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rank #${numberFormat.format(userRank.globalRank ?? 0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ELO: ${numberFormat.format(userRank.elo)} (${userRank.tier.toUpperCase()})',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _getTierColor(userRank.tier),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            if (nextTier != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userRank.tier.toUpperCase(),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    nextTier.name.toUpperCase(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTierColor(userRank.tier),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${numberFormat.format(eloNeeded)} ELO to ${nextTier.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Weekly Gain',
                  value: userRank.weeklyGain >= 0
                      ? '+${userRank.weeklyGain}'
                      : '${userRank.weeklyGain}',
                  color: userRank.weeklyGain >= 0 ? Colors.green : Colors.red,
                ),
                _StatItem(
                  label: 'Country Rank',
                  value: '#${numberFormat.format(userRank.countryRank ?? 0)}',
                  color: theme.primaryColor,
                ),
                _StatItem(
                  label: 'Win Rate',
                  value: '${_calculateWinRate(userRank)}%',
                  color: theme.primaryColor,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // View details button
            Center(
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View My Rank Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateWinRate(UserRank rank) {
    if (rank.matchesPlayed == 0) return 0;
    return ((rank.wins / rank.matchesPlayed) * 100).round();
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'elite':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  List<_TierThreshold> _getTierThresholds() {
    return [
      _TierThreshold(name: 'Elite', minElo: 1800),
      _TierThreshold(name: 'Diamond', minElo: 1600),
      _TierThreshold(name: 'Platinum', minElo: 1400),
      _TierThreshold(name: 'Gold', minElo: 1200),
      _TierThreshold(name: 'Silver', minElo: 1000),
      _TierThreshold(name: 'Bronze', minElo: 0),
    ];
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _TierThreshold {
  final String name;
  final int minElo;

  _TierThreshold({required this.name, required this.minElo});
}
