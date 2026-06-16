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
            ),
            child: Icon(PhosphorIconsBold.x, size: 18,
              color: isDark ? AppColors.white : AppColors.nearBlack),
          ),
        ),
        title: Text(
          '${practice.currentIndex + 1} / ${practice.questions.length}',
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.white.withOpacity(0.7) : AppColors.gray500),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(PhosphorIconsBold.timer, size: 14, color: AppColors.amber),
              const SizedBox(width: 4),
              Text(_timeStr, style: AppTextStyles.label.copyWith(
                color: AppColors.amber, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.brandPurple.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.brandPurple),
              ),
            ),
            const SizedBox(height: 24),

            // Question card
            AppElevatedCard(
              interactive: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AppStatusBadge(
                      label: q.skillTested,
                      type: BadgeType.purple,
                    ),
                    const SizedBox(width: 8),
                    AppDifficultyBadge(level: switch (q.difficulty) {
                      _ when q.difficulty.name == 'easy' => 'Easy',
                      _ when q.difficulty.name == 'hard' => 'Hard',
                      _ => 'Medium',
                    }),
                  ]),
                  const SizedBox(height: 16),
                  Text(q.question, style: AppTextStyles.h4.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack,
                    height: 1.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Answer area
            Expanded(
              child: _submitted
                  ? _FeedbackBox(
                      expectedAnswer: q.expectedAnswer,
                      userAnswer: _answerCtrl.text,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 300.ms)
                  : Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: TextField(
                              controller: _answerCtrl,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: AppTextStyles.body.copyWith(
                                color: isDark ? AppColors.white : AppColors.nearBlack,
                                fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type your answer here...',
                                hintStyle: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.white.withOpacity(0.3)
                                    : AppColors.gray400,
                                  fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Mic placeholder
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.brandPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.brandPurple.withOpacity(0.3)),
                            ),
                            child: const Icon(PhosphorIconsBold.microphone,
                              size: 22, color: AppColors.brandPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppGradientButton(
                              label: 'Submit Answer',
                              onTap: _submit,
                              height: 48,
                              icon: const Icon(PhosphorIconsBold.checkCircle,
                                size: 18, color: Colors.white),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(PhosphorIconsBold.sparkle, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('AI Suggested Answer', style: AppTextStyles.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Text(expectedAnswer, style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.white.withOpacity(0.85) : AppColors.gray500,
                fontSize: 13, height: 1.65)),
            ]),
          ),
          const SizedBox(height: 12),
          if (userAnswer.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepBlue.withOpacity(0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(PhosphorIconsBold.user, size: 14, color: AppColors.deepBlue),
                  const SizedBox(width: 6),
                  Text('Your Answer', style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepBlue, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                Text(userAnswer, style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.white.withOpacity(0.75) : AppColors.gray500,
                  fontSize: 13, height: 1.65)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _FeedbackScreen extends StatelessWidget {
  final bool isDark;
  final int totalQuestions;
  const _FeedbackScreen({required this.isDark, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppProgressRing(
                progress: 0.82,
                size: 120,
                strokeWidth: 10,
                centerWidget: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('82%', style: AppTextStyles.h1.copyWith(
                    color: AppColors.brandPurple, fontSize: 28)),
                  Text('Score', style: AppTextStyles.caption),
                ]),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text('Great session! 🎉', style: AppTextStyles.h2.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack))
                .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text('You answered $totalQuestions questions',
                style: AppTextStyles.body.copyWith(color: AppColors.gray500))
                .animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 32),
              // Feedback categories
              Row(children: [
                _FeedbackPill('Technical', 0.85, AppColors.brandPurple),
                const SizedBox(width: 10),
                _FeedbackPill('Clarity', 0.78, AppColors.teal),
                const SizedBox(width: 10),
                _FeedbackPill('Depth', 0.72, AppColors.deepBlue),
              ]).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              AppElevatedCard(
                interactive: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(PhosphorIconsBold.trophy, size: 16, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Text('Strengths', style: AppTextStyles.labelBold.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack)),
                  ]),
                  const SizedBox(height: 10),
                  Text('Strong understanding of Flutter widget lifecycle and state management patterns.',
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.white.withOpacity(0.75) : AppColors.gray500,
                      fontSize: 13, height: 1.6)),
                ]),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 40),
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

class _FeedbackPill extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _FeedbackPill(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('${(score * 100).round()}%', style: AppTextStyles.h4.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ]),
    ),
  );
}
