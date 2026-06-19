import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack,
          ),
        ),
        trailing ??
            (actionLabel != null
                ? GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple
                            .withValues(alpha: isDark ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brandPurple
                              .withValues(alpha: isDark ? 0.22 : 0.14),
                        ),
                      ),
                      child: Text(
                        actionLabel!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
      ],
    );
  }
}
