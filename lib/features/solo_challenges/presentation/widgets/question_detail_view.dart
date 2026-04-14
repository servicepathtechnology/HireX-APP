/// Part 2 — Question Detail View Widget
library;

import 'package:flutter/material.dart';

import '../../domain/entities/solo_challenge_entities.dart';

class QuestionDetailView extends StatelessWidget {
  final Question question;
  final String difficulty;
  final int estimatedTime;
  final int xpReward;
  final bool completed;

  const QuestionDetailView({
    super.key,
    required this.question,
    required this.difficulty,
    required this.estimatedTime,
    required this.xpReward,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            question.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Metadata
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.signal_cellular_alt,
                label: difficulty.toUpperCase(),
                color: _getDifficultyColor(difficulty),
              ),
              _MetaChip(
                icon: Icons.timer,
                label: '$estimatedTime min',
                color: Colors.blue,
              ),
              _MetaChip(
                icon: Icons.stars,
                label: '+$xpReward XP',
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Problem Statement
          _Section(
            title: 'Problem Statement',
            content: question.problemStatement,
          ),
          const SizedBox(height: 16),

          // Constraints
          _Section(
            title: 'Constraints',
            content: question.constraints,
          ),
          const SizedBox(height: 16),

          // Input Format
          _Section(
            title: 'Input Format',
            content: question.inputFormat,
          ),
          const SizedBox(height: 16),

          // Output Format
          _Section(
            title: 'Output Format',
            content: question.outputFormat,
          ),
          const SizedBox(height: 16),

          // Sample Test Cases
          _Section(
            title: 'Sample Test Case 1',
            content: 'Input:\n${question.sampleInput1}\n\nOutput:\n${question.sampleOutput1}',
          ),
          if (question.sampleInput2 != null && question.sampleOutput2 != null) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Sample Test Case 2',
              content: 'Input:\n${question.sampleInput2}\n\nOutput:\n${question.sampleOutput2}',
            ),
          ],
          const SizedBox(height: 16),

          // Tags
          if (question.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey[200],
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
