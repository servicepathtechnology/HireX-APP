import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/hirex_text_field.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class StepLogisticsWidget extends ConsumerStatefulWidget {
  const StepLogisticsWidget({super.key});

  @override
  ConsumerState<StepLogisticsWidget> createState() => _StepLogisticsWidgetState();
}

class _StepLogisticsWidgetState extends ConsumerState<StepLogisticsWidget> {
  late final TextEditingController _maxSubsCtrl;
  late final TextEditingController _companyNameCtrl;

  static const _submissionTypes = ['Text / Markdown', 'Code', 'File Upload', 'External Link', 'Recording Link'];
  static const _fileTypes = ['PDF', 'ZIP', 'PNG', 'JPG', 'DOCX', 'FIGMA', 'MP4', 'Other'];

  @override
  void initState() {
    super.initState();
    final state = ref.read(postTaskProvider);
    _maxSubsCtrl = TextEditingController(text: state.maxSubmissions?.toString() ?? '');
    _companyNameCtrl = TextEditingController(text: state.companyName ?? '');
  }

  @override
  void dispose() {
    _maxSubsCtrl.dispose();
    _companyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final minDate = now;
    final maxDate = now.add(const Duration(days: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: minDate,
      lastDate: maxDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(postTaskProvider.notifier).updateStep4(deadline: deadline);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postTaskProvider);
    final hasFileUpload = state.submissionTypes.contains('File Upload');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Logistics', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 24),

          // Deadline
          Text('Deadline * (IST)', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: state.deadline == null ? AppColors.divider : AppColors.primary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    state.deadline != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(state.deadline!)
                        : 'Select deadline (min 24h from now)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: state.deadline == null ? AppColors.onSurface.withValues(alpha: 0.4) : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submission types
          Text('Submission Types Allowed *', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          ..._submissionTypes.map((type) {
            final isSelected = state.submissionTypes.contains(type);
            return CheckboxListTile(
              value: isSelected,
              title: Text(type, style: AppTextStyles.bodyMedium),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                final updated = List<String>.from(state.submissionTypes);
                if (v == true) updated.add(type); else updated.remove(type);
                ref.read(postTaskProvider.notifier).updateStep4(submissionTypes: updated);
              },
            );
          }),
          const SizedBox(height: 8),

          // File types (conditional)
          if (hasFileUpload) ...[
            Text('Allowed File Types', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fileTypes.map((type) {
                final isSelected = state.allowedFileTypes?.contains(type) ?? false;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (v) {
                    final updated = List<String>.from(state.allowedFileTypes ?? []);
                    if (v) updated.add(type); else updated.remove(type);
                    ref.read(postTaskProvider.notifier).updateStep4(allowedFileTypes: updated);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Max submissions
          HireXTextField(
            controller: _maxSubsCtrl,
            label: 'Max Submissions Cap (optional, blank = unlimited)',
            hint: 'e.g. 100',
            keyboardType: TextInputType.number,
            onChanged: (v) => ref.read(postTaskProvider.notifier).updateStep4(
              maxSubmissions: int.tryParse(v),
            ),
          ),
          const SizedBox(height: 16),

          // Company visibility
          Row(
            children: [
              Expanded(child: Text('Show Company Name', style: AppTextStyles.bodyMedium)),
              Switch(
                value: state.companyVisible,
                activeColor: AppColors.primary,
                onChanged: (v) => ref.read(postTaskProvider.notifier).updateStep4(companyVisible: v),
              ),
            ],
          ),
          if (state.companyVisible) ...[
            const SizedBox(height: 8),
            HireXTextField(
              controller: _companyNameCtrl,
              label: 'Company Name to Display',
              hint: 'Your company name',
              onChanged: (v) => ref.read(postTaskProvider.notifier).updateStep4(companyName: v),
            ),
          ],
          const SizedBox(height: 16),

          // Task visibility
          Text('Task Visibility', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: AppColors.primary, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Public', style: AppTextStyles.titleSmall),
                      Text('Visible to all candidates', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.onSurface.withValues(alpha: 0.4), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite Only', style: AppTextStyles.titleSmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4))),
                      Text('Coming Soon', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
                  child: Text('Soon', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
