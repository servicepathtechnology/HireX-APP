import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../../../core/network/dio_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/domain_badge.dart';

final candidatePipelineProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await DioClient().instance.get('/api/v1/candidate/pipeline');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class CandidatePipelinePage extends ConsumerStatefulWidget {
  const CandidatePipelinePage({super.key});

  @override
  ConsumerState<CandidatePipelinePage> createState() => _CandidatePipelinePageState();
}

class _CandidatePipelinePageState extends ConsumerState<CandidatePipelinePage> {
  bool _reviewRequested = false;

  Future<void> _maybeRequestReview(List<Map<String, dynamic>> entries) async {
    if (_reviewRequested) return;
    final hasHire = entries.any((e) => e['stage'] == 'hired');
    if (!hasHire) return;
    _reviewRequested = true;
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pipelineAsync = ref.watch(candidatePipelineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(candidatePipelineProvider),
          ),
        ],
      ),
      body: pipelineAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          // Trigger in-app review if candidate has been hired
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRequestReview(entries));

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline, size: 64,
                        color: AppColors.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No applications yet', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'You will appear here once a recruiter shortlists you.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by stage
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final e in entries) {
            final stage = e['stage'] as String? ?? 'shortlisted';
            grouped.putIfAbsent(stage, () => []).add(e);
          }

          const stageOrder = ['shortlisted', 'interviewing', 'offer_sent', 'hired', 'rejected'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: stageOrder
                .where((s) => grouped.containsKey(s))
                .expand((stage) => [
                      _StageDivider(stage: stage),
                      ...grouped[stage]!.map((e) => _PipelineCard(entry: e)),
                    ])
                .toList(),
          );
        },
      ),
    );
  }
}

class _StageDivider extends StatelessWidget {
  const _StageDivider({required this.stage});
  final String stage;

  static const _labels = {
    'shortlisted': 'Shortlisted',
    'interviewing': 'Interviewing',
    'offer_sent': 'Offer Sent',
    'hired': 'Hired 🎉',
    'rejected': 'Not Selected',
  };

  static const _colors = {
    'shortlisted': Color(0xFF3B82F6),
    'interviewing': Color(0xFFF59E0B),
    'offer_sent': Color(0xFF8B5CF6),
    'hired': Color(0xFF10B981),
    'rejected': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[stage] ?? stage;
    final color = _colors[stage] ?? AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final taskTitle = entry['task_title'] as String? ?? 'Task';
    final taskDomain = entry['task_domain'] as String? ?? '';
    final totalScore = (entry['total_score'] as num?)?.toDouble();
    final rank = entry['rank'] as int?;
    final submissionId = entry['submission_id'] as String? ?? '';
    final stage = entry['stage'] as String? ?? '';
    final stageUpdated = entry['stage_updated_at'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(taskTitle, style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis),
              ),
              if (taskDomain.isNotEmpty) DomainBadge(domain: taskDomain, small: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (totalScore != null) ...[
                Icon(Icons.star_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${totalScore.toStringAsFixed(1)}/100',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                const SizedBox(width: 12),
              ],
              if (rank != null) ...[
                Icon(Icons.leaderboard_outlined, size: 14, color: AppColors.onSurface),
                const SizedBox(width: 4),
                Text('Rank #$rank', style: AppTextStyles.labelSmall),
                const SizedBox(width: 12),
              ],
              Text(
                _formatDate(stageUpdated),
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/candidate/submissions/$submissionId'),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('View Submission'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              if (stage == 'shortlisted' || stage == 'interviewing') ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/messages'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Messages'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
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
      return '';
    }
  }
}
