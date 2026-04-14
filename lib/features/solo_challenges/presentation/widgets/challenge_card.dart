/// Part 2 — Challenge Card Widget
library;

import 'package:flutter/material.dart';

class ChallengeCard extends StatelessWidget {
  final String type;
  final String title;
  final String difficulty;
  final int xpReward;
  final String status;
  final bool completed;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.type,
    required this.title,
    required this.difficulty,
    required this.xpReward,
    required this.status,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _DifficultyChip(difficulty: difficulty),
                            const SizedBox(width: 8),
                            Text(
                              '+$xpReward XP',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (completed)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon() {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;

  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
