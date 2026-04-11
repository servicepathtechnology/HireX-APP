import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/submissions/domain/entities/submission_entity.dart';

/// Score breakdown card shown on submission status page.
class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.submission});

  final SubmissionEntity submission;

  @override
  Widget build(BuildContext context) {
    final total = submission.totalScore ?? 0;
    final rank = submission.rank;
    final percentile = submission.percentile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceVariant, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Score', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${total.toStringAsFixed(1)} / 100',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: _scoreColor(total),
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
              ),
              if (rank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('#$rank', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
                      Text('Rank', style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
          if (percentile != null) ...[
            const SizedBox(height: 8),
            Text(
              'Top ${(100 - percentile).toStringAsFixed(1)}% on this task',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Score Breakdown', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          _ScoreRow('Accuracy', 40, submission.scoreAccuracy),
          _ScoreRow('Approach & Thinking', 30, submission.scoreApproach),
          _ScoreRow('Completeness', 20, submission.scoreCompleteness),
          _ScoreRow('Efficiency / Speed', 10, submission.scoreEfficiency),
          const Divider(),
          _ScoreRow('Total', 100, total, isTotal: true),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.weight, this.score, {this.isTotal = false});

  final String label;
  final int weight;
  final double? score;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final weighted = score != null ? (score! * weight / 100) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: isTotal
                  ? AppTextStyles.labelLarge
                  : AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            '$weight%',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              score != null ? '${score!.toStringAsFixed(0)} / 100' : '—',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              weighted != null ? weighted.toStringAsFixed(1) : '—',
              style: isTotal
                  ? AppTextStyles.labelLarge.copyWith(color: AppColors.primary)
                  : AppTextStyles.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
