import 'package:flutter/material.dart';

/// Shows deadline countdown with color coding.
class DeadlineChip extends StatelessWidget {
  const DeadlineChip({super.key, required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) {
      return _chip('Deadline passed', const Color(0xFF6B7280));
    }

    final hours = diff.inHours;
    final days = diff.inDays;

    String label;
    Color color;

    if (hours < 24) {
      label = '${hours}h left';
      color = const Color(0xFFE94560);
    } else if (days < 3) {
      label = '${days}d left';
      color = const Color(0xFFFF9800);
    } else {
      label = '${days}d left';
      color = const Color(0xFF4CAF50);
    }

    return _chip(label, color);
  }

  Widget _chip(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
