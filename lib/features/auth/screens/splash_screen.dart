import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      final seen = await StorageService.hasSeenOnboarding();
      if (!mounted) return;
      context.go(seen ? '/login' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          ),
          // Animated orbs
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) {
              return Stack(
                children: [
                  Positioned(
                    top: -60 + 30 * sin(_orbCtrl.value * 2 * pi),
                    left: -60 + 20 * cos(_orbCtrl.value * 2 * pi),
                    child: _GlowOrb(
                      size: 280,
                      color: AppColors.brandPurple.withValues(alpha: 0.35),
                    ),
                  ),
                  Positioned(
                    bottom: -80 + 25 * cos(_orbCtrl.value * 2 * pi),
                    right: -80 + 20 * sin(_orbCtrl.value * 2 * pi),
                    child: _GlowOrb(
                      size: 320,
                      color: AppColors.deepBlue.withValues(alpha: 0.28),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    right: -40,
                    child: _GlowOrb(
                      size: 200,
                      color: AppColors.teal.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              );
            },
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _LogoWidget(glowCtrl: _glowCtrl)
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 32),
                // App name
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'HireGen AI',
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Hire smarter with AI',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 80),
                // Loading dots
                _LoadingDots()
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.6, spreadRadius: 0)],
        color: color.withValues(alpha: 0.3),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final AnimationController glowCtrl;
  const _LogoWidget({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, __) {
        final glow = 0.4 + 0.3 * glowCtrl.value;
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: glow),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: _AISparkleIcon(),
          ),
        );
      },
    );
  }
}

class _AISparkleIcon extends StatelessWidget {
  const _AISparkleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(52, 52),
      painter: _SparklePainter(),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center diamond
    final path = Path()
      ..moveTo(cx, cy - 20)
      ..lineTo(cx + 6, cy)
      ..lineTo(cx, cy + 20)
      ..lineTo(cx - 6, cy)
      ..close();
    canvas.drawPath(path, paint);

    // Horizontal beam
    final beam = Path()
      ..moveTo(cx - 24, cy)
      ..lineTo(cx - 8, cy - 3)
      ..lineTo(cx - 8, cy + 3)
      ..close();
    canvas.drawPath(beam, paint);

    final beam2 = Path()
      ..moveTo(cx + 24, cy)
      ..lineTo(cx + 8, cy - 3)
      ..lineTo(cx + 8, cy + 3)
      ..close();
    canvas.drawPath(beam2, paint);

    // Small sparkles
    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx - 16, cy - 16), 3, paint);
    canvas.drawCircle(Offset(cx + 16, cy - 16), 2.5, paint);
    canvas.drawCircle(Offset(cx + 16, cy + 16), 3, paint);
    canvas.drawCircle(Offset(cx - 16, cy + 16), 2, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + i * 100),
      );
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, __) => Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.35 + 0.5 * _ctrls[i].value),
            ),
          ),
        );
      }),
    );
  }
}
