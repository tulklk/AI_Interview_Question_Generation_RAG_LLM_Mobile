import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A frosted-glass card. Wraps [child] in a blurred backdrop container.
///
/// Use [padding] / [margin] for spacing, [borderRadius] to override the
/// default 20 px corner radius, and [gradient] to tint the surface with a
/// colour overlay on top of the glass.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.isDark = false,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20.0,
    this.blurSigma = 18.0,
    this.gradient,
    this.border,
    this.boxShadow,
    this.constraints,
    this.onTap,
  });

  final Widget   child;
  final bool     isDark;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double   borderRadius;
  final double   blurSigma;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final effectiveBorder = border ??
        Border.all(color: AppColors.glassBorder(isDark), width: 1);
    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          constraints: constraints,
          decoration: BoxDecoration(
            color:        AppColors.glassCard(isDark),
            gradient:     gradient,
            borderRadius: radius,
            border:       effectiveBorder,
            boxShadow:    effectiveShadow,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// A slim glass banner / stat chip.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.isDark,
    this.icon,
    this.iconColor,
    this.accent,
    this.onTap,
  });

  final String   label;
  final bool     isDark;
  final IconData? icon;
  final Color?   iconColor;
  final Color?   accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF1E2640).withValues(alpha: 0.80)
        : Colors.white.withValues(alpha: 0.72);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:        bg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size:  14,
                    color: iconColor ?? accent ?? AppColors.brandPurple,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize:   12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
