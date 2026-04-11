import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/recruiter_remote_datasource.dart';
import '../../data/models/recruiter_models.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final recruiterDataSourceProvider = Provider<RecruiterRemoteDataSource>((ref) {
  return RecruiterRemoteDataSource(dio: ref.watch(dioClientProvider).instance);
});

// ── Dashboard ─────────────────────────────────────────────────────────────────

final recruiterDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(recruiterDataSourceProvider).getDashboard();
});

// ── Post Task Wizard State ────────────────────────────────────────────────────

class PostTaskState {
  final int currentStep;
  final String? draftTaskId;
  final bool isSaving;
  final String? error;

  // Step 1
  final String title;
  final String domain;
  final String taskType;
  final String difficulty;
  final List<String> skillsTested;
  final double? estimatedHours;
  final String? prizeOrOpportunity;

  // Step 2
  final String description;
  final String problemStatement;
  final String? contextBackground;

  // Step 3
  final List<Map<String, dynamic>> evaluationCriteria;

  // Step 4
  final DateTime? deadline;
  final List<String> submissionTypes;
  final List<String>? allowedFileTypes;
  final int maxFileSizeMb;
  final int? maxSubmissions;
  final bool companyVisible;
  final String? companyName;

  // Step 5
  final String tier;

  const PostTaskState({
    this.currentStep = 0,
    this.draftTaskId,
    this.isSaving = false,
    this.error,
    this.title = '',
    this.domain = '',
    this.taskType = '',
    this.difficulty = 'intermediate',
    this.skillsTested = const [],
    this.estimatedHours,
    this.prizeOrOpportunity,
    this.description = '',
    this.problemStatement = '',
    this.contextBackground,
    this.evaluationCriteria = const [
      {'name': 'Accuracy', 'weight': 40, 'description': 'Does the solution correctly solve the stated problem?'},
      {'name': 'Approach & Thinking', 'weight': 30, 'description': 'Is the logic clear, well-reasoned, and structured?'},
      {'name': 'Completeness', 'weight': 20, 'description': 'Does it address all stated requirements?'},
      {'name': 'Efficiency / Speed', 'weight': 10, 'description': 'Is the solution clean and optimally written?'},
    ],
    this.deadline,
    this.submissionTypes = const [],
    this.allowedFileTypes,
    this.maxFileSizeMb = 10,
    this.maxSubmissions,
    this.companyVisible = true,
    this.companyName,
    this.tier = 'standard',
  });

  PostTaskState copyWith({
    int? currentStep,
    String? draftTaskId,
    bool? isSaving,
    String? error,
    String? title,
    String? domain,
    String? taskType,
    String? difficulty,
    List<String>? skillsTested,
    double? estimatedHours,
    String? prizeOrOpportunity,
    String? description,
    String? problemStatement,
    String? contextBackground,
    List<Map<String, dynamic>>? evaluationCriteria,
    DateTime? deadline,
    List<String>? submissionTypes,
    List<String>? allowedFileTypes,
    int? maxFileSizeMb,
    int? maxSubmissions,
    bool? companyVisible,
    String? companyName,
    String? tier,
  }) {
    return PostTaskState(
      currentStep: currentStep ?? this.currentStep,
      draftTaskId: draftTaskId ?? this.draftTaskId,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      taskType: taskType ?? this.taskType,
      difficulty: difficulty ?? this.difficulty,
      skillsTested: skillsTested ?? this.skillsTested,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      prizeOrOpportunity: prizeOrOpportunity ?? this.prizeOrOpportunity,
      description: description ?? this.description,
      problemStatement: problemStatement ?? this.problemStatement,
      contextBackground: contextBackground ?? this.contextBackground,
      evaluationCriteria: evaluationCriteria ?? this.evaluationCriteria,
      deadline: deadline ?? this.deadline,
      submissionTypes: submissionTypes ?? this.submissionTypes,
      allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb ?? this.maxFileSizeMb,
      maxSubmissions: maxSubmissions ?? this.maxSubmissions,
      companyVisible: companyVisible ?? this.companyVisible,
      companyName: companyName ?? this.companyName,
      tier: tier ?? this.tier,
    );
  }

  double get criteriaWeightTotal =>
      evaluationCriteria.fold(0.0, (sum, c) => sum + ((c['weight'] as num?)?.toDouble() ?? 0));

  bool get step1Valid =>
      title.length >= 5 && domain.isNotEmpty && taskType.isNotEmpty && skillsTested.isNotEmpty;

  bool get step2Valid =>
      description.length >= 30 && problemStatement.length >= 20;

  bool get step3Valid =>
      evaluationCriteria.length >= 2 && (criteriaWeightTotal - 100).abs() < 0.5;

  bool get step4Valid =>
      deadline != null &&
      deadline!.isAfter(DateTime.now()) &&
      submissionTypes.isNotEmpty;
}

class PostTaskNotifier extends Notifier<PostTaskState> {
  @override
  PostTaskState build() => const PostTaskState();

