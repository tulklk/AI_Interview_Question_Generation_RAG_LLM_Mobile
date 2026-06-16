import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  String _selectedRole = 'Flutter Developer';
  String _selectedDifficulty = 'Medium';

  static const _roles = [
    ('Flutter Developer', PhosphorIconsBold.deviceMobile, AppColors.brandPurple),
    ('Backend Developer', PhosphorIconsBold.database, AppColors.deepBlue),
    ('Frontend Developer', PhosphorIconsBold.monitor, AppColors.reactCyan),
    ('QA Tester', PhosphorIconsBold.bugBeetle, AppColors.success),
    ('Business Analyst', PhosphorIconsBold.chartBar, AppColors.amber),
  ];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

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
              // Header
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(13)),
                  child: const Icon(PhosphorIconsBold.robot, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Mock Interview', style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack)),
                  Text('Practice with real questions',
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                ]),
              ]).animate().fadeIn(),
              const SizedBox(height: 28),

              // Stats row
              Row(children: [
                _StatCard('12', 'Sessions\nCompleted', AppColors.brandPurple, isDark),
                const SizedBox(width: 12),
                _StatCard('78%', 'Avg\nScore', AppColors.teal, isDark),
                const SizedBox(width: 12),
                _StatCard('5', 'Skills\nImproved', AppColors.success, isDark),
              ]).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 28),

              // Role selection
              Text('Select Role', style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack))
                .animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 14),
              Column(
                children: _roles.asMap().entries.map((e) {
                  final (label, icon, color) = e.value;
                  final isSelected = label == _selectedRole;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                            ? color.withOpacity(0.08)
                            : (isDark ? AppColors.darkCard : AppColors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1),
                          boxShadow: isSelected ? [
                            BoxShadow(color: color.withOpacity(0.2),
                              blurRadius: 12, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, size: 18,
                              color: isSelected ? Colors.white : color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(label,
                            style: AppTextStyles.label.copyWith(
                              color: isSelected ? color
                                : (isDark ? AppColors.white : AppColors.nearBlack),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500))),
                          if (isSelected)
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color),
                              child: const Icon(Icons.check, size: 13, color: Colors.white),
                            ),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (140 + e.key * 50).ms)
                        .slideX(begin: 0.15, end: 0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Difficulty
              Text('Difficulty Level', style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack))
                .animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 14),
              Row(
                children: _difficulties.map((d) {
                  final isSelected = d == _selectedDifficulty;
                  final colors = {'Easy': AppColors.success, 'Medium': AppColors.amber, 'Hard': AppColors.error};
                  final c = colors[d]!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? c : c.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? c : c.withOpacity(0.2)),
                        ),
                        child: Column(children: [
                          Text(d, style: AppTextStyles.labelBold.copyWith(
                            color: isSelected ? Colors.white : c)),
                        ]),
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
                icon: const Icon(PhosphorIconsBold.play, size: 18, color: Colors.white),
              ).animate().fadeIn(delay: 420.ms),
              const SizedBox(height: 20),

              // Recent sessions
              Text('Recent Sessions', style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack))
                .animate().fadeIn(delay: 460.ms),
              const SizedBox(height: 12),
              ...['Flutter Basics', 'State Management', 'Architecture'].asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppElevatedCard(
                    padding: const EdgeInsets.all(14),
                    interactive: false,
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(PhosphorIconsBold.robot, size: 18,
                          color: AppColors.brandPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value, style: AppTextStyles.label.copyWith(
                            color: isDark ? AppColors.white : AppColors.nearBlack)),
                          Text('Flutter Developer · Medium',
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                        ],
                      )),
                      AppStatusBadge(label: '${80 + e.key * 6}%', type: BadgeType.success),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  const _StatCard(this.value, this.label, this.color, this.isDark);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(
          fontSize: 10, height: 1.4), textAlign: TextAlign.center),
      ]),
    ),
  );
}
