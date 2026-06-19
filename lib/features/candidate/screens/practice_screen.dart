import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_stats_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'Flutter Developer';
  String _selectedDifficulty = 'Medium';
  late AnimationController _floatCtrl;

  static const _roles = [
    ('Flutter Developer', PhosphorIconsBold.deviceMobile, AppColors.brandPurple),
    ('Backend Developer', PhosphorIconsBold.database, AppColors.deepBlue),
    ('Frontend Developer', PhosphorIconsBold.monitor, AppColors.reactCyan),
    ('QA Tester', PhosphorIconsBold.bugBeetle, AppColors.success),
    ('Business Analyst', PhosphorIconsBold.chartBar, AppColors.amber),
  ];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final questions = ref.read(practiceQuestionsProvider);
    ref.read(practiceProvider.notifier).startPractice(questions);
    context.push('/candidate/practice/session');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Floating hero card ────────────────────────────────────
              _HeroCard(floatCtrl: _floatCtrl)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.08, end: 0),

              // ── Stats row ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: AppStatsCard(
                    title: 'Sessions',
                    value: '12',
                    icon: const Icon(PhosphorIconsBold.lightning),
                    iconColor: AppColors.brandPurple,
                    subtitle: '+3',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    title: 'Avg Score',
                    value: '78%',
                    icon: const Icon(PhosphorIconsBold.chartBar),
                    iconColor: AppColors.teal,
                    subtitle: '+5%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatsCard(
                    title: 'Improved',
                    value: '5',
                    icon: const Icon(PhosphorIconsBold.trendUp),
                    iconColor: AppColors.success,
                    subtitle: 'skills',
                  ),
                ),
              ]).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 28),

              // ── Role selection ────────────────────────────────────────
              Text(
                'Select Role',
                style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                ),
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 14),
              Column(
                children: _roles.asMap().entries.map((e) {
                  final (label, icon, color) = e.value;
                  final isSelected = label == _selectedRole;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRole = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.08)
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.50)
                                : (isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.cardBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isSelected ? 0.04 : 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isSelected ? 0.08 : 0.04),
                              blurRadius: 16,
                              spreadRadius: -4,
                              offset: const Offset(0, 6),
                            ),
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.18),
                                blurRadius: 24,
                                spreadRadius: -6,
                                offset: const Offset(0, 10),
                              ),
                          ],
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        color,
                                        color.withValues(alpha: 0.72)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            color.withValues(alpha: 0.38),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: AppTextStyles.label.copyWith(
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? AppColors.white
                                        : AppColors.nearBlack),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withValues(alpha: 0.80)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.check,
                                  size: 13, color: Colors.white),
                            ),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (140 + e.key * 50).ms)
                        .slideX(begin: 0.08, end: 0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Difficulty ────────────────────────────────────────────
              Text(
                'Difficulty Level',
                style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                ),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 14),
              Row(
                children: _difficulties.map((d) {
                  final isSelected = d == _selectedDifficulty;
                  const colors = {
                    'Easy': AppColors.success,
                    'Medium': AppColors.amber,
                    'Hard': AppColors.error,
                  };
                  final c = colors[d]!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDifficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c
                              : c.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? c
                                : c.withValues(alpha: 0.20),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.32),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelBold.copyWith(
                            color:
                                isSelected ? Colors.white : c,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 380.ms),
              const SizedBox(height: 32),

              AppGradientButton(
                label: 'Start Practice Session',
                onTap: _start,
                height: 54,
                icon: const Icon(PhosphorIconsBold.play,
                    size: 18, color: Colors.white),
              ).animate().fadeIn(delay: 420.ms),
              const SizedBox(height: 28),

              // ── Recent sessions ───────────────────────────────────────
              Text(
                'Recent Sessions',
                style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                ),
              ).animate().fadeIn(delay: 460.ms),
              const SizedBox(height: 12),
              ...[
                ('Flutter Basics', 82),
                ('State Management', 88),
                ('Architecture', 74),
              ].asMap().entries.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppElevatedCard(
                    padding: const EdgeInsets.all(14),
                    interactive: false,
                    accentColor: AppColors.brandPurple,
                    child: Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.brandPurple,
                              AppColors.deepBlue
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPurple
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(PhosphorIconsBold.robot,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value.$1,
                              style: AppTextStyles.label.copyWith(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.nearBlack,
                              ),
                            ),
                            Text(
                              '$_selectedRole · $_selectedDifficulty',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: '${e.value.$2}%',
                        type: BadgeType.success,
                      ),
                    ]),
                  ).animate().fadeIn(delay: (480 + e.key * 60).ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card with floating robot ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final AnimationController floatCtrl;
  const _HeroCard({required this.floatCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatCtrl,
      builder: (_, __) {
        final dy = -6.0 * sin(floatCtrl.value * pi);
        return Container(
          margin: const EdgeInsets.only(bottom: 28),
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3BFF).withValues(alpha: 0.42),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: -8,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Specular top highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                'AI Practice',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AI Mock\nInterview',
                              style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Master interviews with AI feedback',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Floating robot icon
                      Transform.translate(
                        offset: Offset(0, dy),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIconsBold.robot,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
