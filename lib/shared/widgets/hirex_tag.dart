import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Skill tag chip — colored, with optional remove button.
class HireXTag extends StatelessWidget {
  const HireXTag({
    super.key,
    required this.label,
    this.onRemove,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback? onRemove;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: isSelected ? AppColors.primary : AppColors.onSurface),
            ),
          ],
        ],
      ),
    );
  }
}
