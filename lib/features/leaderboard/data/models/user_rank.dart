import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_rank.freezed.dart';
part 'user_rank.g.dart';

@freezed
class UserRank with _$UserRank {
  const factory UserRank({
    required int elo,
    required String tier,
    @JsonKey(name: 'global_rank') int? globalRank,
    @JsonKey(name: 'country_rank') int? countryRank,
    @JsonKey(name: 'weekly_gain') required int weeklyGain,
    @JsonKey(name: 'monthly_gain') required int monthlyGain,
    @JsonKey(name: 'placement_matches_remaining') int? placementMatchesRemaining,
    @JsonKey(name: 'season_end_date') String? seasonEndDate,
    @JsonKey(name: 'days_remaining') int? daysRemaining,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
    required int wins,
    required int losses,
    required int draws,
    @JsonKey(name: 'peak_elo') required int peakElo,
    @JsonKey(name: 'current_streak') required int currentStreak,
  }) = _UserRank;

  factory UserRank.fromJson(Map<String, dynamic> json) =>
      _$UserRankFromJson(json);
}

@freezed
class EloHistoryItem with _$EloHistoryItem {
  const factory EloHistoryItem({
    required DateTime date,
    @JsonKey(name: 'elo_before') required int eloBefore,
    @JsonKey(name: 'elo_after') required int eloAfter,
    required int change,
    required String source,
    @JsonKey(name: 'opponent_name') String? opponentName,
  }) = _EloHistoryItem;

  factory EloHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$EloHistoryItemFromJson(json);
}

@freezed
class EloBreakdown with _$EloBreakdown {
  const factory EloBreakdown({
    @JsonKey(name: 'from_1v1') required int from1v1,
    @JsonKey(name: 'from_daily') required int fromDaily,
    @JsonKey(name: 'from_weekly') required int fromWeekly,
    @JsonKey(name: 'from_monthly') required int fromMonthly,
    @JsonKey(name: 'from_bonuses') required int fromBonuses,
  }) = _EloBreakdown;

  factory EloBreakdown.fromJson(Map<String, dynamic> json) =>
      _$EloBreakdownFromJson(json);
}
