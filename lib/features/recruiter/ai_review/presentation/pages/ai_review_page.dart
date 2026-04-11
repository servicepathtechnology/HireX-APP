import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/dio_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_card.dart';
import '../../../../../shared/widgets/hirex_loader.dart';
import '../providers/ai_review_providers.dart';

class AIReviewPage extends ConsumerStatefulWidget {
  const AIReviewPage({super.key, required this.submissionId});
  final String submissionId;

  @override
  ConsumerState<AIReviewPage> createState() => _AIReviewPageState();
}

class _AIReviewPageState extends ConsumerState<AIReviewPage> {
  final _feedbackController = TextEditingController();
  bool _isApproving = false;
  String? _jobId;
  bool _isEnqueuing = false;

  @override
  void initState() {
    super.initState();
    // Try to load existing review; if not found, offer to enqueue
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _enqueueAndPoll() async {
    setState(() => _isEnqueuing = true);
    final jobId = await enqueueAIScoring(DioClient(), widget.submissionId);
    setState(() {
      _isEnqueuing = false;
      _jobId = jobId;
    });
  }

  Future<void> _approve({bool withOverrides = false}) async {
    setState(() => _isApproving = true);
    final overrides = withOverrides
        ? ref.read(scoreOverridesProvider(widget.submissionId))
        : null;

    final ok = await approveAIScores(
      DioClient(),
      widget.submissionId,
      overrides: overrides,
      feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
    );

    setState(() => _isApproving = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores approved and published to candidate.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(aiReviewProvider(widget.submissionId));

    // If a job was just enqueued, show polling UI
    if (_jobId != null) {
      return _AIJobPollingView(
        jobId: _jobId!,
        submissionId: widget.submissionId,
        onComplete: () {
          setState(() => _jobId = null);
          ref.invalidate(aiReviewProvider(widget.submissionId));
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Score Review'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Powered by GPT-4o', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: reviewAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => _NoJobView(
          isEnqueuing: _isEnqueuing,
          onEnqueue: _enqueueAndPoll,
        ),
        data: (review) {
          final job = review['job'] as Map<String, dynamic>;
          final task = review['task'] as Map<String, dynamic>;
          final aiScores = job['ai_scores'] as Map<String, dynamic>? ?? {};
          final aiFlags = job['ai_flags'] as Map<String, dynamic>?;
          final aiSummary = job['ai_summary'] as String?;
          final criteria = (task['evaluation_criteria'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          if (_feedbackController.text.isEmpty && aiSummary != null) {
            _feedbackController.text = aiSummary;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Summary
                if (aiSummary != null) ...[
                  HireXCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('AI Executive Summary', style: AppTextStyles.labelLarge),
                        ]),
                        const SizedBox(height: 8),
                        Text(aiSummary, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Flags
                if (aiFlags != null) ...[
                  if (aiFlags['plagiarism_suspected'] == true)
                    _FlagCard(
                      color: Colors.amber,
                      icon: Icons.warning_amber_rounded,
                      message: 'AI flagged potential copied content. Review carefully before scoring.',
                      reason: aiFlags['reason'] as String?,
                    ),
                  if (aiFlags['ai_generated_suspected'] == true)
                    _FlagCard(
                      color: Colors.orange,
                      icon: Icons.smart_toy_outlined,
                      message: 'AI detected possible AI-generated submission. Human judgment required.',
                      reason: aiFlags['reason'] as String?,
                    ),
                  const SizedBox(height: 16),
                ],

                // Criteria scores
                Text('Criterion Scores', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                ...criteria.map((c) {
                  final name = c['name'] as String? ?? '';
                  final weight = c['weight'] as num? ?? 0;
                  final scoreData = aiScores[name] as Map<String, dynamic>?;
                  final aiScore = (scoreData?['score'] as num?)?.toDouble() ?? 0;
                  final reasoning = scoreData?['reasoning'] as String?;
                  final suggestion = scoreData?['suggestion'] as String?;

                  return _CriterionCard(
                    name: name,
                    weight: weight.toInt(),
                    aiScore: aiScore,
                    reasoning: reasoning,
                    suggestion: suggestion,
                    submissionId: widget.submissionId,
                  );
                }),

                const SizedBox(height: 16),

                // Live total
                _LiveTotalCard(
                  submissionId: widget.submissionId,
                  aiScores: aiScores,
                  criteria: criteria,
                ),

                const SizedBox(height: 16),

                // Feedback
                Text('Recruiter Feedback', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Edit feedback for candidate...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                if (_isApproving)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve AI Scores'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _approve(withOverrides: true),
                          icon: const Icon(Icons.tune),
                          label: const Text('Approve with Overrides'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            '/recruiter/submissions/${widget.submissionId}/score',
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Score Manually Instead'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlagCard extends StatefulWidget {
  const _FlagCard({required this.color, required this.icon, required this.message, this.reason});
  final Color color;
  final IconData icon;
  final String message;
  final String? reason;

  @override
  State<_FlagCard> createState() => _FlagCardState();
}

class _FlagCardState extends State<_FlagCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.message, style: AppTextStyles.bodyMedium)),
              ],
            ),
            if (widget.reason != null && widget.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Hide details' : 'Show details',
                  style: AppTextStyles.labelSmall.copyWith(color: widget.color),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 4),
                Text(widget.reason!, style: AppTextStyles.bodySmall),
              ],
            ],
          ],
        ),
      );
}

class _CriterionCard extends ConsumerStatefulWidget {
  const _CriterionCard({
    required this.name,
    required this.weight,
    required this.aiScore,
    this.reasoning,
    this.suggestion,
    required this.submissionId,
  });
  final String name;
  final int weight;
  final double aiScore;
  final String? reasoning;
  final String? suggestion;
  final String submissionId;

  @override
  ConsumerState<_CriterionCard> createState() => _CriterionCardState();
}

class _CriterionCardState extends ConsumerState<_CriterionCard> {
  bool _overriding = false;

  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(scoreOverridesProvider(widget.submissionId));
    final displayScore = overrides[widget.name] ?? widget.aiScore;

    return HireXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.name, style: AppTextStyles.labelLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${widget.weight}%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${displayScore.toStringAsFixed(0)} / 100',
            style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
          ),
          if (widget.reasoning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(widget.reasoning!, style: AppTextStyles.bodySmall),
            ),
          ],
          if (widget.suggestion != null) ...[
            const SizedBox(height: 6),
            Text(
              'Suggestion: ${widget.suggestion}',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _overriding = !_overriding),
            child: Text(
              _overriding ? 'Cancel Override' : 'Override AI Score',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          ),
          if (_overriding) ...[
            const SizedBox(height: 8),
            Slider(
              value: displayScore,
              min: 0,
              max: 100,
              divisions: 100,
              label: displayScore.toStringAsFixed(0),
              activeColor: AppColors.primary,
              onChanged: (v) {
                ref.read(scoreOverridesProvider(widget.submissionId).notifier).state = {
                  ...ref.read(scoreOverridesProvider(widget.submissionId)),
                  widget.name: v,
                };
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveTotalCard extends ConsumerWidget {
  const _LiveTotalCard({
    required this.submissionId,
    required this.aiScores,
    required this.criteria,
  });
  final String submissionId;
  final Map<String, dynamic> aiScores;
  final List<Map<String, dynamic>> criteria;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(scoreOverridesProvider(submissionId));
    final hasOverrides = overrides.isNotEmpty;

    double total = 0;
    double totalWeight = 0;
    for (final c in criteria) {
      final name = c['name'] as String? ?? '';
      final weight = (c['weight'] as num?)?.toDouble() ?? 0;
      final scoreData = aiScores[name] as Map<String, dynamic>?;
      final score = overrides[name] ?? (scoreData?['score'] as num?)?.toDouble() ?? 0;
      total += score * (weight / 100);
      totalWeight += weight;
    }
    if (totalWeight > 0) total = total * (100 / totalWeight);

    return HireXCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasOverrides ? 'Adjusted Total' : 'AI Total',
                  style: AppTextStyles.labelSmall,
                ),
                Text(
                  '${total.toStringAsFixed(1)} / 100',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (hasOverrides)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Overridden', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
            ),
        ],
      ),
    );
  }
}

// ── No job yet — offer to enqueue ─────────────────────────────────────────────

class _NoJobView extends StatelessWidget {
  const _NoJobView({required this.isEnqueuing, required this.onEnqueue});
  final bool isEnqueuing;
  final VoidCallback onEnqueue;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('No AI scoring yet', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Run AI scoring to get per-criterion scores, reasoning, and flags for this submission.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isEnqueuing)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: onEnqueue,
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Start AI Scoring'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ── Polling view — shown while job is processing ──────────────────────────────

class _AIJobPollingView extends ConsumerWidget {
  const _AIJobPollingView({
    required this.jobId,
    required this.submissionId,
    required this.onComplete,
  });
  final String jobId;
  final String submissionId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(aiJobProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Scoring in Progress')),
      body: jobAsync.when(
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jobData) {
          switch (jobData.pollState) {
            case AIJobPollState.completed:
              // Auto-navigate to review
              WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
              return const Center(child: HireXLoader());

            case AIJobPollState.failed:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('AI scoring failed', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        jobData.job?['error_message'] as String? ??
                            'An error occurred. Please score manually.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push(
                          '/recruiter/submissions/$submissionId/score',
                        ),
                        child: const Text('Score Manually'),
                      ),
                    ],
                  ),
                ),
              );

            case AIJobPollState.timeout:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 64, color: AppColors.warning),
                      const SizedBox(height: 16),
                      Text('Taking longer than expected', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'We will notify you when AI scoring is complete.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );

            case AIJobPollState.polling:
              final count = jobData.pollCount;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text('AI is evaluating the submission...', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'This usually takes 15–30 seconds.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Checking... ($count/20)',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