  void updateStep1({
    String? title,
    String? domain,
    String? taskType,
    String? difficulty,
    List<String>? skillsTested,
    double? estimatedHours,
    String? prizeOrOpportunity,
  }) {
    state = state.copyWith(
      title: title,
      domain: domain,
      taskType: taskType,
      difficulty: difficulty,
      skillsTested: skillsTested,
      estimatedHours: estimatedHours,
      prizeOrOpportunity: prizeOrOpportunity,
    );
  }

  void updateStep2({String? description, String? problemStatement, String? contextBackground}) {
    state = state.copyWith(
      description: description,
      problemStatement: problemStatement,
      contextBackground: contextBackground,
    );
  }

  void updateCriteria(List<Map<String, dynamic>> criteria) {
    state = state.copyWith(evaluationCriteria: criteria);
  }

  void updateStep4({
    DateTime? deadline,
    List<String>? submissionTypes,
    List<String>? allowedFileTypes,
    int? maxFileSizeMb,
    int? maxSubmissions,
    bool? companyVisible,
    String? companyName,
  }) {
    state = state.copyWith(
      deadline: deadline,
      submissionTypes: submissionTypes,
      allowedFileTypes: allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb,
      maxSubmissions: maxSubmissions,
      companyVisible: companyVisible,
      companyName: companyName,
    );
  }

  void setTier(String tier) => state = state.copyWith(tier: tier);

  void setDraftTaskId(String id) => state = state.copyWith(draftTaskId: id);

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  Future<void> saveDraft() async {
    if (state.isSaving) return; // prevent concurrent saves
    state = state.copyWith(isSaving: true, error: null);
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      final data = _buildTaskPayload();
      RecruiterTaskModel task;
      if (state.draftTaskId != null) {
        task = await ds.updateTask(state.draftTaskId!, data);
      } else {
        task = await ds.createTask(data);
      }
      state = state.copyWith(isSaving: false, draftTaskId: task.id);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Map<String, dynamic> _buildTaskPayload() => {
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
        'max_submissions': state.maxSubmissions,
        'company_visible': state.companyVisible,
        'company_name': state.companyName,
        'prize_or_opportunity': state.prizeOrOpportunity,
        'estimated_hours': state.estimatedHours,
        'tier': state.tier,
      };

  void reset() => state = const PostTaskState();
}

final postTaskProvider = NotifierProvider<PostTaskNotifier, PostTaskState>(PostTaskNotifier.new);

// ── Recruiter Tasks ───────────────────────────────────────────────────────────

final recruiterTasksProvider = FutureProvider.family<List<RecruiterTaskModel>, String?>((ref, status) async {
  return ref.read(recruiterDataSourceProvider).getMyTasks(status: status);
});

final recruiterTaskDetailProvider = FutureProvider.family<RecruiterTaskModel, String>((ref, taskId) async {
  return ref.read(recruiterDataSourceProvider).getTask(taskId);
});

// ── Submissions Dashboard ─────────────────────────────────────────────────────

class SubmissionsDashboardState {
  final List<RecruiterSubmissionModel> submissions;
  final int total;
  final bool isLoading;
  final String? error;
  final String statusFilter;
  final String sort;
  final bool isLeaderboardView;

  const SubmissionsDashboardState({
    this.submissions = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.statusFilter = 'all',
    this.sort = 'most_recent',
    this.isLeaderboardView = false,
  });

  SubmissionsDashboardState copyWith({
    List<RecruiterSubmissionModel>? submissions,
    int? total,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? sort,
    bool? isLeaderboardView,
  }) {
    return SubmissionsDashboardState(
      submissions: submissions ?? this.submissions,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      sort: sort ?? this.sort,
      isLeaderboardView: isLeaderboardView ?? this.isLeaderboardView,
    );
  }
}

class SubmissionsDashboardNotifier extends FamilyNotifier<SubmissionsDashboardState, String> {
  @override
  SubmissionsDashboardState build(String taskId) {
    Future.microtask(() => load());
    return const SubmissionsDashboardState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      final data = await ds.getTaskSubmissions(
        arg,
        status: state.statusFilter == 'all' ? null : state.statusFilter,
        sort: state.sort,
      );
      final items = (data['items'] as List)
          .map((e) => RecruiterSubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(submissions: items, total: data['total'] as int? ?? 0, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    load();
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort);
    load();
  }

  void toggleView() {
    state = state.copyWith(isLeaderboardView: !state.isLeaderboardView);
  }
}

final submissionsDashboardProvider =
    NotifierProviderFamily<SubmissionsDashboardNotifier, SubmissionsDashboardState, String>(
  SubmissionsDashboardNotifier.new,
);

// ── Score Submission ──────────────────────────────────────────────────────────

class ScoreState {
  final RecruiterSubmissionModel? submission;
  final List<Map<String, dynamic>> criterionScores;
  final String feedback;
  final bool isLoading;
  final bool isSaved;
  final String? error;

  const ScoreState({
    this.submission,
    this.criterionScores = const [],
    this.feedback = '',
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });

