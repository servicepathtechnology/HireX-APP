/// Part 2 — Solo Challenges Data Models
library;

import '../../domain/entities/solo_challenge_entities.dart';

class ChallengeHubModel {
  static ChallengeHub fromJson(Map<String, dynamic> json) {
    return ChallengeHub(
      daily: DailyChallengeInfoModel.fromJson(json['daily']),
      weekly: WeeklyChallengeInfoModel.fromJson(json['weekly']),
      monthly: MonthlyChallengeInfoModel.fromJson(json['monthly']),
      streak: StreakInfoModel.fromJson(json['streak']),
      recentCompletions: (json['recent_completions'] as List?)
              ?.map((e) => RecentCompletionModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DailyChallengeInfoModel {
  static DailyChallengeInfo fromJson(Map<String, dynamic> json) {
    return DailyChallengeInfo(
      id: json['id'],
      date: json['date'],
      questionTitle: json['question_title'],
      difficulty: json['difficulty'] ?? 'easy',
      status: json['status'] ?? 'not_started',
      completed: json['completed'] ?? false,
      xpReward: json['xp_reward'] ?? 30,
    );
  }
}

class WeeklyChallengeInfoModel {
  static WeeklyChallengeInfo fromJson(Map<String, dynamic> json) {
    return WeeklyChallengeInfo(
      id: json['id'],
      year: json['year'],
      week: json['week'],
      questionTitle: json['question_title'],
      difficulty: json['difficulty'] ?? 'medium',
      status: json['status'] ?? 'not_started',
      completed: json['completed'] ?? false,
      xpReward: json['xp_reward'] ?? 75,
    );
  }
}

class MonthlyChallengeInfoModel {
  static MonthlyChallengeInfo fromJson(Map<String, dynamic> json) {
    return MonthlyChallengeInfo(
      id: json['id'],
      year: json['year'],
      month: json['month'],
      questionTitle: json['question_title'],
      difficulty: json['difficulty'] ?? 'hard',
      status: json['status'] ?? 'not_started',
      completed: json['completed'] ?? false,
      xpReward: json['xp_reward'] ?? 150,
    );
  }
}

class StreakInfoModel {
  static StreakInfo fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      graceDayAvailable: json['grace_day_available'] ?? false,
    );
  }
}

class RecentCompletionModel {
  static RecentCompletion fromJson(Map<String, dynamic> json) {
    return RecentCompletion(
      challengeType: json['challenge_type'] ?? '',
      submittedAt: json['submitted_at'],
      score: json['score'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
    );
  }
}

class ChallengeDetailModel {
  static ChallengeDetail fromJson(Map<String, dynamic> json) {
    return ChallengeDetail(
      id: json['id'] ?? '',
      question: QuestionModel.fromJson(json['question'] ?? {}),
      difficulty: json['difficulty'] ?? 'easy',
      estimatedTimeMinutes: json['estimated_time_minutes'] ?? 15,
      xpReward: json['xp_reward'] ?? 30,
      userStatus: json['user_status'] ?? 'not_started',
      completed: json['completed'] ?? false,
      extra: json,
    );
  }
}

class QuestionModel {
  static Question fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? 'easy',
      problemStatement: json['problem_statement'] ?? '',
      constraints: json['constraints'] ?? '',
      inputFormat: json['input_format'] ?? '',
      outputFormat: json['output_format'] ?? '',
      sampleInput1: json['sample_input_1'] ?? '',
      sampleOutput1: json['sample_output_1'] ?? '',
      sampleInput2: json['sample_input_2'],
      sampleOutput2: json['sample_output_2'],
      timeLimitMs: json['time_limit_ms'] ?? 2000,
      memoryLimitMb: json['memory_limit_mb'] ?? 256,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class StartChallengeResponseModel {
  static StartChallengeResponse fromJson(Map<String, dynamic> json) {
    return StartChallengeResponse(
      challengeId: json['challenge_id'] ?? '',
      roomUrl: json['room_url'] ?? '',
      roomToken: json['room_token'] ?? '',
    );
  }
}

class UserPreferencesModel {
  static UserPreferences fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      weeklyDay: json['weekly_day'] ?? 'monday',
      monthlyDate: json['monthly_date'] ?? 1,
      notificationTime: json['notification_time'] ?? '09:00',
      timezone: json['timezone'] ?? 'UTC',
      notificationsEnabled: json['notifications_enabled'] ?? true,
    );
  }

  static Map<String, dynamic> toJson(UserPreferences prefs) {
    return {
      'weekly_day': prefs.weeklyDay,
      'monthly_date': prefs.monthlyDate,
      'notification_time': prefs.notificationTime,
      'timezone': prefs.timezone,
    };
  }
}
