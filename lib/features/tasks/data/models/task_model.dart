import '../../domain/entities/task_entity.dart';

class TaskModel {
  const TaskModel({
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
    required this.deadline,
    this.maxSubmissions,
    required this.isPublished,
    required this.isActive,
    required this.skillsTested,
    this.estimatedHours,
    required this.companyVisible,
    this.companyName,
    this.prizeOrOpportunity,
    required this.viewCount,
    required this.submissionCount,
    required this.createdAt,
    required this.updatedAt,
    this.isBookmarked = false,
    this.candidateSubmissionId,
    this.candidateSubmissionStatus,
  });

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
  final DateTime deadline;
  final int? maxSubmissions;
  final bool isPublished;
  final bool isActive;
  final List<String> skillsTested;
  final double? estimatedHours;
  final bool companyVisible;
  final String? companyName;
  final String? prizeOrOpportunity;
  final int viewCount;
  final int submissionCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBookmarked;
  final String? candidateSubmissionId;
  final String? candidateSubmissionStatus;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        recruiterId: json['recruiter_id'] as String,
        title: json['title'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String,
        problemStatement: json['problem_statement'] as String,
        evaluationCriteria: (json['evaluation_criteria'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        domain: json['domain'] as String,
        difficulty: json['difficulty'] as String,
        taskType: json['task_type'] as String,
        submissionTypes: (json['submission_types'] as List<dynamic>?)?.cast<String>() ?? [],
        maxFileSizeMb: json['max_file_size_mb'] as int? ?? 10,
        allowedFileTypes: (json['allowed_file_types'] as List<dynamic>?)?.cast<String>(),
        deadline: DateTime.parse(json['deadline'] as String),
        maxSubmissions: json['max_submissions'] as int?,
        isPublished: json['is_published'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        skillsTested: (json['skills_tested'] as List<dynamic>?)?.cast<String>() ?? [],
        estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
        companyVisible: json['company_visible'] as bool? ?? false,
        companyName: json['company_name'] as String?,
        prizeOrOpportunity: json['prize_or_opportunity'] as String?,
        viewCount: json['view_count'] as int? ?? 0,
        submissionCount: json['submission_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isBookmarked: json['is_bookmarked'] as bool? ?? false,
        candidateSubmissionId: json['candidate_submission_id'] as String?,
        candidateSubmissionStatus: json['candidate_submission_status'] as String?,
      );

  TaskEntity toEntity() => TaskEntity(
        id: id, recruiterId: recruiterId, title: title, slug: slug,
        description: description, problemStatement: problemStatement,
        evaluationCriteria: evaluationCriteria, domain: domain,
        difficulty: difficulty, taskType: taskType, submissionTypes: submissionTypes,
        maxFileSizeMb: maxFileSizeMb, allowedFileTypes: allowedFileTypes,
        deadline: deadline, maxSubmissions: maxSubmissions, isPublished: isPublished,
        isActive: isActive, skillsTested: skillsTested, estimatedHours: estimatedHours,
        companyVisible: companyVisible, companyName: companyName,
        prizeOrOpportunity: prizeOrOpportunity, viewCount: viewCount,
        submissionCount: submissionCount, createdAt: createdAt, updatedAt: updatedAt,
        isBookmarked: isBookmarked, candidateSubmissionId: candidateSubmissionId,
        candidateSubmissionStatus: candidateSubmissionStatus,
      );
}

class PaginatedTasksModel {
  const PaginatedTasksModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<TaskModel> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginatedTasksModel.fromJson(Map<String, dynamic> json) => PaginatedTasksModel(
        items: (json['items'] as List<dynamic>)
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
        hasMore: json['has_more'] as bool,
      );

  PaginatedTasks toEntity() => PaginatedTasks(
        items: items.map((m) => m.toEntity()).toList(),
        total: total,
        page: page,
        pageSize: pageSize,
        hasMore: hasMore,
      );
}
