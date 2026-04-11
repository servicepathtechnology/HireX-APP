import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_button.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../../../shared/widgets/domain_badge.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class StepPreviewWidget extends ConsumerStatefulWidget {
  const StepPreviewWidget({super.key});

  @override
  ConsumerState<StepPreviewWidget> createState() => _StepPreviewWidgetState();
}

class _StepPreviewWidgetState extends ConsumerState<StepPreviewWidget> {
  bool _isProcessingPayment = false;

  static const _tierPrices = {'basic': 4999, 'standard': 9999, 'premium': 19999};
  static const _tierFeatures = {
    'basic': ['1 task', 'Max 50 submissions', 'Manual scoring only'],
    'standard': ['1 task', 'Unlimited submissions', 'AI summary stub', 'Recruiter analytics'],
    'premium': ['1 task', 'Unlimited submissions', 'Priority listing', 'Featured badge', 'Full analytics', 'Candidate export'],
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _publishFree() async {
    final state = ref.read(postTaskProvider);
    setState(() => _isProcessingPayment = true);
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      // Save/create the task first if not already saved
      String taskId;
      if (state.draftTaskId != null) {
        await ds.updateTask(state.draftTaskId!, _buildPayload(state, publish: true));
        taskId = state.draftTaskId!;
      } else {
        final task = await ds.createTask(_buildPayload(state, publish: true));
        taskId = task.id;
      }
      if (mounted) {
        ref.read(postTaskProvider.notifier).reset();
        HireXSnackbar.show(context, message: 'Task published! Waiting for submissions.');
        context.go('/recruiter/tasks/$taskId/submissions');
      }
    } catch (e) {
      if (mounted) HireXSnackbar.show(context, message: 'Failed to publish: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Map<String, dynamic> _buildPayload(PostTaskState state, {bool publish = false}) => {
    'title': state.title,
    'domain': state.domain,
    'task_type': state.taskType,
    'difficulty': state.difficulty,
    'skills_tested': state.skillsTested,
    'description': state.description,
    'problem_statement': state.problemStatement,
    'evaluation_criteria': state.evaluationCriteria,
    'deadline': state.deadline?.toIso8601String(),
    'submission_types': state.submissionTypes,
    'allowed_file_types': state.allowedFileTypes,
    'max_file_size_mb': state.maxFileSizeMb,
    'company_visible': state.companyVisible,
    'company_name': state.companyName,
    'prize_or_opportunity': state.prizeOrOpportunity,
    'estimated_hours': state.estimatedHours,
    'tier': state.tier,
    if (publish) 'is_published': true,
    if (publish) 'is_active': true,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postTaskProvider);
    final price = _tierPrices[state.tier] ?? 9999;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview & Publish', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('This is how your task will appear to candidates', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.7))),
          ),
          const SizedBox(height: 16),

          // Task preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DomainBadge(domain: state.domain),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
                      child: Text(state.difficulty, style: AppTextStyles.bodySmall),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () => ref.read(postTaskProvider.notifier).goToStep(0), child: const Text('Edit')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(state.title.isEmpty ? 'Task Title' : state.title, style: AppTextStyles.headlineLarge),
                if (state.prizeOrOpportunity != null) ...[
                  const SizedBox(height: 4),
                  Text(state.prizeOrOpportunity!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Description', style: AppTextStyles.titleSmall),
                    TextButton(onPressed: () => ref.read(postTaskProvider.notifier).goToStep(1), child: const Text('Edit')),
                  ],
                ),
                MarkdownBody(data: state.description.isEmpty ? '*No description*' : state.description.substring(0, state.description.length.clamp(0, 300))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Evaluation Rubric', style: AppTextStyles.titleSmall),
                    TextButton(onPressed: () => ref.read(postTaskProvider.notifier).goToStep(2), child: const Text('Edit')),
                  ],
                ),
                ...state.evaluationCriteria.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text('${c['name']}', style: AppTextStyles.bodySmall)),
                      Text('${c['weight']}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      state.deadline != null ? 'Deadline: ${DateFormat('dd MMM yyyy').format(state.deadline!)}' : 'No deadline set',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tier selection
          Text('Select Plan', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...['basic', 'standard', 'premium'].map((tier) {
            final isSelected = state.tier == tier;
            final tierPrice = _tierPrices[tier]!;
            final features = _tierFeatures[tier]!;
            return GestureDetector(
              onTap: () => ref.read(postTaskProvider.notifier).setTier(tier),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(tier[0].toUpperCase() + tier.substring(1), style: AppTextStyles.titleSmall),
                              if (tier == 'standard') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Recommended', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...features.map((f) => Text('• $f', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.7)))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${NumberFormat('#,##0').format(tierPrice)}', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                        if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          HireXButton(
            label: _isProcessingPayment ? 'Publishing...' : 'Publish Task — Free',
            onPressed: _isProcessingPayment ? null : _publishFree,
            isLoading: _isProcessingPayment,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Task will be published immediately and visible to all candidates.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
