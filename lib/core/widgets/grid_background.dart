import 'package:flutter/material.dart';

/// Subtle square-grid page background (matches web HR / Candidate dashboards).
/// Place behind content in a [Stack]; use [IgnorePointer] so it never blocks taps.
class GridBackground extends StatelessWidget {
  final bool? isDark;
  final double step;
  final double strokeWidth;

  const GridBackground({
    super.key,
    this.isDark,
    this.step = 48,
    this.strokeWidth = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ??
        Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GridPainter(
            isDark: dark,
            step: step,
            strokeWidth: strokeWidth,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Convenience wrapper: grid behind [child] (for fullscreen Scaffold bodies).
class GridBackdrop extends StatelessWidget {
  final Widget child;
  const GridBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: GridBackground()),
        child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  final double step;
  final double strokeWidth;

  _GridPainter({
    required this.isDark,
    required this.step,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.045)
          : const Color(0xFF64748B).withValues(alpha: 0.10)
      ..strokeWidth = strokeWidth;

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.isDark != isDark ||
      old.step != step ||
      old.strokeWidth != strokeWidth;
}
