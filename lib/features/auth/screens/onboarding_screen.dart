import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _SlideData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> bgGradient;   // page background top color → white
  final List<Color> cardGradient; // hero card gradient
  final Color accentColor;
  final List<_BadgeData> badges;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgGradient,
    required this.cardGradient,
    required this.accentColor,
    required this.badges,
  });
}

class _BadgeData {
  final String icon;
  final String label;
  final bool topRight; // true = top-right, false = bottom-left
  const _BadgeData(this.icon, this.label, this.topRight);
}

const _slides = [
  _SlideData(
    emoji: '🤖',
    title: 'Generate interview\nquestions with AI',
    subtitle:
        'Paste any job description and get a complete, structured interview kit in seconds — tailored to the role and difficulty.',
    bgGradient: [Color(0xFFEDE9FF), Colors.white],
    cardGradient: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
    accentColor: Color(0xFF6C47FF),
    badges: [
      _BadgeData('⚡', '94% match', true),
      _BadgeData('✨', 'AI generated', false),
    ],
  ),
  _SlideData(
    emoji: '📊',
    title: 'Evaluate candidates\nwith scorecards',
    subtitle:
        'Structured scorecards for every interview. Track communication, technical skills, culture fit, and problem solving.',
    bgGradient: [Color(0xFFD9FDF8), Colors.white],
    cardGradient: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    accentColor: Color(0xFF14B8A6),
    badges: [
      _BadgeData('📈', 'Score tracked', true),
      _BadgeData('🎯', 'Culture fit', false),
    ],
  ),
  _SlideData(
    emoji: '🎯',
    title: 'Practice interviews,\nimprove your answers',
    subtitle:
        'AI-powered mock interviews with real feedback. Know your strengths, fix your weaknesses, land the job.',
    bgGradient: [Color(0xFFFFE4F0), Colors.white],
    cardGradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    accentColor: Color(0xFFEC4899),
    badges: [
      _BadgeData('🔥', 'Live feedback', true),
      _BadgeData('🏆', 'Get hired', false),
    ],
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  // Blob idle animation
  late AnimationController _blobCtrl;
  // Float animation for hero card
  late AnimationController _floatCtrl;
  // Screen fade-in on mount
  late AnimationController _fadeCtrl;
  // Per-page content animation (reset on page change)
  late AnimationController _contentCtrl;
  // Button press scale
  late AnimationController _btnCtrl;

  @override
  void initState() {
    super.initState();

    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _blobCtrl.dispose();
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    _contentCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _contentCtrl.forward(from: 0);
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/role');
    }
  }

  void _onBtnTapDown(TapDownDetails _) {
    _btnCtrl.reverse();
  }

  void _onBtnTapUp(TapUpDetails _) {
    _btnCtrl.forward().then((_) => _next());
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];

    return FadeTransition(
      opacity: _fadeCtrl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Animated gradient background ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: slide.bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.55],
                ),
              ),
            ),

            // ── Animated blobs ────────────────────────────────────────────
            AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) {
                final t = _blobCtrl.value * 2 * pi;
                return Stack(
                  children: [
                    Positioned(
                      top: -80 + 28 * sin(t),
                      left: -60 + 18 * cos(t * 0.7),
                      child: _Blob(
                        size: 320,
                        color: slide.accentColor.withValues(alpha: 0.18),
                      ),
                    ),
                    Positioned(
                      top: 100 + 20 * cos(t * 0.9),
                      right: -80 + 14 * sin(t),
                      child: _Blob(
                        size: 220,
                        color: slide.cardGradient[1].withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      bottom: 180 + 16 * sin(t * 0.8),
                      left: -40 + 10 * cos(t),
                      child: _Blob(
                        size: 180,
                        color: slide.accentColor.withValues(alpha: 0.09),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── Main content ──────────────────────────────────────────────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skip
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                      child: _SkipButton(onTap: () => context.go('/role')),
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _slides.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, i) => _SlidePage(
                        slide: _slides[i],
                        floatCtrl: _floatCtrl,
                        contentCtrl: _contentCtrl,
                      ),
                    ),
                  ),

                  // Indicator + button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                    child: Column(
                      children: [
                        _PillIndicator(
                          count: _slides.length,
                          current: _page,
                          activeColor: slide.accentColor,
                        ),
                        const SizedBox(height: 28),
                        _PrimaryButton(
                          label: _page == _slides.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          gradient: LinearGradient(
                            colors: slide.cardGradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          glowColor: slide.accentColor,
                          btnCtrl: _btnCtrl,
                          onTapDown: _onBtnTapDown,
                          onTapUp: _onBtnTapUp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide page ───────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  final AnimationController floatCtrl;
  final AnimationController contentCtrl;

  const _SlidePage({
    required this.slide,
    required this.floatCtrl,
    required this.contentCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final illustrationH = screenH < 700 ? 220.0 : 280.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: illustrationH,
            child: _HeroIllustration(
              slide: slide,
              floatCtrl: floatCtrl,
              contentCtrl: contentCtrl,
            ),
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: contentCtrl,
            builder: (_, child) => Opacity(
              opacity: contentCtrl.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - contentCtrl.value)),
                child: child,
              ),
            ),
            child: Column(
              children: [
                Text(
                  slide.title,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: screenH < 700 ? 22 : 26,
                    height: 1.3,
                    color: const Color(0xFF141827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  slide.subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gray500,
                    height: 1.65,
                    fontSize: screenH < 700 ? 13 : 14.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero illustration ────────────────────────────────────────────────────────

class _HeroIllustration extends StatelessWidget {
  final _SlideData slide;
  final AnimationController floatCtrl;
  final AnimationController contentCtrl;

  const _HeroIllustration({
    required this.slide,
    required this.floatCtrl,
    required this.contentCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Radial glow behind card
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                slide.accentColor.withValues(alpha: 0.22),
                slide.accentColor.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // Floating hero card
        AnimatedBuilder(
          animation: floatCtrl,
          builder: (_, child) {
            final dy = -6.0 * sin(floatCtrl.value * pi);
            return Transform.translate(
              offset: Offset(0, dy),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: contentCtrl,
            builder: (_, child) => Transform.scale(
              scale: 0.82 + 0.18 * Curves.elasticOut.transform(
                    contentCtrl.value.clamp(0.0, 1.0),
                  ),
              child: Opacity(
                opacity: contentCtrl.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: slide.cardGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.45),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: slide.cardGradient[1].withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  slide.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
          ),
        ),

        // Badges
        ...slide.badges.asMap().entries.map((e) {
          final idx = e.key;
          final badge = e.value;
          return Positioned(
            top: badge.topRight ? 16 : null,
            bottom: badge.topRight ? null : 16,
            right: badge.topRight ? 0 : null,
            left: badge.topRight ? null : 0,
            child: _GlassBadge(
              icon: badge.icon,
              label: badge.label,
              accentColor: slide.accentColor,
              contentCtrl: contentCtrl,
              delay: 0.15 + idx * 0.1,
            ),
          );
        }),
      ],
    );
  }
}

// ─── Glass badge ─────────────────────────────────────────────────────────────

class _GlassBadge extends StatelessWidget {
  final String icon;
  final String label;
  final Color accentColor;
  final AnimationController contentCtrl;
  final double delay; // 0.0–1.0 fraction of animation range

  const _GlassBadge({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.contentCtrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: contentCtrl,
      builder: (_, child) {
        final progress = ((contentCtrl.value - delay) / (1.0 - delay))
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pill indicator ───────────────────────────────────────────────────────────

class _PillIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;

  const _PillIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : activeColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color glowColor;
  final AnimationController btnCtrl;
  final void Function(TapDownDetails) onTapDown;
  final void Function(TapUpDetails) onTapUp;

  const _PrimaryButton({
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.btnCtrl,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: btnCtrl,
      builder: (_, child) => Transform.scale(
        scale: btnCtrl.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: () => btnCtrl.forward(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 54,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.42),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skip button ──────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gray200.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Skip',
          style: AppTextStyles.label.copyWith(
            color: AppColors.gray500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Blob ─────────────────────────────────────────────────────────────────────

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
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }
}
