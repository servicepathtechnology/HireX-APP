import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_avatar.dart';
import '../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../shared/widgets/hirex_tag.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../recruiter/presentation/providers/recruiter_providers.dart';

/// Recruiter profile view — updated for Part 3 with credibility stats.
class RecruiterProfilePage extends ConsumerWidget {
  const RecruiterProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);
    if (user == null) return const HireXScaffold(body: Center(child: CircularProgressIndicator()));

    final rp = user.recruiterProfile;
    final dashboardAsync = ref.watch(recruiterDashboardProvider);

    return HireXScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HireXAvatar(imageUrl: user.avatarUrl, name: user.fullName, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: AppTextStyles.headlineLarge),
                      if (rp?.roleAtCompany != null)
                        Text(rp!.roleAtCompany!, style: AppTextStyles.bodyMedium),
                      if (rp?.companyName != null)
                        Row(children: [
                          const Icon(Icons.business_outlined, size: 14, color: AppColors.onSurface),
                          const SizedBox(width: 4),
                          Text(rp!.companyName!, style: AppTextStyles.labelSmall),
                          if (rp.companySize != null) ...[
                            const SizedBox(width: 8),
                            Text('· ${rp.companySize}', style: AppTextStyles.labelSmall),
                          ],
                        ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (rp?.hiringDomains.isNotEmpty == true) ...[
              Text('Hiring domains', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rp!.hiringDomains.map((d) => HireXTag(label: d)).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Recruiter credibility stats
            Text('Credibility Stats', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            dashboardAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final stats = data['stats'] as Map<String, dynamic>? ?? {};
                return Column(
                  children: [
                    Row(
                      children: [
                        _StatCard(label: 'Tasks Posted', value: '${stats['active_tasks'] ?? 0}'),
                        const SizedBox(width: 8),
                        _StatCard(label: 'Submissions', value: '${stats['total_submissions'] ?? 0}'),
                        const SizedBox(width: 8),
                        _StatCard(label: 'Hires Made', value: '${stats['hires_made'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/recruiter/analytics'),
                            icon: const Icon(Icons.bar_chart, size: 16),
                            label: const Text('View Analytics'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/recruiter/billing'),
                            icon: const Icon(Icons.receipt_long_outlined, size: 16),
                            label: const Text('Billing'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.divider),
                              foregroundColor: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
