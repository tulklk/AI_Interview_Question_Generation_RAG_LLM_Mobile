import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium 3D-depth card with multi-layer shadow, top-edge highlight,
/// and optional colored accent stripe. Replaces the flat card everywhere.
class AppElevatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;
  final bool interactive;
  final Color? accentColor; // draws a 2.5px gradient stripe at the top

  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 16,
    this.color,
    this.interactive = true,
    this.accentColor,
  });

  @override
  State<AppElevatedCard> createState() => _AppElevatedCardState();
}

class _AppElevatedCardState extends State<AppElevatedCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius;
    final doPress = widget.interactive;

    // ── Shadow pack ─────────────────────────────────────────────────────────
    final List<BoxShadow> shadows = _pressed
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            // near contact shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            // mid depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            // ambient purple glow
            BoxShadow(
              color: AppColors.brandPurple
                  .withValues(alpha: isDark ? 0.14 : 0.08),
              blurRadius: 32,
              spreadRadius: -8,
              offset: const Offset(0, 12),
            ),
          ];

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: doPress ? (_) => _setPressed(true) : null,
      onTapUp: doPress ? (_) => _setPressed(false) : null,
      onTapCancel: doPress ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: doPress && _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          // Subtle top-left → bottom-right gradient for depth
          gradient: widget.color != null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1D2440), const Color(0xFF131825)]
                      : [Colors.white, const Color(0xFFF8F9FE)],
                ),
          color: widget.color,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.gray200.withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 0.5),
          child: Stack(
            children: [
              // ── Top-edge specular highlight ──────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.01),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                    ),
                  ),
                ),
              ),

              // ── Optional accent top stripe ───────────────────────────────
              if (widget.accentColor != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor!,
                          widget.accentColor!.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Content ──────────────────────────────────────────────────
              Padding(
                padding: widget.padding ?? const EdgeInsets.all(20),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
