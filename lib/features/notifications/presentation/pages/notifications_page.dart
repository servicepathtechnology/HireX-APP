import 'dart:async';
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

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30s for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(notificationsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          loading: () => const Center(child: HireXLoader()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 64,
                        color: AppColors.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No notifications yet', style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            }

            final unread = notifications.where((n) => !n.isRead).length;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + (unread > 0 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (unread > 0 && i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unread unread',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final idx = unread > 0 ? i - 1 : i;
                return _NotificationTile(notification: notifications[idx]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  IconData _iconForType(String type) {
    switch (type) {
      case 'challenge_invite': return Icons.sports_esports_rounded;
      case 'challenge_accepted': return Icons.check_circle_outline_rounded;
      case 'challenge_declined': return Icons.cancel_outlined;
      case 'invite_expired': return Icons.timer_off_rounded;
      case 'match_starting': return Icons.play_circle_outline_rounded;
      case 'match_result_ready': return Icons.emoji_events_outlined;
      case 'elo_tier_changed': return Icons.leaderboard_rounded;
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

  Color _colorForType(String type) {
    switch (type) {
      case 'challenge_invite': return AppColors.warning;
      case 'challenge_accepted': return AppColors.success;
      case 'challenge_declined': return AppColors.error;
      case 'invite_expired': return AppColors.error;
      case 'match_starting': return AppColors.primary;
      case 'match_result_ready': return const Color(0xFFF59E0B);
      case 'elo_tier_changed': return const Color(0xFF8B5CF6);
      case 'hired': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'challenge_invite': return 'Challenge Invite';
      case 'challenge_accepted': return 'Challenge Accepted';
      case 'challenge_declined': return 'Challenge Declined';
      case 'invite_expired': return 'Invite Expired';
      case 'match_starting': return 'Match Starting';
      case 'match_result_ready': return 'Result Ready';
      case 'elo_tier_changed': return 'ELO Tier Changed';
      default: return '';
    }
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    final data = notification.data;
    final type = notification.type;

    // Challenge-specific navigation
    final matchId = data?['match_id'] as String?;
    if (matchId != null) {
      switch (type) {
        case 'challenge_invite':
          context.push('/challenges/1v1/$matchId/invite');
          return;
        case 'challenge_accepted':
        case 'match_starting':
          context.push('/challenges/1v1/$matchId/invite');
          return;
        case 'challenge_declined':
        case 'invite_expired':
          context.go('/challenges/1v1');
          return;
        case 'match_result_ready':
          context.push('/challenges/1v1/$matchId/result');
          return;
        case 'elo_tier_changed':
          context.go('/challenges/1v1');
          return;
      }
    }

    if (data == null) return;

    final taskId = data['task_id'] as String?;
    final submissionId = data['submission_id'] as String?;
    final pipelineId = data['pipeline_id'] as String?;
    final threadId = data['thread_id'] as String?;

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
    final color = _colorForType(notification.type);
    final typeLabel = _labelForType(notification.type);
    final isChallengeType = notification.type.startsWith('challenge_') ||
        notification.type == 'match_starting' ||
        notification.type == 'match_result_ready' ||
        notification.type == 'elo_tier_changed' ||
        notification.type == 'invite_expired';

    return GestureDetector(
      onTap: () {
        ref.read(notificationsProvider.notifier).markRead(notification.id);
        _onTap(context, ref);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForType(notification.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            )),
                      ),
                      if (isChallengeType && typeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeago.format(notification.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      if (!notification.isRead)
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
