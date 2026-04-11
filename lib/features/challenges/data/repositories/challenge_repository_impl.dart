import 'package:dio/dio.dart';
import '../../domain/entities/challenge_entities.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_remote_datasource.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  const ChallengeRepositoryImpl({required this.dataSource});
  final ChallengeRemoteDataSource dataSource;

  @override
  Future<MatchEntity> sendInvite({
    required String opponentId,
    required ChallengeDomain domain,
    required int durationMinutes,
    String? message,
  }) async {
    final model = await dataSource.sendInvite(
      opponentId: opponentId,
      domain: domain.value,
      durationMinutes: durationMinutes,
      message: message,
    );
    return model.toEntity();
  }

  @override
  Future<MatchEntity> acceptInvite(String matchId) async {
    final model = await dataSource.acceptInvite(matchId);
    return model.toEntity();
  }

  @override
  Future<void> declineInvite(String matchId) => dataSource.declineInvite(matchId);

  @override
  Future<MatchEntity> getMatch(String matchId) async {
    final model = await dataSource.getMatch(matchId);
    return model.toEntity();
  }

  @override
  Future<List<MatchEntity>> getMyMatches({
    String? domain,
    String? result,
    DateTime? from,
    DateTime? to,
  }) async {
    final models = await dataSource.getMyMatches(
      domain: domain,
      result: result,
      from: from?.toIso8601String(),
      to: to?.toIso8601String(),
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChallengeSubmissionEntity> submitAnswer({
    required String matchId,
    required String content,
    String? language,
    bool isAuto = false,
  }) async {
    final model = await dataSource.submitAnswer(
      matchId: matchId,
      content: content,
      language: language,
      isAuto: isAuto,
    );
    return model.toEntity();
  }

  @override
  Future<UserEloEntity> getMyElo() async {
    final model = await dataSource.getMyElo();
    return model.toEntity();
  }

  @override
  Future<UserEloEntity> getUserElo(String userId) async {
    final model = await dataSource.getUserElo(userId);
    return model.toEntity();
  }

  @override
  Future<MatchResultEntity> getMatchResult(String matchId) async {
    final model = await dataSource.getMatchResult(matchId);
    return model.toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query, {CancelToken? cancelToken}) =>
      dataSource.searchUsers(query, cancelToken: cancelToken);
}
