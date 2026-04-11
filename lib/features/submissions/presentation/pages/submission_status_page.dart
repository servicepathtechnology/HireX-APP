import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../../../shared/widgets/score_card.dart';
import '../../../tasks/data/datasources/task_remote_datasource.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/submission_entity.dart';

final _submissionDetailProvider =
    FutureProvider.family<SubmissionEntity, String>((ref, id) async {
  final ds = ref.read(taskDataSourceProvider);
  final model = await ds.getSubmission(id);
  return model.toEntity();
});

class SubmissionStatusPage extends ConsumerWidget {
  const SubmissionStatusPage({super.key, required this.submissionId});
  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(_submissionDetailProvider(submissionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Submission'),
        actions: [
          subAsync.whenOrNull(
            data: (sub) => sub.isScored
                ? IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Share.share(
                      'I scored ${sub.totalScore?.toStringAsFixed(1)}/100 on HireX! 🎯',
                    ),
                  )
                : null,
          ) ?? const SizedBox(),
        ],
      ),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Submission not found', style: AppTextStyles.bodyLarge)),
        data: (sub) => _SubmissionBody(submission: sub),
      ),
    );
  }
}

class _SubmissionBody extends StatelessWidget {
  const _SubmissionBody({required this.submission});
  final SubmissionEntity submission;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _StatusBadge(status: submission.status),
          const SizedBox(height: 16),

          // Score card (if scored)
          if (submission.isScored) ...[
            ScoreCard(submission: submission),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/candidate/submissions/${submission.id}/score-explanation'),
                icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: const Text('See Score Explanation'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.push('/candidate/leaderboard/${submission.taskId}'),
              icon: const Icon(Icons.leaderboard),
              label: const Text('View Leaderboard'),
            ),
            const SizedBox(height: 16),
          ],

          // Recruiter feedback
          if (submission.recruiterFeedback != null) ...[
            HireXCard(
              border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recruiter Feedback', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(submission.recruiterFeedback!, style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submitted content
          Text('Your Submission', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),

          if (submission.textContent?.isNotEmpty == true) ...[
            _ContentSection(
              icon: Icons.text_fields,
              title: 'Text Response',
              child: Text(submission.textContent!, style: AppTextStyles.bodyLarge),
            ),
            const SizedBox(height: 12),
          ],

          if (submission.codeContent?.isNotEmpty == true) ...[
            _ContentSection(
              icon: Icons.code,
              title: 'Code (${submission.codeLanguage ?? ""})',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  submission.codeContent!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (submission.fileUrls?.isNotEmpty == true) ...[
            _ContentSection(
              icon: Icons.attach_file,
              title: 'Files',
              child: Column(
                children: submission.fileUrls!
                    .map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(url.split('/').last, style: AppTextStyles.bodyMedium),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (submission.linkUrl?.isNotEmpty == true) ...[
            _ContentSection(
              icon: Icons.link,
              title: 'Link',
              child: Text(submission.linkUrl!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
          ],

          if (submission.recordingUrl?.isNotEmpty == true) ...[
            _ContentSection(
              icon: Icons.videocam_outlined,
              title: 'Recording',
              child: Text(submission.recordingUrl!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
          ],

          // Submitted at
          if (submission.submittedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Submitted ${_formatDate(submission.submittedAt!)}',
              style: AppTextStyles.labelSmall,
            ),
          ],

          // Leaderboard teaser (not scored)
          if (!submission.isScored && !submission.isDraft) ...[
            const SizedBox(height: 16),
            HireXCard(
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Leaderboard will be available after scoring closes. Check back later.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    final label = _labels[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => HireXCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.onSurface),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.headlineMedium),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}
