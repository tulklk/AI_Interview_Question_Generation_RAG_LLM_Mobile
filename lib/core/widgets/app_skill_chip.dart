import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSkillChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final bool selected;
  final VoidCallback? onTap;

  const AppSkillChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.brandPurple;
    final bgColor = backgroundColor ??
        (selected
            ? chipColor.withValues(alpha: 0.18)
            : (isDark
                ? chipColor.withValues(alpha: 0.12)
                : chipColor.withValues(alpha: 0.08)));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: chipColor.withValues(alpha: selected ? 0.5 : 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.chipText.copyWith(
            color: isDark ? const Color(0xFFB39DFF) : chipColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
