import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_text_field.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class StepBasicsWidget extends ConsumerStatefulWidget {
  const StepBasicsWidget({super.key});

  @override
  ConsumerState<StepBasicsWidget> createState() => _StepBasicsWidgetState();
}

class _StepBasicsWidgetState extends ConsumerState<StepBasicsWidget> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _prizeCtrl;
  final _skillInput = TextEditingController();

  static const _domains = ['Engineering', 'Design', 'Product', 'Business', 'Marketing', 'Writing', 'Other'];
  static const _taskTypes = ['Code Challenge', 'Design Challenge', 'Case Study', 'Business Problem', 'Product Task', 'Writing Task'];

  // Maps display label → DB enum value
  static const _taskTypeMap = {
    'Code Challenge': 'code',
    'Design Challenge': 'design',
    'Case Study': 'case_study',
    'Business Problem': 'business',
    'Product Task': 'product',
    'Writing Task': 'writing',
  };
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

  @override
  void initState() {
    super.initState();
    final state = ref.read(postTaskProvider);
    _titleCtrl = TextEditingController(text: state.title);
    _hoursCtrl = TextEditingController(text: state.estimatedHours?.toString() ?? '');
    _prizeCtrl = TextEditingController(text: state.prizeOrOpportunity ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hoursCtrl.dispose();
    _prizeCtrl.dispose();
    _skillInput.dispose();
    super.dispose();
  }

  void _update() {
    // If there's text in the skill input, add it before updating
    if (_skillInput.text.trim().isNotEmpty && ref.read(postTaskProvider).skillsTested.length < 8) {
      final currentSkills = ref.read(postTaskProvider).skillsTested;
      final newSkill = _skillInput.text.trim();
      if (!currentSkills.contains(newSkill)) {
        ref.read(postTaskProvider.notifier).updateStep1(
          skillsTested: [...currentSkills, newSkill],
        );
        _skillInput.clear();
      }
    }

    ref.read(postTaskProvider.notifier).updateStep1(
      title: _titleCtrl.text.trim(),
      estimatedHours: double.tryParse(_hoursCtrl.text),
      prizeOrOpportunity: _prizeCtrl.text.trim().isEmpty ? null : _prizeCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postTaskProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Basics', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text('Tell candidates what this task is about.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          HireXTextField(
            controller: _titleCtrl,
            label: 'Task Title *',
            hint: 'e.g. Build a REST API for a todo app',
            onChanged: (_) => _update(),
          ),
          const SizedBox(height: 16),

          _DropdownField(
            label: 'Domain *',
            value: state.domain.isEmpty ? null : state.domain,
            items: _domains,
            onChanged: (v) {
              ref.read(postTaskProvider.notifier).updateStep1(domain: v);
              _update();
            },
          ),
          const SizedBox(height: 16),

          _DropdownField(
            label: 'Task Type *',
            value: state.taskType.isEmpty ? null : _taskTypeMap.entries
                .firstWhere((e) => e.value == state.taskType,
                    orElse: () => MapEntry(state.taskType, state.taskType))
                .key,
            items: _taskTypes,
            onChanged: (v) {
              final dbValue = _taskTypeMap[v] ?? v?.toLowerCase().replaceAll(' ', '_') ?? '';
              ref.read(postTaskProvider.notifier).updateStep1(taskType: dbValue);
              _update();
            },
          ),
          const SizedBox(height: 16),

          Text('Difficulty Level *', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: _difficulties.map((d) {
              final isSelected = state.difficulty.toLowerCase() == d.toLowerCase();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => ref.read(postTaskProvider.notifier).updateStep1(difficulty: d.toLowerCase()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(d, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text('Skills Tested * (min 1, max 8)', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...state.skillsTested.map((skill) => Chip(
                label: Text(skill),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  final updated = List<String>.from(state.skillsTested)..remove(skill);
                  ref.read(postTaskProvider.notifier).updateStep1(skillsTested: updated);
                },
                backgroundColor: AppColors.surfaceVariant,
                labelStyle: AppTextStyles.bodySmall,
              )),
              if (state.skillsTested.length < 8)
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _skillInput,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Add skill + Enter',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty && state.skillsTested.length < 8) {
                        final updated = [...state.skillsTested, v.trim()];
                        ref.read(postTaskProvider.notifier).updateStep1(skillsTested: updated);
                        _skillInput.clear();
                      }
                    },
                    onEditingComplete: () {
                      final v = _skillInput.text;
                      if (v.trim().isNotEmpty && state.skillsTested.length < 8) {
                        final updated = [...state.skillsTested, v.trim()];
                        ref.read(postTaskProvider.notifier).updateStep1(skillsTested: updated);
                        _skillInput.clear();
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          HireXTextField(
            controller: _hoursCtrl,
            label: 'Estimated Hours (optional)',
            hint: 'e.g. 4',
            keyboardType: TextInputType.number,
            onChanged: (_) => _update(),
          ),
          const SizedBox(height: 16),

          HireXTextField(
            controller: _prizeCtrl,
            label: 'Prize / Opportunity (optional)',
            hint: 'e.g. Top 3 get interviews at Acme Corp',
            onChanged: (_) => _update(),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          dropdownColor: AppColors.surface,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          hint: Text('Select...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4))),
        ),
      ],
    );
  }
}
