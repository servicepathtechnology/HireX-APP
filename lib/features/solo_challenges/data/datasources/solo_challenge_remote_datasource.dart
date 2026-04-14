/// Part 2 — Solo Challenges Remote Data Source
library;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/solo_challenge_models.dart';
import '../../domain/entities/solo_challenge_entities.dart';

class SoloChallengeRemoteDataSource {
  final DioClient _dioClient;

  SoloChallengeRemoteDataSource(this._dioClient);

  Future<ChallengeHub> getChallengeHub() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/hub');
    return ChallengeHubModel.fromJson(response.data);
  }

  Future<ChallengeDetail> getDailyChallenge() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/daily');
    return ChallengeDetailModel.fromJson(response.data);
  }

  Future<StartChallengeResponse> startDailyChallenge() async {
    final response = await _dioClient.instance.post('/api/v1/challenges/daily/start');
    return StartChallengeResponseModel.fromJson(response.data);
  }

  Future<ChallengeDetail> getWeeklyChallenge() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/weekly');
    return ChallengeDetailModel.fromJson(response.data);
  }

  Future<StartChallengeResponse> startWeeklyChallenge() async {
    final response = await _dioClient.instance.post('/api/v1/challenges/weekly/start');
    return StartChallengeResponseModel.fromJson(response.data);
  }

  Future<ChallengeDetail> getMonthlyChallenge() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/monthly');
    return ChallengeDetailModel.fromJson(response.data);
  }

  Future<StartChallengeResponse> startMonthlyChallenge() async {
    final response = await _dioClient.instance.post('/api/v1/challenges/monthly/start');
    return StartChallengeResponseModel.fromJson(response.data);
  }

  Future<StreakInfo> getMyStreak() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/streaks/me');
    return StreakInfoModel.fromJson(response.data);
  }

  Future<UserPreferences> getPreferences() async {
    final response = await _dioClient.instance.get('/api/v1/challenges/preferences');
    return UserPreferencesModel.fromJson(response.data);
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    await _dioClient.instance.patch(
      '/api/v1/challenges/preferences',
      data: UserPreferencesModel.toJson(preferences),
    );
  }
}
