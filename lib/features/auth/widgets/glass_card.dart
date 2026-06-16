import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/auth_animations.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool hasFocus;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.hasFocus = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _breathe;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: AuthAnimations.cardFloat)
      ..repeat(reverse: true);
    _breathe = AnimationController(vsync: this, duration: AuthAnimations.cardBreathe)
      ..repeat(reverse: true);
    _shine = AnimationController(vsync: this, duration: AuthAnimations.cardShine)
      ..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _breathe.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: Listenable.merge([_float, _breathe, _shine]),
      builder: (context, child) {
        final floatY = reduceMotion ? 0.0
            : math.sin(_float.value * math.pi) * 4.0;
        final breathePurple = 0.18 + _breathe.value * 0.16;
        final breatheCyan = 0.08 + _breathe.value * 0.10;
        final shineX = _shine.value * 2 - 0.5; // -0.5 → 1.5

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Stack(
            children: [
              // Glass container
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F1729).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: widget.hasFocus
                          ? Border.all(
                              color: AppColors.brandPurple,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: [
                        // Breathe purple
                        BoxShadow(
                          color: AppColors.brandPurple.withValues(alpha: breathePurple),
                          blurRadius: 40,
                          spreadRadius: -8,
                          offset: const Offset(0, 12),
                        ),
                        // Breathe cyan
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: breatheCyan),
                          blurRadius: 60,
                          spreadRadius: -12,
                          offset: const Offset(0, 20),
                        ),
                        // Base shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
              // Shine sweep
              if (!reduceMotion)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: IgnorePointer(
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment(shineX - 0.5, -0.5),
                          end: Alignment(shineX + 0.5, 0.5),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
                            Colors.transparent,
                          ],
                        ).createShader(bounds),
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: Padding(padding: widget.padding, child: widget.child),
    );
  }
}
