import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double height;
  final double? width;
  final Color? textColor;
  final Color? borderColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.height = 48,
    this.width,
    this.textColor,
    this.borderColor,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.darkCard : AppColors.offWhite)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.borderColor ?? AppColors.cardBorder,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.label.copyWith(
                  color: widget.textColor ??
                      (isDark ? AppColors.white : AppColors.nearBlack),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
