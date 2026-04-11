import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Branded horizontal divider with optional center label.
class HireXDivider extends StatelessWidget {
  const HireXDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(color: AppColors.divider, height: 1);
    }
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label!, style: AppTextStyles.labelSmall),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
