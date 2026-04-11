import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/data/datasources/task_remote_datasource.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/submission_entity.dart';

// ── Submission draft state ────────────────────────────────────────────────────

class SubmissionDraftState {
  const SubmissionDraftState({
    this.submissionId,
    this.textContent = '',
    this.codeContent = '',
    this.codeLanguage = 'python',
    this.fileUrls = const [],
    this.linkUrl = '',
    this.recordingUrl = '',
    this.notes = '',
    this.timeSpentMinutes,
    this.currentStep = 0,
    this.agreedToRequirements = false,
    this.isSaving = false,
    this.lastSavedAt,
    this.saveError,
    this.isSubmitting = false,
  });

  final String? submissionId;
  final String textContent;
  final String codeContent;
  final String codeLanguage;
  final List<String> fileUrls;
  final String linkUrl;
  final String recordingUrl;
  final String notes;
  final int? timeSpentMinutes;
  final int currentStep;
  final bool agreedToRequirements;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String? saveError;
  final bool isSubmitting;

  bool get hasContent =>
      textContent.isNotEmpty ||
      codeContent.isNotEmpty ||
      fileUrls.isNotEmpty ||
      linkUrl.isNotEmpty ||
      recordingUrl.isNotEmpty;

  SubmissionDraftState copyWith({
    String? submissionId,
    String? textContent,
    String? codeContent,
    String? codeLanguage,
    List<String>? fileUrls,
    String? linkUrl,
    String? recordingUrl,
    String? notes,
    int? timeSpentMinutes,
    int? currentStep,
    bool? agreedToRequirements,
    bool? isSaving,
    DateTime? lastSavedAt,
    String? saveError,
    bool? isSubmitting,
    bool clearSaveError = false,
  }) =>
      SubmissionDraftState(
        submissionId: submissionId ?? this.submissionId,
        textContent: textContent ?? this.textContent,
        codeContent: codeContent ?? this.codeContent,
        codeLanguage: codeLanguage ?? this.codeLanguage,
        fileUrls: fileUrls ?? this.fileUrls,
        linkUrl: linkUrl ?? this.linkUrl,
        recordingUrl: recordingUrl ?? this.recordingUrl,
        notes: notes ?? this.notes,
        timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
        currentStep: currentStep ?? this.currentStep,
        agreedToRequirements: agreedToRequirements ?? this.agreedToRequirements,
        isSaving: isSaving ?? this.isSaving,
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
        saveError: clearSaveError ? null : (saveError ?? this.saveError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

// ── Submission notifier with auto-save ────────────────────────────────────────

class SubmissionNotifier extends StateNotifier<SubmissionDraftState>
    with WidgetsBindingObserver {
  SubmissionNotifier(this._ds, this._taskId) : super(const SubmissionDraftState()) {
    WidgetsBinding.instance.addObserver(this);
    _startAutoSave();
  }

  final TaskRemoteDataSource _ds;
  final String _taskId;
  Timer? _autoSaveTimer;
  String? _lastSavedContent;

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (state.submissionId == null || !state.hasContent) return;
    final currentContent = '${state.textContent}${state.codeContent}${state.fileUrls}${state.linkUrl}';
    if (currentContent == _lastSavedContent) return;

    state = state.copyWith(isSaving: true, clearSaveError: true);
    try {
      await _ds.updateSubmission(state.submissionId!, _buildPayload());
      _lastSavedContent = currentContent;
      state = state.copyWith(isSaving: false, lastSavedAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(isSaving: false, saveError: 'Save failed — retrying');
      // Retry in 10s
      Timer(const Duration(seconds: 10), _autoSave);
    }
  }

  Map<String, dynamic> _buildPayload() => {
        if (state.textContent.isNotEmpty) 'text_content': state.textContent,
        if (state.codeContent.isNotEmpty) 'code_content': state.codeContent,
        if (state.codeContent.isNotEmpty) 'code_language': state.codeLanguage,
        if (state.fileUrls.isNotEmpty) 'file_urls': state.fileUrls,
        if (state.linkUrl.isNotEmpty) 'link_url': state.linkUrl,
        if (state.recordingUrl.isNotEmpty) 'recording_url': state.recordingUrl,
        if (state.notes.isNotEmpty) 'notes': state.notes,
        if (state.timeSpentMinutes != null) 'time_spent_minutes': state.timeSpentMinutes,
      };

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive) {
      _autoSave();
    }
  }

  Future<void> initFromTask() async {
    // Try to load existing draft
    try {
      final all = await _ds.getMySubmissions();
      final existing = all.where((m) => m.taskId == _taskId).toList();
      if (existing.isNotEmpty) {
        final s = existing.first;
        state = state.copyWith(
          submissionId: s.id,
          textContent: s.textContent ?? '',
          codeContent: s.codeContent ?? '',
          codeLanguage: s.codeLanguage ?? 'python',
          fileUrls: s.fileUrls ?? [],
          linkUrl: s.linkUrl ?? '',
          recordingUrl: s.recordingUrl ?? '',
          notes: s.notes ?? '',
          timeSpentMinutes: s.timeSpentMinutes,
        );
      } else {
        // Create new draft
        final created = await _ds.createSubmission(_taskId);
        state = state.copyWith(submissionId: created.id);
      }
    } catch (_) {}
  }

  void setStep(int step) => state = state.copyWith(currentStep: step);
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setAgreed(bool v) => state = state.copyWith(agreedToRequirements: v);
  void setTimeSpent(int? v) => state = state.copyWith(timeSpentMinutes: v);
  void setTextContent(String v) => state = state.copyWith(textContent: v);
  void setCodeContent(String v) => state = state.copyWith(codeContent: v);
  void setCodeLanguage(String v) => state = state.copyWith(codeLanguage: v);
  void setLinkUrl(String v) => state = state.copyWith(linkUrl: v);
  void setRecordingUrl(String v) => state = state.copyWith(recordingUrl: v);
  void setNotes(String v) => state = state.copyWith(notes: v);

  void addFileUrl(String url) {
    if (state.fileUrls.length < 3) {
      state = state.copyWith(fileUrls: [...state.fileUrls, url]);
    }
  }

  void removeFileUrl(String url) {
    state = state.copyWith(fileUrls: state.fileUrls.where((u) => u != url).toList());
  }

  Future<void> saveNow() async => _autoSave();

  Future<SubmissionEntity?> submitFinal() async {
    if (state.submissionId == null) return null;
    state = state.copyWith(isSubmitting: true);
    try {
      // Save latest content first
      await _ds.updateSubmission(state.submissionId!, _buildPayload());
      final result = await _ds.submitSubmission(state.submissionId!);
      state = state.copyWith(isSubmitting: false);
      return result.toEntity();
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final submissionNotifierProvider =
    StateNotifierProvider.family<SubmissionNotifier, SubmissionDraftState, String>(
  (ref, taskId) {
    final ds = ref.read(taskDataSourceProvider);
    return SubmissionNotifier(ds, taskId);
  },
);
