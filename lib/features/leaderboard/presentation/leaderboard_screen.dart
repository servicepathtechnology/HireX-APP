import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:hirex_app/features/leaderboard/data/leaderboard_repository.dart';
import 'package:hirex_app/features/leaderboard/data/models/leaderboard_row.dart';
import 'package:hirex_app/features/leaderboard/data/models/user_rank.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/your_rank_card.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/leaderboard_row_widget.dart';
import 'package:shimmer/shimmer.dart';

enum LeaderboardType {
  global,
  country,
  domain,
  experience,
  weekly,
  monthly,
}

final userRankProvider = FutureProvider<UserRank>((ref) async {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getMyRank();
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _currentType = LeaderboardType.global;
  
  final Map<LeaderboardType, PagingController<int, LeaderboardRow>> _pagingControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Initialize paging controllers
    for (final type in LeaderboardType.values) {
      _pagingControllers[type] = PagingController<int, LeaderboardRow>(
        firstPageKey: 1,
      );
      _pagingControllers[type]!.addPageRequestListener((pageKey) {
        _fetchPage(type, pageKey);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _pagingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentType = LeaderboardType.values[_tabController.index];
      });
    }
  }

  Future<void> _fetchPage(LeaderboardType type, int pageKey) async {
    try {
      final repository = ref.read(leaderboardRepositoryProvider);
      LeaderboardResponse response;

      switch (type) {
        case LeaderboardType.global:
          response = await repository.getGlobalLeaderboard(page: pageKey);
          break;
        case LeaderboardType.country:
          response = await repository.getCountryLeaderboard(page: pageKey);
          break;
        case LeaderboardType.domain:
          response = await repository.getDomainLeaderboard(page: pageKey);
          break;
        case LeaderboardType.experience:
          response = await repository.getExperienceLeaderboard(page: pageKey);
          break;
        case LeaderboardType.weekly:
          response = await repository.getWeeklyLeaderboard(page: pageKey);
          break;
        case LeaderboardType.monthly:
          response = await repository.getMonthlyLeaderboard(page: pageKey);
          break;
      }

      final isLastPage = response.rows.length < 50;
      if (isLastPage) {
        _pagingControllers[type]!.appendLastPage(response.rows);
      } else {
        _pagingControllers[type]!.appendPage(response.rows, pageKey + 1);
      }
    } catch (error) {
      _pagingControllers[type]!.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRankAsync = ref.watch(userRankProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Country'),
            Tab(text: 'Coding'),
            Tab(text: 'Experience'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Your Rank Card
          userRankAsync.when(
            data: (userRank) => YourRankCard(
              userRank: userRank,
              onTap: () => context.push('/leaderboard/my-rank'),
            ),
            loading: () => _buildRankCardShimmer(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          
          // Leaderboard List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: LeaderboardType.values.map((type) {
                return _buildLeaderboardList(type);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardType type) {
    final controller = _pagingControllers[type]!;
    final userRankAsync = ref.watch(userRankProvider);
    final currentUserId = userRankAsync.value?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        controller.refresh();
      },
      child: CustomScrollView(
        slivers: [
          PagedSliverList<int, LeaderboardRow>(
            pagingController: controller,
            builderDelegate: PagedChildBuilderDelegate<LeaderboardRow>(
              itemBuilder: (context, row, index) {
                return LeaderboardRowWidget(
                  row: row,
                  isCurrentUser: row.userId == currentUserId,
                  onTap: () {
                    // Navigate to user profile
                    context.push('/profile/${row.userId}');
                  },
                );
              },
              firstPageErrorIndicatorBuilder: (context) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load leaderboard',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => controller.refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              newPageProgressIndicatorBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              firstPageProgressIndicatorBuilder: (context) => SliverFillRemaining(
                child: _buildListShimmer(),
              ),
              noItemsFoundIndicatorBuilder: (context) => SliverFillRemaining(
                child: const Center(
                  child: Text('No data available'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
