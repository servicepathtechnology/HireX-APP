/// Domain entity for a HireX task.
class TaskEntity {
  const TaskEntity({
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

  String get displayCompany => companyVisible && companyName != null ? companyName! : 'Confidential Company';

  bool get isDeadlinePassed => deadline.isBefore(DateTime.now());

  Duration get timeUntilDeadline => deadline.difference(DateTime.now());

  TaskEntity copyWith({bool? isBookmarked}) => TaskEntity(
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
        isBookmarked: isBookmarked ?? this.isBookmarked,
        candidateSubmissionId: candidateSubmissionId,
        candidateSubmissionStatus: candidateSubmissionStatus,
      );
}

class PaginatedTasks {
  const PaginatedTasks({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<TaskEntity> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

class TaskFilters {
  const TaskFilters({
    this.domain,
    this.difficulty,
    this.sort = 'latest',
    this.search,
  });

  final String? domain;
  final String? difficulty;
  final String sort;
  final String? search;

  TaskFilters copyWith({
    String? domain,
    String? difficulty,
    String? sort,
    String? search,
    bool clearDomain = false,
    bool clearDifficulty = false,
    bool clearSearch = false,
  }) =>
      TaskFilters(
        domain: clearDomain ? null : (domain ?? this.domain),
        difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
        sort: sort ?? this.sort,
        search: clearSearch ? null : (search ?? this.search),
      );
}
