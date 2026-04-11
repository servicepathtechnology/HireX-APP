import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/domain_badge.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../../../data/models/recruiter_models.dart';

class RecruiterMyTasksPage extends ConsumerStatefulWidget {
  const RecruiterMyTasksPage({super.key});

  @override
  ConsumerState<RecruiterMyTasksPage> createState() => _RecruiterMyTasksPageState();
}

class _RecruiterMyTasksPageState extends ConsumerState<RecruiterMyTasksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HireXScaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/recruiter/post-task/basics'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Closed'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TaskList(status: 'active'),
          _TaskList(status: 'closed'),
          _TaskList(status: 'draft'),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(recruiterTasksProvider(status));

    return tasksAsync.when(
      loading: () => const Center(child: HireXLoader()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_outlined, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No $status tasks', style: AppTextStyles.bodyMedium),
                if (status == 'draft') ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/recruiter/post-task/basics'),
                    child: const Text('Post a Task'),
                  ),
                ],
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(recruiterTasksProvider(status).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _TaskCard(task: tasks[i], status: status),
          ),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.status});
  final RecruiterTaskModel task;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = task.deadline != null
        ? task.deadline!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
              DomainBadge(domain: task.domain),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(6)),
                child: Text(task.difficulty, style: AppTextStyles.bodySmall),
              ),
              const Spacer(),
              if (!task.isActive && task.isPublished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text('Paused', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status == 'active') ...[
                Icon(Icons.timer_outlined, size: 14, color: daysLeft <= 2 ? AppColors.error : AppColors.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('$daysLeft days left', style: AppTextStyles.bodySmall.copyWith(color: daysLeft <= 2 ? AppColors.error : null)),
              ] else if (status == 'closed' && task.deadline != null) ...[
                Text('Closed ${DateFormat('dd MMM').format(task.deadline!)}', style: AppTextStyles.bodySmall),
              ],
              const Spacer(),
              Icon(Icons.people_outline, size: 14, color: AppColors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text('${task.submissionCount} submissions', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Submissions',
                icon: Icons.list_alt,
                onTap: () => context.push('/recruiter/tasks/${task.id}/submissions'),
              ),
              _ActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: () => context.push('/recruiter/tasks/${task.id}/edit'),
              ),
              if (task.isPublished)
                _ActionButton(
                  label: task.isActive ? 'Pause' : 'Resume',
                  icon: task.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  onTap: () async {
                    try {
                      await ref.read(recruiterDataSourceProvider).pauseTask(task.id);
                      ref.invalidate(recruiterTasksProvider(status));
                    } catch (e) {
                      if (context.mounted) HireXSnackbar.show(context, message: 'Failed: $e', isError: true);
                    }
                  },
                ),
              if (task.isPublished && task.isActive)
                _ActionButton(
                  label: 'Close',
                  icon: Icons.stop_circle_outlined,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Close Task?'),
                        content: const Text('No new submissions will be accepted. Existing submissions are preserved.'),
                        actions: [
                          TextButton(onPressed: () => dialogCtx.pop(false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => dialogCtx.pop(true), child: const Text('Close Task')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(recruiterDataSourceProvider).closeTask(task.id);
                        ref.invalidate(recruiterTasksProvider(status));
                      } catch (e) {
                        if (context.mounted) HireXSnackbar.show(context, message: 'Failed: $e', isError: true);
                      }
                    }
                  },
                ),
              if (!task.isPublished)
                _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: AppColors.error,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Delete Draft?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => dialogCtx.pop(false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => dialogCtx.pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await ref.read(recruiterDataSourceProvider).deleteTask(task.id);
                        ref.invalidate(recruiterTasksProvider(status));
                      } catch (e) {
                        if (context.mounted) HireXSnackbar.show(context, message: 'Failed: $e', isError: true);
                      }
                    }
                  },
                ),
              _ActionButton(
                label: 'Duplicate',
                icon: Icons.copy_outlined,
                onTap: () async {
                  try {
                    await ref.read(recruiterDataSourceProvider).duplicateTask(task.id);
                    ref.invalidate(recruiterTasksProvider('draft'));
                    if (context.mounted) HireXSnackbar.show(context, message: 'Task duplicated as draft.');
                  } catch (e) {
                    if (context.mounted) HireXSnackbar.show(context, message: 'Failed: $e', isError: true);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.color});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (color ?? AppColors.primary).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color ?? AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
