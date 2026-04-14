/// Part 2 — Solo Challenges Repository Implementation
library;

import '../../domain/entities/solo_challenge_entities.dart';
import '../../domain/repositories/solo_challenge_repository.dart';
import '../datasources/solo_challenge_remote_datasource.dart';

class SoloChallengeRepositoryImpl implements SoloChallengeRepository {
  final SoloChallengeRemoteDataSource _remoteDataSource;

  SoloChallengeRepositoryImpl(this._remoteDataSource);

  @override
  Future<ChallengeHub> getChallengeHub() async {
    return await _remoteDataSource.getChallengeHub();
  }

  @override
  Future<ChallengeDetail> getDailyChallenge() async {
    return await _remoteDataSource.getDailyChallenge();
  }

  @override
  Future<StartChallengeResponse> startDailyChallenge() async {
    return await _remoteDataSource.startDailyChallenge();
  }

  @override
  Future<ChallengeDetail> getWeeklyChallenge() async {
    return await _remoteDataSource.getWeeklyChallenge();
  }

  @override
  Future<StartChallengeResponse> startWeeklyChallenge() async {
    return await _remoteDataSource.startWeeklyChallenge();
  }

  @override
  Future<ChallengeDetail> getMonthlyChallenge() async {
    return await _remoteDataSource.getMonthlyChallenge();
  }

  @override
  Future<StartChallengeResponse> startMonthlyChallenge() async {
    return await _remoteDataSource.startMonthlyChallenge();
  }

  @override
  Future<StreakInfo> getMyStreak() async {
    return await _remoteDataSource.getMyStreak();
  }

  @override
  Future<UserPreferences> getPreferences() async {
    return await _remoteDataSource.getPreferences();
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    await _remoteDataSource.updatePreferences(preferences);
  }
}
