import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppElevatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;
  final bool interactive;

  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 12,
    this.color,
    this.interactive = true,
  });

  @override
  State<AppElevatedCard> createState() => _AppElevatedCardState();
}

class _AppElevatedCardState extends State<AppElevatedCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.color ??
        (isDark ? AppColors.darkCard : AppColors.white);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.interactive ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: widget.interactive && _pressed
            ? (Matrix4.identity()..scale(0.985))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 32,
                    spreadRadius: -8,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.brandPurple.withOpacity(isDark ? 0.12 : 0.08),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(20),
          child: widget.child,
        ),
      ),
    );
  }
}
