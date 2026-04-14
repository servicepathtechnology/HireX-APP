/// Part 2 — Solo Challenge Hub Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/solo_challenge_providers.dart';
import '../widgets/challenge_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/recent_completions_list.dart';

class SoloChallengeHubPage extends ConsumerWidget {
  const SoloChallengeHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubAsync = ref.watch(challengeHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/challenges/solo/preferences'),
          ),
        ],
      ),
      body: hubAsync.when(
        data: (hub) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(challengeHubProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                StreakCard(streak: hub.streak),
                const SizedBox(height: 24),

                // Daily challenge
                Text(
                  'Daily Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ChallengeCard(
                  type: 'daily',
                  title: hub.daily.questionTitle ?? 'No challenge today',
                  difficulty: hub.daily.difficulty,
                  xpReward: hub.daily.xpReward,
                  status: hub.daily.status,
                  completed: hub.daily.completed,
                  onTap: () => context.push('/challenges/solo/daily'),
                ),
                const SizedBox(height: 24),

                // Weekly challenge
                Text(
                  'Weekly Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ChallengeCard(
                  type: 'weekly',
                  title: hub.weekly.questionTitle ?? 'No challenge this week',
                  difficulty: hub.weekly.difficulty,
                  xpReward: hub.weekly.xpReward,
                  status: hub.weekly.status,
                  completed: hub.weekly.completed,
                  onTap: () => context.push('/challenges/solo/weekly'),
                ),
                const SizedBox(height: 24),

                // Monthly challenge
                Text(
                  'Monthly Challenge',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ChallengeCard(
                  type: 'monthly',
                  title: hub.monthly.questionTitle ?? 'No challenge this month',
                  difficulty: hub.monthly.difficulty,
                  xpReward: hub.monthly.xpReward,
                  status: hub.monthly.status,
                  completed: hub.monthly.completed,
                  onTap: () => context.push('/challenges/solo/monthly'),
                ),
                const SizedBox(height: 24),

                // Recent completions
                if (hub.recentCompletions.isNotEmpty) ...[
                  Text(
                    'Recent Completions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  RecentCompletionsList(completions: hub.recentCompletions),
                ],
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(challengeHubProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
