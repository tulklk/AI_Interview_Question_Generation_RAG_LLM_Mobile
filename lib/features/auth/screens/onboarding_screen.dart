import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _slides = const [
    _OnboardingSlide(
      emoji: '🤖',
      title: 'Generate interview\nquestions with AI',
      subtitle:
          'Paste any job description and get a complete, structured interview kit in seconds — tailored to the role and difficulty.',
      gradientColors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
      accentColor: Color(0xFF8B5CF6),
    ),
    _OnboardingSlide(
      emoji: '📊',
      title: 'Evaluate candidates\nwith scorecards',
      subtitle:
          'Structured scorecards for every interview. Track communication, technical skills, culture fit, and problem solving.',
      gradientColors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
      accentColor: Color(0xFF14B8A6),
    ),
    _OnboardingSlide(
      emoji: '🎯',
      title: 'Practice interviews,\nimprove your answers',
      subtitle:
          'AI-powered mock interviews with real feedback. Know your strengths, fix your weaknesses, land the job.',
      gradientColors: [Color(0xFFEC4899), Color(0xFF6C47FF)],
      accentColor: Color(0xFFEC4899),
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _slides[_page].gradientColors[0].withOpacity(0.12),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                    child: GestureDetector(
                      onTap: () => context.go('/role'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _OnboardingPage(slide: _slides[i]),
                  ),
                ),
                // Indicator + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageCtrl,
                        count: _slides.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3.5,
                          activeDotColor: _slides[_page].accentColor,
                          dotColor: AppColors.gray200,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppGradientButton(
                        label: _page == _slides.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        onTap: _next,
                        height: 54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          _IllustrationWidget(slide: slide),
          const SizedBox(height: 48),
          Text(
            slide.title,
            style: AppTextStyles.h1.copyWith(
              fontSize: 28,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.gray500,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _IllustrationWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  const _IllustrationWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blob background
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.gradientColors[0].withOpacity(0.15),
                  slide.gradientColors[1].withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Central emoji icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: slide.gradientColors[0].withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.85, 0.85),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          // Floating mini cards
          Positioned(
            top: 20,
            right: 10,
            child: _FloatingCard(
              color: slide.gradientColors[0],
              label: '94% match',
              icon: '⚡',
            ).animate().slideX(begin: 0.3, end: 0, delay: 200.ms),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _FloatingCard(
              color: slide.gradientColors[1],
              label: 'AI generated',
              icon: '✨',
            ).animate().slideX(begin: -0.3, end: 0, delay: 300.ms),
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final Color color;
  final String label;
  final String icon;
  const _FloatingCard({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
  });
}
