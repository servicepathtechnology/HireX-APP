import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hirex_app/features/leaderboard/data/leaderboard_repository.dart';
import 'package:hirex_app/features/leaderboard/data/models/user_rank.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/tier_badge.dart';
import 'package:intl/intl.dart';

final eloHistoryProvider = FutureProvider<List<EloHistoryItem>>((ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getEloHistory(days: 30);
});

final eloBreakdownProvider = FutureProvider<EloBreakdown>((ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getEloBreakdown();
});

class TierDetailScreen extends ConsumerWidget {
  final UserRank userRank;

  const TierDetailScreen({super.key, required this.userRank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');
    final eloHistoryAsync = ref.watch(eloHistoryProvider);
    final eloBreakdownAsync = ref.watch(eloBreakdownProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Rank'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large tier display
            Center(
              child: Column(
                children: [
                  TierBadge(
                    tier: userRank.tier,
                    size: 120,
                    showGlow: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userRank.tier.toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTierColor(userRank.tier),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ELO: ${numberFormat.format(userRank.elo)}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Global rank card
            _buildInfoCard(
              context,
              title: 'Global Rank',
              value: '#${numberFormat.format(userRank.globalRank ?? 0)}',
              subtitle: 'out of ${numberFormat.format(10000)} candidates',
            ),
            
            const SizedBox(height: 16),
            
            // Country rank card
            if (userRank.countryRank != null)
              _buildInfoCard(
                context,
                title: 'Country Rank',
                value: '#${numberFormat.format(userRank.countryRank!)}',
                subtitle: 'Top performers in your country',
              ),
            
            const SizedBox(height: 24),
            
            // ELO breakdown
            Text(
              'ELO Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            eloBreakdownAsync.when(
              data: (breakdown) => _buildEloBreakdownChart(context, breakdown),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load breakdown'),
            ),
            
            const SizedBox(height: 24),
            
            // ELO history chart
            Text(
              'ELO History (Last 30 Days)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            eloHistoryAsync.when(
              data: (history) => _buildEloHistoryChart(context, history),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load history'),
            ),
            
            const SizedBox(height: 24),
            
            // All-time stats
            Text(
              'All-Time Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(context, userRank),
            
            const SizedBox(height: 24),
            
            // Recent ELO events
            Text(
              'Recent ELO Events',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            eloHistoryAsync.when(
              data: (history) => _buildEloEventsList(context, history),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Text('Failed to load events'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEloBreakdownChart(BuildContext context, EloBreakdown breakdown) {
    final data = [
      _ChartData('1v1', breakdown.from1v1.toDouble(), Colors.blue),
      _ChartData('Daily', breakdown.fromDaily.toDouble(), Colors.green),
      _ChartData('Weekly', breakdown.fromWeekly.toDouble(), Colors.orange),
      _ChartData('Monthly', breakdown.fromMonthly.toDouble(), Colors.purple),
      _ChartData('Bonuses', breakdown.fromBonuses.toDouble(), Colors.red),
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: entry.value.color,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()].label,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildEloHistoryChart(BuildContext context, List<EloHistoryItem> history) {
    if (history.isEmpty) {
      return const Center(child: Text('No history available'));
    }

    final spots = history.reversed.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.eloAfter.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserRank rank) {
    final stats = [
      _StatItem('Peak ELO', NumberFormat('#,###').format(rank.peakElo)),
      _StatItem('Matches', '${rank.matchesPlayed}'),
      _StatItem('Wins', '${rank.wins}'),
      _StatItem('Losses', '${rank.losses}'),
      _StatItem('Win Streak', '${rank.currentStreak}'),
      _StatItem('Win Rate', '${_calculateWinRate(rank)}%'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: stats.map((stat) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEloEventsList(BuildContext context, List<EloHistoryItem> history) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 10 ? 10 : history.length,
      itemBuilder: (context, index) {
        final event = history[index];
        final isPositive = event.change >= 0;

        return ListTile(
          leading: Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? Colors.green : Colors.red,
          ),
          title: Text(_formatEventSource(event.source)),
          subtitle: event.opponentName != null
              ? Text('vs ${event.opponentName}')
              : null,
          trailing: Text(
            '${isPositive ? '+' : ''}${event.change}',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }

  String _formatEventSource(String source) {
    switch (source) {
      case '1v1_win':
        return '1v1 Challenge Win';
      case '1v1_loss':
        return '1v1 Challenge Loss';
      case 'daily_complete':
        return 'Daily Challenge';
      case 'weekly_complete':
        return 'Weekly Challenge';
      case 'monthly_complete':
        return 'Monthly Challenge';
      default:
        return source;
    }
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
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}
