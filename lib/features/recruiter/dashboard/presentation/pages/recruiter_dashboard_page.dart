import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/domain_badge.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../../../data/models/recruiter_models.dart';

class RecruiterDashboardPage extends ConsumerWidget {
  const RecruiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final dashboardAsync = ref.watch(recruiterDashboardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(recruiterDashboardProvider.future),
          child: dashboardAsync.when(
            loading: () => const Center(child: HireXLoader()),
            error: (e, _) => Center(
              child: Text('Error: $e', style: AppTextStyles.bodyMedium),
            ),
            data: (data) => _DashboardContent(
              data: data,
              userName: user?.fullName ?? '',
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.userName});
  final Map<String, dynamic> data;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final stats = DashboardStatsModel.fromJson(
      data['stats'] as Map<String, dynamic>,
    );
    final activeTasks = (data['active_tasks'] as List? ?? [])
        .map((e) => RecruiterTaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final recentSubs = data['recent_submissions'] as List? ?? [];

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _HeroHeader(greeting: greeting, userName: userName),
          ),
          title: Text(
            'Dashboard',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
          titleSpacing: 16,
          actions: [_NotificationBell(), const SizedBox(width: 12)],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _PostTaskBanner(),
              const SizedBox(height: 24),
              _StatsGrid(stats: stats),
              const SizedBox(height: 28),
              if (activeTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Active Tasks',
                  actionLabel: 'View All',
                  onAction: () => context.push('/recruiter/my-tasks'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: activeTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _ActiveTaskCard(task: activeTasks[i]),
                  ),
                ),
                const SizedBox(height: 28),
              ],
              _SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              _QuickActionsRow(),
              const SizedBox(height: 28),
              if (recentSubs.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Recent Submissions',
                  actionLabel: 'See All',
                  onAction: () => context.push('/recruiter/my-tasks'),
                ),
                const SizedBox(height: 8),
                ...recentSubs
                    .take(5)
                    .map((s) => _RecentSubmissionTile(data: s as Map<String, dynamic>)),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.greeting, required this.userName});
  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'H',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          firstName.isNotEmpty ? firstName : 'Partner',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Hiring Partner',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Post Task Banner ──────────────────────────────────────────────────────────

class _PostTaskBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/recruiter/post-task/basics'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE94560), Color(0xFFB91C3C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Top Talent',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Post a task and discover skilled candidates',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Post Task',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final DashboardStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Active Tasks',
              value: '${stats.activeTasks}',
              icon: Icons.rocket_launch_outlined,
              iconColor: AppColors.primary,
              bgColor: AppColors.primary.withValues(alpha: 0.1),
              onTap: () => context.push('/recruiter/my-tasks'),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Submissions',
              value: '${stats.totalSubmissions}',
              icon: Icons.inbox_outlined,
              iconColor: const Color(0xFF3B82F6),
              bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              onTap: () => context.push('/recruiter/my-tasks'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Pending Review',
              value: '${stats.pendingReview}',
              icon: Icons.pending_actions_outlined,
              iconColor: AppColors.warning,
              bgColor: AppColors.warning.withValues(alpha: 0.1),
              onTap: () => context.push('/recruiter/my-tasks'),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Hires Made',
              value: '${stats.hiresMade}',
              icon: Icons.handshake_outlined,
              iconColor: AppColors.success,
              bgColor: AppColors.success.withValues(alpha: 0.1),
              onTap: () => context.push('/recruiter/pipeline'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Active Task Card ──────────────────────────────────────────────────────────

class _ActiveTaskCard extends StatelessWidget {
  const _ActiveTaskCard({required this.task});
  final RecruiterTaskModel task;

  @override
  Widget build(BuildContext context) {
    final daysLeft = task.deadline != null
        ? task.deadline!.difference(DateTime.now()).inDays
        : null;
    final isUrgent = daysLeft != null && daysLeft <= 2;

    return GestureDetector(
      onTap: () => context.push('/recruiter/tasks/${task.id}/submissions'),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DomainBadge(domain: task.domain),
                const Spacer(),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Urgent',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: AppTextStyles.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const Divider(color: Color(0xFF2A2A4A), height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 12,
                  color: isUrgent
                      ? AppColors.error
                      : AppColors.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  daysLeft != null ? '$daysLeft days left' : 'No deadline',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isUrgent
                        ? AppColors.error
                        : AppColors.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.group_outlined,
                  size: 12,
                  color: AppColors.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.submissionCount}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'Post Task',
        color: AppColors.primary,
        bg: AppColors.primary.withValues(alpha: 0.1),
        route: '/recruiter/post-task/basics',
      ),
      _QAction(
        icon: Icons.account_tree_outlined,
        label: 'Pipeline',
        color: const Color(0xFF3B82F6),
        bg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        route: '/recruiter/pipeline',
      ),
      _QAction(
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        color: AppColors.success,
        bg: AppColors.success.withValues(alpha: 0.1),
        route: '/recruiter/analytics',
      ),
      _QAction(
        icon: Icons.workspace_premium_outlined,
        label: 'Upgrade',
        color: AppColors.warning,
        bg: AppColors.warning.withValues(alpha: 0.1),
        route: '/recruiter/subscription',
      ),
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => context.push(a.route),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: a.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QAction {
  const _QAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.route,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final String route;
}

// ── Recent Submission Tile ────────────────────────────────────────────────────

class _RecentSubmissionTile extends StatelessWidget {
  const _RecentSubmissionTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final submittedAt = data['submitted_at'] != null
        ? DateTime.tryParse(data['submitted_at'] as String)
        : null;
    final status = data['status'] as String? ?? 'submitted';

    return GestureDetector(
      onTap: () =>
          context.push('/recruiter/submissions/${data['submission_id']}/score'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.onSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['task_title'] as String? ?? 'Task',
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submittedAt != null
                        ? timeago.format(submittedAt)
                        : 'recently',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'scored':
        color = AppColors.success;
        break;
      case 'shortlisted':
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Notification Bell ─────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: AppColors.onBackground,
              size: 20,
            ),
            if (count > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
