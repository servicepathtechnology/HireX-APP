import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/deep_link/deep_link_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/domain_badge.dart';
import '../../../../shared/widgets/deadline_chip.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskDataSourceProvider).incrementView(widget.taskId);
    });
  }

  Future<void> _shareTask(TaskEntity task) async {
    AnalyticsService.instance.taskViewed(task.id, task.domain, task.difficulty);
    final link = await DeepLinkHandler.instance.createTaskLink(task.id, task.title, task.domain);
    final shareText = link != null
        ? 'Check out this task on HireX: ${task.title}\n$link'
        : 'Check out this task on HireX: ${task.title}\nhttps://hirex.app/tasks/${task.id}';
    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          taskAsync.whenOrNull(
            data: (task) => IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareTask(task),
            ),
          ) ?? const SizedBox(),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Task not found', style: AppTextStyles.bodyLarge),
        ),
        data: (task) => _TaskDetailBody(task: task),
      ),
    );
  }
}

class _TaskDetailBody extends ConsumerWidget {
  const _TaskDetailBody({required this.task});
  final TaskEntity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Hero header
              Text(task.title, style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text(task.displayCompany, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  DomainBadge(domain: task.domain),
                  const SizedBox(width: 8),
                  DifficultyBadge(difficulty: task.difficulty),
                ],
              ),
              const SizedBox(height: 16),

              // Key stats
              _StatsRow(task: task),
              const SizedBox(height: 16),

              // Skills
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: task.skillsTested
                    .map((s) => _SkillChip(s))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Prize banner
              if (task.prizeOrOpportunity != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.prizeOrOpportunity!,
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              Text('Description', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              MarkdownBody(
                data: task.description,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: AppTextStyles.bodyLarge,
                  code: AppTextStyles.bodyMedium.copyWith(
                    fontFamily: 'monospace',
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Problem statement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Problem Statement', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: task.problemStatement,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: AppTextStyles.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Evaluation rubric
              _RubricSection(criteria: task.evaluationCriteria),
              const SizedBox(height: 20),

              // Submission types
              Text('Allowed Submission Types', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: task.submissionTypes.map((t) => _SubmissionTypeChip(t)).toList(),
              ),
              const SizedBox(height: 20),

              // Time & deadline
              HireXCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deadline', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          DeadlineChip(deadline: task.deadline),
                        ],
                      ),
                    ),
                    if (task.estimatedHours != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated Time', style: AppTextStyles.labelSmall),
                            const SizedBox(height: 4),
                            Text('~${task.estimatedHours}h', style: AppTextStyles.bodyLarge),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sticky bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _StickyBottomBar(task: task),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.task});
  final TaskEntity task;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Stat(Icons.people_outline, '${task.submissionCount} submissions'),
          const SizedBox(width: 16),
          _Stat(Icons.category_outlined, task.taskType.replaceAll('_', ' ')),
          if (task.estimatedHours != null) ...[
            const SizedBox(width: 16),
            _Stat(Icons.access_time, '~${task.estimatedHours}h'),
          ],
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurface),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      );
}

class _RubricSection extends StatefulWidget {
  const _RubricSection({required this.criteria});
  final List<Map<String, dynamic>> criteria;

  @override
  State<_RubricSection> createState() => _RubricSectionState();
}

class _RubricSectionState extends State<_RubricSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text('Evaluation Rubric', style: AppTextStyles.headlineMedium),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.onSurface,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            ...widget.criteria.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${c['weight']}%',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['criterion'] as String, style: AppTextStyles.labelLarge),
                            Text(c['description'] as String? ?? '', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      );
}

class _SubmissionTypeChip extends StatelessWidget {
  const _SubmissionTypeChip(this.type);
  final String type;

  static const _icons = {
    'text': Icons.text_fields,
    'code': Icons.code,
    'file': Icons.attach_file,
    'link': Icons.link,
    'recording': Icons.videocam_outlined,
  };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icons[type] ?? Icons.help_outline, size: 14, color: AppColors.onSurface),
            const SizedBox(width: 6),
            Text(type[0].toUpperCase() + type.substring(1), style: AppTextStyles.labelSmall),
          ],
        ),
      );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: AppTextStyles.labelSmall),
      );
}

// ── Sticky bottom bar with CTA ────────────────────────────────────────────────

class _StickyBottomBar extends ConsumerWidget {
  const _StickyBottomBar({required this.task});
  final TaskEntity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = task.candidateSubmissionStatus;
    final submissionId = task.candidateSubmissionId;
    final deadlinePassed = task.isDeadlinePassed;

    String label;
    bool enabled;
    VoidCallback? onTap;

    if (deadlinePassed && status == null) {
      label = 'Deadline Passed';
      enabled = false;
    } else if (status == null) {
      label = 'Start Task';
      enabled = true;
      onTap = () => context.push('/candidate/tasks/${task.id}/submit');
    } else if (status == 'draft') {
      label = 'Continue Draft';
      enabled = true;
      onTap = () => context.push('/candidate/tasks/${task.id}/submit');
    } else if (status == 'scored') {
      label = 'View My Score';
      enabled = true;
      onTap = () => context.push('/candidate/submissions/$submissionId');
    } else {
      label = 'View My Submission';
      enabled = true;
      onTap = () => context.push('/candidate/submissions/$submissionId');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              task.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: task.isBookmarked ? AppColors.primary : AppColors.onSurface,
            ),
            onPressed: () => ref.read(bookmarksProvider.notifier).toggle(task.id),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? AppColors.primary : AppColors.surface,
                foregroundColor: enabled ? AppColors.onPrimary : AppColors.onSurface,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
