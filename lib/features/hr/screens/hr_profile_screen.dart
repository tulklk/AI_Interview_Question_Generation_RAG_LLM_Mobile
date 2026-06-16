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
import '../../../data/providers/app_providers.dart';

class HRProfileScreen extends ConsumerWidget {
  const HRProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final isDark = ref.watch(themeProvider);
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isCurrentlyDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentlyDark
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
                  child: Column(
                    children: [
                      AppAvatar(name: user.name, size: 88, showRing: true)
                          .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(user.name,
                          style: AppTextStyles.h2.copyWith(
                              color: isCurrentlyDark ? AppColors.white : AppColors.nearBlack))
                          .animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 4),
                      Text(user.title ?? 'HR Manager',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.brandPurple, fontWeight: FontWeight.w600))
                          .animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text(user.company ?? 'FPT Software',
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500))
                          .animate().fadeIn(delay: 180.ms),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatPill(label: 'Jobs', value: '5'),
                          const SizedBox(width: 12),
                          _StatPill(label: 'Candidates', value: '10'),
                          const SizedBox(width: 12),
                          _StatPill(label: 'Hires', value: '3'),
                        ],
                      ).animate().fadeIn(delay: 220.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileSection(
                  title: 'Account',
                  isDark: isCurrentlyDark,
                  items: [
                    _ProfileItem(
                      icon: PhosphorIconsBold.user,
                      label: 'Edit Profile',
                      onTap: () {},
                    ),
                    _ProfileItem(
                      icon: PhosphorIconsBold.building,
                      label: 'Company Profile',
                      subtitle: user.company,
                      onTap: () {},
                    ),
                    _ProfileItem(
                      icon: PhosphorIconsBold.users,
                      label: 'Team Members',
                      onTap: () {},
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Preferences',
                  isDark: isCurrentlyDark,
                  items: [
                    _ProfileItem(
                      icon: PhosphorIconsBold.bell,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    _SwitchItem(
                      icon: PhosphorIconsBold.moon,
                      label: 'Dark Mode',
                      value: isDark,
                      onChanged: (v) =>
                          ref.read(themeProvider.notifier).state = v,
                    ),
                    _ProfileItem(
                      icon: PhosphorIconsBold.globe,
                      label: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Support',
                  isDark: isCurrentlyDark,
                  items: [
                    _ProfileItem(
                      icon: PhosphorIconsBold.question,
                      label: 'Help & FAQ',
                      onTap: () {},
                    ),
                    _ProfileItem(
                      icon: PhosphorIconsBold.shieldCheck,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),
                AppGradientButton(
                  label: 'Sign Out',
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  height: 52,
                ).animate().fadeIn(delay: 350.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: [
        Text(value, style: AppTextStyles.h3.copyWith(
            color: AppColors.brandPurple, fontSize: 20)),
        Text(label, style: AppTextStyles.caption),
      ]),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;
  const _ProfileSection(
      {required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(title,
            style: AppTextStyles.overline.copyWith(
                color: isDark ? AppColors.white.withOpacity(0.4) : AppColors.gray400,
                letterSpacing: 1.5)),
      ),
      AppElevatedCard(
        interactive: false,
        padding: EdgeInsets.zero,
        child: Column(
          children: items
              .expand((w) => [w, if (w != items.last) const Divider(height: 1, indent: 56)])
              .toList(),
        ),
      ),
    ]);
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfileItem(
      {required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.brandPurple),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.caption),
            ],
          )),
          Icon(PhosphorIconsBold.caretRight, size: 14, color: AppColors.gray400),
        ]),
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchItem(
      {required this.icon, required this.label, required this.value,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.brandPurple),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack))),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.brandPurple,
        ),
      ]),
    );
  }
}
