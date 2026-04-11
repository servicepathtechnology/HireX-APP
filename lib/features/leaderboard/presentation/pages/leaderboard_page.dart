import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_avatar.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(leaderboardProvider(taskId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leaderboard')),
      body: lbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty, size: 48, color: AppColors.onSurface),
              const SizedBox(height: 12),
              Text(
                'Leaderboard will be available after scoring closes. Check back later.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (data) => _LeaderboardBody(data: data),
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final entries = (data['entries'] as List<dynamic>?) ?? [];
    final totalScored = data['total_scored'] as int? ?? 0;
    final taskTitle = data['task_title'] as String? ?? '';
    final currentUserEntry = data['current_user_entry'];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(taskTitle, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('$totalScored candidates scored', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),

        // Top 3 podium
        if (entries.length >= 3)
          _PodiumRow(entries: entries.take(3).toList()),

        const SizedBox(height: 8),

        // Ranked list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i] as Map<String, dynamic>;
              final isCurrentUser = entry['is_current_user'] as bool? ?? false;
              return _RankRow(entry: entry, isCurrentUser: isCurrentUser);
            },
          ),
        ),

        // Sticky current user row if not in visible list
        if (currentUserEntry != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: _RankRow(
              entry: currentUserEntry as Map<String, dynamic>,
              isCurrentUser: true,
            ),
          ),
      ],
    );
  }
}

class _PodiumRow extends StatelessWidget {
  const _PodiumRow({required this.entries});
  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final entry = entries[i] as Map<String, dynamic>;
          final isAnon = entry['is_anonymous'] as bool? ?? false;
          final name = isAnon ? 'Anonymous' : (entry['candidate_name'] as String? ?? '');
          final score = (entry['total_score'] as num?)?.toDouble() ?? 0;
          final heights = [100.0, 80.0, 60.0];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(medals[i], style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              HireXAvatar(name: name, radius: 20),
              const SizedBox(height: 4),
              Text(
                name.length > 10 ? '${name.substring(0, 10)}...' : name,
                style: AppTextStyles.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                score.toStringAsFixed(1),
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
              ),
              Container(
                width: 80,
                height: heights[i],
                decoration: BoxDecoration(
                  color: [
                    const Color(0xFFFFD700),
                    const Color(0xFFC0C0C0),
                    const Color(0xFFCD7F32),
                  ][i].withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.isCurrentUser});
  final Map<String, dynamic> entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int? ?? 0;
    final isAnon = entry['is_anonymous'] as bool? ?? false;
    final name = isAnon ? 'Anonymous Candidate' : (entry['candidate_name'] as String? ?? '');
    final score = (entry['total_score'] as num?)?.toDouble() ?? 0;
    final percentile = (entry['percentile'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: AppTextStyles.labelLarge.copyWith(
                color: isCurrentUser ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
          HireXAvatar(name: name, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Top ${(100 - percentile).toStringAsFixed(1)}%',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
