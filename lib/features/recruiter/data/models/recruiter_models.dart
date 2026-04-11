// Recruiter data models for Part 3

// ── Recruiter Task ────────────────────────────────────────────────────────────

class RecruiterTaskModel {
  final String id;
  final String recruiterId;
  final String title;
  final String slug;
  final String description;
  final String problemStatement;
  final List<Map<String, dynamic>> evaluationCriteria;
  final String domain;
  final String difficulty;
  final String taskType;
  final List<String> submissionTypes;
  final int maxFileSizeMb;
  final List<String>? allowedFileTypes;
  final DateTime? deadline;
  final int? maxSubmissions;
  final bool isPublished;
  final bool isActive;
  final List<String> skillsTested;
  final double? estimatedHours;
  final bool companyVisible;
  final String? companyName;
  final String? prizeOrOpportunity;
  final String tier;
  final int viewCount;
  final int submissionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecruiterTaskModel({
    required this.id,
    required this.recruiterId,
    required this.title,
    required this.slug,
    required this.description,
    required this.problemStatement,
    required this.evaluationCriteria,
    required this.domain,
    required this.difficulty,
    required this.taskType,
    required this.submissionTypes,
    required this.maxFileSizeMb,
    this.allowedFileTypes,
    this.deadline,
    this.maxSubmissions,
    required this.isPublished,
    required this.isActive,
    required this.skillsTested,
    this.estimatedHours,
    required this.companyVisible,
    this.companyName,
    this.prizeOrOpportunity,
    required this.tier,
    required this.viewCount,
    required this.submissionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecruiterTaskModel.fromJson(Map<String, dynamic> json) {
    return RecruiterTaskModel(
      id: json['id'] as String,
      recruiterId: json['recruiter_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String? ?? '',
      problemStatement: json['problem_statement'] as String? ?? '',
      evaluationCriteria: (json['evaluation_criteria'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      domain: json['domain'] as String,
      difficulty: json['difficulty'] as String,
      taskType: json['task_type'] as String,
      submissionTypes: List<String>.from(json['submission_types'] as List? ?? []),
      maxFileSizeMb: json['max_file_size_mb'] as int? ?? 10,
      allowedFileTypes: json['allowed_file_types'] != null
          ? List<String>.from(json['allowed_file_types'] as List)
          : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      maxSubmissions: json['max_submissions'] as int?,
      isPublished: json['is_published'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      skillsTested: List<String>.from(json['skills_tested'] as List? ?? []),
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      companyVisible: json['company_visible'] as bool? ?? true,
      companyName: json['company_name'] as String?,
      prizeOrOpportunity: json['prize_or_opportunity'] as String?,
      tier: json['tier'] as String? ?? 'standard',
      viewCount: json['view_count'] as int? ?? 0,
      submissionCount: json['submission_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'domain': domain,
        'task_type': taskType,
        'difficulty': difficulty,
        'skills_tested': skillsTested,
        'description': description,
        'problem_statement': problemStatement,
        'evaluation_criteria': evaluationCriteria,
        'deadline': deadline?.toIso8601String(),
        'submission_types': submissionTypes,
        'allowed_file_types': allowedFileTypes,
        'max_file_size_mb': maxFileSizeMb,
        'max_submissions': maxSubmissions,
        'company_visible': companyVisible,
        'company_name': companyName,
        'prize_or_opportunity': prizeOrOpportunity,
        'estimated_hours': estimatedHours,
        'tier': tier,
      };
}

// ── Recruiter Submission ──────────────────────────────────────────────────────

class RecruiterSubmissionModel {
  final String id;
  final String taskId;
  final String candidateId;
  final String? candidateName;
  final String? candidateAvatar;
  final String status;
  final String? textContent;
  final String? codeContent;
  final String? codeLanguage;
  final List<String>? fileUrls;
  final String? linkUrl;
  final String? recordingUrl;
  final String? notes;
  final DateTime? submittedAt;
  final double? totalScore;
  final int? rank;
  final double? percentile;
  final String? recruiterFeedback;
  final int? timeSpentMinutes;
  final bool isShortlisted;
  final String? aiSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecruiterSubmissionModel({
    required this.id,
    required this.taskId,
    required this.candidateId,
    this.candidateName,
    this.candidateAvatar,
    required this.status,
    this.textContent,
    this.codeContent,
    this.codeLanguage,
    this.fileUrls,
    this.linkUrl,
    this.recordingUrl,
    this.notes,
    this.submittedAt,
    this.totalScore,
    this.rank,
    this.percentile,
    this.recruiterFeedback,
    this.timeSpentMinutes,
    required this.isShortlisted,
    this.aiSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecruiterSubmissionModel.fromJson(Map<String, dynamic> json) {
    return RecruiterSubmissionModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      candidateId: json['candidate_id'] as String,
      candidateName: json['candidate_name'] as String?,
      candidateAvatar: json['candidate_avatar'] as String?,
      status: json['status'] as String,
      textContent: json['text_content'] as String?,
      codeContent: json['code_content'] as String?,
      codeLanguage: json['code_language'] as String?,
      fileUrls: json['file_urls'] != null ? List<String>.from(json['file_urls'] as List) : null,
      linkUrl: json['link_url'] as String?,
      recordingUrl: json['recording_url'] as String?,
      notes: json['notes'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
      totalScore: (json['total_score'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
      percentile: (json['percentile'] as num?)?.toDouble(),
      recruiterFeedback: json['recruiter_feedback'] as String?,
      timeSpentMinutes: json['time_spent_minutes'] as int?,
      isShortlisted: json['is_shortlisted'] as bool? ?? false,
      aiSummary: json['ai_summary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

// ── Pipeline Entry ────────────────────────────────────────────────────────────

class PipelineEntryModel {
  final String id;
  final String recruiterId;
  final String candidateId;
  final String? candidateName;
  final String? candidateAvatar;
  final String taskId;
  final String? taskTitle;
  final String? taskDomain;
  final String submissionId;
  final double? totalScore;
  final int? rank;
  final String stage;
  final String? recruiterNotes;
  final DateTime stageUpdatedAt;
  final DateTime createdAt;

  const PipelineEntryModel({
    required this.id,
    required this.recruiterId,
    required this.candidateId,
    this.candidateName,
    this.candidateAvatar,
    required this.taskId,
    this.taskTitle,
    this.taskDomain,
    required this.submissionId,
    this.totalScore,
    this.rank,
    required this.stage,
    this.recruiterNotes,
    required this.stageUpdatedAt,
    required this.createdAt,
  });

  factory PipelineEntryModel.fromJson(Map<String, dynamic> json) {
    return PipelineEntryModel(
      id: json['id'] as String,
      recruiterId: json['recruiter_id'] as String,
      candidateId: json['candidate_id'] as String,
      candidateName: json['candidate_name'] as String?,
      candidateAvatar: json['candidate_avatar'] as String?,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String?,
      taskDomain: json['task_domain'] as String?,
      submissionId: json['submission_id'] as String,
      totalScore: (json['total_score'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
      stage: json['stage'] as String,
      recruiterNotes: json['recruiter_notes'] as String?,
      stageUpdatedAt: DateTime.parse(json['stage_updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ── Notification ──────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ── Dashboard Stats ───────────────────────────────────────────────────────────

class DashboardStatsModel {
  final int activeTasks;
  final int totalSubmissions;
  final int pendingReview;
  final int hiresMade;

  const DashboardStatsModel({
    required this.activeTasks,
    required this.totalSubmissions,
    required this.pendingReview,
    required this.hiresMade,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      activeTasks: json['active_tasks'] as int? ?? 0,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      pendingReview: json['pending_review'] as int? ?? 0,
      hiresMade: json['hires_made'] as int? ?? 0,
    );
  }
}

// ── Payment ───────────────────────────────────────────────────────────────────

class PaymentModel {
  final String id;
  final String taskId;
  final String? taskTitle;
  final String tier;
  final int amountPaise;
  final String currency;
  final String status;
  final String razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.tier,
    required this.amountPaise,
    required this.currency,
    required this.status,
    required this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String?,
      tier: json['tier'] as String,
      amountPaise: json['amount_paise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double get amountInr => amountPaise / 100;
}
