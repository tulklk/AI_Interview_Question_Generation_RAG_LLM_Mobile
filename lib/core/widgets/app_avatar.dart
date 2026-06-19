import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showRing;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.showRing = false,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _colorFromName(String name) {
    if (name.isEmpty) return AppColors.brandPurple;
    final colors = [
      AppColors.brandPurple,
      AppColors.deepBlue,
      AppColors.teal,
      AppColors.magenta,
      AppColors.amber,
    ];
    return colors[name.codeUnits.first % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFromName(name);
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTextStyles.labelBold.copyWith(
            color: color,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );

    if (showRing) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: avatar,
      );
    }
    return avatar;
  }
}
