import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/challenge_remote_datasource.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../data/services/challenge_realtime_service.dart';
import '../../domain/entities/challenge_entities.dart';
import '../../domain/repositories/challenge_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final challengeDataSourceProvider = Provider<ChallengeRemoteDataSource>((ref) {
  return ChallengeRemoteDataSource(dio: ref.watch(dioClientProvider).instance);
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl(dataSource: ref.watch(challengeDataSourceProvider));
});

// ── My ELO ────────────────────────────────────────────────────────────────────

final myEloProvider = FutureProvider<UserEloEntity>((ref) async {
  return ref.watch(challengeRepositoryProvider).getMyElo();
});

// ── User ELO (by userId) ──────────────────────────────────────────────────────

final userEloProvider = FutureProvider.family<UserEloEntity, String>((ref, userId) async {
  return ref.watch(challengeRepositoryProvider).getUserElo(userId);
});

// ── My Matches ────────────────────────────────────────────────────────────────

class MatchHistoryFilters {
  const MatchHistoryFilters({this.domain, this.result, this.from, this.to});
  final String? domain;
  final String? result;
  final DateTime? from;
  final DateTime? to;

  MatchHistoryFilters copyWith({
    String? domain,
    String? result,
    DateTime? from,
    DateTime? to,
    bool clearDomain = false,
    bool clearResult = false,
  }) =>
      MatchHistoryFilters(
        domain: clearDomain ? null : (domain ?? this.domain),
        result: clearResult ? null : (result ?? this.result),
        from: from ?? this.from,
        to: to ?? this.to,
      );
}

final matchHistoryFiltersProvider =
    StateProvider<MatchHistoryFilters>((ref) => const MatchHistoryFilters());

final myMatchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  final filters = ref.watch(matchHistoryFiltersProvider);
  return ref.watch(challengeRepositoryProvider).getMyMatches(
        domain: filters.domain,
        result: filters.result,
        from: filters.from,
        to: filters.to,
      );
});

// ── Match Detail ──────────────────────────────────────────────────────────────

final matchDetailProvider = FutureProvider.family<MatchEntity, String>((ref, matchId) async {
  return ref.watch(challengeRepositoryProvider).getMatch(matchId);
});

// ── Match Result ──────────────────────────────────────────────────────────────

final matchResultProvider =
    FutureProvider.family<MatchResultEntity, String>((ref, matchId) async {
  return ref.watch(challengeRepositoryProvider).getMatchResult(matchId);
});

// ── User Search ───────────────────────────────────────────────────────────────

final userSearchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.watch(challengeRepositoryProvider).searchUsers(query);
});

// ── New Challenge Form State ──────────────────────────────────────────────────

class NewChallengeState {
  const NewChallengeState({
    this.selectedOpponent,
    this.selectedDomain = ChallengeDomain.coding,
    this.selectedDifficulty = ChallengeDifficulty.easy,
    this.durationMinutes = 30,
    this.message,
    this.isLoading = false,
    this.error,
    this.createdMatch,
  });

  final Map<String, dynamic>? selectedOpponent;
  final ChallengeDomain selectedDomain;
  final ChallengeDifficulty selectedDifficulty;
  final int durationMinutes;
  final String? message;
  final bool isLoading;
  final String? error;
  final MatchEntity? createdMatch;

  bool get isValid => selectedOpponent != null;

  NewChallengeState copyWith({
    Map<String, dynamic>? selectedOpponent,
    ChallengeDomain? selectedDomain,
    ChallengeDifficulty? selectedDifficulty,
    int? durationMinutes,
    String? message,
    bool? isLoading,
    String? error,
    MatchEntity? createdMatch,
    bool clearOpponent = false,
    bool clearError = false,
    bool clearMatch = false,
  }) =>
      NewChallengeState(
        selectedOpponent: clearOpponent ? null : (selectedOpponent ?? this.selectedOpponent),
        selectedDomain: selectedDomain ?? this.selectedDomain,
        selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        message: message ?? this.message,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        createdMatch: clearMatch ? null : (createdMatch ?? this.createdMatch),
      );
}

class NewChallengeNotifier extends Notifier<NewChallengeState> {
  @override
  NewChallengeState build() => const NewChallengeState();

  void setOpponent(Map<String, dynamic>? opponent) =>
      state = state.copyWith(selectedOpponent: opponent, clearOpponent: opponent == null);

  void setDomain(ChallengeDomain domain) =>
      state = state.copyWith(selectedDomain: domain);

  void setDifficulty(ChallengeDifficulty difficulty) =>
      state = state.copyWith(selectedDifficulty: difficulty);

  void setDuration(int minutes) =>
      state = state.copyWith(durationMinutes: minutes);

  void setMessage(String? msg) =>
      state = state.copyWith(message: msg);

