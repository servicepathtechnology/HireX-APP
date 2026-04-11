import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/recruiter_providers.dart';

class StepProblemWidget extends ConsumerStatefulWidget {
  const StepProblemWidget({super.key});

  @override
  ConsumerState<StepProblemWidget> createState() => _StepProblemWidgetState();
}

class _StepProblemWidgetState extends ConsumerState<StepProblemWidget> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _problemCtrl;
  late final TextEditingController _contextCtrl;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(postTaskProvider);
    _descCtrl = TextEditingController(text: state.description);
    _problemCtrl = TextEditingController(text: state.problemStatement);
    _contextCtrl = TextEditingController(text: state.contextBackground ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _problemCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  void _update() {
    ref.read(postTaskProvider.notifier).updateStep2(
      description: _descCtrl.text,
      problemStatement: _problemCtrl.text,
      contextBackground: _contextCtrl.text.isEmpty ? null : _contextCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Problem Statement', style: AppTextStyles.headlineLarge),
              TextButton.icon(
                onPressed: () => setState(() => _showPreview = !_showPreview),
                icon: Icon(_showPreview ? Icons.edit : Icons.preview),
                label: Text(_showPreview ? 'Edit' : 'Preview'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _MarkdownField(
            controller: _descCtrl,
            label: 'Task Description * (min 30 chars)',
            hint: 'Describe the task in detail...',
            minLines: 5,
            showPreview: _showPreview,
            onChanged: (_) => _update(),
            hint2: _descCtrl.text.length < 30
                ? '⚠️ Your description is very short. Add more detail for better submissions.'
                : '✅ Good length — detailed enough for candidates.',
          ),
          const SizedBox(height: 16),

          _MarkdownField(
            controller: _problemCtrl,
            label: 'Problem Statement * (min 20 chars)',
            hint: 'The specific challenge candidates must solve...',
            minLines: 4,
            showPreview: _showPreview,
            onChanged: (_) => _update(),
            hint2: 'Be specific. Include input/output format, constraints, or examples if applicable.',
          ),
          const SizedBox(height: 16),

          _MarkdownField(
            controller: _contextCtrl,
            label: 'Context / Background (optional)',
            hint: 'Any background context, dataset links, or reference materials...',
            minLines: 3,
            showPreview: _showPreview,
            onChanged: (_) => _update(),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pro tip: Include an example input and expected output for clearer challenges.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownField extends StatelessWidget {
  const _MarkdownField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.minLines,
    required this.showPreview,
    required this.onChanged,
    this.hint2,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final bool showPreview;
  final void Function(String) onChanged;
  final String? hint2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        if (showPreview)
          Container(
            constraints: BoxConstraints(minHeight: minLines * 24.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: MarkdownBody(
              data: controller.text.isEmpty ? '*No content yet*' : controller.text,
              styleSheet: MarkdownStyleSheet(
                p: AppTextStyles.bodyMedium,
                code: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace', backgroundColor: AppColors.surfaceVariant),
              ),
            ),
          )
        else
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: null,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: onChanged,
          ),
        if (hint2 != null) ...[
          const SizedBox(height: 6),
          Text(hint2!, style: AppTextStyles.bodySmall.copyWith(
            color: hint2!.startsWith('✅') ? AppColors.success : AppColors.warning,
          )),
        ],
      ],
    );
  }
}
