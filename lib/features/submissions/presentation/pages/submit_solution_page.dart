import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../../tasks/data/datasources/task_remote_datasource.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../providers/submission_provider.dart';

class SubmitSolutionPage extends ConsumerStatefulWidget {
  const SubmitSolutionPage({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<SubmitSolutionPage> createState() => _SubmitSolutionPageState();
}

class _SubmitSolutionPageState extends ConsumerState<SubmitSolutionPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(submissionNotifierProvider(widget.taskId).notifier).initFromTask();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final draft = ref.watch(submissionNotifierProvider(widget.taskId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Solution'),
        actions: [
          if (draft.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (draft.lastSavedAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('Saved', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
              ),
            )
          else if (draft.saveError != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(draft.saveError!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
              ),
            ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Task not found', style: AppTextStyles.bodyLarge)),
        data: (task) => _WizardBody(task: task, taskId: widget.taskId),
      ),
    );
  }
}

class _WizardBody extends ConsumerWidget {
  const _WizardBody({required this.task, required this.taskId});
  final TaskEntity task;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(submissionNotifierProvider(taskId));

    return Column(
      children: [
        // Step indicator
        _StepIndicator(currentStep: draft.currentStep, totalSteps: 4),

        Expanded(
          child: Builder(
            builder: (context) {
              final step = draft.currentStep.clamp(0, 3);
              final steps = [
                _Step1TaskRecap(task: task, taskId: taskId),
                _Step2SolutionInput(task: task, taskId: taskId),
                _Step3Notes(taskId: taskId),
                _Step4ReviewSubmit(task: task, taskId: taskId),
              ];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: steps[step],
              );
            },
          ),
        ),

        // Navigation buttons
        _NavButtons(
          taskId: taskId,
          currentStep: draft.currentStep,
          task: task,
        ),
      ],
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i == currentStep;
            final isDone = i < currentStep;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  color: isDone || isActive ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      );
}

// ── Step 1: Task Recap ────────────────────────────────────────────────────────

class _Step1TaskRecap extends ConsumerWidget {
  const _Step1TaskRecap({required this.task, required this.taskId});
  final TaskEntity task;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(submissionNotifierProvider(taskId));
    final notifier = ref.read(submissionNotifierProvider(taskId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Overview', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 16),
        HireXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              ...task.evaluationCriteria.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('${c['weight']}%',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c['criterion'] as String, style: AppTextStyles.bodyMedium)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'How long did you spend? (optional)',
            hintText: 'Minutes',
            suffixText: 'min',
          ),
          onChanged: (v) => notifier.setTimeSpent(int.tryParse(v)),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: draft.agreedToRequirements,
          onChanged: (v) => notifier.setAgreed(v ?? false),
          title: const Text('I understand the requirements and evaluation criteria'),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Step 2: Solution Input ────────────────────────────────────────────────────

class _Step2SolutionInput extends ConsumerStatefulWidget {
  const _Step2SolutionInput({required this.task, required this.taskId});
  final TaskEntity task;
  final String taskId;

  @override
  ConsumerState<_Step2SolutionInput> createState() => _Step2SolutionInputState();
}

class _Step2SolutionInputState extends ConsumerState<_Step2SolutionInput>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _previewMode = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  // Stable controllers to avoid cursor-jump on rebuild
  late final TextEditingController _textController;
  late final TextEditingController _codeController;
  late final TextEditingController _linkController;
  late final TextEditingController _recordingController;

  @override
  void initState() {
    super.initState();
    final types = widget.task.submissionTypes;
    _tabController = TabController(length: types.length, vsync: this);
    final draft = ref.read(submissionNotifierProvider(widget.taskId));
    _textController = TextEditingController(text: draft.textContent);
    _codeController = TextEditingController(text: draft.codeContent);
    _linkController = TextEditingController(text: draft.linkUrl);
    _recordingController = TextEditingController(text: draft.recordingUrl);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _codeController.dispose();
    _linkController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: widget.task.allowedFileTypes ?? ['pdf', 'zip', 'png', 'jpg', 'docx'],
      type: FileType.custom,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final maxBytes = widget.task.maxFileSizeMb * 1024 * 1024;

    if ((file.size) > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File exceeds ${widget.task.maxFileSizeMb}MB limit')),
        );
      }
      return;
    }

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final ds = ref.read(taskDataSourceProvider);
      final contentType = _guessContentType(file.name);
      final fileUrl = await ds.getPresignedFileUrl(file.name, contentType);
      final uploadUrl = await ds.getPresignedUrl(file.name, contentType);

      // Upload to S3
      final dio = Dio();
      final filePath = file.path;
      if (filePath == null) {
        throw Exception('File path unavailable on this platform.');
      }
      await dio.put(
        uploadUrl,
        data: File(filePath).openRead(),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': file.size,
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) setState(() => _uploadProgress = sent / total);
        },
      );

