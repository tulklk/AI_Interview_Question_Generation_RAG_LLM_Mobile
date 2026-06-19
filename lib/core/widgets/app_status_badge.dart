import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeType { success, warning, danger, info, teal, purple }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final Widget? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.info,
    this.icon,
  });

  Color get _color {
    switch (type) {
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.warning:
        return AppColors.amber;
      case BadgeType.danger:
        return AppColors.error;
      case BadgeType.teal:
        return AppColors.teal;
      case BadgeType.purple:
        return AppColors.brandPurple;
      case BadgeType.info:
        return AppColors.deepBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AppDifficultyBadge extends StatelessWidget {
  final String level;

  const AppDifficultyBadge({super.key, required this.level});

  BadgeType get _type {
    switch (level.toLowerCase()) {
      case 'easy':
        return BadgeType.success;
      case 'medium':
        return BadgeType.warning;
      case 'hard':
        return BadgeType.danger;
      default:
        return BadgeType.info;
    }
  }

  @override
  Widget build(BuildContext context) => AppStatusBadge(label: level, type: _type);
}
