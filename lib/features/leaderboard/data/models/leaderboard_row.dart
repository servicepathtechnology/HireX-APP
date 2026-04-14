import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_row.freezed.dart';
part 'leaderboard_row.g.dart';

@freezed
class LeaderboardRow with _$LeaderboardRow {
  const factory LeaderboardRow({
    required int rank,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    String? avatar,
    String? country,
    required int elo,
    required String tier,
    @JsonKey(name: 'win_rate') required double winRate,
    @JsonKey(name: 'matches_played') required int matchesPlayed,
  }) = _LeaderboardRow;

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardRowFromJson(json);
}

@freezed
class LeaderboardResponse with _$LeaderboardResponse {
  const factory LeaderboardResponse({
    required List<LeaderboardRow> rows,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'user_row') LeaderboardRow? userRow,
  }) = _LeaderboardResponse;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardResponseFromJson(json);
}
