import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _radarCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    )..forward();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      final seen = await StorageService.hasSeenOnboarding();
      if (!mounted) return;
      context.go(seen ? '/login' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _glowCtrl.dispose();
    _radarCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0520),
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0C0520),
                  Color(0xFF0A1348),
                  Color(0xFF050E1E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Particle field ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Floating orbs ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) {
              final t = _orbCtrl.value * 2 * pi;
              return Stack(
                children: [
                  Positioned(
                    top: -80 + 45 * sin(t),
                    left: -80 + 30 * cos(t * 0.7),
                    child: _GlowOrb(
                      size: 340,
                      color: AppColors.brandPurple.withValues(alpha: 0.22),
                    ),
                  ),
                  Positioned(
                    bottom: -100 + 40 * cos(t * 0.8),
                    right: -100 + 25 * sin(t),
                    child: _GlowOrb(
                      size: 400,
                      color: AppColors.deepBlue.withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.38 + 20 * sin(t * 1.3),
                    right: -50 + 18 * cos(t * 0.9),
                    child: _GlowOrb(
                      size: 230,
                      color: AppColors.teal.withValues(alpha: 0.13),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.12 + 12 * sin(t * 1.1),
                    left: size.width * 0.55 + 14 * cos(t * 0.8),
                    child: _GlowOrb(
                      size: 150,
                      color: AppColors.accentCyan.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Mesh grid ────────────────────────────────────────────────────
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // ── Center content ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + rings
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _RadarRing(
                        controller: _radarCtrl,
                        phase: 0.0,
                        baseRadius: 72,
                        color: AppColors.brandPurple,
                      ),
                      _RadarRing(
                        controller: _radarCtrl,
                        phase: 0.33,
                        baseRadius: 72,
                        color: AppColors.deepBlue,
                      ),
                      _RadarRing(
                        controller: _radarCtrl,
                        phase: 0.66,
                        baseRadius: 72,
                        color: AppColors.accentCyan,
                      ),
                      _GlassLogoBox(
                        glowCtrl: _glowCtrl,
                        scanCtrl: _scanCtrl,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 40),

                // App name
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFCFB3FF),
                      Color(0xFF7C5CFF),
                      Color(0xFF60A5FA),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    AppConstants.appName,
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 700.ms)
                    .slideY(
                      begin: 0.4,
                      end: 0,
                      delay: 450.ms,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 10),

                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 700.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 700.ms,
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 64),

                // Progress arc
                _ProgressArc(controller: _progressCtrl)
                    .animate()
                    .fadeIn(delay: 950.ms, duration: 500.ms),
              ],
            ),
          ),

          // ── Bottom powered-by label ──────────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: Text(
              'POWERED BY AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.20),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
              ),
            ).animate().fadeIn(delay: 1300.ms, duration: 700.ms),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar ring: expands from baseRadius outward and fades
// ─────────────────────────────────────────────────────────────────────────────
class _RadarRing extends StatelessWidget {
  final AnimationController controller;
  final double phase;
  final double baseRadius;
  final Color color;

  const _RadarRing({
    required this.controller,
    required this.phase,
    required this.baseRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = ((controller.value + phase) % 1.0);
        final radius = baseRadius + t * 88;
        final opacity = (1.0 - t) * 0.50;
        return SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glassmorphism logo container with pulsing border + scan line
// ─────────────────────────────────────────────────────────────────────────────
class _GlassLogoBox extends StatelessWidget {
  final AnimationController glowCtrl;
  final AnimationController scanCtrl;

  const _GlassLogoBox({
    required this.glowCtrl,
    required this.scanCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glowCtrl, scanCtrl]),
      builder: (_, __) {
        final glow = 0.45 + 0.30 * glowCtrl.value;
        final scanY = scanCtrl.value;

        return Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandPurple.withValues(alpha: 0.30),
                AppColors.deepBlue.withValues(alpha: 0.20),
              ],
            ),
            border: Border.all(
              color: AppColors.brandPurple
                  .withValues(alpha: 0.30 + 0.25 * glowCtrl.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: glow * 0.55),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.deepBlue.withValues(alpha: glow * 0.25),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const AppLogoImage(size: 76),
                // Horizontal scan line sweeping top→bottom
                Positioned(
                  top: scanY * 124 - 1,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.accentCyan.withValues(alpha: 0.80),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple glow orb
// ─────────────────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.75,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular progress arc filling over the animation duration
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressArc extends StatelessWidget {
  final AnimationController controller;
  const _ProgressArc({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: const Size(44, 44),
        painter: _ArcPainter(progress: controller.value),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3.0;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFF22D3EE)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dot at the arc tip
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      final dotOffset = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(
        dotOffset,
        3.0,
        Paint()
          ..color = const Color(0xFF22D3EE)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating particles drifting upward
// ─────────────────────────────────────────────────────────────────────────────
class _ParticleData {
  final double x;
  final double yOffset;
  final double speed;
  final double radius;
  final double opacity;
  const _ParticleData({
    required this.x,
    required this.yOffset,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final double t;
  static final List<_ParticleData> _pool = _buildPool();

  _ParticlePainter(this.t);

  static List<_ParticleData> _buildPool() {
    final rng = Random(7);
    return List.generate(30, (_) => _ParticleData(
      x: rng.nextDouble(),
      yOffset: rng.nextDouble(),
      speed: 0.035 + rng.nextDouble() * 0.07,
      radius: 0.9 + rng.nextDouble() * 1.8,
      opacity: 0.12 + rng.nextDouble() * 0.30,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pool) {
      final progress = (p.yOffset + t * p.speed) % 1.0;
      final y = size.height * (1.0 - progress);
      final x = size.width * p.x +
          14 * sin((t * 2 + p.yOffset) * 2 * pi);
      final alpha = p.opacity * sin(progress * pi).clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle dot-grid background pattern
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner dots at intersections
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
