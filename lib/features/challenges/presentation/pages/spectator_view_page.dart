import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';
import '../widgets/elo_badge.dart';

/// Read-only spectator view for an active match.
/// Route: /challenges/1v1/[matchId]/watch
class SpectatorViewPage extends ConsumerWidget {
  const SpectatorViewPage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));

    // Track spectator join
    ref.listen(matchDetailProvider(matchId), (prev, next) {
      if (prev == null && next.hasValue) {
        AnalyticsService.instance.spectatorJoined(matchId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spectating', style: AppTextStyles.headlineMedium),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded, size: 14, color: AppColors.error),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: matchAsync.when(
        data: (match) => _SpectatorContent(match: match),
        loading: () => const Center(child: HireXLoader()),
        error: (e, _) => Center(
          child: Text(e.toString(), style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _SpectatorContent extends StatelessWidget {
  const _SpectatorContent({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Match info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        match.domain.label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${match.durationMinutes} min',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _PlayerCard(
                        name: match.challengerName ?? 'Challenger',
                        avatarUrl: match.challengerAvatarUrl,
                        elo: match.challengerEloBefore,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface.withValues(alpha: 0.4),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PlayerCard(
                        name: match.opponentName ?? 'Opponent',
                        avatarUrl: match.opponentAvatarUrl,
                        elo: match.opponentEloBefore,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timer
          if (match.status == MatchStatus.active) ...[
            _LiveTimer(match: match),
            const SizedBox(height: 20),
          ],

          // Status info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Spectator Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can see the match status but not the submission content. '
                  'Submission content is private to each player.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.name, this.avatarUrl, required this.elo});
  final String name;
  final String? avatarUrl;
  final int elo;

  @override
  Widget build(BuildContext context) {
    final tier = EloTierX.fromElo(elo);
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        EloBadge(tier: tier, elo: elo, compact: true),
      ],
    );
  }
}

class _LiveTimer extends StatelessWidget {
  const _LiveTimer({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    final remaining = match.remainingTime;
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    final isCritical = remaining.inSeconds <= 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? AppColors.error : AppColors.divider,
        ),
      ),
      child: Center(
        child: Text(
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: isCritical ? AppColors.error : Colors.white,
            fontFamily: 'Inter',
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
