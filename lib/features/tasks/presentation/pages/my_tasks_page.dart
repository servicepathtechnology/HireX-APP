import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../../submissions/domain/entities/submission_entity.dart';
import '../providers/task_providers.dart';

class MyTasksPage extends ConsumerStatefulWidget {
  const MyTasksPage({super.key});

  @override
  ConsumerState<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends ConsumerState<MyTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final subsAsync = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'In Progress'),
            Tab(text: 'Submitted'),
            Tab(text: 'Scored'),
          ],
        ),
      ),
      body: subsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(mySubmissionsProvider),
        ),
        data: (subs) => TabBarView(
          controller: _tabController,
          children: [
            _SubList(
              subs: subs.where((s) => s.isDraft).toList(),
              emptyMessage: 'No tasks in progress. Start solving a challenge!',
              tab: 'in_progress',
            ),
            _SubList(
              subs: subs.where((s) => s.isSubmitted || s.isUnderReview).toList(),
              emptyMessage: 'No submitted tasks yet.',
              tab: 'submitted',
            ),
            _SubList(
              subs: subs.where((s) => s.isScored).toList()
                ..sort((a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0)),
              emptyMessage: 'No scored tasks yet. Submit a solution to see your score here.',
              tab: 'scored',
            ),
          ],
        ),
      ),
    );
  }
}

class _SubList extends ConsumerWidget {
  const _SubList({
    required this.subs,
    required this.emptyMessage,
    required this.tab,
  });

  final List<SubmissionEntity> subs;
  final String emptyMessage;
  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppColors.onSurface.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(emptyMessage, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(mySubmissionsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subs.length,
        itemBuilder: (context, i) => _SubCard(sub: subs[i], tab: tab),
      ),
    );
  }
}

class _SubCard extends ConsumerWidget {
  const _SubCard({required this.sub, required this.tab});
  final SubmissionEntity sub;
  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(sub.id),
      direction: sub.isDraft ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Draft?'),
            content: const Text('This will permanently delete your draft. This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(mySubmissionsProvider.notifier).deleteSubmission(sub.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HireXCard(
          onTap: () {
            if (sub.isDraft) {
              context.push('/candidate/tasks/${sub.taskId}/submit');
            } else {
              context.push('/candidate/submissions/${sub.id}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sub.taskId.length >= 8
                          ? 'Task #${sub.taskId.substring(0, 8)}...'
                          : 'Task #${sub.taskId}',
                      style: AppTextStyles.headlineMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: sub.status),
                ],
              ),
              const SizedBox(height: 8),

              if (sub.isDraft) ...[
                Text(
                  'Last edited ${_timeAgo(sub.updatedAt)}',
                  style: AppTextStyles.labelSmall,
                ),
              ],

              if (sub.isSubmitted || sub.isUnderReview) ...[
                Text(
                  'Submitted ${_timeAgo(sub.submittedAt ?? sub.updatedAt)}',
                  style: AppTextStyles.labelSmall,
                ),
              ],

              if (sub.isScored && sub.totalScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${sub.totalScore!.toStringAsFixed(1)}/100',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: _scoreColor(sub.totalScore!),
                      ),
                    ),
                    if (sub.rank != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${sub.rank}',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  static const _labels = {
    'draft': 'Draft',
    'submitted': 'Submitted',
    'under_review': 'Under Review',
    'scored': 'Scored',
    'rejected': 'Rejected',
  };

  static const _colors = {
    'draft': Color(0xFF6B7280),
    'submitted': Color(0xFF4CAF50),
    'under_review': Color(0xFFFF9800),
    'scored': Color(0xFF3B82F6),
    'rejected': Color(0xFFE94560),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _labels[status] ?? status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
