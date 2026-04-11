import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_avatar.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/messaging_providers.dart';

class ThreadListPage extends ConsumerWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadListProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isCandidate = user?.isCandidate ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(threadListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64,
                        color: AppColors.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No messages yet', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      isCandidate
                          ? 'You will receive messages once shortlisted.'
                          : 'Shortlist a candidate to start messaging.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final thread = threads[i];
              final hasUnread = thread.unreadCount > 0;

              return GestureDetector(
                onTap: () => context.push('/messages/${thread.id}'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasUnread
                        ? AppColors.surfaceVariant.withOpacity(0.5)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasUnread
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      HireXAvatar(
                        name: thread.otherPartyName ?? '?',
                        imageUrl: thread.otherPartyAvatar,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    thread.otherPartyName ?? 'Unknown',
                                    style: AppTextStyles.labelLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (thread.lastMessageAt != null)
                                  Text(
                                    timeago.format(thread.lastMessageAt!),
                                    style: AppTextStyles.labelSmall,
                                  ),
                              ],
                            ),
                            if (thread.taskTitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Re: ${thread.taskTitle}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (thread.lastMessagePreview != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                thread.lastMessagePreview!.length > 60
                                    ? '${thread.lastMessagePreview!.substring(0, 60)}...'
                                    : thread.lastMessagePreview!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
