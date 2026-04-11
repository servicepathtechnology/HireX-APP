import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_scaffold.dart';
import '../../../../../shared/widgets/hirex_snackbar.dart';
import '../../../presentation/providers/recruiter_providers.dart';
import '../widgets/step_basics_widget.dart';
import '../widgets/step_problem_widget.dart';
import '../widgets/step_evaluation_widget.dart';
import '../widgets/step_logistics_widget.dart';
import '../widgets/step_preview_widget.dart';

class PostTaskWizardPage extends ConsumerStatefulWidget {
  const PostTaskWizardPage({super.key, this.editTaskId});
  final String? editTaskId;

  @override
  ConsumerState<PostTaskWizardPage> createState() => _PostTaskWizardPageState();
}

class _PostTaskWizardPageState extends ConsumerState<PostTaskWizardPage> {
  final _pageController = PageController();
  Timer? _autoSaveTimer;

  static const _stepLabels = ['Basics', 'Problem', 'Evaluation', 'Logistics', 'Preview'];

  @override
  void initState() {
    super.initState();
    // If editing an existing task, pre-populate the draft ID
    if (widget.editTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(postTaskProvider.notifier);
        // Set the draft task ID so saves go to the right task
        notifier.setDraftTaskId(widget.editTaskId!);
      });
    }
    // Auto-save every 60 seconds
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _saveDraft();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    // Dismiss keyboard to trigger any pending onChanged callbacks
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 50));
    final notifier = ref.read(postTaskProvider.notifier);
    await notifier.saveDraft();
    if (mounted) {
      final state = ref.read(postTaskProvider);
      if (state.error != null) {
        HireXSnackbar.show(context, message: 'Draft save failed: ${state.error}', isError: true);
      } else {
        HireXSnackbar.show(context, message: 'Draft saved.');
      }
    }
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Save as Draft?'),
        content: const Text('Your task is saved as a draft. You can continue later from My Tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _saveDraft();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _nextStep() async {
    // Give the skill input a chance to commit if focused
    FocusScope.of(context).unfocus();
    // Small delay to let onEditingComplete fire
    await Future.delayed(const Duration(milliseconds: 100));

    final state = ref.read(postTaskProvider);
    final step = state.currentStep;

    bool valid = false;
    switch (step) {
      case 0: valid = state.step1Valid; break;
      case 1: valid = state.step2Valid; break;
      case 2: valid = state.step3Valid; break;
      case 3: valid = state.step4Valid; break;
      case 4: valid = true; break;
    }

    if (!valid) {
      // Show which field is missing
      String msg = 'Please complete all required fields.';
      if (step == 0) {
        final s = ref.read(postTaskProvider);
        if (s.title.trim().length < 5) msg = 'Task title must be at least 5 characters.';
        else if (s.domain.isEmpty) msg = 'Please select a domain.';
        else if (s.taskType.isEmpty) msg = 'Please select a task type.';
        else if (s.skillsTested.isEmpty) msg = 'Add at least one skill.';
      } else if (step == 1) {
        final s = ref.read(postTaskProvider);
        if (s.description.length < 30) msg = 'Description must be at least 30 characters (currently ${s.description.length}).';
        else if (s.problemStatement.length < 20) msg = 'Problem statement must be at least 20 characters (currently ${s.problemStatement.length}).';
      } else if (step == 2) {
        final s = ref.read(postTaskProvider);
        if ((s.criteriaWeightTotal - 100).abs() >= 0.5) msg = 'Criteria weights must total 100% (currently ${s.criteriaWeightTotal.toStringAsFixed(0)}%).';
        else if (s.evaluationCriteria.length < 2) msg = 'Add at least 2 evaluation criteria.';
      } else if (step == 3) {
        final s = ref.read(postTaskProvider);
        if (s.deadline == null) msg = 'Please set a deadline.';
        else if (!s.deadline!.isAfter(DateTime.now())) msg = 'Deadline must be in the future.';
        else if (s.submissionTypes.isEmpty) msg = 'Select at least one submission type.';
      }
      HireXSnackbar.show(context, message: msg, isError: true);
      return;
    }

    // Navigate immediately, save in background
    ref.read(postTaskProvider.notifier).goToStep(step + 1);
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _saveDraft(); // background save, don't await
  }

  void _prevStep() {
    final step = ref.read(postTaskProvider).currentStep;
    if (step > 0) {
      ref.read(postTaskProvider.notifier).goToStep(step - 1);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postTaskProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) context.pop();
        }
      },
      child: HireXScaffold(
        appBar: AppBar(
          title: Text('Post Task — Step ${state.currentStep + 1} of 5'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) context.pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: state.isSaving ? null : _saveDraft,
              child: state.isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Draft'),
            ),
          ],
        ),
        body: Column(
          children: [
            _StepIndicator(currentStep: state.currentStep, labels: _stepLabels),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StepBasicsWidget(),
                  StepProblemWidget(),
                  StepEvaluationWidget(),
                  StepLogisticsWidget(),
                  StepPreviewWidget(),
                ],
              ),
            ),
            _WizardNavBar(
              currentStep: state.currentStep,
              onBack: state.currentStep > 0 ? _prevStep : null,
              onNext: state.currentStep < 4 ? _nextStep : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.labels});
  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.success : isActive ? AppColors.primary : AppColors.divider,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(labels[i], style: AppTextStyles.bodySmall.copyWith(
                        color: isActive ? AppColors.primary : AppColors.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      )),
                    ],
                  ),
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.success : AppColors.divider,
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _WizardNavBar extends StatelessWidget {
  const _WizardNavBar({required this.currentStep, this.onBack, this.onNext});
  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Back'),
              ),
            ),
          if (onBack != null && onNext != null) const SizedBox(width: 12),
          if (onNext != null)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(currentStep == 3 ? 'Preview Task' : 'Next'),
              ),
            ),
        ],
      ),
    );
  }
}
