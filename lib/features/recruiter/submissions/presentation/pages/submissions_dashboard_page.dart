import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../../../data/models/recruiter_models.dart';

class SubmissionsDashboardPage extends ConsumerWidget {
  const SubmissionsDashboardPage({required this.taskId, super.key});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submissionsDashboardProvider(taskId));
    final taskAsync = ref.watch(recruiterTaskDetailProvider(taskId));

    return HireXScaffold(
      appBar: AppBar(
        title: taskAsync.when(
          data: (t) => Text(t.title, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Submissions'),
          error: (_, __) => const Text('Submissions'),
        ),
        actions: [
          IconButton(
            icon: Icon(state.isLeaderboardView ? Icons.list : Icons.leaderboard),
            onPressed: () => ref.read(submissionsDashboardProvider(taskId).notifier).toggleView(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _FilterBar(taskId: taskId),
          // Stats row
          if (!state.isLoading)
            _StatsRow(submissions: state.submissions, total: state.total),
          // List
          Expanded(
            child: state.isLoading
                ? const Center(child: HireXLoader())
                : state.submissions.isEmpty
                    ? _EmptyState()
                    : state.isLeaderboardView
                        ? _LeaderboardView(submissions: state.submissions)
                        : _ListView(submissions: state.submissions, taskId: taskId),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submissionsDashboardProvider(taskId));
    final notifier = ref.read(submissionsDashboardProvider(taskId).notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['all', 'pending', 'scored', 'shortlisted'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: state.statusFilter == f,
                        onSelected: (_) => notifier.setFilter(f),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: notifier.setSort,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'most_recent', child: Text('Most Recent')),
              const PopupMenuItem(value: 'highest_score', child: Text('Highest Score')),
              const PopupMenuItem(value: 'lowest_score', child: Text('Lowest Score')),
              const PopupMenuItem(value: 'oldest', child: Text('Oldest')),
              const PopupMenuItem(value: 'time_spent', child: Text('Time Spent')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.submissions, required this.total});
  final List<RecruiterSubmissionModel> submissions;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scored = submissions.where((s) => s.status == 'scored').length;
    final pending = submissions.where((s) => s.status == 'submitted').length;
    final shortlisted = submissions.where((s) => s.isShortlisted).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: '$total'),
          const SizedBox(width: 8),
          _StatChip(label: 'Scored', value: '$scored', color: AppColors.success),
          const SizedBox(width: 8),
          _StatChip(label: 'Pending', value: '$pending', color: AppColors.warning),
          const SizedBox(width: 8),
          _StatChip(label: 'Shortlisted', value: '$shortlisted', color: const Color(0xFF3B82F6)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.onSurface).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: AppTextStyles.bodySmall.copyWith(color: color ?? AppColors.onSurface)),
    );
  }
}

class _ListView extends ConsumerWidget {
  const _ListView({required this.submissions, required this.taskId});
  final List<RecruiterSubmissionModel> submissions;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _SubmissionCard(submission: submissions[i], rank: i + 1),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.submissions});
  final List<RecruiterSubmissionModel> submissions;

  @override
  Widget build(BuildContext context) {
    final scored = submissions.where((s) => s.totalScore != null).toList()
      ..sort((a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: scored.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final sub = scored[i];
        final rank = i + 1;
        Color rankColor = AppColors.onSurface;
        if (rank == 1) rankColor = const Color(0xFFFFD700);
        else if (rank == 2) rankColor = const Color(0xFFC0C0C0);
        else if (rank == 3) rankColor = const Color(0xFFCD7F32);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rank <= 3 ? rankColor.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(child: Text('#$rank', style: AppTextStyles.titleSmall.copyWith(color: rankColor))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(sub.candidateName ?? 'Anonymous Candidate', style: AppTextStyles.titleSmall),
              ),
              Text('${sub.totalScore?.toStringAsFixed(1) ?? '-'} / 100',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  const _SubmissionCard({required this.submission, required this.rank});
  final RecruiterSubmissionModel submission;
  final int rank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScored = submission.totalScore != null;
    final isShortlisted = submission.isShortlisted;

    return GestureDetector(
      onTap: () => context.push('/recruiter/submissions/${submission.id}/score'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isShortlisted ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: submission.candidateAvatar != null ? NetworkImage(submission.candidateAvatar!) : null,
                  child: submission.candidateAvatar == null ? const Icon(Icons.person_outline, color: AppColors.onSurface) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(submission.candidateName ?? 'Anonymous Candidate', style: AppTextStyles.titleSmall),
                      if (submission.submittedAt != null)
                        Text(timeago.format(submission.submittedAt!), style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isScored)
                      Text('${submission.totalScore!.toStringAsFixed(1)} / 100',
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary))
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('Pending', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
                      ),
                    if (isShortlisted)
                      const Icon(Icons.bookmark, color: Color(0xFF3B82F6), size: 16),
                  ],
                ),
              ],
            ),
            // AI Score button (shown for unscored submissions)
            if (!isScored) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/recruiter/submissions/${submission.id}/ai-review'),
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Get AI Score'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            // AI Summary (shown after AI scoring)
            if (submission.aiSummary != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('AI Summary', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      submission.aiSummary!.split('.').first + '.',
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No submissions yet', style: AppTextStyles.bodyMedium),
          Text('Submissions will appear here once candidates start submitting.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
