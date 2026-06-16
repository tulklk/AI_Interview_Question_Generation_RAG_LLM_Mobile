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
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    final job = jobs.firstWhere((j) => j.id == jobId, orElse: () => jobs.first);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchScore = 75 + (jobId.hashCode % 25).abs();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIconsBold.arrowLeft, size: 18,
                  color: isDark ? AppColors.white : AppColors.nearBlack),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(PhosphorIconsBold.bookmarkSimple, size: 18,
                    color: isDark ? AppColors.white : AppColors.nearBlack),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandPurple.withOpacity(0.12),
                      isDark ? AppColors.darkBg : AppColors.offWhite,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(PhosphorIconsBold.briefcase,
                              size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.title, style: AppTextStyles.h2.copyWith(
                                color: isDark ? AppColors.white : AppColors.nearBlack,
                                fontSize: 20)),
                              const SizedBox(height: 4),
                              Text('FPT Software', style: AppTextStyles.body.copyWith(
                                color: AppColors.brandPurple, fontWeight: FontWeight.w600,
                                fontSize: 14)),
                            ],
                          )),
                          AppProgressRing(
                            progress: matchScore / 100,
                            size: 56,
                            strokeWidth: 5,
                            label: 'match',
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [
                          AppStatusBadge(label: job.location, type: BadgeType.info),
                          if (job.isRemote) AppStatusBadge(label: 'Remote', type: BadgeType.teal),
                          if (job.salaryRange != null)
                            AppStatusBadge(label: job.salaryRange!, type: BadgeType.success),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tabs: Overview / Requirements / Benefits
                _DetailSection(title: 'Overview', isDark: isDark,
                  child: Text(job.description, style: AppTextStyles.body.copyWith(
                    color: isDark ? AppColors.white.withOpacity(0.8) : AppColors.gray500,
                    height: 1.7, fontSize: 14)))
                  .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),

                _DetailSection(title: 'Required Skills', isDark: isDark,
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: job.skills.map((s) => AppSkillChip(label: s)).toList()))
                  .animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),

                _DetailSection(title: 'AI Match Analysis', isDark: isDark,
                  child: Column(children: [
                    _MatchRow('Skills Coverage', 0.92, AppColors.brandPurple),
                    const SizedBox(height: 10),
                    _MatchRow('Experience Level', 0.85, AppColors.deepBlue),
                    const SizedBox(height: 10),
                    _MatchRow('Location Preference', 1.0, AppColors.teal),
                  ]))
                  .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                _DetailSection(title: 'Benefits', isDark: isDark,
                  child: Column(
                    children: [
                      '13th month salary + performance bonus',
                      'Flexible remote work policy',
                      'Health insurance (Bao Viet premium)',
                      '15 days annual leave',
                      'Learning & development budget \$500/year',
                    ].map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withOpacity(0.12)),
                          child: const Icon(PhosphorIconsBold.check,
                            size: 11, color: AppColors.success)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(b, style: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.white.withOpacity(0.8) : AppColors.gray500,
                          fontSize: 14))),
                      ]),
                    )).toList(),
                  ))
                  .animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: AppGradientButton(
          label: 'Apply Now',
          height: 54,
          onTap: () => _showApplySheet(context, isDark),
          icon: const Icon(PhosphorIconsBold.paperPlaneTilt,
            size: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _showApplySheet(BuildContext ctx, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 24),
          Text('Apply for this position', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Your profile will be submitted to the hiring team',
            style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14)),
          const SizedBox(height: 24),
          // CV upload mock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brandPurple.withOpacity(0.2),
                style: BorderStyle.solid),
            ),
            child: Row(children: [
              const Icon(PhosphorIconsBold.filePdf, size: 28, color: AppColors.brandPurple),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My_CV_2024.pdf', style: AppTextStyles.labelBold.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                Text('Last updated Nov 2024', style: AppTextStyles.caption),
              ])),
              const Icon(PhosphorIconsBold.checkCircle, color: AppColors.success),
            ]),
          ),
          const Spacer(),
          AppGradientButton(
            label: 'Submit Application',
            height: 54,
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Application submitted! 🎉',
                    style: AppTextStyles.label.copyWith(color: Colors.white)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _DetailSection({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) => AppElevatedCard(
    interactive: false,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.h4.copyWith(
        color: isDark ? AppColors.white : AppColors.nearBlack)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _MatchRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MatchRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(flex: 3, child: Text(label, style: AppTextStyles.caption)),
      const SizedBox(width: 10),
      Expanded(flex: 5, child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value, minHeight: 6,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('${(value * 100).round()}%', style: AppTextStyles.caption.copyWith(
        color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}
