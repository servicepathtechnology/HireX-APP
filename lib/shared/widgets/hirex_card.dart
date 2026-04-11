import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Rounded card with surface color and optional border.
class HireXCard extends StatelessWidget {
  const HireXCard({
    super.key,
    required this.child,
    this.padding,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: child,
      ),
    );
  }
}