  double get totalScore {
    if (criterionScores.isEmpty) return 0;
    return criterionScores.fold(0.0, (sum, c) {
      final score = (c['score'] as num?)?.toDouble() ?? 0;
      final weight = (c['weight'] as num?)?.toDouble() ?? 0;
      return sum + (score * weight / 100);
    });
  }

  ScoreState copyWith({
    RecruiterSubmissionModel? submission,
    List<Map<String, dynamic>>? criterionScores,
    String? feedback,
    bool? isLoading,
    bool? isSaved,
    String? error,
  }) {
    return ScoreState(
      submission: submission ?? this.submission,
      criterionScores: criterionScores ?? this.criterionScores,
      feedback: feedback ?? this.feedback,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }
}

class ScoreSubmissionNotifier extends FamilyNotifier<ScoreState, String> {
  @override
  ScoreState build(String submissionId) {
    Future.microtask(() => _loadSubmission());
    return const ScoreState(isLoading: true);
  }

  Future<void> _loadSubmission() async {
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      final sub = await ds.getSubmission(arg);
      // Initialize criterion scores from task evaluation criteria
      state = state.copyWith(submission: sub, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void initCriteria(List<Map<String, dynamic>> criteria) {
    final scores = criteria.map((c) => {
          'criterion_name': c['name'] as String,
          'score': 50.0,
          'weight': (c['weight'] as num?)?.toDouble() ?? 25.0,
        }).toList();
    state = state.copyWith(criterionScores: scores);
  }

  void updateScore(int index, double score) {
    final updated = List<Map<String, dynamic>>.from(state.criterionScores);
    updated[index] = {...updated[index], 'score': score};
    state = state.copyWith(criterionScores: updated);
  }

  void setFeedback(String feedback) => state = state.copyWith(feedback: feedback);

  Future<void> saveScore({bool shortlist = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      await ds.scoreSubmission(arg, {
        'criterion_scores': state.criterionScores,
        'recruiter_feedback': state.feedback.isEmpty ? null : state.feedback,
        'shortlist': shortlist,
      });
      state = state.copyWith(isLoading: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final scoreSubmissionProvider =
    NotifierProviderFamily<ScoreSubmissionNotifier, ScoreState, String>(ScoreSubmissionNotifier.new);

// ── Pipeline ──────────────────────────────────────────────────────────────────

class PipelineNotifier extends Notifier<AsyncValue<Map<String, List<PipelineEntryModel>>>> {
  @override
  AsyncValue<Map<String, List<PipelineEntryModel>>> build() {
    Future.microtask(() => load());
    return const AsyncLoading();
  }

  Future<void> load({String? taskId}) async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      final data = await ds.getPipelineBoard(taskId: taskId);
      final board = <String, List<PipelineEntryModel>>{};
      for (final stage in ['shortlisted', 'interviewing', 'offer_sent', 'hired', 'rejected']) {
        board[stage] = (data[stage] as List? ?? [])
            .map((e) => PipelineEntryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      state = AsyncData(board);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> moveStage(String entryId, String newStage) async {
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      await ds.updatePipelineStage(entryId, newStage);
      await load();
    } catch (e) {
      // ignore — UI shows error via snackbar
    }
  }
}

final pipelineProvider =
    NotifierProvider<PipelineNotifier, AsyncValue<Map<String, List<PipelineEntryModel>>>>(
  PipelineNotifier.new,
);

// ── Notifications ─────────────────────────────────────────────────────────────

class NotificationsNotifier extends Notifier<AsyncValue<List<NotificationModel>>> {
  @override
  AsyncValue<List<NotificationModel>> build() {
    Future.microtask(() => load());
    return const AsyncLoading();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final ds = ref.read(recruiterDataSourceProvider);
      final data = await ds.getNotifications();
      final items = (data['items'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await ref.read(recruiterDataSourceProvider).markNotificationRead(id);
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((n) => n.id == id
          ? NotificationModel(
              id: n.id, userId: n.userId, type: n.type, title: n.title,
              body: n.body, data: n.data, isRead: true, createdAt: n.createdAt)
          : n).toList());
    } catch (_) {
      // Silent fail per PRD
    }
  }

  Future<void> markAllRead() async {
    try {
      await ref.read(recruiterDataSourceProvider).markAllNotificationsRead();
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((n) => NotificationModel(
          id: n.id, userId: n.userId, type: n.type, title: n.title,
          body: n.body, data: n.data, isRead: true, createdAt: n.createdAt)).toList());
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.read(recruiterDataSourceProvider).getUnreadCount();
});

// ── Billing ───────────────────────────────────────────────────────────────────

final billingProvider = FutureProvider<List<PaymentModel>>((ref) async {
  return ref.read(recruiterDataSourceProvider).getPaymentHistory();
});

// ── Analytics ─────────────────────────────────────────────────────────────────

final recruiterAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, taskId) async {
  return ref.read(recruiterDataSourceProvider).getAnalytics(taskId: taskId);
});
