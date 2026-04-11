import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../../core/network/dio_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_card.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/domain_badge.dart';

final _skillScoreDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await DioClient().instance.get('/api/v1/scores/me/detail');
  return res.data as Map<String, dynamic>;
});

class SkillScoreDetailPage extends ConsumerWidget {
  const SkillScoreDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_skillScoreDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Skill Score')),
      body: dataAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final overall = data['overall_score'] as int? ?? 0;
          final percentile = (data['percentile_overall'] as num?)?.toDouble() ?? 0;
          final tier = data['tier'] as Map<String, dynamic>? ?? {};
          final domainScores = data['domain_scores'] as Map<String, dynamic>? ?? {};
          final percentileByDomain = data['percentile_by_domain'] as Map<String, dynamic>? ?? {};
          final snapshots = (data['snapshots'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Overall Score Hero
                _OverallScoreHero(
                  overall: overall,
                  percentile: percentile,
                  tier: tier,
                ),
                const SizedBox(height: 20),

                // Section 2: Domain Breakdown
                Text('Domain Breakdown', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                ...domainScores.entries.map((e) {
                  final score = (e.value as num).toInt();
                  final domainPercentile = (percentileByDomain[e.key] as num?)?.toDouble() ?? 0;
                  return _DomainBar(
                    domain: e.key,
                    score: score,
                    percentile: domainPercentile,
                  );
                }),

                const SizedBox(height: 20),

                // Section 3: Score History
                Text('Score History', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                if (snapshots.isEmpty)
                  Text('No score history yet.', style: AppTextStyles.bodyMedium)
                else
                  ...snapshots.take(20).map((s) => _SnapshotRow(snapshot: s)),

                const SizedBox(height: 20),

                // Section 4: How it works
                _HowItWorksCard(),

                const SizedBox(height: 20),

                // Section 5: Tamper evidence
                HireXCard(
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your score history is cryptographically verified',
                                style: AppTextStyles.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Each score snapshot is hashed and timestamped — it cannot be altered retroactively.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverallScoreHero extends StatefulWidget {
  const _OverallScoreHero({
    required this.overall,
    required this.percentile,
    required this.tier,
  });
  final int overall;
  final double percentile;
  final Map<String, dynamic> tier;

  @override
  State<_OverallScoreHero> createState() => _OverallScoreHeroState();
}

class _OverallScoreHeroState extends State<_OverallScoreHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.overall / 1000).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierLabel = widget.tier['label'] as String? ?? 'Beginner';
    final tierColorHex = widget.tier['color'] as String? ?? '#6B7280';
    final tierColor = _hexColor(tierColorHex);

    return HireXCard(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) => CircularPercentIndicator(
              radius: 80,
              lineWidth: 12,
              percent: _animation.value,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 1000).toInt()}',
                    style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                  ),
                  Text('/ 1000', style: AppTextStyles.labelSmall),
                ],
              ),
              progressColor: tierColor,
              backgroundColor: AppColors.divider,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tierLabel,
              style: TextStyle(color: tierColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top ${(100 - widget.percentile).toStringAsFixed(1)}% of all HireX candidates',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _DomainBar extends StatelessWidget {
  const _DomainBar({required this.domain, required this.score, required this.percentile});
  final String domain;
  final int score;
  final double percentile;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DomainBadge(domain: domain, small: true),
                const Spacer(),
                Text('$score', style: AppTextStyles.labelLarge),
                const SizedBox(width: 8),
                Text(
                  'Top ${(100 - percentile).toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (score / 1000).clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              color: DomainBadge.colorFor(domain),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.snapshot});
  final Map<String, dynamic> snapshot;

  @override
  Widget build(BuildContext context) {
    final reason = snapshot['snapshot_reason'] as String? ?? '';
    final overall = snapshot['overall_score'] as int? ?? 0;
    final createdAt = snapshot['created_at'] as String? ?? '';
    final isDecay = reason.toLowerCase().contains('decay');

    // Compute delta from domain_scores if available
    final domainScores = snapshot['domain_scores'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isDecay ? AppColors.error : AppColors.success,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason, style: AppTextStyles.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          Text(
            'Overall: $overall',
            style: AppTextStyles.labelLarge.copyWith(
              color: isDecay ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _HowItWorksCard extends StatefulWidget {
  @override
  State<_HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<_HowItWorksCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => HireXCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text('How is my score calculated?', style: AppTextStyles.labelLarge),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                'Your score increases when you submit tasks and rank well. '
                'It decreases slightly if you are inactive for 30+ days in a domain. '
                'Harder tasks give bigger score boosts. Ranking in the top 10% gives a 1.5x multiplier.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
        ),
      );
}
