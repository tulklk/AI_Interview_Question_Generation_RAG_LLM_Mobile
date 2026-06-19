import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight animated gradient background with soft floating blobs.
/// Suitable for feature screens. Isolated in RepaintBoundary so blob
/// animations don't trigger repaints outside this widget.
class AnimatedGradientBg extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color primaryBlob;
  final Color secondaryBlob;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  const AnimatedGradientBg({
    super.key,
    required this.child,
    required this.gradientColors,
    required this.primaryBlob,
    required this.secondaryBlob,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
  });

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient (static – no rebuild)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: widget.gradientBegin,
              end: widget.gradientEnd,
              stops: const [0.0, 0.6],
            ),
          ),
        ),

        // Animated blobs (isolated repaint boundary)
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value * 2 * pi;
              return Stack(
                children: [
                  Positioned(
                    top: -70 + 28 * sin(t),
                    left: -50 + 18 * cos(t * 0.7),
                    child: _Blob(size: 280, color: widget.primaryBlob),
                  ),
                  Positioned(
                    top: 80 + 20 * cos(t * 0.85),
                    right: -60 + 14 * sin(t * 1.1),
                    child: _Blob(size: 200, color: widget.secondaryBlob),
                  ),
                ],
              );
            },
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}
