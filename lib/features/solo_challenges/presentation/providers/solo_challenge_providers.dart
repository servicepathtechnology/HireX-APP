/// Part 2 — Solo Challenges Providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/solo_challenge_remote_datasource.dart';
import '../../data/repositories/solo_challenge_repository_impl.dart';
import '../../domain/entities/solo_challenge_entities.dart';
import '../../domain/repositories/solo_challenge_repository.dart';

// Repository provider
final soloChallengeRepositoryProvider = Provider<SoloChallengeRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final dataSource = SoloChallengeRemoteDataSource(dioClient);
  return SoloChallengeRepositoryImpl(dataSource);
});

// Challenge Hub provider
final challengeHubProvider = FutureProvider<ChallengeHub>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getChallengeHub();
});

// Daily challenge provider
final dailyChallengeProvider = FutureProvider<ChallengeDetail>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getDailyChallenge();
});

// Weekly challenge provider
final weeklyChallengeProvider = FutureProvider<ChallengeDetail>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getWeeklyChallenge();
});

// Monthly challenge provider
final monthlyChallengeProvider = FutureProvider<ChallengeDetail>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getMonthlyChallenge();
});

// Streak provider
final streakProvider = FutureProvider<StreakInfo>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getMyStreak();
});

// Preferences provider
final preferencesProvider = FutureProvider<UserPreferences>((ref) async {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return await repository.getPreferences();
});

// Start challenge notifier
class StartChallengeNotifier extends StateNotifier<AsyncValue<StartChallengeResponse?>> {
  final SoloChallengeRepository _repository;

  StartChallengeNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> startDaily() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.startDailyChallenge();
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startWeekly() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.startWeeklyChallenge();
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startMonthly() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.startMonthlyChallenge();
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final startChallengeProvider =
    StateNotifierProvider<StartChallengeNotifier, AsyncValue<StartChallengeResponse?>>((ref) {
  final repository = ref.watch(soloChallengeRepositoryProvider);
  return StartChallengeNotifier(repository);
});
