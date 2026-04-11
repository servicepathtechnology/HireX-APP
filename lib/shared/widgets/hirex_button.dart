import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'hirex_loader.dart';

enum HireXButtonVariant { primary, secondary, ghost }

/// Reusable button with primary / secondary / ghost variants and loading state.
class HireXButton extends StatelessWidget {
  const HireXButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HireXButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final HireXButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const HireXLoader(size: 22)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: AppTextStyles.labelLarge),
            ],
          );

    switch (variant) {
      case HireXButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case HireXButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: child,
          ),
        );
      case HireXButtonVariant.ghost:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: child,
          ),
        );
    }
  }
}