  Future<void> sendInvite() async {
    if (!state.isValid || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final match = await ref.read(challengeRepositoryProvider).sendInvite(
            opponentId: state.selectedOpponent!['id'] as String,
            domain: state.selectedDomain,
            durationMinutes: state.durationMinutes,
            difficulty: state.selectedDifficulty,
            message: state.message,
          );
      AnalyticsService.instance.challengeInviteSent(
        state.selectedDomain.value,
        state.durationMinutes,
      );
      state = state.copyWith(isLoading: false, createdMatch: match);
      // Cache the match so PendingChallengePage can use it without re-fetching
      ref.read(createdMatchCacheProvider.notifier).setMatch(match);
      // Invalidate all challenge-related providers so hub refreshes immediately
      ref.invalidate(myMatchesProvider);
      ref.invalidate(pendingInvitesProvider);
      ref.invalidate(myEloProvider);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message;
      if (data is Map && data['detail'] != null) {
        message = data['detail'].toString();
      } else if (status == 409) {
        message = 'A pending challenge with this opponent already exists.';
      } else if (status == 400) {
        message = 'Invalid request. Check your selections and try again.';
      } else if (status != null && status >= 500) {
        message = 'Server error. Please try again in a moment.';
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        message = 'No connection. Check your internet and try again.';
      } else {
        message = 'Something went wrong (${status ?? 'unknown'}). Try again.';
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const NewChallengeState();
}

final newChallengeProvider = NotifierProvider<NewChallengeNotifier, NewChallengeState>(
  NewChallengeNotifier.new,
);

// ── Created Match Cache (persisted to Hive so it survives app restarts) ──────

class _CreatedMatchCacheNotifier extends Notifier<MatchEntity?> {
  static const _boxKey = 'pending_match_id';
  static const _boxName = 'cache';

  @override
  MatchEntity? build() {
    // Restore from Hive on startup
    _restoreFromHive();
    return null;
  }

  void _restoreFromHive() {
    try {
      final box = Hive.box<dynamic>(_boxName);
      final matchId = box.get(_boxKey) as String?;
      if (matchId != null) {
        // Fetch the match from the list (avoids 404 on direct GET)
        Future.microtask(() async {
          try {
            final matches = await ref.read(challengeRepositoryProvider).getMyMatches();
            final match = matches.firstWhere(
              (m) => m.id == matchId && m.status == MatchStatus.pending,
              orElse: () => throw StateError('not found'),
            );
            state = match;
          } catch (_) {
            // Match no longer pending — clear cache
            _clearHive();
          }
        });
      }
    } catch (_) {}
  }

  void _clearHive() {
    try {
      Hive.box<dynamic>('cache').delete(_boxKey);
    } catch (_) {}
  }

  void setMatch(MatchEntity? value) {
    state = value;
    try {
      final box = Hive.box<dynamic>('cache');
      if (value != null) {
        box.put(_boxKey, value.id);
      } else {
        box.delete(_boxKey);
      }
    } catch (_) {}
  }
}

final createdMatchCacheProvider =
    NotifierProvider<_CreatedMatchCacheNotifier, MatchEntity?>(
  _CreatedMatchCacheNotifier.new,
);

// ── Live Room State ───────────────────────────────────────────────────────────

class LiveRoomState {
  const LiveRoomState({
    this.match,
    this.isLoading = true,
    this.error,
    this.submissionContent = '',
    this.selectedLanguage = 'python',
    this.isSubmitting = false,
    this.hasSubmitted = false,
    this.opponentStatus = OpponentStatus.waiting,
    this.remainingSeconds = 0,
    this.isConnected = false,
    this.spectatorCount = 0,
    this.showSubmitConfirm = false,
  });

  final MatchEntity? match;
  final bool isLoading;
  final String? error;
  final String submissionContent;
  final String selectedLanguage;
  final bool isSubmitting;
  final bool hasSubmitted;
  final OpponentStatus opponentStatus;
  final int remainingSeconds;
  final bool isConnected;
  final int spectatorCount;
  final bool showSubmitConfirm;

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isTimerCritical => remainingSeconds <= 60 && remainingSeconds > 0;

  LiveRoomState copyWith({
    MatchEntity? match,
    bool? isLoading,
    String? error,
    String? submissionContent,
    String? selectedLanguage,
    bool? isSubmitting,
    bool? hasSubmitted,
    OpponentStatus? opponentStatus,
    int? remainingSeconds,
    bool? isConnected,
    int? spectatorCount,
    bool? showSubmitConfirm,
    bool clearError = false,
  }) =>
      LiveRoomState(
        match: match ?? this.match,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        submissionContent: submissionContent ?? this.submissionContent,
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        hasSubmitted: hasSubmitted ?? this.hasSubmitted,
        opponentStatus: opponentStatus ?? this.opponentStatus,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        isConnected: isConnected ?? this.isConnected,
        spectatorCount: spectatorCount ?? this.spectatorCount,
        showSubmitConfirm: showSubmitConfirm ?? this.showSubmitConfirm,
      );
}

class LiveRoomNotifier extends FamilyNotifier<LiveRoomState, String> {
  StreamSubscription? _timerSub;
  StreamSubscription? _opponentSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _spectatorSub;
  StreamSubscription? _connectionSub;
  Timer? _localTimer;

  @override
  LiveRoomState build(String matchId) {
    ref.onDispose(_cleanup);
    _init(matchId);
    return const LiveRoomState();
  }

  Future<void> _init(String matchId) async {
    try {
      final match = await ref.read(challengeRepositoryProvider).getMatch(matchId);
      final remaining = match.remainingTime.inSeconds;
      state = state.copyWith(
        match: match,
        isLoading: false,
        remainingSeconds: remaining > 0 ? remaining : 0,
      );

      // Connect WebSocket with actual Firebase ID token (JWT)
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user != null) {
        // Get the actual Firebase ID token (JWT), not just the UID
        String? idToken;
        try {
          final firebaseUser = await _getFirebaseIdToken();
          idToken = firebaseUser;
        } catch (_) {
          idToken = user.firebaseUid; // fallback
        }
        await ChallengeRealtimeService.instance.connect(matchId, idToken ?? user.firebaseUid);
        _subscribeToEvents();
      }

      // Start local countdown as fallback
      if (remaining > 0) _startLocalTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribeToEvents() {
    final svc = ChallengeRealtimeService.instance;

    _timerSub = svc.timerStream.listen((duration) {
      state = state.copyWith(remainingSeconds: duration.inSeconds);
    });

    _opponentSub = svc.opponentStatusStream.listen((status) {
      state = state.copyWith(opponentStatus: status);
    });

    _completedSub = svc.matchCompletedStream.listen((_) {
      _localTimer?.cancel();
      state = state.copyWith(remainingSeconds: 0);
    });

    _spectatorSub = svc.spectatorCountStream.listen((count) {
      state = state.copyWith(spectatorCount: count);
    });

    _connectionSub = ChallengeRealtimeService.instance.events
        .where((e) => e.type == 'connection_status')
        .listen((e) {
      state = state.copyWith(isConnected: e.data['connected'] as bool? ?? false);
    });
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.remainingSeconds;
      if (current <= 0) {
        _localTimer?.cancel();
        if (!state.hasSubmitted) _autoSubmit();
        return;
      }
      state = state.copyWith(remainingSeconds: current - 1);
    });
  }

  void updateContent(String content) {
    state = state.copyWith(submissionContent: content);
    // Notify backend we're working
    ChallengeRealtimeService.instance.sendStatus('working');
  }

  void setLanguage(String lang) => state = state.copyWith(selectedLanguage: lang);

  void showConfirmDialog() => state = state.copyWith(showSubmitConfirm: true);
  void hideConfirmDialog() => state = state.copyWith(showSubmitConfirm: false);

  Future<void> submit({bool isAuto = false}) async {
    if (state.hasSubmitted || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, showSubmitConfirm: false);
    try {
      final matchId = state.match?.id;
      if (matchId == null) return;
      await ref.read(challengeRepositoryProvider).submitAnswer(
            matchId: matchId,
            content: state.submissionContent,
            language: state.selectedLanguage,
            isAuto: isAuto,
          );
      AnalyticsService.instance.matchSubmitted(
        matchId,
        state.match!.domain.value,
        isAuto,
        state.remainingSeconds,
      );
      state = state.copyWith(isSubmitting: false, hasSubmitted: true);
      ChallengeRealtimeService.instance.sendStatus('submitted');
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<void> _autoSubmit() async {
    await submit(isAuto: true);
  }

  /// Get the current Firebase ID token (JWT) for WebSocket auth.
  Future<String?> _getFirebaseIdToken() async {
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return firebaseUser.getIdToken();
  }

  void _cleanup() {
    _timerSub?.cancel();
    _opponentSub?.cancel();
    _completedSub?.cancel();
    _spectatorSub?.cancel();
    _connectionSub?.cancel();
    _localTimer?.cancel();
    ChallengeRealtimeService.instance.disconnect();
  }
}

final liveRoomProvider =
    NotifierProviderFamily<LiveRoomNotifier, LiveRoomState, String>(
  LiveRoomNotifier.new,
);

// ── Pending Invites ───────────────────────────────────────────────────────────

final pendingInvitesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  final all = await ref.watch(challengeRepositoryProvider).getMyMatches();
  return all.where((m) => m.status == MatchStatus.pending).toList();
});

// ── Invite Action Notifier ────────────────────────────────────────────────────

class InviteActionNotifier extends Notifier<AsyncValue<MatchEntity?>> {
  @override
  AsyncValue<MatchEntity?> build() => const AsyncData(null);

  Future<MatchEntity?> accept(String matchId) async {
    state = const AsyncLoading();
    try {
      final match = await ref.read(challengeRepositoryProvider).acceptInvite(matchId);
      AnalyticsService.instance.challengeInviteAccepted(matchId, match.domain.value);
      state = AsyncData(match);
      ref.invalidate(pendingInvitesProvider);
      ref.invalidate(myMatchesProvider);
      return match;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> decline(String matchId, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await ref.read(challengeRepositoryProvider).declineInvite(matchId, reason: reason);
        return null;
      },
    );
    if (!state.hasError) {
      AnalyticsService.instance.challengeInviteDeclined(matchId, reason ?? '');
      ref.invalidate(pendingInvitesProvider);
    }
  }
}

final inviteActionProvider =
    NotifierProvider<InviteActionNotifier, AsyncValue<MatchEntity?>>(
  InviteActionNotifier.new,
);
