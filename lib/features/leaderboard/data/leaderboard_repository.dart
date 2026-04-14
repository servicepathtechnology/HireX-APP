import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hirex_app/core/network/dio_client.dart';
import 'package:hirex_app/features/leaderboard/data/models/leaderboard_row.dart';
import 'package:hirex_app/features/leaderboard/data/models/user_rank.dart';

final _dioClientProvider = Provider<DioClient>((ref) => DioClient());

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final dio = ref.watch(_dioClientProvider).instance;
  return LeaderboardRepository(dio);
});

class LeaderboardRepository {
  final Dio _dio;

  LeaderboardRepository(this._dio);

  Future<LeaderboardResponse> getGlobalLeaderboard({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/global',
      queryParameters: {'page': page, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<LeaderboardResponse> getCountryLeaderboard({
    String? country,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/country',
      queryParameters: {
        if (country != null) 'country': country,
        'page': page,
        'limit': limit,
      },
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<LeaderboardResponse> getDomainLeaderboard({
    String domain = 'coding',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/domain',
      queryParameters: {'domain': domain, 'page': page, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<LeaderboardResponse> getExperienceLeaderboard({
    String level = 'junior',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/experience',
      queryParameters: {'level': level, 'page': page, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<LeaderboardResponse> getWeeklyLeaderboard({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/weekly',
      queryParameters: {'page': page, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<LeaderboardResponse> getMonthlyLeaderboard({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/api/v1/leaderboard/monthly',
      queryParameters: {'page': page, 'limit': limit},
    );
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<UserRank> getMyRank() async {
    final response = await _dio.get('/api/v1/elo/me');
    return UserRank.fromJson(response.data);
  }

  Future<UserRank> getUserRank(String userId) async {
    final response = await _dio.get('/api/v1/elo/$userId');
    return UserRank.fromJson(response.data);
  }

  Future<List<EloHistoryItem>> getEloHistory({int days = 30}) async {
    final response = await _dio.get(
      '/api/v1/elo/me/history',
      queryParameters: {'days': days},
    );
    final items = (response.data['items'] as List)
        .map((item) => EloHistoryItem.fromJson(item))
        .toList();
    return items;
  }

  Future<EloBreakdown> getEloBreakdown() async {
    final response = await _dio.get('/api/v1/elo/me/breakdown');
    return EloBreakdown.fromJson(response.data);
  }
}
