/// Domain entities for the 1v1 Live Challenges feature.
/// Pure Dart — no Flutter or Firebase imports.

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ChallengeDomain { coding, design, product, marketing, data, writing }

extension ChallengeDomainX on ChallengeDomain {
  String get label {
    switch (this) {
      case ChallengeDomain.coding: return 'Coding';
      case ChallengeDomain.design: return 'Design';
      case ChallengeDomain.product: return 'Product';
      case ChallengeDomain.marketing: return 'Marketing';
      case ChallengeDomain.data: return 'Data';
      case ChallengeDomain.writing: return 'Writing';
    }
  }

  String get value {
    switch (this) {
      case ChallengeDomain.coding: return 'coding';
      case ChallengeDomain.design: return 'design';
      case ChallengeDomain.product: return 'product';
      case ChallengeDomain.marketing: return 'marketing';
      case ChallengeDomain.data: return 'data';
      case ChallengeDomain.writing: return 'writing';
    }
  }

  static ChallengeDomain fromString(String v) {
    return ChallengeDomain.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ChallengeDomain.coding,
    );
  }
}

enum MatchStatus { pending, active, completed, cancelled, expired }

extension MatchStatusX on MatchStatus {
  String get value {
    switch (this) {
      case MatchStatus.pending: return 'pending';
      case MatchStatus.active: return 'active';
      case MatchStatus.completed: return 'completed';
      case MatchStatus.cancelled: return 'cancelled';
      case MatchStatus.expired: return 'expired';
    }
  }

  static MatchStatus fromString(String v) {
    return MatchStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => MatchStatus.pending,
    );
  }
}

enum EloTier { bronze, silver, gold, platinum, diamond, elite }

extension EloTierX on EloTier {
  String get label {
    switch (this) {
      case EloTier.bronze: return 'Bronze';
      case EloTier.silver: return 'Silver';
      case EloTier.gold: return 'Gold';
      case EloTier.platinum: return 'Platinum';
      case EloTier.diamond: return 'Diamond';
      case EloTier.elite: return 'Elite';
    }
  }

  String get value {
    switch (this) {
      case EloTier.bronze: return 'bronze';
      case EloTier.silver: return 'silver';
      case EloTier.gold: return 'gold';
      case EloTier.platinum: return 'platinum';
      case EloTier.diamond: return 'diamond';
      case EloTier.elite: return 'elite';
    }
  }

  static EloTier fromString(String v) {
    return EloTier.values.firstWhere(
      (e) => e.value == v,
      orElse: () => EloTier.bronze,
    );
  }

  static EloTier fromElo(int elo) {
    if (elo >= 1800) return EloTier.elite;
    if (elo >= 1600) return EloTier.diamond;
    if (elo >= 1400) return EloTier.platinum;
    if (elo >= 1200) return EloTier.gold;
    if (elo >= 1000) return EloTier.silver;
    return EloTier.bronze;
  }
}

// ── Match Entity ──────────────────────────────────────────────────────────────

class MatchEntity {
  const MatchEntity({
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
  final ChallengeDomain domain;
  final String taskId;
  final int durationMinutes;
  final MatchStatus status;
  final String? challengeLink;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? winnerId;
  final int challengerEloBefore;
  final int opponentEloBefore;
  final int? challengerEloAfter;
  final int? opponentEloAfter;
  final DateTime createdAt;

  // Joined fields
  final String? challengerName;
  final String? opponentName;
  final String? challengerAvatarUrl;
  final String? opponentAvatarUrl;
  final String? taskTitle;
  final String? taskDescription;
  final String? taskRequirements;
  final String? inviteMessage;
  final int? spectatorCount;

  bool get isDraw => status == MatchStatus.completed && winnerId == null;

  bool isWinner(String userId) => winnerId == userId;

  DateTime? get endsAt => startedAt?.add(Duration(minutes: durationMinutes));

  Duration get remainingTime {
    final end = endsAt;
    if (end == null) return Duration.zero;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// ── Submission Entity ─────────────────────────────────────────────────────────

class ChallengeSubmissionEntity {
  const ChallengeSubmissionEntity({
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
}

// ── UserELO Entity ────────────────────────────────────────────────────────────

class UserEloEntity {
  const UserEloEntity({
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
  final EloTier tier;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int peakElo;
  final int currentStreak;
  final DateTime updatedAt;
  final String? username;
  final String? avatarUrl;

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;
}

// ── Match Result Entity ───────────────────────────────────────────────────────

class MatchResultEntity {
  const MatchResultEntity({
    required this.match,
    required this.mySubmission,
    this.opponentSubmission,
    required this.myEloChange,
    required this.opponentEloChange,
    required this.myNewElo,
    required this.opponentNewElo,
    required this.myNewTier,
    required this.opponentNewTier,
    required this.tierChanged,
  });

  final MatchEntity match;
  final ChallengeSubmissionEntity? mySubmission;
  final ChallengeSubmissionEntity? opponentSubmission;
  final int myEloChange;
  final int opponentEloChange;
  final int myNewElo;
  final int opponentNewElo;
  final EloTier myNewTier;
  final EloTier opponentNewTier;
  final bool tierChanged;
}

// ── Opponent Status ───────────────────────────────────────────────────────────

enum OpponentStatus { waiting, working, submitted }

extension OpponentStatusX on OpponentStatus {
  String get label {
    switch (this) {
      case OpponentStatus.waiting: return 'Waiting';
      case OpponentStatus.working: return 'Working...';
      case OpponentStatus.submitted: return 'Submitted';
    }
  }

  static OpponentStatus fromString(String v) {
    switch (v) {
      case 'working': return OpponentStatus.working;
      case 'submitted': return OpponentStatus.submitted;
      default: return OpponentStatus.waiting;
    }
  }
}
