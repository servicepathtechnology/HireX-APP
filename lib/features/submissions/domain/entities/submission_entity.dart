/// Domain entity for a HireX submission.
class SubmissionEntity {
  const SubmissionEntity({
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

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isScored => status == 'scored';
  bool get isUnderReview => status == 'under_review';
  bool get isRejected => status == 'rejected';

  SubmissionEntity copyWith({
    String? status, String? textContent, String? codeContent,
    String? codeLanguage, List<String>? fileUrls, String? linkUrl,
    String? recordingUrl, String? notes, int? timeSpentMinutes,
  }) =>
      SubmissionEntity(
        id: id, taskId: taskId, candidateId: candidateId,
        status: status ?? this.status,
        textContent: textContent ?? this.textContent,
        codeContent: codeContent ?? this.codeContent,
        codeLanguage: codeLanguage ?? this.codeLanguage,
        fileUrls: fileUrls ?? this.fileUrls,
        linkUrl: linkUrl ?? this.linkUrl,
        recordingUrl: recordingUrl ?? this.recordingUrl,
        notes: notes ?? this.notes,
        submittedAt: submittedAt, scoreAccuracy: scoreAccuracy,
        scoreApproach: scoreApproach, scoreCompleteness: scoreCompleteness,
        scoreEfficiency: scoreEfficiency, totalScore: totalScore,
        rank: rank, percentile: percentile, recruiterFeedback: recruiterFeedback,
        aiSummary: aiSummary,
        timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
        isShortlisted: isShortlisted, createdAt: createdAt, updatedAt: updatedAt,
      );
}
