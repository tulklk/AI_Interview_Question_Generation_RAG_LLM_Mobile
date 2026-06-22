import 'dart:math';
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
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    final applications = ref.watch(applicationsProvider);
    final jobs = ref.watch(jobsProvider);
    final upcomingInterviews = ref.watch(upcomingInterviewsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nextInterview =
        upcomingInterviews.isNotEmpty ? upcomingInterviews.first : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F5FB),
      body: CustomScrollView(
        slivers: [
          // ── Premium header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CandidateHeader(
              userName: user.name,
              isDark: isDark,
            ).animate().fadeIn(duration: 500.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Career progress card
                _CareerProgressCard(isDark: isDark)
                    .animate()
                    .fadeIn(delay: 80.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 14),

                // Upcoming interview card
                if (nextInterview != null) ...[
                  _UpcomingInterviewCard(
                      interview: nextInterview, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 140.ms)
                      .slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 14),
                ],

                // Application summary
                _ApplicationSummaryCard(
                        applications: applications, isDark: isDark)
                    .animate()
                    .fadeIn(delay: 190.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 22),

                // AI Practice card (gradient hero)
                _PracticeCard(
                        onTap: () => context.go('/candidate/practice'))
                    .animate()
                    .fadeIn(delay: 240.ms)
                    .slideY(begin: 0.15, end: 0),
                const SizedBox(height: 28),

                // Recommended jobs
                AppSectionHeader(
                  title: 'Recommended Jobs',
                  actionLabel: 'See all',
                  onAction: () => context.go('/candidate/jobs'),
                ).animate().fadeIn(delay: 290.ms),
                const SizedBox(height: 12),
                ...jobs.take(3).toList().asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _JobMiniCard(
                          job: e.value,
                          onTap: () =>
                              context.push('/candidate/jobs/${e.value.id}'),
                        )
                            .animate()
                            .fadeIn(delay: (310 + e.key * 60).ms)
                            .slideY(begin: 0.1, end: 0),
                      ),
                    ),
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

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
                colors: [Color(0xFF0B1828), Color(0xFF080A16)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFFDDFAF6), Color(0xFFF4F5FB)],
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
                    Text(
                      _greeting,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.50)
                            : AppColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      userName.split(' ').last,
                      style: AppTextStyles.h4.copyWith(
                        color: isDark ? AppColors.white : AppColors.nearBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isDark
                            ? AppColors.teal.withValues(alpha: 0.25)
                            : AppColors.gray200.withValues(alpha: 0.8),
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIconsBold.bell,
                        size: 20,
                        color:
                            isDark ? AppColors.white : AppColors.nearBlack,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 14,
                      height: 14,
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

// ─── Career progress card ─────────────────────────────────────────────────────

class _CareerProgressCard extends StatelessWidget {
  final bool isDark;
  const _CareerProgressCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    'CAREER READINESS',
                    style: AppTextStyles.overline.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Backend Interview\nReadiness',
                  style: AppTextStyles.h3
                      .copyWith(color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete 3 more practice sessions\nto reach 90%+',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppProgressRing(
            progress: 0.78,
            size: 80,
            strokeWidth: 7,
            gradientColors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.45),
            ],
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '78%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'ready',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9,
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

// ─── Upcoming interview card ──────────────────────────────────────────────────

class _UpcomingInterviewCard extends StatelessWidget {
  final dynamic interview;
  final bool isDark;
  const _UpcomingInterviewCard(
      {required this.interview, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(interview.scheduledAt);
    final date = DateFormat('MMM d').format(interview.scheduledAt);

    return AppElevatedCard(
      padding: const EdgeInsets.all(16),
      accentColor: AppColors.brandPurple,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                const Icon(PhosphorIconsBold.video, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Interview',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  interview.jobTitle,
                  style: AppTextStyles.labelBold.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$date at $time', style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'Prepare',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Application summary card ─────────────────────────────────────────────────

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

    const colors = {
      'Applied': AppColors.teal,
      'Screening': AppColors.deepBlue,
      'Interview': AppColors.brandPurple,
      'Offer': AppColors.success,
    };

    return AppElevatedCard(
      interactive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applications',
                style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/candidate/applications'),
                child: Text(
                  'View all',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: counts.entries.map((e) {
              final c = colors[e.key]!;
              return Expanded(
                child: Column(
                  children: [
                    // Colored number
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [c, c.withValues(alpha: 0.7)],
                      ).createShader(bounds),
                      child: Text(
                        '${e.value}',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.key,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.45)
                            : AppColors.gray400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Practice card (gradient hero with floating icon) ─────────────────────────

class _PracticeCard extends StatefulWidget {
  final VoidCallback onTap;
  const _PracticeCard({required this.onTap});

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  bool _pressed = false;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6C3BFF), Color(0xFF2F80ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED)
                    .withValues(alpha: _pressed ? 0.22 : 0.46),
                blurRadius: _pressed ? 12 : 28,
                offset: Offset(0, _pressed ? 4 : 12),
              ),
              BoxShadow(
                color: const Color(0xFF2F80ED).withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Text column ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsBold.brain,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'AI MOCK INTERVIEW',
                            style: AppTextStyles.overline.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Practice & ace\nyour next interview',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        height: 1.3,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real questions, instant AI feedback.\nKnow your strengths, fix weaknesses.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Practice',
                            style: AppTextStyles.labelBold.copyWith(
                              color: AppColors.brandPurple,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(PhosphorIconsBold.arrowRight,
                              size: 12, color: AppColors.brandPurple),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // ── Floating 3D robot icon ───────────────────────────────
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, -6.0 * sin(_floatCtrl.value * pi)),
                  child: child,
                ),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(PhosphorIconsBold.robot,
                        size: 38, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Job mini card ────────────────────────────────────────────────────────────

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(PhosphorIconsBold.briefcase,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: AppTextStyles.labelBold.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.location}  ·  ${job.salaryRange ?? "Negotiable"}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '89%',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
