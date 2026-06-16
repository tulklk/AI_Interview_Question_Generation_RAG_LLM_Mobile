import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// Particle screen-percentage positions (x%, y%)
const _particlePositions = [
  (0.08, 0.12), (0.85, 0.08), (0.20, 0.75), (0.70, 0.85),
  (0.45, 0.30), (0.92, 0.55), (0.12, 0.45), (0.60, 0.15),
];

class AuthBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;

  const AuthBackground({super.key, required this.isDark, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with TickerProviderStateMixin {
  late final AnimationController _aurora;
  late final AnimationController _orbs;
  late final List<AnimationController> _particles;

  @override
  void initState() {
    super.initState();
    _aurora = AnimationController(vsync: this, duration: const Duration(seconds: 32))
      ..repeat();
    _orbs = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
    _particles = List.generate(8, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 12000 + i * 875),
    )..repeat(reverse: true));
  }

  @override
  void dispose() {
    _aurora.dispose();
    _orbs.dispose();
    for (final c in _particles) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _BaseGradientLayer(isDark: isDark),
          if (!reduceMotion)
            RepaintBoundary(
              child: _AuroraLayer(controller: _aurora, isDark: isDark),
            ),
          _GridLayer(isDark: isDark),
          if (!reduceMotion) ...[
            RepaintBoundary(
              child: _ParticlesLayer(controllers: _particles, isDark: isDark),
            ),
            _OrbsLayer(controller: _orbs, isDark: isDark),
          ],
          widget.child,
        ],
      ),
    );
  }
}

// ─── L1: Base gradient ────────────────────────────────────────────────────────

class _BaseGradientLayer extends StatelessWidget {
  final bool isDark;
  const _BaseGradientLayer({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF020617), Color(0xFF050816),
                Color(0xFF070B1A), Color(0xFF0B1026),
              ]
            : const [
                Color(0xFFF8FAFC), Color(0xFFF5F7FF),
                Color(0xFFEEF6FF), Color(0xFFFAF5FF),
              ],
      ),
    ),
  );
}

// ─── L2: Aurora blobs ─────────────────────────────────────────────────────────

class _AuroraLayer extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _AuroraLayer({required this.controller, required this.isDark});

  static const _blobs = [
    _BlobConfig(
      color: AppColors.brandPurple,
      size: 280,
      baseX: -0.15, baseY: -0.10,
      ampX: 0.06, ampY: 0.05, phase: 0.0,
    ),
    _BlobConfig(
      color: AppColors.accentCyan,
      size: 240,
      baseX: 0.80, baseY: 0.70,
      ampX: 0.05, ampY: 0.07, phase: math.pi * 0.7,
    ),
    _BlobConfig(
      color: AppColors.accentViolet,
      size: 200,
      baseX: 0.55, baseY: -0.05,
      ampX: 0.07, ampY: 0.04, phase: math.pi * 1.3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * math.pi * 2;
        return Stack(
          children: _blobs.map((blob) {
            final dx = (blob.baseX + math.sin(t + blob.phase) * blob.ampX) * size.width;
            final dy = (blob.baseY + math.cos(t * 0.6 + blob.phase) * blob.ampY) * size.height;
            final scale = 1.0 + math.sin(t * 0.4 + blob.phase) * 0.03;
            return Positioned(
              left: dx - (blob.size * scale) / 2,
              top: dy - (blob.size * scale) / 2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Opacity(
                  opacity: isDark ? 0.35 : 0.45,
                  child: Container(
                    width: blob.size * scale,
                    height: blob.size * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [blob.color, blob.color.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BlobConfig {
  final Color color;
  final double size;
  final double baseX, baseY;
  final double ampX, ampY;
  final double phase;
  const _BlobConfig({
    required this.color, required this.size,
    required this.baseX, required this.baseY,
    required this.ampX, required this.ampY,
    required this.phase,
  });
}

// ─── L3: Grid ─────────────────────────────────────────────────────────────────

class _GridLayer extends StatelessWidget {
  final bool isDark;
  const _GridLayer({required this.isDark});

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) => const RadialGradient(
      center: Alignment.center,
      radius: 0.75,
      colors: [Colors.white, Colors.transparent],
    ).createShader(bounds),
    blendMode: BlendMode.dstIn,
    child: CustomPaint(
      painter: _GridPainter(isDark: isDark),
    ),
  );
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFF6C47FF).withValues(alpha: 0.07)
      ..strokeWidth = 0.6;
    const step = 48.0;
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}

// ─── L4: Particles ───────────────────────────────────────────────────────────

class _ParticlesLayer extends StatelessWidget {
  final List<AnimationController> controllers;
  final bool isDark;
  const _ParticlesLayer({required this.controllers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge(controllers),
      builder: (_, __) => Stack(
        children: List.generate(_particlePositions.length, (i) {
          final (px, py) = _particlePositions[i];
          final t = controllers[i].value;
          final opacity = isDark
              ? 0.15 + t * 0.75  // twinkle 0.15↔0.90
              : 0.25 + t * 0.30; // subtle drift glow
          final dx = isDark ? 0.0 : math.sin(t * math.pi * 2) * 6;
          final dy = isDark ? 0.0 : math.cos(t * math.pi * 2 + i) * 6;
          return Positioned(
            left: px * size.width + dx,
            top: py * size.height + dy,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 3, height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i.isEven ? AppColors.brandPurple : AppColors.accentCyan,
                  boxShadow: [
                    BoxShadow(
                      color: (i.isEven ? AppColors.brandPurple : AppColors.accentCyan)
                          .withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── L5: Orbs ────────────────────────────────────────────────────────────────

class _OrbsLayer extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const _OrbsLayer({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final pulse = 0.85 + controller.value * 0.15;
        final baseOpacity = isDark ? 0.08 : 0.05;
        return Stack(children: [
          // Top-left orb 360px
          Positioned(
            left: -size.width * 0.25,
            top: -size.height * 0.10,
            child: _Orb(size: 360 * pulse, color: AppColors.brandPurple,
              opacity: baseOpacity),
          ),
          // Bottom-right orb 300px
          Positioned(
            right: -size.width * 0.20,
            bottom: -size.height * 0.08,
            child: _Orb(size: 300 * (2.0 - pulse), color: AppColors.accentCyan,
              opacity: baseOpacity * 0.8),
          ),
          // Center orb 220px
          Positioned(
            right: -size.width * 0.10,
            top: size.height * 0.35,
            child: _Orb(size: 220 * pulse, color: AppColors.accentViolet,
              opacity: baseOpacity * 0.6),
          ),
        ]);
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ),
    ),
  );
}
