import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class RecruiterAnalyticsPage extends ConsumerStatefulWidget {
  const RecruiterAnalyticsPage({super.key});

  @override
  ConsumerState<RecruiterAnalyticsPage> createState() => _RecruiterAnalyticsPageState();
}

class _RecruiterAnalyticsPageState extends ConsumerState<RecruiterAnalyticsPage> {
  String? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(recruiterAnalyticsProvider(_selectedTaskId));
    final tasksAsync = ref.watch(recruiterTasksProvider(null));

    return HireXScaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Column(
        children: [
          // Task selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: tasksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (tasks) => DropdownButtonFormField<String?>(
                value: _selectedTaskId,
                decoration: InputDecoration(
                  labelText: 'Select Task',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                ),
                dropdownColor: AppColors.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Tasks')),
                  ...tasks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _selectedTaskId = v),
              ),
            ),
          ),
          Expanded(
            child: analyticsAsync.when(
              loading: () => const Center(child: HireXLoader()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data['total_submissions'] == 0) {
                  return Center(
                    child: Text(
                      'Not enough data yet. Analytics appear after first submission is scored.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return _AnalyticsContent(data: data);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final timeline = data['submission_timeline'] as List? ?? [];
    final distribution = data['score_distribution'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Row(
            children: [
              _MetricCard(label: 'Total Views', value: '${data['total_views'] ?? 0}'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Submissions', value: '${data['total_submissions'] ?? 0}'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Conversion', value: '${data['conversion_rate'] ?? 0}%'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Avg Score', value: data['avg_score'] != null ? '${(data['avg_score'] as num).toStringAsFixed(1)}' : '-'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricCard(label: 'Scored', value: '${data['scored_count'] ?? 0}'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Shortlisted', value: '${data['shortlisted_count'] ?? 0}'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Hired', value: '${data['hired_count'] ?? 0}'),
              const SizedBox(width: 8),
              _MetricCard(label: 'Avg Time', value: data['avg_time_spent_mins'] != null ? '${(data['avg_time_spent_mins'] as num).toStringAsFixed(0)}m' : '-'),
            ],
          ),
          const SizedBox(height: 24),

          // Submission timeline
          if (timeline.isNotEmpty) ...[
            Text('Submissions Over Time', style: AppTextStyles.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: timeline.asMap().entries.map((e) {
                        final point = e.value as Map<String, dynamic>;
                        return FlSpot(e.key.toDouble(), (point['count'] as num).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Score distribution
          if (distribution.isNotEmpty) ...[
            Text('Score Distribution', style: AppTextStyles.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final keys = distribution.keys.toList();
                          if (v.toInt() < keys.length) return Text(keys[v.toInt()], style: const TextStyle(fontSize: 9, color: Colors.white70));
                          return const Text('');
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: distribution.entries.toList().asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value.value as num).toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Pipeline funnel
          Text('Pipeline Funnel', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          _FunnelChart(data: data),
        ],
      ),
    );
  }
}

class _FunnelChart extends StatelessWidget {
  const _FunnelChart({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('Submitted', data['total_submissions'] as int? ?? 0),
      ('Scored', data['scored_count'] as int? ?? 0),
      ('Shortlisted', data['shortlisted_count'] as int? ?? 0),
      ('Hired', data['hired_count'] as int? ?? 0),
    ];
    final maxVal = stages.map((s) => s.$2).reduce((a, b) => a > b ? a : b);

    return Column(
      children: stages.map((stage) {
        final fraction = maxVal > 0 ? stage.$2 / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(stage.$1, style: AppTextStyles.bodySmall)),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 24, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: Container(height: 24, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${stage.$2}', style: AppTextStyles.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontSize: 18)),
            Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
