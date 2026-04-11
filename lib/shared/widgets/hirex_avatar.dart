import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Circular avatar with initials fallback when no image URL is provided.
class HireXAvatar extends StatelessWidget {
  const HireXAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 28,
  });

  final String? imageUrl;
  final String name;
  final double radius;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.2),
      child: Text(
        _initials,
        style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}
