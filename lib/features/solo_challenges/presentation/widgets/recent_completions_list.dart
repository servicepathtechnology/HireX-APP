/// Part 2 — Recent Completions List Widget
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/solo_challenge_entities.dart';

class RecentCompletionsList extends StatelessWidget {
  final List<RecentCompletion> completions;

  const RecentCompletionsList({super.key, required this.completions});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: completions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final completion = completions[index];
          return ListTile(
            leading: _getTypeIcon(completion.challengeType),
            title: Text(
              _getTypeLabel(completion.challengeType),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              completion.submittedAt != null
                  ? _formatDate(completion.submittedAt!)
                  : 'Recently',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${completion.score}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(completion.score),
                  ),
                ),
                Text(
                  '+${completion.xpEarned} XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'daily':
        icon = Icons.today;
        color = Colors.blue;
        break;
      case 'weekly':
        icon = Icons.calendar_view_week;
        color = Colors.purple;
        break;
      case 'monthly':
        icon = Icons.calendar_month;
        color = Colors.orange;
        break;
      default:
        icon = Icons.code;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'daily':
        return 'Daily Challenge';
      case 'weekly':
        return 'Weekly Challenge';
      case 'monthly':
        return 'Monthly Challenge';
      default:
        return 'Challenge';
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