      ref.read(submissionNotifierProvider(widget.taskId).notifier).addFileUrl(fileUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0; });
    }
  }

  String _guessContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'zip': 'application/zip',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.task.submissionTypes;
    final draft = ref.watch(submissionNotifierProvider(widget.taskId));
    final notifier = ref.read(submissionNotifierProvider(widget.taskId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Solution', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 12),
        if (types.length > 1) ...[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: types.map((t) => Tab(text: t[0].toUpperCase() + t.substring(1))).toList(),
          ),
          const SizedBox(height: 16),
        ],
        // Show input for each type
        ...types.asMap().entries.map((entry) {
          final type = entry.value;
          return _buildInputForType(type, draft, notifier);
        }),
      ],
    );
  }

  Widget _buildInputForType(String type, SubmissionDraftState draft, SubmissionNotifier notifier) {
    switch (type) {
      case 'text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Text / Markdown', style: AppTextStyles.headlineMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _previewMode = !_previewMode),
                  child: Text(_previewMode ? 'Edit' : 'Preview'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_previewMode)
              Container(
                constraints: const BoxConstraints(minHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: MarkdownBody(data: draft.textContent),
              )
            else
              TextField(
                maxLines: 12,
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Write your solution in markdown...',
                  alignLabelWithHint: true,
                ),
                onChanged: notifier.setTextContent,
              ),
            const SizedBox(height: 4),
            Text('${draft.textContent.length} chars (min 100)',
                style: AppTextStyles.labelSmall),
            const SizedBox(height: 16),
          ],
        );

      case 'code':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Code', style: AppTextStyles.headlineMedium),
                const Spacer(),
                DropdownButton<String>(
                  value: draft.codeLanguage,
                  dropdownColor: AppColors.surface,
                  underline: const SizedBox(),
                  items: const [
                    'python', 'javascript', 'typescript', 'dart', 'java',
                    'c++', 'go', 'sql', 'shell', 'other',
                  ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) { if (v != null) notifier.setCodeLanguage(v); },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                maxLines: 16,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: '// Write your code here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: notifier.setCodeContent,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );

      case 'file':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File Upload', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Allowed: ${widget.task.allowedFileTypes?.join(", ") ?? "pdf, zip, png, jpg, docx"} · Max ${widget.task.maxFileSizeMb}MB · Up to 3 files',
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: 12),
            ...draft.fileUrls.map((url) => _FileItem(
                  url: url,
                  onRemove: () => notifier.removeFileUrl(url),
                )),
            if (_isUploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress, color: AppColors.primary),
              const SizedBox(height: 4),
              Text('Uploading... ${(_uploadProgress * 100).toInt()}%', style: AppTextStyles.labelSmall),
            ],
            if (draft.fileUrls.length < 3 && !_isUploading)
              OutlinedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Choose File'),
              ),
            const SizedBox(height: 16),
          ],
        );

      case 'link':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('GitHub repo, Figma prototype, Google Docs, deployed app URL',
                style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                hintText: 'https://',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: notifier.setLinkUrl,
            ),
            const SizedBox(height: 16),
          ],
        );

      case 'recording':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recording Link', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('Paste a link to your screen recording or demo video (Loom, YouTube unlisted, Google Drive)',
                style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _recordingController,
              decoration: const InputDecoration(
                hintText: 'https://loom.com/share/...',
                prefixIcon: Icon(Icons.videocam_outlined),
              ),
              keyboardType: TextInputType.url,
              onChanged: notifier.setRecordingUrl,
            ),
            const SizedBox(height: 16),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}

