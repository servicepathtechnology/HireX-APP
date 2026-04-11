import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../domain/entities/task_entity.dart';
import '../../../submissions/domain/entities/submission_entity.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final taskDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(dio: ref.watch(dioClientProvider).instance);
});

// ── Filters ───────────────────────────────────────────────────────────────────

final taskFiltersProvider = StateNotifierProvider<TaskFiltersNotifier, TaskFilters>((ref) {
  return TaskFiltersNotifier();
});

class TaskFiltersNotifier extends StateNotifier<TaskFilters> {
  TaskFiltersNotifier() : super(const TaskFilters());

  void setDomain(String? domain) =>
      state = state.copyWith(domain: domain, clearDomain: domain == null);
  void setDifficulty(String? d) =>
      state = state.copyWith(difficulty: d, clearDifficulty: d == null);
  void setSort(String sort) => state = state.copyWith(sort: sort);
  void setSearch(String? search) =>
      state = state.copyWith(search: search, clearSearch: search == null || search.isEmpty);
  void reset() => state = const TaskFilters();
}

// ── Task Feed (paginated) ─────────────────────────────────────────────────────

class TaskFeedNotifier extends AsyncNotifier<PaginatedTasks> {
  int _page = 1;
  bool _isFetchingMore = false;
  List<TaskEntity> _allItems = [];

  @override
  Future<PaginatedTasks> build() async {
    final filters = ref.watch(taskFiltersProvider);
    _page = 1;
    _allItems = [];
    return _fetch(filters, page: 1);
  }

  Future<PaginatedTasks> _fetch(TaskFilters filters, {required int page}) async {
    final ds = ref.read(taskDataSourceProvider);
    final result = await ds.getTasks(
      page: page,
      domain: filters.domain,
      difficulty: filters.difficulty,
      sort: filters.sort,
      search: filters.search,
    );
    final entities = result.items.map((m) => m.toEntity()).toList();
    if (page == 1) {
      _allItems = entities;
    } else {
      _allItems = [..._allItems, ...entities];
    }
    return PaginatedTasks(
      items: _allItems,
      total: result.total,
      page: page,
      pageSize: result.pageSize,
      hasMore: result.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isFetchingMore) return;
    _isFetchingMore = true;
    try {
      _page++;
      final filters = ref.read(taskFiltersProvider);
      final next = await _fetch(filters, page: _page);
      state = AsyncData(next);
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _page = 1;
    _allItems = [];
    state = await AsyncValue.guard(() => _fetch(ref.read(taskFiltersProvider), page: 1));
  }

  void toggleBookmarkLocally(String taskId, bool bookmarked) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.items.map((t) {
      return t.id == taskId ? t.copyWith(isBookmarked: bookmarked) : t;
    }).toList();
    state = AsyncData(PaginatedTasks(
      items: updated,
      total: current.total,
      page: current.page,
      pageSize: current.pageSize,
      hasMore: current.hasMore,
    ));
  }
}

final taskFeedProvider = AsyncNotifierProvider<TaskFeedNotifier, PaginatedTasks>(
  TaskFeedNotifier.new,
);

// ── Task Detail ───────────────────────────────────────────────────────────────

final taskDetailProvider =
    FutureProvider.family<TaskEntity, String>((ref, taskId) async {
  final ds = ref.read(taskDataSourceProvider);
  final model = await ds.getTask(taskId);
  return model.toEntity();
});

// ── Bookmarks ─────────────────────────────────────────────────────────────────

class BookmarksNotifier extends AsyncNotifier<List<TaskEntity>> {
  @override
  Future<List<TaskEntity>> build() async {
    final ds = ref.read(taskDataSourceProvider);
    final models = await ds.getBookmarks();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> toggle(String taskId) async {
    final ds = ref.read(taskDataSourceProvider);
    try {
      final isNowBookmarked = await ds.toggleBookmark(taskId);
      ref.read(taskFeedProvider.notifier).toggleBookmarkLocally(taskId, isNowBookmarked);
      if (!isNowBookmarked) {
        // Remove from local list immediately
        final current = state.valueOrNull ?? [];
        state = AsyncData(current.where((t) => t.id != taskId).toList());
      } else {
        // Re-fetch the full bookmarks list so the new task appears
        state = const AsyncLoading();
        state = await AsyncValue.guard(() async {
          final models = await ds.getBookmarks();
          return models.map((m) => m.toEntity()).toList();
        });
      }
    } catch (_) {
      // Revert the feed icon on failure
      final current = state.valueOrNull;
      if (current != null) {
        final wasBookmarked = current.any((t) => t.id == taskId);
        ref.read(taskFeedProvider.notifier).toggleBookmarkLocally(taskId, wasBookmarked);
      }
      rethrow;
    }
  }
}

final bookmarksProvider = AsyncNotifierProvider<BookmarksNotifier, List<TaskEntity>>(
  BookmarksNotifier.new,
);

// ── My Submissions ────────────────────────────────────────────────────────────

class MySubmissionsNotifier extends AsyncNotifier<List<SubmissionEntity>> {
  @override
  Future<List<SubmissionEntity>> build() async {
    final ds = ref.read(taskDataSourceProvider);
    final models = await ds.getMySubmissions();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final ds = ref.read(taskDataSourceProvider);
      final models = await ds.getMySubmissions();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  Future<void> deleteSubmission(String id) async {
    final ds = ref.read(taskDataSourceProvider);
    await ds.deleteSubmission(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }
}

final mySubmissionsProvider =
    AsyncNotifierProvider<MySubmissionsNotifier, List<SubmissionEntity>>(
  MySubmissionsNotifier.new,
);

// ── Submission for a task ─────────────────────────────────────────────────────

final submissionForTaskProvider =
    FutureProvider.family<SubmissionEntity?, String>((ref, taskId) async {
  final ds = ref.read(taskDataSourceProvider);
  final all = await ds.getMySubmissions();
  final match = all.where((m) => m.taskId == taskId).toList();
  return match.isEmpty ? null : match.first.toEntity();
});

// ── Leaderboard ───────────────────────────────────────────────────────────────

final leaderboardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, taskId) async {
  final ds = ref.read(taskDataSourceProvider);
  return ds.getLeaderboard(taskId);
});

// ── POW Profile ───────────────────────────────────────────────────────────────

final powProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final ds = ref.read(taskDataSourceProvider);
  return ds.getPOWProfile();
});

final badgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ds = ref.read(taskDataSourceProvider);
  return ds.getBadges();
});
