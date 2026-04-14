import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hirex_app/features/leaderboard/data/models/leaderboard_row.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/tier_badge.dart';
import 'package:intl/intl.dart';

class LeaderboardRowWidget extends StatelessWidget {
  final LeaderboardRow row;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const LeaderboardRowWidget({
    super.key,
    required this.row,
    this.isCurrentUser = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    // Determine background color
    Color? backgroundColor;
    if (isCurrentUser) {
      backgroundColor = Colors.blue[50];
    } else if (row.rank <= 3) {
      backgroundColor = const Color(0xFFFFF8E1); // Gold tint
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Rank with medal for top 3
            SizedBox(
              width: 50,
              child: Row(
                children: [
                  if (row.rank <= 3) ...[
                    Text(
                      _getMedalEmoji(row.rank),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '#${row.rank}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Tier badge
            TierBadge(tier: row.tier, size: 24),
            
            const SizedBox(width: 12),
            
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: row.avatar != null
                  ? CachedNetworkImageProvider(row.avatar!)
                  : null,
              child: row.avatar == null
                  ? Text(
                      _getInitials(row.name),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Name and country
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (row.country != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getCountryFlag(row.country!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // ELO
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  numberFormat.format(row.elo),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getTierColor(row.tier),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.winRate.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _getCountryFlag(String countryCode) {
    // Convert country code to flag emoji
    // This is a simplified version - you might want to use a package for this
    final code = countryCode.toUpperCase();
    return String.fromCharCodes(
      code.runes.map((r) => r + 127397),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'elite':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }
}
