import '../../domain/entities/challenge_entities.dart';

// ── Match Model ───────────────────────────────────────────────────────────────

class MatchModel {
  const MatchModel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.domain,
    required this.taskId,
    required this.durationMinutes,
    required this.status,
    this.challengeLink,
    this.startedAt,
    this.endedAt,
    this.winnerId,
    required this.challengerEloBefore,
    required this.opponentEloBefore,
    this.challengerEloAfter,
    this.opponentEloAfter,
    required this.createdAt,
    this.challengerName,
    this.opponentName,
    this.challengerAvatarUrl,
    this.opponentAvatarUrl,
    this.taskTitle,
    this.taskDescription,
    this.taskRequirements,
    this.inviteMessage,
    this.spectatorCount,
  });

  final String id;
  final String challengerId;
  final String opponentId;
  final String domain;
  final String taskId;
  final int durationMinutes;
  final String status;
  final String? challengeLink;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? winnerId;
  final int challengerEloBefore;
  final int opponentEloBefore;
  final int? challengerEloAfter;
  final int? opponentEloAfter;
  final DateTime createdAt;
  final String? challengerName;
  final String? opponentName;
  final String? challengerAvatarUrl;
  final String? opponentAvatarUrl;
  final String? taskTitle;
  final String? taskDescription;
  final String? taskRequirements;
  final String? inviteMessage;
  final int? spectatorCount;

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'] as String,
        challengerId: json['challenger_id'] as String,
        opponentId: json['opponent_id'] as String,
        domain: json['domain'] as String,
        taskId: json['task_id'] as String,
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
        challengeLink: json['challenge_link'] as String?,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        winnerId: json['winner_id'] as String?,
        challengerEloBefore: json['challenger_elo_before'] as int? ?? 1000,
        opponentEloBefore: json['opponent_elo_before'] as int? ?? 1000,
        challengerEloAfter: json['challenger_elo_after'] as int?,
        opponentEloAfter: json['opponent_elo_after'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        challengerName: json['challenger_name'] as String?,
        opponentName: json['opponent_name'] as String?,
        challengerAvatarUrl: json['challenger_avatar_url'] as String?,
        opponentAvatarUrl: json['opponent_avatar_url'] as String?,
        taskTitle: json['task_title'] as String?,
        taskDescription: json['task_description'] as String?,
        taskRequirements: json['task_requirements'] as String?,
        inviteMessage: json['invite_message'] as String?,
        spectatorCount: json['spectator_count'] as int?,
      );

  MatchEntity toEntity() => MatchEntity(
        id: id,
        challengerId: challengerId,
        opponentId: opponentId,
        domain: ChallengeDomainX.fromString(domain),
        taskId: taskId,
        durationMinutes: durationMinutes,
        status: MatchStatusX.fromString(status),
        challengeLink: challengeLink,
        startedAt: startedAt,
        endedAt: endedAt,
        winnerId: winnerId,
        challengerEloBefore: challengerEloBefore,
        opponentEloBefore: opponentEloBefore,
        challengerEloAfter: challengerEloAfter,
        opponentEloAfter: opponentEloAfter,
        createdAt: createdAt,
        challengerName: challengerName,
        opponentName: opponentName,
        challengerAvatarUrl: challengerAvatarUrl,
        opponentAvatarUrl: opponentAvatarUrl,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        taskRequirements: taskRequirements,
        inviteMessage: inviteMessage,
        spectatorCount: spectatorCount,
      );
}

// ── Submission Model ──────────────────────────────────────────────────────────

class ChallengeSubmissionModel {
  const ChallengeSubmissionModel({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.content,
    this.language,
    required this.submittedAt,
    this.score,
    this.scoreBreakdown,
    this.aiFeedback,
    required this.isAuto,
  });

  final String id;
  final String matchId;
  final String userId;
  final String content;
  final String? language;
  final DateTime submittedAt;
  final int? score;
  final Map<String, dynamic>? scoreBreakdown;
  final String? aiFeedback;
  final bool isAuto;

  factory ChallengeSubmissionModel.fromJson(Map<String, dynamic> json) =>
      ChallengeSubmissionModel(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        userId: json['user_id'] as String,
        content: json['content'] as String? ?? '',
        language: json['language'] as String?,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        score: json['score'] as int?,
        scoreBreakdown: json['score_breakdown'] as Map<String, dynamic>?,
        aiFeedback: json['ai_feedback'] as String?,
        isAuto: json['is_auto'] as bool? ?? false,
      );

