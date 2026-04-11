import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Circular progress indicator in brand color.
class HireXLoader extends StatelessWidget {
  const HireXLoader({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}
