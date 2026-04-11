import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/analytics/analytics_service.dart';
import '../../../../../core/deep_link/deep_link_handler.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_card.dart';
import '../../../../../shared/widgets/hirex_loader.dart';

final _scoreExplanationProvider = FutureProviderFamily<Map<String, dynamic>, String>(
  (ref, submissionId) async {
    final res = await DioClient().instance.get('/api/v1/ai/explanation/$submissionId');
    return res.data as Map<String, dynamic>;
  },
);

class ScoreExplanationPage extends ConsumerWidget {
  const ScoreExplanationPage({super.key, required this.submissionId});
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_scoreExplanationProvider(submissionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Score Explanation')),
      body: dataAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final taskTitle = data['task_title'] as String? ?? '';
          final totalScore = (data['total_score'] as num?)?.toDouble() ?? 0;
          final rank = data['rank'] as int?;
          final percentile = (data['percentile'] as num?)?.toDouble() ?? 0;
          final aiSummary = data['ai_summary'] as String?;
          final aiScores = data['ai_scores'] as Map<String, dynamic>? ?? {};
          final criteria = (data['evaluation_criteria'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                HireXCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Here is why you scored ${totalScore.toStringAsFixed(0)}/100',
                        style: AppTextStyles.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('on $taskTitle', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ScorePill(
                            label: '${totalScore.toStringAsFixed(1)}/100',
                            color: totalScore >= 80 ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          if (rank != null)
                            _ScorePill(label: 'Rank #$rank', color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Percentile context
                HireXCard(
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This score places you in the top ${(100 - percentile).toStringAsFixed(1)}% of all submissions for this task.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Per-criterion breakdown
                Text('Score Breakdown', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                ...criteria.map((c) {
                  final name = c['name'] as String? ?? '';
                  final weight = c['weight'] as num? ?? 0;
                  final scoreData = aiScores[name] as Map<String, dynamic>?;
                  final score = (scoreData?['score'] as num?)?.toDouble() ?? 0;
                  final reasoning = scoreData?['reasoning'] as String?;
                  final suggestion = scoreData?['suggestion'] as String?;

                  return _CriterionExplanation(
                    name: name,
                    weight: weight.toInt(),
                    score: score,
                    reasoning: reasoning,
                    suggestion: suggestion,
                  );
                }),

                const SizedBox(height: 16),

                // Overall summary
                if (aiSummary != null) ...[
                  Text('Overall Summary', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  HireXCard(
                    child: Text(aiSummary, style: AppTextStyles.bodyMedium),
                  ),
                  const SizedBox(height: 16),
                ],

                // Share button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final link = await DeepLinkHandler.instance.createScoreLink(
                        submissionId,
                        taskTitle,
                        totalScore,
                      );
                      final shareText = link != null
                          ? 'I scored ${totalScore.toStringAsFixed(0)}/100 on "$taskTitle" on HireX! 🎯\n$link'
                          : 'I scored ${totalScore.toStringAsFixed(0)}/100 on "$taskTitle" on HireX! 🎯';
                      await Share.share(shareText);
                      AnalyticsService.instance.scoreViewed(
                        submissionId,
                        totalScore,
                        rank ?? 0,
                        percentile,
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share this score'),
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

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      );
}

class _CriterionExplanation extends StatelessWidget {
  const _CriterionExplanation({
    required this.name,
    required this.weight,
    required this.score,
    this.reasoning,
    this.suggestion,
  });
  final String name;
  final int weight;
  final double score;
  final String? reasoning;
  final String? suggestion;

  @override
  Widget build(BuildContext context) => HireXCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'You scored ${score.toStringAsFixed(0)}/100 on $name (Weight: $weight%)',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
                _ScoreBar(score: score),
              ],
            ),
            if (reasoning != null) ...[
              const SizedBox(height: 8),
              Text(reasoning!, style: AppTextStyles.bodySmall),
            ],
            if (suggestion != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'How to improve: $suggestion',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.error;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(0),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
