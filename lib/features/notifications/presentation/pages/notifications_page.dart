import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../recruiter/presentation/providers/recruiter_providers.dart';
import '../../../recruiter/data/models/recruiter_models.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return HireXScaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  IconData _iconForType(String type) {
    switch (type) {
      case 'submission_scored': return Icons.star_outline;
      case 'shortlisted': return Icons.bookmark_outline;
      case 'stage_changed': return Icons.swap_horiz;
      case 'hired': return Icons.celebration_outlined;
      case 'task_closed': return Icons.lock_outline;
      case 'new_submission': return Icons.inbox_outlined;
      case 'submission_count_milestone': return Icons.emoji_events_outlined;
      case 'new_message': return Icons.chat_bubble_outline;
      case 'ai_scoring_complete': return Icons.auto_awesome_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  void _onTap(BuildContext context) {
    final data = notification.data;
    if (data == null) return;

    final taskId = data['task_id'] as String?;
    final submissionId = data['submission_id'] as String?;
    final pipelineId = data['pipeline_id'] as String?;
    final threadId = data['thread_id'] as String?;
    final type = data['type'] as String?;

    if (type == 'new_message' && threadId != null) {
      context.push('/messages/$threadId');
    } else if (type == 'submission_scored' && submissionId != null) {
      context.push('/candidate/submissions/$submissionId/score-explanation');
    } else if (type == 'ai_scoring_complete' && taskId != null) {
      context.push('/recruiter/tasks/$taskId/submissions');
    } else if (submissionId != null) {
      context.push('/recruiter/submissions/$submissionId/score');
    } else if (taskId != null) {
      context.push('/recruiter/tasks/$taskId/submissions');
    } else if (pipelineId != null) {
      context.push('/recruiter/pipeline');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(notificationsProvider.notifier).markRead(notification.id);
        _onTap(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: notification.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(notification.type), color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(notification.body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(height: 4),
                  Text(timeago.format(notification.createdAt), style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
