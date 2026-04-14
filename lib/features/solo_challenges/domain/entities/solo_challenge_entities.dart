/// Part 2 — Solo Challenges Domain Entities
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'solo_challenge_entities.freezed.dart';

/// Challenge Hub data
@freezed
class ChallengeHub with _$ChallengeHub {
  const factory ChallengeHub({
    required DailyChallengeInfo daily,
    required WeeklyChallengeInfo weekly,
    required MonthlyChallengeInfo monthly,
    required StreakInfo streak,
    required List<RecentCompletion> recentCompletions,
  }) = _ChallengeHub;
}

/// Daily challenge info
@freezed
class DailyChallengeInfo with _$DailyChallengeInfo {
  const factory DailyChallengeInfo({
    String? id,
    String? date,
    String? questionTitle,
    required String difficulty,
    required String status,
    required bool completed,
    required int xpReward,
  }) = _DailyChallengeInfo;
}

/// Weekly challenge info
@freezed
class WeeklyChallengeInfo with _$WeeklyChallengeInfo {
  const factory WeeklyChallengeInfo({
    String? id,
    int? year,
    int? week,
    String? questionTitle,
    required String difficulty,
    required String status,
    required bool completed,
    required int xpReward,
  }) = _WeeklyChallengeInfo;
}

/// Monthly challenge info
@freezed
class MonthlyChallengeInfo with _$MonthlyChallengeInfo {
  const factory MonthlyChallengeInfo({
    String? id,
    int? year,
    int? month,
    String? questionTitle,
    required String difficulty,
    required String status,
    required bool completed,
    required int xpReward,
  }) = _MonthlyChallengeInfo;
}

/// Streak information
@freezed
class StreakInfo with _$StreakInfo {
  const factory StreakInfo({
    required int currentStreak,
    required int longestStreak,
    required bool graceDayAvailable,
  }) = _StreakInfo;
}

/// Recent completion
@freezed
class RecentCompletion with _$RecentCompletion {
  const factory RecentCompletion({
    required String challengeType,
    String? submittedAt,
    required int score,
    required int xpEarned,
  }) = _RecentCompletion;
}

/// Full challenge detail
@freezed
class ChallengeDetail with _$ChallengeDetail {
  const factory ChallengeDetail({
    required String id,
    required Question question,
    required String difficulty,
    required int estimatedTimeMinutes,
    required int xpReward,
    required String userStatus,
    required bool completed,
    Map<String, dynamic>? extra,
  }) = _ChallengeDetail;
}

/// Question entity
@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required String title,
    required String difficulty,
    required String problemStatement,
    required String constraints,
    required String inputFormat,
    required String outputFormat,
    required String sampleInput1,
    required String sampleOutput1,
    String? sampleInput2,
    String? sampleOutput2,
    required int timeLimitMs,
    required int memoryLimitMb,
    required List<String> tags,
  }) = _Question;
}

/// Start challenge response
@freezed
class StartChallengeResponse with _$StartChallengeResponse {
  const factory StartChallengeResponse({
    required String challengeId,
    required String roomUrl,
    required String roomToken,
  }) = _StartChallengeResponse;
}

/// User preferences
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    required String weeklyDay,
    required int monthlyDate,
    required String notificationTime,
    required String timezone,
    required bool notificationsEnabled,
  }) = _UserPreferences;
}

/// Submit result
@freezed
class SubmitResult with _$SubmitResult {
  const factory SubmitResult({
    required String status,
    required int score,
    required int testsPassed,
    required int testsTotal,
    required int xpEarned,
  }) = _SubmitResult;
}
