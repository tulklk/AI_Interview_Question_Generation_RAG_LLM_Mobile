import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/auth_animations.dart';

class ShimmerButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final double height;

  const ShimmerButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onTap,
    this.trailingIcon,
    this.height = 52,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _pressed = true);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;

    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      onTapDown: enabled ? _onTapDown : null,
      onTapUp: enabled ? _onTapUp : null,
      onTapCancel: enabled ? _onTapCancel : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) {
            final shimX = _shimmer.value * 2.5 - 0.75;
            return Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.brandPurple, AppColors.deepBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: _pressed ? 0.20 : 0.40),
                    blurRadius: _pressed ? 8 : 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Shimmer layer
                    Positioned.fill(
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment(shimX - 0.4, -0.5),
                          end: Alignment(shimX + 0.4, 0.5),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ).createShader(bounds),
                        child: Container(color: Colors.white),
                      ),
                    ),
                    // Label
                    Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.label,
                                  style: AppTextStyles.buttonText.copyWith(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2)),
                                if (widget.trailingIcon != null) ...[
                                  const SizedBox(width: 6),
                                  AnimatedSlide(
                                    offset: _pressed
                                        ? const Offset(0.15, 0)
                                        : Offset.zero,
                                    duration: AuthAnimations.shimmerSweep,
                                    child: Icon(widget.trailingIcon,
                                      size: 16, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
