import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_gradient_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    this.icon = PhosphorIconsBold.magnifyingGlass,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? AppColors.brandPurple;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient icon container ─────────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: isDark ? 0.20 : 0.12),
                    color.withValues(alpha: isDark ? 0.06 : 0.03),
                  ],
                  stops: const [0.35, 1.0],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 38,
                color: color.withValues(alpha: 0.55),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 22),

            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 120.ms),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.48)
                    : AppColors.gray500,
                fontSize: 14,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 160.ms),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 170,
                child: AppGradientButton(
                  label: actionLabel!,
                  onTap: onAction,
                  height: 46,
                ),
              ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