class _FileItem extends StatelessWidget {
  const _FileItem({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url.split('/').last,
                style: AppTextStyles.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

// ── Step 3: Notes ─────────────────────────────────────────────────────────────

class _Step3Notes extends ConsumerStatefulWidget {
  const _Step3Notes({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_Step3Notes> createState() => _Step3NotesState();
}

class _Step3NotesState extends ConsumerState<_Step3Notes> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(submissionNotifierProvider(widget.taskId));
    _notesController = TextEditingController(text: draft.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(submissionNotifierProvider(widget.taskId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes & Context', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 16),
        TextField(
          maxLines: 5,
          maxLength: 500,
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Anything you want to tell the recruiter? (optional)',
            alignLabelWithHint: true,
          ),
          onChanged: notifier.setNotes,
        ),
      ],
    );
  }
}

// ── Step 4: Review & Submit ───────────────────────────────────────────────────

class _Step4ReviewSubmit extends ConsumerWidget {
  const _Step4ReviewSubmit({required this.task, required this.taskId});
  final TaskEntity task;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(submissionNotifierProvider(taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Submit', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 16),
        HireXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Submission Summary', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              if (draft.textContent.isNotEmpty)
                _SummaryRow(Icons.text_fields, 'Text', '${draft.textContent.length} chars'),
              if (draft.codeContent.isNotEmpty)
                _SummaryRow(Icons.code, 'Code', draft.codeLanguage),
              if (draft.fileUrls.isNotEmpty)
                _SummaryRow(Icons.attach_file, 'Files', '${draft.fileUrls.length} file(s)'),
              if (draft.linkUrl.isNotEmpty)
                _SummaryRow(Icons.link, 'Link', draft.linkUrl),
              if (draft.recordingUrl.isNotEmpty)
                _SummaryRow(Icons.videocam_outlined, 'Recording', draft.recordingUrl),
              if (!draft.hasContent)
                Text('No content added yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_outlined, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Once submitted, you cannot edit your solution.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            Text('$label: ', style: AppTextStyles.labelLarge),
            Expanded(
              child: Text(value ?? '', style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

// ── Navigation buttons ────────────────────────────────────────────────────────

class _NavButtons extends ConsumerWidget {
  const _NavButtons({required this.taskId, required this.currentStep, required this.task});
  final String taskId;
  final int currentStep;
  final TaskEntity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(submissionNotifierProvider(taskId));
    final notifier = ref.read(submissionNotifierProvider(taskId).notifier);
    final isLast = currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: notifier.prevStep,
                child: const Text('Back'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed(draft) ? () => _onNext(context, ref, notifier, draft) : null,
              child: draft.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLast ? 'Submit Solution' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed(SubmissionDraftState draft) {
    if (draft.isSubmitting) return false;
    switch (currentStep) {
      case 0:
        return draft.agreedToRequirements;
      case 1:
        return draft.hasContent;
      case 2:
        return true;
      case 3:
        return draft.hasContent;
      default:
        return true;
    }
  }

  Future<void> _onNext(BuildContext context, WidgetRef ref,
      SubmissionNotifier notifier, SubmissionDraftState draft) async {
    if (currentStep < 3) {
      notifier.nextStep();
      return;
    }

    // Final submit
    try {
      final result = await notifier.submitFinal();
      if (result != null && context.mounted) {
        context.go('/candidate/submissions/${result.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}
