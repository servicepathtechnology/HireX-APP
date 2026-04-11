import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/domain_badge.dart';
import '../../../../shared/widgets/deadline_chip.dart';
import '../../../../shared/widgets/hirex_card.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';

class TaskFeedPage extends ConsumerStatefulWidget {
  const TaskFeedPage({super.key});

  @override
  ConsumerState<TaskFeedPage> createState() => _TaskFeedPageState();
}

class _TaskFeedPageState extends ConsumerState<TaskFeedPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(taskFeedProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(taskFiltersProvider.notifier).setSearch(value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(taskFiltersProvider);
    final feedAsync = ref.watch(taskFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/candidate/bookmarks'),
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(Icons.bookmark_outline, color: AppColors.onBackground),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // For You tab chip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/candidate/recommended'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('For You', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('All Tasks', style: AppTextStyles.labelLarge),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search tasks, domains, skills...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(taskFiltersProvider.notifier).setSearch(null);
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Domain filter chips
            _DomainFilterRow(selectedDomain: filters.domain),
            const SizedBox(height: 4),

            // Difficulty + Sort row
            _DifficultyAndSortRow(
              selectedDifficulty: filters.difficulty,
              selectedSort: filters.sort,
            ),
            const SizedBox(height: 8),

            // Task list
            Expanded(
              child: feedAsync.when(
                loading: () => _ShimmerList(),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load tasks', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(taskFeedProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (paginated) {
                  if (paginated.items.isEmpty) {
                    return _EmptyState(hasFilters: filters.domain != null ||
                        filters.difficulty != null ||
                        (filters.search?.isNotEmpty ?? false));
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(taskFeedProvider.notifier).refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: paginated.items.length + (paginated.hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == paginated.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return TaskCard(task: paginated.items[i]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Domain filter row ─────────────────────────────────────────────────────────

class _DomainFilterRow extends ConsumerWidget {
  const _DomainFilterRow({required this.selectedDomain});
  final String? selectedDomain;

  static const _domains = [
    null, 'engineering', 'design', 'product', 'business', 'marketing', 'writing'
  ];
  static const _labels = [
    'All', 'Engineering', 'Design', 'Product', 'Business', 'Marketing', 'Writing'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final domain = _domains[i];
          final isSelected = selectedDomain == domain;
          final color = domain != null
              ? DomainBadge.colorFor(domain)
              : AppColors.primary;
          return GestureDetector(
            onTap: () => ref.read(taskFiltersProvider.notifier).setDomain(domain),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : AppColors.divider,
                ),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Difficulty + Sort row ─────────────────────────────────────────────────────

class _DifficultyAndSortRow extends ConsumerWidget {
  const _DifficultyAndSortRow({
    required this.selectedDifficulty,
    required this.selectedSort,
  });
  final String? selectedDifficulty;
  final String selectedSort;

  static const _difficulties = [null, 'beginner', 'intermediate', 'advanced', 'expert'];
  static const _diffLabels = ['All', 'Beginner', 'Intermediate', 'Advanced', 'Expert'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _difficulties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final d = _difficulties[i];
                  final isSelected = selectedDifficulty == d;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(taskFiltersProvider.notifier).setDifficulty(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceVariant
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _diffLabels[i],
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.onSurface,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedSort,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.onBackground),
            items: const [
              DropdownMenuItem(value: 'latest', child: Text('Latest')),
              DropdownMenuItem(value: 'deadline_soon', child: Text('Deadline Soon')),
              DropdownMenuItem(value: 'most_popular', child: Text('Most Popular')),
              DropdownMenuItem(value: 'best_match', child: Text('Best Match')),
            ],
            onChanged: (v) {
              if (v != null) ref.read(taskFiltersProvider.notifier).setSort(v);
            },
          ),
        ],
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});
  final TaskEntity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HireXCard(
        onTap: () => context.push('/candidate/tasks/${task.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTextStyles.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    task.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: task.isBookmarked ? AppColors.primary : AppColors.onSurface,
                    size: 22,
                  ),
                  onPressed: () => ref.read(bookmarksProvider.notifier).toggle(task.id),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(task.displayCompany, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 10),

            // Badges
            Row(
              children: [
                DomainBadge(domain: task.domain),
                const SizedBox(width: 6),
                DifficultyBadge(difficulty: task.difficulty),
              ],
            ),
            const SizedBox(height: 10),

            // Skills
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...task.skillsTested.take(3).map((s) => _SkillChip(s)),
                if (task.skillsTested.length > 3)
                  _SkillChip('+${task.skillsTested.length - 3} more'),
              ],
            ),
            const SizedBox(height: 10),

            // Prize banner
            if (task.prizeOrOpportunity != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.prizeOrOpportunity!,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Footer stats
            Row(
              children: [
                DeadlineChip(deadline: task.deadline),
                const Spacer(),
                const Icon(Icons.people_outline, size: 13, color: AppColors.onSurface),
                const SizedBox(width: 3),
                Text('${task.submissionCount}', style: AppTextStyles.labelSmall),
                if (task.estimatedHours != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time, size: 13, color: AppColors.onSurface),
                  const SizedBox(width: 3),
                  Text('~${task.estimatedHours}h', style: AppTextStyles.labelSmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: AppTextStyles.labelSmall),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFilters ? Icons.search_off : Icons.task_alt,
                size: 64,
                color: AppColors.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters
                    ? 'No tasks found. Try changing your filters.'
                    : 'New tasks are being added daily. Check back soon!',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.shimmer,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
}
