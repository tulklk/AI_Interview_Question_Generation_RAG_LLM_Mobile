import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_progress_ring.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/application_model.dart';
import '../../../models/job_model.dart';

class CandidateHomeScreen extends ConsumerWidget {
  const CandidateHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final applications = ref.watch(applicationsProvider);
    final jobs = ref.watch(jobsProvider);
    final upcomingInterviews = ref.watch(upcomingInterviewsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextInterview = upcomingInterviews.isNotEmpty
        ? upcomingInterviews.first
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: _CandidateHeader(
              userName: user.name,
              isDark: isDark,
            ).animate().fadeIn(duration: 400.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Career progress card
                _CareerProgressCard(isDark: isDark)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 16),

                // Upcoming interview card
                if (nextInterview != null) ...[
                  _UpcomingInterviewCard(interview: nextInterview, isDark: isDark)
                      .animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 16),
                ],

                // Application status summary
                _ApplicationSummaryCard(applications: applications, isDark: isDark)
                    .animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 24),

                // AI Practice reminder
                _PracticeCard(onTap: () => context.go('/candidate/practice'))
                    .animate().fadeIn(delay: 250.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 24),

                // Recommended jobs
                AppSectionHeader(
                  title: 'Recommended Jobs',
                  actionLabel: 'See all',
                  onAction: () => context.go('/candidate/jobs'),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                ...jobs.take(3).toList().asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _JobMiniCard(
                    job: e.value,
                    onTap: () => context.push('/candidate/jobs/${e.value.id}'),
                  ).animate().fadeIn(delay: (320 + e.key * 60).ms)
                      .slideY(begin: 0.1, end: 0),
                )),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _CandidateHeader extends StatelessWidget {
  final String userName;
  final bool isDark;
  const _CandidateHeader({required this.userName, required this.isDark});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF111827), Color(0xFF0A0A14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [AppColors.teal.withOpacity(0.08), AppColors.offWhite],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              AppAvatar(name: userName, size: 48, showRing: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.white.withOpacity(0.5) : AppColors.gray500)),
                    Text(userName.split(' ').last,
                      style: AppTextStyles.h4.copyWith(
                        color: isDark ? AppColors.white : AppColors.nearBlack)),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Icon(PhosphorIconsBold.bell, size: 20,
                      color: isDark ? AppColors.white : AppColors.nearBlack),
                  ),
                  Positioned(
                    top: -3, right: -3,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareerProgressCard extends StatelessWidget {
  final bool isDark;
  const _CareerProgressCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('CAREER READINESS', style: AppTextStyles.overline.copyWith(
                    color: Colors.white, fontSize: 9, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                Text('Backend Interview\nReadiness',
                  style: AppTextStyles.h3.copyWith(color: Colors.white, height: 1.3)),
                const SizedBox(height: 6),
                Text('Complete 3 more practice sessions\nto reach 90%+',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.8), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppProgressRing(
            progress: 0.78,
            size: 80,
            strokeWidth: 7,
            gradientColors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)],
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('78%', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('ready', style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingInterviewCard extends StatelessWidget {
  final dynamic interview;
  final bool isDark;
  const _UpcomingInterviewCard({required this.interview, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(interview.scheduledAt);
    final date = DateFormat('MMM d').format(interview.scheduledAt);

    return AppElevatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(PhosphorIconsBold.video, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming Interview', style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(interview.jobTitle, style: AppTextStyles.labelBold.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 2),
                Text('$date at $time', style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Prepare', style: AppTextStyles.caption.copyWith(
              color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ApplicationSummaryCard extends StatelessWidget {
  final List<ApplicationModel> applications;
  final bool isDark;
  const _ApplicationSummaryCard(
      {required this.applications, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final counts = {
      'Applied': applications
          .where((a) => a.status == ApplicationStatus.applied)
          .length,
      'Screening': applications
          .where((a) => a.status == ApplicationStatus.cvScreening)
          .length,
      'Interview': applications
          .where((a) => a.status == ApplicationStatus.interview)
          .length,
      'Offer': applications
          .where((a) => a.status == ApplicationStatus.offer)
          .length,
    };

    return AppElevatedCard(
      interactive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Applications', style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack)),
              GestureDetector(
                onTap: () => context.go('/candidate/applications'),
                child: Text('View all', style: AppTextStyles.label.copyWith(
                  color: AppColors.brandPurple, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: counts.entries.map((e) {
              final colors = {
                'Applied': AppColors.teal,
                'Screening': AppColors.deepBlue,
                'Interview': AppColors.brandPurple,
                'Offer': AppColors.success,
              };
              final c = colors[e.key]!;
              return Expanded(
                child: Column(children: [
                  Text('${e.value}', style: AppTextStyles.h2.copyWith(
                    color: c, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(e.key, style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.white.withOpacity(0.5) : AppColors.gray400,
                    fontSize: 10)),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PracticeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.brandPurple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandPurple.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(PhosphorIconsBold.robot, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Mock Interview', style: AppTextStyles.labelBold.copyWith(
                color: AppColors.brandPurple)),
              const SizedBox(height: 2),
              Text('Practice with real interview questions\nand get instant AI feedback',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500, height: 1.5)),
            ]),
          ),
          const Icon(PhosphorIconsBold.arrowRight,
            size: 18, color: AppColors.brandPurple),
        ]),
      ),
    );
  }
}

class _JobMiniCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  const _JobMiniCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppElevatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(PhosphorIconsBold.briefcase, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: AppTextStyles.labelBold.copyWith(
              color: isDark ? AppColors.white : AppColors.nearBlack)),
            const SizedBox(height: 2),
            Text('${job.location}  ·  ${job.salaryRange ?? "Negotiable"}',
              style: AppTextStyles.caption),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('89%', style: AppTextStyles.caption.copyWith(
            color: AppColors.success, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
