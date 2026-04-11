import 'package:dio/dio.dart';
import '../models/challenge_models.dart';

class ChallengeRemoteDataSource {
  const ChallengeRemoteDataSource({required this.dio});
  final Dio dio;

  Future<MatchModel> sendInvite({
    required String opponentId,
    required String domain,
    required int durationMinutes,
    String? message,
  }) async {
    final res = await dio.post('/api/v1/challenges/matches', data: {
      'opponent_id': opponentId,
      'domain': domain,
      'duration_minutes': durationMinutes,
      if (message != null) 'invite_message': message,
    });
    return MatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MatchModel> acceptInvite(String matchId) async {
    final res = await dio.post('/api/v1/challenges/matches/$matchId/accept');
    return MatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> declineInvite(String matchId) async {
    await dio.post('/api/v1/challenges/matches/$matchId/decline');
  }

  Future<MatchModel> getMatch(String matchId) async {
    final res = await dio.get('/api/v1/challenges/matches/$matchId');
    return MatchModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MatchModel>> getMyMatches({
    String? domain,
    String? result,
    String? from,
    String? to,
  }) async {
    final res = await dio.get('/api/v1/challenges/matches', queryParameters: {
      if (domain != null) 'domain': domain,
      if (result != null) 'result': result,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final list = res.data as List<dynamic>;
    return list.map((e) => MatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChallengeSubmissionModel> submitAnswer({
    required String matchId,
    required String content,
    String? language,
    bool isAuto = false,
  }) async {
    final res = await dio.post(
      '/api/v1/challenges/matches/$matchId/submit',
      data: {
        'content': content,
        if (language != null) 'language': language,
        'is_auto': isAuto,
      },
    );
    return ChallengeSubmissionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserEloModel> getMyElo() async {
    final res = await dio.get('/api/v1/challenges/elo/me');
    return UserEloModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserEloModel> getUserElo(String userId) async {
    final res = await dio.get('/api/v1/challenges/elo/$userId');
    return UserEloModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MatchResultModel> getMatchResult(String matchId) async {
    final res = await dio.get('/api/v1/challenges/matches/$matchId/result');
    return MatchResultModel.fromJson(res.data as Map<String, dynamic>);
  }
  Future<List<Map<String, dynamic>>> searchUsers(String query, {CancelToken? cancelToken}) async {
    final res = await dio.get(
      '/api/v1/candidates/search',
      queryParameters: {'q': query, 'limit': 10, 'exclude_self': true},
      cancelToken: cancelToken,
    );
    final data = res.data as Map<String, dynamic>;
    final items = data['results'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }
}
