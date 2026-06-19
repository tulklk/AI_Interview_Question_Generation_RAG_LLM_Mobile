import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_progress_ring.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';

class PracticeQuestionScreen extends ConsumerStatefulWidget {
  const PracticeQuestionScreen({super.key});

  @override
  ConsumerState<PracticeQuestionScreen> createState() =>
      _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState
    extends ConsumerState<PracticeQuestionScreen> {
  final _answerCtrl = TextEditingController();
  late Timer _timer;
  int _seconds = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submit() {
    _timer.cancel();
    ref.read(practiceProvider.notifier).submitAnswer(_answerCtrl.text);
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (practice.isComplete) {
      return _FeedbackScreen(
        isDark: isDark,
        totalQuestions: practice.questions.length,
      );
    }

    if (practice.questions.isEmpty) {
      return Scaffold(
        body: Center(child: Text('No questions', style: AppTextStyles.body)),
      );
    }

    final q = practice.questions[practice.currentIndex];
    final progress = practice.progress;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              PhosphorIconsBold.x,
              size: 18,
              color: isDark ? AppColors.white : AppColors.nearBlack,
            ),
          ),
        ),
        title: Text(
          '${practice.currentIndex + 1} / ${practice.questions.length}',
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.65)
                : AppColors.gray500,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(PhosphorIconsBold.timer,
                  size: 14, color: AppColors.amber),
              const SizedBox(width: 5),
              Text(
                _timeStr,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient progress bar ─────────────────────────────────
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.brandPurple.withValues(alpha: 0.12)
                    : AppColors.brandPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPurple
                            .withValues(alpha: 0.40),
                        blurRadius: 8,
                        spreadRadius: -1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Question card ─────────────────────────────────────────
            AppElevatedCard(
              interactive: false,
              accentColor: AppColors.brandPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AppStatusBadge(
                      label: q.skillTested,
                      type: BadgeType.purple,
                    ),
                    const SizedBox(width: 8),
                    AppDifficultyBadge(
                        level: switch (q.difficulty) {
                      _ when q.difficulty.name == 'easy' => 'Easy',
                      _ when q.difficulty.name == 'hard' => 'Hard',
                      _ => 'Medium',
                    }),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    q.question,
                    style: AppTextStyles.h4.copyWith(
                      color:
                          isDark ? AppColors.white : AppColors.nearBlack,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // ── Answer area ───────────────────────────────────────────
            Expanded(
              child: _submitted
                  ? _FeedbackBox(
                      expectedAnswer: q.expectedAnswer,
                      userAnswer: _answerCtrl.text,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 300.ms)
                  : Column(
                      children: [
                        // Glass textarea
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF1D2440),
                                        const Color(0xFF131825)
                                      ]
                                    : [
                                        Colors.white,
                                        const Color(0xFFF8F9FE)
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.brandPurple
                                        .withValues(alpha: 0.12)
                                    : AppColors.cardBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _answerCtrl,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: AppTextStyles.body.copyWith(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.nearBlack,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your answer here...',
                                hintStyle: AppTextStyles.body.copyWith(
                                  color: isDark
                                      ? AppColors.white
                                          .withValues(alpha: 0.28)
                                      : AppColors.gray400,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Bottom action row
                        Row(children: [
                          // Gradient mic button
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  AppColors.deepBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.42),
                                  blurRadius: 14,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              PhosphorIconsBold.microphone,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppGradientButton(
                              label: 'Submit Answer',
                              onTap: _submit,
                              height: 52,
                              icon: const Icon(
                                PhosphorIconsBold.checkCircle,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-question feedback box ─────────────────────────────────────────────────

class _FeedbackBox extends StatelessWidget {
  final String expectedAnswer;
  final String userAnswer;
  final bool isDark;
  const _FeedbackBox({
    required this.expectedAnswer,
    required this.userAnswer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI suggested answer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                left: BorderSide(color: AppColors.success, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(PhosphorIconsBold.sparkle,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'AI Suggested Answer',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  expectedAnswer,
                  style: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.82)
                        : AppColors.gray500,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          if (userAnswer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  left: BorderSide(color: AppColors.deepBlue, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(PhosphorIconsBold.user,
                        size: 14, color: AppColors.deepBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Your Answer',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    userAnswer,
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.72)
                          : AppColors.gray500,
                      fontSize: 13,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Full session feedback screen ──────────────────────────────────────────────

class _FeedbackScreen extends StatelessWidget {
  final bool isDark;
  final int totalQuestions;
  const _FeedbackScreen(
      {required this.isDark, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Hero gradient score section ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF6C3BFF),
                      Color(0xFF2F80ED),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C3BFF).withValues(alpha: 0.40),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Specular ring around progress ring
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: AppProgressRing(
                        progress: 0.82,
                        size: 120,
                        strokeWidth: 10,
                        centerWidget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '82%',
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'Score',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(
                        duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    Text(
                      'Great session! 🎉',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 6),
                    Text(
                      'You answered $totalQuestions questions',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Score breakdown pills ─────────────────────────────────
              Row(children: [
                _FeedbackPill('Technical', 0.85, AppColors.brandPurple),
                const SizedBox(width: 10),
                _FeedbackPill('Clarity', 0.78, AppColors.teal),
                const SizedBox(width: 10),
                _FeedbackPill('Depth', 0.72, AppColors.deepBlue),
              ]).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              // ── Strengths card ────────────────────────────────────────
              AppElevatedCard(
                interactive: false,
                accentColor: AppColors.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.amber,
                              AppColors.amber.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.38),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(PhosphorIconsBold.trophy,
                            size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Strengths',
                        style: AppTextStyles.labelBold.copyWith(
                          color:
                              isDark ? AppColors.white : AppColors.nearBlack,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      'Strong understanding of Flutter widget lifecycle and state management patterns.',
                      style: AppTextStyles.body.copyWith(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.72)
                            : AppColors.gray500,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 32),

              AppGradientButton(
                label: 'Practice Again',
                onTap: () => context.pop(),
                height: 52,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Back to Home',
                onTap: () => context.go('/candidate'),
                height: 48,
              ).animate().fadeIn(delay: 440.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score breakdown pill ──────────────────────────────────────────────────────

class _FeedbackPill extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _FeedbackPill(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1D2440), const Color(0xFF131825)]
                : [Colors.white, const Color(0xFFF8F9FE)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: -3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, color.withValues(alpha: 0.70)],
            ).createShader(bounds),
            child: Text(
              '${(score * 100).round()}%',
              style: AppTextStyles.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.50)
                  : AppColors.gray500,
            ),
          ),
        ]),
      ),
    );
  }
}
