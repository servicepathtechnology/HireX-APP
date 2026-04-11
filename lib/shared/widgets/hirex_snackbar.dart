import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum SnackbarType { success, error, info }

/// Shows a branded snackbar. Call from anywhere with a BuildContext.
class HireXSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    bool isError = false,
  }) {
    final effectiveType = isError ? SnackbarType.error : type;
    final color = switch (effectiveType) {
      SnackbarType.success => AppColors.success,
      SnackbarType.error => AppColors.error,
      SnackbarType.info => AppColors.surfaceVariant,
    };

    final icon = switch (effectiveType) {
      SnackbarType.success => Icons.check_circle_outline,
      SnackbarType.error => Icons.error_outline,
      SnackbarType.info => Icons.info_outline,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
