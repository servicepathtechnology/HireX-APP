/// Part 2 — Solo Challenges Repository Interface
library;

import '../entities/solo_challenge_entities.dart';

abstract class SoloChallengeRepository {
  /// Get challenge hub data
  Future<ChallengeHub> getChallengeHub();

  /// Get daily challenge detail
  Future<ChallengeDetail> getDailyChallenge();

  /// Start daily challenge
  Future<StartChallengeResponse> startDailyChallenge();

  /// Get weekly challenge detail
  Future<ChallengeDetail> getWeeklyChallenge();

  /// Start weekly challenge
  Future<StartChallengeResponse> startWeeklyChallenge();

  /// Get monthly challenge detail
  Future<ChallengeDetail> getMonthlyChallenge();

  /// Start monthly challenge
  Future<StartChallengeResponse> startMonthlyChallenge();

  /// Get user streak
  Future<StreakInfo> getMyStreak();

  /// Get user preferences
  Future<UserPreferences> getPreferences();

  /// Update user preferences
  Future<void> updatePreferences(UserPreferences preferences);
}