  ChallengeSubmissionEntity toEntity() => ChallengeSubmissionEntity(
        id: id,
        matchId: matchId,
        userId: userId,
        content: content,
        language: language,
        submittedAt: submittedAt,
        score: score,
        scoreBreakdown: scoreBreakdown,
        aiFeedback: aiFeedback,
        isAuto: isAuto,
      );
}

// ── UserELO Model ─────────────────────────────────────────────────────────────

class UserEloModel {
  const UserEloModel({
    required this.userId,
    required this.elo,
    required this.tier,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.peakElo,
    required this.currentStreak,
    required this.updatedAt,
    this.username,
    this.avatarUrl,
  });

  final String userId;
  final int elo;
  final String tier;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int peakElo;
  final int currentStreak;
  final DateTime updatedAt;
  final String? username;
  final String? avatarUrl;

  factory UserEloModel.fromJson(Map<String, dynamic> json) => UserEloModel(
        userId: json['user_id'] as String,
        elo: json['elo'] as int? ?? 1000,
        tier: json['tier'] as String? ?? 'silver',
        matchesPlayed: json['matches_played'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
        peakElo: json['peak_elo'] as int? ?? 1000,
        currentStreak: json['current_streak'] as int? ?? 0,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        username: json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  UserEloEntity toEntity() => UserEloEntity(
        userId: userId,
        elo: elo,
        tier: EloTierX.fromString(tier),
        matchesPlayed: matchesPlayed,
        wins: wins,
        losses: losses,
        draws: draws,
        peakElo: peakElo,
        currentStreak: currentStreak,
        updatedAt: updatedAt,
        username: username,
        avatarUrl: avatarUrl,
      );
}

// ── Match Result Model ────────────────────────────────────────────────────────

class MatchResultModel {
  const MatchResultModel({
    required this.match,
    this.mySubmission,
    this.opponentSubmission,
    required this.myEloChange,
    required this.opponentEloChange,
    required this.myNewElo,
    required this.opponentNewElo,
    required this.myNewTier,
    required this.opponentNewTier,
    required this.tierChanged,
  });

  final MatchModel match;
  final ChallengeSubmissionModel? mySubmission;
  final ChallengeSubmissionModel? opponentSubmission;
  final int myEloChange;
  final int opponentEloChange;
  final int myNewElo;
  final int opponentNewElo;
  final String myNewTier;
  final String opponentNewTier;
  final bool tierChanged;

  factory MatchResultModel.fromJson(Map<String, dynamic> json) =>
      MatchResultModel(
        match: MatchModel.fromJson(json['match'] as Map<String, dynamic>),
        mySubmission: json['my_submission'] != null
            ? ChallengeSubmissionModel.fromJson(
                json['my_submission'] as Map<String, dynamic>)
            : null,
        opponentSubmission: json['opponent_submission'] != null
            ? ChallengeSubmissionModel.fromJson(
                json['opponent_submission'] as Map<String, dynamic>)
            : null,
        myEloChange: json['my_elo_change'] as int? ?? 0,
        opponentEloChange: json['opponent_elo_change'] as int? ?? 0,
        myNewElo: json['my_new_elo'] as int? ?? 1000,
        opponentNewElo: json['opponent_new_elo'] as int? ?? 1000,
        myNewTier: json['my_new_tier'] as String? ?? 'silver',
        opponentNewTier: json['opponent_new_tier'] as String? ?? 'silver',
        tierChanged: json['tier_changed'] as bool? ?? false,
      );

  MatchResultEntity toEntity() => MatchResultEntity(
        match: match.toEntity(),
        mySubmission: mySubmission?.toEntity(),
        opponentSubmission: opponentSubmission?.toEntity(),
        myEloChange: myEloChange,
        opponentEloChange: opponentEloChange,
        myNewElo: myNewElo,
        opponentNewElo: opponentNewElo,
        myNewTier: EloTierX.fromString(myNewTier),
        opponentNewTier: EloTierX.fromString(opponentNewTier),
        tierChanged: tierChanged,
      );
}
