import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../../../../../shared/widgets/hirex_button.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class ScoreSubmissionPage extends ConsumerStatefulWidget {
  const ScoreSubmissionPage({required this.submissionId, super.key});
  final String submissionId;

  @override
  ConsumerState<ScoreSubmissionPage> createState() => _ScoreSubmissionPageState();
}

class _ScoreSubmissionPageState extends ConsumerState<ScoreSubmissionPage> {
  final _feedbackCtrl = TextEditingController();
  bool _criteriaInitialized = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreSubmissionProvider(widget.submissionId));
    final notifier = ref.read(scoreSubmissionProvider(widget.submissionId).notifier);

    // Initialize criteria from task evaluation_criteria once submission loads
    if (!_criteriaInitialized && state.submission != null && state.criterionScores.isEmpty) {
      _criteriaInitialized = true;
      // Load task criteria to initialize scoring sliders
      Future.microtask(() async {
        final ds = ref.read(recruiterDataSourceProvider);
        try {
          final taskData = await ds.getTask(state.submission!.taskId);
          final criteria = taskData.evaluationCriteria;
          if (criteria.isNotEmpty) {
            ref.read(scoreSubmissionProvider(widget.submissionId).notifier).initCriteria(criteria);
          } else {
            ref.read(scoreSubmissionProvider(widget.submissionId).notifier).initCriteria([
              {'name': 'Accuracy', 'weight': 40},
              {'name': 'Approach & Thinking', 'weight': 30},
              {'name': 'Completeness', 'weight': 20},
              {'name': 'Efficiency / Speed', 'weight': 10},
            ]);
          }
        } catch (_) {
          ref.read(scoreSubmissionProvider(widget.submissionId).notifier).initCriteria([
            {'name': 'Accuracy', 'weight': 40},
            {'name': 'Approach & Thinking', 'weight': 30},
            {'name': 'Completeness', 'weight': 20},
            {'name': 'Efficiency / Speed', 'weight': 10},
          ]);
        }
      });
    }

    if (state.isSaved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HireXSnackbar.show(context, message: 'Score saved successfully!');
          context.pop();
        }
      });
    }

    return HireXScaffold(
      appBar: AppBar(
        title: const Text('Score Submission'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.criterionScores.isNotEmpty) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Unsaved Changes'),
                  content: const Text('You have unsaved scores. Are you sure you want to go back?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
                    ElevatedButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: const Text('Go Back')),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: state.isLoading
          ? const Center(child: HireXLoader())
          : state.submission == null
              ? Center(child: Text('Submission not found', style: AppTextStyles.bodyMedium))
              : _ScoreContent(
                  submissionId: widget.submissionId,
                  feedbackCtrl: _feedbackCtrl,
                ),
    );
  }
}

class _ScoreContent extends ConsumerWidget {
  const _ScoreContent({required this.submissionId, required this.feedbackCtrl});
  final String submissionId;
  final TextEditingController feedbackCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreSubmissionProvider(submissionId));
    final notifier = ref.read(scoreSubmissionProvider(submissionId).notifier);
    final sub = state.submission!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submission viewer
          Text('Submission', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),

          if (sub.textContent != null && sub.textContent!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: MarkdownBody(data: sub.textContent!),
            ),
            const SizedBox(height: 12),
          ],

          if (sub.codeContent != null && sub.codeContent!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                        child: Text(sub.codeLanguage ?? 'code', style: AppTextStyles.bodySmall),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(sub.codeContent!, style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace', color: Colors.greenAccent)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (sub.linkUrl != null) ...[
            _LinkCard(url: sub.linkUrl!, icon: Icons.link),
            const SizedBox(height: 12),
          ],

          if (sub.recordingUrl != null) ...[
            _LinkCard(url: sub.recordingUrl!, icon: Icons.videocam_outlined),
            const SizedBox(height: 12),
          ],

          if (sub.fileUrls != null && sub.fileUrls!.isNotEmpty) ...[
            ...sub.fileUrls!.map((url) => _FileCard(url: url)),
            const SizedBox(height: 12),
          ],

          if (sub.notes != null && sub.notes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Candidate Notes', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(sub.notes!, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // Scoring panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scoring Panel', style: AppTextStyles.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${state.totalScore.toStringAsFixed(1)} / 100',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total = ${state.criterionScores.map((c) => '(${c['criterion_name']} × ${c['weight']}%)').join(' + ')}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),

          ...state.criterionScores.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final score = (c['score'] as num?)?.toDouble() ?? 50.0;
            final weight = (c['weight'] as num?)?.toDouble() ?? 25.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c['criterion_name'] as String, style: AppTextStyles.titleSmall)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('Weight: ${weight.toStringAsFixed(0)}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: score,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: AppColors.primary,
                          onChanged: (v) => notifier.updateScore(i, v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${score.toStringAsFixed(0)}', style: AppTextStyles.titleSmall, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Feedback
          Text('Recruiter Feedback (optional)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: feedbackCtrl,
            maxLines: 4,
            maxLength: 1000,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Share feedback to help the candidate improve. This will be visible to them.',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
            ),
            onChanged: notifier.setFeedback,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Reject Submission?'),
                        content: const Text('This will mark the submission as rejected.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(recruiterDataSourceProvider).rejectSubmission(submissionId);
                      if (context.mounted) context.pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () => notifier.saveScore(shortlist: false),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: state.isLoading ? const HireXLoader(size: 20) : const Text('Save Score'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () => notifier.saveScore(shortlist: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Save + Shortlist'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.url, required this.icon});
  final String url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(url, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final fileName = url.split('/').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(fileName, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.download_outlined, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
