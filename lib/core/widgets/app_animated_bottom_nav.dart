import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Floating glass bottom nav bar with animated active pill + glow indicator.
class AppAnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const AppAnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827).withValues(alpha: 0.93)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? AppColors.brandPurple.withValues(alpha: 0.22)
                    : AppColors.brandPurple.withValues(alpha: 0.10),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple
                      .withValues(alpha: isDark ? 0.20 : 0.14),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Icon container with pill + glow ──────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 48 : 30,
                          height: 30,
                          decoration: isActive
                              ? BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.brandPurple,
                                      AppColors.deepBlue,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandPurple
                                          .withValues(alpha: 0.50),
                                      blurRadius: 12,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                )
                              : null,
                          child: Center(
                            child: Icon(
                              isActive ? items[i].activeIcon : items[i].icon,
                              size: 18,
                              color: isActive
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.white.withValues(alpha: 0.40)
                                      : AppColors.gray400),
                            ),
                          ),
                        ),

                        const SizedBox(height: 3),

                        // ── Label ─────────────────────────────────────────
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: AppTextStyles.caption.copyWith(
                            color: isActive
                                ? AppColors.brandPurple
                                : (isDark
                                    ? AppColors.white.withValues(alpha: 0.38)
                                    : AppColors.gray400),
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 10,
                          ),
                          child: Text(items[i].label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ).animate().slideY(
          begin: 1.2,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
