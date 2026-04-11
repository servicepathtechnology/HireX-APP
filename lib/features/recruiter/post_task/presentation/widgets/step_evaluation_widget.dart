import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class StepEvaluationWidget extends ConsumerWidget {
  const StepEvaluationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postTaskProvider);
    final criteria = state.evaluationCriteria;
    final totalWeight = state.criteriaWeightTotal;
    final isValid = (totalWeight - 100).abs() < 0.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evaluation Criteria', style: AppTextStyles.headlineLarge),
              TextButton(
                onPressed: () => ref.read(postTaskProvider.notifier).updateCriteria([
                  {'name': 'Accuracy', 'weight': 40, 'description': 'Does the solution correctly solve the stated problem?'},
                  {'name': 'Approach & Thinking', 'weight': 30, 'description': 'Is the logic clear, well-reasoned, and structured?'},
                  {'name': 'Completeness', 'weight': 20, 'description': 'Does it address all stated requirements?'},
                  {'name': 'Efficiency / Speed', 'weight': 10, 'description': 'Is the solution clean and optimally written?'},
                ]),
                child: const Text('Reset to defaults'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weight total indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isValid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isValid ? AppColors.success : AppColors.error),
            ),
            child: Row(
              children: [
                Icon(isValid ? Icons.check_circle : Icons.warning, color: isValid ? AppColors.success : AppColors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  isValid ? 'Total: 100% ✓' : 'Total: ${totalWeight.toStringAsFixed(0)}% — adjust to reach 100%',
                  style: AppTextStyles.bodySmall.copyWith(color: isValid ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...criteria.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return _CriterionCard(
              index: i,
              criterion: c,
              canDelete: criteria.length > 2,
              onUpdate: (updated) {
                final list = List<Map<String, dynamic>>.from(criteria);
                list[i] = updated;
                ref.read(postTaskProvider.notifier).updateCriteria(list);
              },
              onDelete: () {
                final list = List<Map<String, dynamic>>.from(criteria)..removeAt(i);
                ref.read(postTaskProvider.notifier).updateCriteria(list);
              },
            );
          }),

          if (criteria.length < 6) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                final list = List<Map<String, dynamic>>.from(criteria);
                list.add({'name': 'New Criterion', 'weight': 0, 'description': 'Describe this criterion'});
                ref.read(postTaskProvider.notifier).updateCriteria(list);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Criterion'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],

          const SizedBox(height: 24),
          // Score preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score Preview (example)', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                ...criteria.map((c) {
                  final exampleScore = 80.0;
                  final weight = (c['weight'] as num?)?.toDouble() ?? 0;
                  final contribution = exampleScore * weight / 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text('${c['name']} (${weight.toStringAsFixed(0)}%)', style: AppTextStyles.bodySmall)),
                        Text('${exampleScore.toStringAsFixed(0)} × ${weight.toStringAsFixed(0)}% = ${contribution.toStringAsFixed(1)}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Score', style: AppTextStyles.titleSmall),
                    Text('${(80.0 * totalWeight / 100).toStringAsFixed(1)} / 100', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionCard extends StatefulWidget {
  const _CriterionCard({
    required this.index,
    required this.criterion,
    required this.canDelete,
    required this.onUpdate,
    required this.onDelete,
  });

  final int index;
  final Map<String, dynamic> criterion;
  final bool canDelete;
  final void Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;

  @override
  State<_CriterionCard> createState() => _CriterionCardState();
}

class _CriterionCardState extends State<_CriterionCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.criterion['name'] as String? ?? '');
    _descCtrl = TextEditingController(text: widget.criterion['description'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _update({double? weight}) {
    widget.onUpdate({
      'name': _nameCtrl.text,
      'weight': weight ?? (widget.criterion['weight'] as num?)?.toDouble() ?? 0,
      'description': _descCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final weight = (widget.criterion['weight'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: AppTextStyles.titleSmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _update(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${weight.toStringAsFixed(0)}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              ),
              if (widget.canDelete) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: weight,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            onChanged: (v) => _update(weight: v.roundToDouble()),
          ),
          TextField(
            controller: _descCtrl,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'Describe this criterion (shown to candidates)...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _update(),
          ),
        ],
      ),
    );
  }
}
