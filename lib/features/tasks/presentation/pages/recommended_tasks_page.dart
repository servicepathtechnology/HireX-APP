import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../../../shared/widgets/domain_badge.dart';
import '../../../../shared/widgets/hirex_card.dart';

final recommendedTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await DioClient().instance.get(
    '/api/v1/tasks/recommended',
    queryParameters: {'page': 1, 'page_size': 20},
  );
  final data = res.data as Map<String, dynamic>;
  return (data['items'] as List).cast<Map<String, dynamic>>();
});

class RecommendedTasksPage extends ConsumerWidget {
  const RecommendedTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(recommendedTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('For You')),
      body: tasksAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.onSurface),
                const SizedBox(height: 16),
                Text('Complete your profile and submit your first task to unlock personalized recommendations',
                    style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 64,
                        color: AppColors.onSurface),
                    const SizedBox(height: 16),
                    Text(
                      'Complete your profile and submit your first task to unlock personalized recommendations',
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
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RecommendedTaskCard(task: tasks[i]),
          );
        },
      ),
    );
  }
}

class _RecommendedTaskCard extends StatelessWidget {
  const _RecommendedTaskCard({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final id = task['id'] as String? ?? '';
    final title = task['title'] as String? ?? '';
    final domain = task['domain'] as String? ?? '';
    final difficulty = task['difficulty'] as String? ?? '';
    final estimatedHours = (task['estimated_hours'] as num?)?.toDouble();
    final submissionCount = task['submission_count'] as int? ?? 0;
    final matchReasons = (task['match_reasons'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () => context.push('/candidate/tasks/$id'),
      child: HireXCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppTextStyles.labelLarge)),
                _RecommendedChip(reasons: matchReasons),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                DomainBadge(domain: domain, small: true),
                const SizedBox(width: 8),
                _DifficultyBadge(difficulty: difficulty),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (estimatedHours != null) ...[
                  const Icon(Icons.schedule, size: 14, color: AppColors.onSurface),
                  const SizedBox(width: 4),
                  Text('${estimatedHours.toStringAsFixed(0)}h', style: AppTextStyles.labelSmall),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.people_outline, size: 14, color: AppColors.onSurface),
                const SizedBox(width: 4),
                Text('$submissionCount submissions', style: AppTextStyles.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedChip extends StatelessWidget {
  const _RecommendedChip({required this.reasons});
  final List<String> reasons;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: reasons.isEmpty ? 'Recommended for you' : reasons.join(' • '),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Recommended', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      );
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  static const _colors = {
    'beginner': Color(0xFF10B981),
    'intermediate': Color(0xFF3B82F6),
    'advanced': Color(0xFFF59E0B),
    'expert': Color(0xFFE94560),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[difficulty] ?? AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
