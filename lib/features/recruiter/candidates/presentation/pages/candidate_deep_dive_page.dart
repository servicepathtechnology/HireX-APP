import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/hirex_button.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../../shared/widgets/hirex_tag.dart';
import '../../../presentation/providers/recruiter_providers.dart';

final _candidateProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final ds = ref.read(recruiterDataSourceProvider);
  final res = await ds.dio.get('/api/v1/profile/$userId');
  return res.data as Map<String, dynamic>;
});

class CandidateDeepDivePage extends ConsumerWidget {
  const CandidateDeepDivePage({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_candidateProfileProvider(userId));

    return HireXScaffold(
      appBar: AppBar(title: const Text('Candidate Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _CandidateContent(data: data, userId: userId),
      ),
    );
  }
}

class _CandidateContent extends ConsumerWidget {
  const _CandidateContent({required this.data, required this.userId});
  final Map<String, dynamic> data;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final skillScore = data['skill_score'] as Map<String, dynamic>? ?? {};
    final badges = data['badges'] as List? ?? [];
    final recentSubs = data['recent_submissions'] as List? ?? [];
    final skillTags = List<String>.from(profile['skill_tags'] as List? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity card
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url'] as String) : null,
                child: user['avatar_url'] == null ? const Icon(Icons.person, size: 32) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] as String? ?? 'Candidate', style: AppTextStyles.headlineLarge),
                    if (profile['headline'] != null)
                      Text(profile['headline'] as String, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.7))),
                    if (profile['city'] != null)
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14),
                        const SizedBox(width: 4),
                        Text(profile['city'] as String, style: AppTextStyles.bodySmall),
                      ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Skill score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skill Score', style: AppTextStyles.bodySmall),
                    Text('${skillScore['overall'] ?? 0}', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Percentile', style: AppTextStyles.bodySmall),
                    Text('Top ${(100 - ((skillScore['percentile'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)}%', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Links
          Row(
            children: [
              if (profile['github_url'] != null)
                _LinkButton(label: 'GitHub', url: profile['github_url'] as String, icon: Icons.code),
              if (profile['linkedin_url'] != null) ...[
                const SizedBox(width: 8),
                _LinkButton(label: 'LinkedIn', url: profile['linkedin_url'] as String, icon: Icons.work_outline),
              ],
              if (profile['portfolio_url'] != null) ...[
                const SizedBox(width: 8),
                _LinkButton(label: 'Portfolio', url: profile['portfolio_url'] as String, icon: Icons.web),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Skills
          if (skillTags.isNotEmpty) ...[
            Text('Skills', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: skillTags.map((s) => HireXTag(label: s)).toList()),
            const SizedBox(height: 16),
          ],

          // Activity stats
          Text('Activity Stats', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatCard(label: 'Attempted', value: '${stats['tasks_attempted'] ?? 0}'),
              const SizedBox(width: 8),
              _StatCard(label: 'Scored', value: '${stats['tasks_scored'] ?? 0}'),
              const SizedBox(width: 8),
              _StatCard(label: 'Best Rank', value: stats['best_rank'] != null ? '#${stats['best_rank']}' : '-'),
              const SizedBox(width: 8),
              _StatCard(label: 'Avg Score', value: stats['average_score'] != null ? '${(stats['average_score'] as num).toStringAsFixed(1)}' : '-'),
            ],
          ),
          const SizedBox(height: 16),

          // Performance history
          if (recentSubs.isNotEmpty) ...[
            Text('Performance History', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            ...recentSubs.take(5).map((s) {
              final sub = s as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sub['task_id'] as String? ?? 'Task', style: AppTextStyles.bodyMedium),
                trailing: sub['total_score'] != null
                    ? Text('${(sub['total_score'] as num).toStringAsFixed(1)} / 100', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary))
                    : null,
              );
            }),
            const SizedBox(height: 16),
          ],

          // Badges
          if (badges.isNotEmpty) ...[
            Text('Badges', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.where((b) => (b as Map)['earned'] == true).map((b) {
                final badge = b as Map<String, dynamic>;
                return Chip(
                  label: Text(badge['name'] as String),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Actions
          HireXButton(
            label: 'Shortlist this Candidate',
            onPressed: () async {
              HireXSnackbar.show(context, message: 'Please shortlist from the submissions dashboard.');
            },
          ),
          const SizedBox(height: 8),
          HireXButton(
            label: 'Message (Coming in Part 4)',
            variant: HireXButtonVariant.secondary,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.url, required this.icon});
  final String label;
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => launchUrl(Uri.parse(url)),
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.divider),
        foregroundColor: AppColors.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
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
