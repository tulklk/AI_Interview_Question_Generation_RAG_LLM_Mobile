import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../data/providers/app_providers.dart';

class CandidateProfileScreen extends ConsumerWidget {
  const CandidateProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final isDarkMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const skills = ['Flutter', 'Dart', 'Riverpod', 'Firebase', 'REST API',
      'Clean Architecture', 'CI/CD', 'Git'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBg]
                    : [AppColors.violetWash, AppColors.offWhite],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    AppAvatar(name: user.name, size: 88, showRing: true)
                      .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(user.name, style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack))
                      .animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    Text(user.title ?? 'Flutter Developer',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.brandPurple, fontWeight: FontWeight.w600))
                      .animate().fadeIn(delay: 140.ms),
                    const SizedBox(height: 4),
                    Text(user.email, style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500))
                      .animate().fadeIn(delay: 170.ms),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _StatPill('6', 'Applications', isDark),
                      const SizedBox(width: 12),
                      _StatPill('12', 'Practices', isDark),
                      const SizedBox(width: 12),
                      _StatPill('4', 'Yrs Exp', isDark),
                    ]).animate().fadeIn(delay: 200.ms),
                  ]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Skills
                _Section(title: 'Skills', icon: PhosphorIconsBold.code, isDark: isDark,
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: skills.map((s) => AppSkillChip(label: s)).toList()))
                  .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Resume
                _Section(title: 'Resume', icon: PhosphorIconsBold.filePdf, isDark: isDark,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandPurple.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(PhosphorIconsBold.filePdf, size: 28,
                        color: AppColors.brandPurple),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My_CV_2024.pdf', style: AppTextStyles.labelBold.copyWith(
                            color: isDark ? AppColors.white : AppColors.nearBlack)),
                          Text('Last updated November 2024',
                            style: AppTextStyles.caption),
                        ],
                      )),
                      const Icon(PhosphorIconsBold.arrowUpRight,
                        size: 16, color: AppColors.brandPurple),
                    ]),
                  ))
                  .animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),

                // Preferences
                _Section(title: 'Preferences', icon: PhosphorIconsBold.sliders, isDark: isDark,
                  child: Column(children: [
                    _PrefRow('Job Type', 'Full-time, Remote', isDark),
                    const Divider(height: 20),
                    _PrefRow('Location', 'Ho Chi Minh City', isDark),
                    const Divider(height: 20),
                    _PrefRow('Salary', '2,000+ USD/month', isDark),
                    const Divider(height: 20),
                    _PrefRow('Availability', 'Immediately', isDark),
                  ]))
                  .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),

                // Settings
                _Section(title: 'Settings', icon: PhosphorIconsBold.gear, isDark: isDark,
                  child: Column(children: [
                    _SettingRow(icon: PhosphorIconsBold.bell, label: 'Notifications',
                      isDark: isDark, onTap: () {}),
                    const Divider(height: 1, indent: 50),
                    Row(children: [
                      const SizedBox(width: 50),
                      const Expanded(child: Text('Dark Mode')),
                      Switch.adaptive(
                        value: isDarkMode,
                        onChanged: (v) =>
                          ref.read(themeProvider.notifier).state = v,
                        activeColor: AppColors.brandPurple,
                      ),
                    ]),
                    const Divider(height: 1, indent: 50),
                    _SettingRow(icon: PhosphorIconsBold.globe, label: 'Language: English',
                      isDark: isDark, onTap: () {}),
                  ]))
                  .animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 24),

                AppGradientButton(
                  label: 'Sign Out',
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  height: 52,
                ).animate().fadeIn(delay: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatPill(this.value, this.label, this.isDark);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(children: [
      Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.brandPurple, fontSize: 18)),
      Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
    ]),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;
  const _Section({required this.title, required this.icon, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) => AppElevatedCard(
    interactive: false,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: AppColors.brandPurple),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h4.copyWith(
          color: isDark ? AppColors.white : AppColors.nearBlack)),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _PrefRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _PrefRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyles.caption),
      Text(value, style: AppTextStyles.label.copyWith(
        color: isDark ? AppColors.white : AppColors.nearBlack,
        fontWeight: FontWeight.w600)),
    ],
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _SettingRow({required this.icon, required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.brandPurple),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.white : AppColors.nearBlack))),
        const Icon(PhosphorIconsBold.caretRight, size: 14, color: AppColors.gray400),
      ]),
    ),
  );
}
