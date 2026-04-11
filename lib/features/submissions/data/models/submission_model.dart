import '../../domain/entities/submission_entity.dart';

class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.taskId,
    required this.candidateId,
    required this.status,
    this.textContent,
    this.codeContent,
    this.codeLanguage,
    this.fileUrls,
    this.linkUrl,
    this.recordingUrl,
    this.notes,
    this.submittedAt,
    this.scoreAccuracy,
    this.scoreApproach,
    this.scoreCompleteness,
    this.scoreEfficiency,
    this.totalScore,
    this.rank,
    this.percentile,
    this.recruiterFeedback,
    this.aiSummary,
    this.timeSpentMinutes,
    required this.isShortlisted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String candidateId;
  final String status;
  final String? textContent;
  final String? codeContent;
  final String? codeLanguage;
  final List<String>? fileUrls;
  final String? linkUrl;
  final String? recordingUrl;
  final String? notes;
  final DateTime? submittedAt;
  final double? scoreAccuracy;
  final double? scoreApproach;
  final double? scoreCompleteness;
  final double? scoreEfficiency;
  final double? totalScore;
  final int? rank;
  final double? percentile;
  final String? recruiterFeedback;
  final String? aiSummary;
  final int? timeSpentMinutes;
  final bool isShortlisted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) => SubmissionModel(
        id: json['id'] as String,
        taskId: json['task_id'] as String,
        candidateId: json['candidate_id'] as String,
        status: json['status'] as String,
        textContent: json['text_content'] as String?,
        codeContent: json['code_content'] as String?,
        codeLanguage: json['code_language'] as String?,
        fileUrls: (json['file_urls'] as List<dynamic>?)?.cast<String>(),
        linkUrl: json['link_url'] as String?,
        recordingUrl: json['recording_url'] as String?,
        notes: json['notes'] as String?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        scoreAccuracy: (json['score_accuracy'] as num?)?.toDouble(),
        scoreApproach: (json['score_approach'] as num?)?.toDouble(),
        scoreCompleteness: (json['score_completeness'] as num?)?.toDouble(),
        scoreEfficiency: (json['score_efficiency'] as num?)?.toDouble(),
        totalScore: (json['total_score'] as num?)?.toDouble(),
        rank: json['rank'] as int?,
        percentile: (json['percentile'] as num?)?.toDouble(),
        recruiterFeedback: json['recruiter_feedback'] as String?,
        aiSummary: json['ai_summary'] as String?,
        timeSpentMinutes: json['time_spent_minutes'] as int?,
        isShortlisted: json['is_shortlisted'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  SubmissionEntity toEntity() => SubmissionEntity(
        id: id, taskId: taskId, candidateId: candidateId, status: status,
        textContent: textContent, codeContent: codeContent, codeLanguage: codeLanguage,
        fileUrls: fileUrls, linkUrl: linkUrl, recordingUrl: recordingUrl, notes: notes,
        submittedAt: submittedAt, scoreAccuracy: scoreAccuracy, scoreApproach: scoreApproach,
        scoreCompleteness: scoreCompleteness, scoreEfficiency: scoreEfficiency,
        totalScore: totalScore, rank: rank, percentile: percentile,
        recruiterFeedback: recruiterFeedback, aiSummary: aiSummary,
        timeSpentMinutes: timeSpentMinutes, isShortlisted: isShortlisted,
        createdAt: createdAt, updatedAt: updatedAt,
      );
}
