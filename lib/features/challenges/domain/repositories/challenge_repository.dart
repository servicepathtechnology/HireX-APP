import 'package:dio/dio.dart';
import '../entities/challenge_entities.dart';

abstract class ChallengeRepository {
  // ── Invites ────────────────────────────────────────────────────────────────
  Future<MatchEntity> sendInvite({
    required String opponentId,
    required ChallengeDomain domain,
    required int durationMinutes,
    String? message,
  });

  Future<MatchEntity> acceptInvite(String matchId);
  Future<void> declineInvite(String matchId);

  // ── Match ──────────────────────────────────────────────────────────────────
  Future<MatchEntity> getMatch(String matchId);
  Future<List<MatchEntity>> getMyMatches({String? domain, String? result, DateTime? from, DateTime? to});

  // ── Submission ─────────────────────────────────────────────────────────────
  Future<ChallengeSubmissionEntity> submitAnswer({
    required String matchId,
    required String content,
    String? language,
    bool isAuto = false,
  });

  // ── ELO ───────────────────────────────────────────────────────────────────
  Future<UserEloEntity> getMyElo();
  Future<UserEloEntity> getUserElo(String userId);

  // ── Result ─────────────────────────────────────────────────────────────────
  Future<MatchResultEntity> getMatchResult(String matchId);

  // ── User search ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchUsers(String query, {CancelToken? cancelToken});
}
