import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../../shared/widgets/domain_badge.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../../../data/models/recruiter_models.dart';

const _stageColors = {
  'shortlisted': Color(0xFF3B82F6),
  'interviewing': Color(0xFFF59E0B),
  'offer_sent': Color(0xFF8B5CF6),
  'hired': Color(0xFF10B981),
  'rejected': Color(0xFF6B7280),
};

const _stageLabels = {
  'shortlisted': 'Shortlisted',
  'interviewing': 'Interviewing',
  'offer_sent': 'Offer Sent',
  'hired': 'Hired',
  'rejected': 'Rejected',
};

const _stageOrder = ['shortlisted', 'interviewing', 'offer_sent', 'hired', 'rejected'];

class HiringPipelinePage extends ConsumerWidget {
  const HiringPipelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipelineAsync = ref.watch(pipelineProvider);

    return HireXScaffold(
      appBar: AppBar(
        title: const Text('Hiring Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(pipelineProvider.notifier).load(),
          ),
        ],
      ),
      body: pipelineAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (board) {
          final hasAny = board.values.any((list) => list.isNotEmpty);
          if (!hasAny) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No candidates shortlisted yet.', style: AppTextStyles.bodyMedium),
                  Text('Score submissions to start building your pipeline.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/recruiter/my-tasks'),
                    child: const Text('View Submissions'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: _stageOrder.map((stage) {
              final entries = board[stage] ?? [];
              return _PipelineColumn(stage: stage, entries: entries);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PipelineColumn extends ConsumerWidget {
  const _PipelineColumn({required this.stage, required this.entries});
  final String stage;
  final List<PipelineEntryModel> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _stageColors[stage] ?? AppColors.onSurface;
    final label = _stageLabels[stage] ?? stage;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
                const Spacer(),
                Text('${entries.length}', style: AppTextStyles.bodySmall.copyWith(color: color)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) async {
                final data = details.data;
                final entryId = data['id'] as String;
                final newStage = stage;
                if (newStage == 'hired') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Confirm Hire'),
                      content: Text('Confirm hire for ${data['candidateName']} for ${data['taskTitle']}?\n\nThis will be recorded as a verified hire on HireX.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Confirm Hire'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }
                await ref.read(pipelineProvider.notifier).moveStage(entryId, newStage);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty ? color.withValues(alpha: 0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: candidateData.isNotEmpty ? Border.all(color: color.withValues(alpha: 0.3), style: BorderStyle.solid) : null,
                  ),
                  child: entries.isEmpty
                      ? Center(child: Text('Drop here', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.3))))
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _PipelineCard(entry: entries[i], stage: stage),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineCard extends ConsumerWidget {
  const _PipelineCard({required this.entry, required this.stage});
  final PipelineEntryModel entry;
  final String stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysInStage = DateTime.now().difference(entry.stageUpdatedAt).inDays;
    final stageIdx = _stageOrder.indexOf(stage);
    final nextStage = stageIdx < _stageOrder.length - 2 ? _stageOrder[stageIdx + 1] : null;

    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'id': entry.id,
        'candidateName': entry.candidateName ?? 'Anonymous',
        'taskTitle': entry.taskTitle ?? 'Task',
      },
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: Text(entry.candidateName ?? 'Anonymous', style: AppTextStyles.titleSmall),
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push('/recruiter/candidates/${entry.candidateId}'),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: entry.candidateAvatar != null ? NetworkImage(entry.candidateAvatar!) : null,
                    child: entry.candidateAvatar == null ? const Icon(Icons.person_outline, size: 16) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.candidateName ?? 'Anonymous', style: AppTextStyles.titleSmall, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              if (entry.taskTitle != null) ...[
                Row(
                  children: [
                    if (entry.taskDomain != null) DomainBadge(domain: entry.taskDomain!, size: 'small'),
                    const SizedBox(width: 4),
                    Expanded(child: Text(entry.taskTitle!, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  if (entry.totalScore != null)
                    Text('${entry.totalScore!.toStringAsFixed(1)} / 100', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  if (entry.rank != null) ...[
                    const SizedBox(width: 8),
                    Text('#${entry.rank}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
                  ],
                  const Spacer(),
                  Text('$daysInStage d', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
                ],
              ),
              if (nextStage != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    if (nextStage == 'hired') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Confirm Hire'),
                          content: Text('Confirm hire for ${entry.candidateName}?\n\nThis will be recorded as a verified hire on HireX.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    await ref.read(pipelineProvider.notifier).moveStage(entry.id, nextStage);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Move to ${_stageLabels[nextStage]}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
