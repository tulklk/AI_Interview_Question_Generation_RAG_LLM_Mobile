import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_stats_card.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/candidate_model.dart';
import 'package:intl/intl.dart';

class HRDashboardScreen extends ConsumerWidget {
  const HRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final jobs = ref.watch(activeJobsProvider);
    final candidates = ref.watch(candidatesProvider);
    final interviews = ref.watch(upcomingInterviewsProvider);
    final kits = ref.watch(kitsProvider);
    final notifications = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final topCandidates = [...candidates]
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _DashboardHeader(
              userName: user.name,
              notificationCount: notifications,
              isDark: isDark,
            ).animate().fadeIn(duration: 400.ms),
          ),
          // Stats row 1
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                AppStatsCard(
                  title: 'Active Jobs',
                  value: '${jobs.length}',
                  icon: const Icon(PhosphorIconsBold.briefcase, size: 20, color: AppColors.brandPurple),
                  iconColor: AppColors.brandPurple,
                  subtitle: '+2 this week',
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'Candidates',
                  value: '${candidates.length}',
                  icon: const Icon(PhosphorIconsBold.users, size: 20, color: AppColors.deepBlue),
                  iconColor: AppColors.deepBlue,
                  subtitle: '+5 today',
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'Interviews Today',
                  value: '${interviews.length}',
                  icon: const Icon(PhosphorIconsBold.calendar, size: 20, color: AppColors.teal),
                  iconColor: AppColors.teal,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'AI Question Sets',
                  value: '${kits.length}',
                  icon: const Icon(PhosphorIconsBold.sparkle, size: 20, color: AppColors.magenta),
                  iconColor: AppColors.magenta,
                  subtitle: 'AI powered',
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 140,
              ),
            ),
          ),
          // AI Highlight
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _AIHighlightCard(
                onTap: () => context.push('/hr/ai-generator'),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            ),
          ),
          // Upcoming Interviews
          if (interviews.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: 'Upcoming Interviews',
                  actionLabel: 'See all',
                  onAction: () => context.go('/hr/interviews'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InterviewTile(interview: interviews[i])
                        .animate()
                        .fadeIn(delay: (350 + i * 60).ms)
                        .slideX(begin: 0.1, end: 0),
                  ),
                  childCount: interviews.take(2).length,
                ),
              ),
            ),
          ],
          // Top Candidates
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Top Candidates',
                actionLabel: 'View all',
                onAction: () => context.go('/hr/candidates'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CandidateTile(
                    candidate: topCandidates[i],
                    onTap: () => context.push('/hr/candidates/${topCandidates[i].id}'),
                  ).animate().fadeIn(delay: (400 + i * 60).ms).slideY(begin: 0.1, end: 0),
                ),
                childCount: topCandidates.take(4).length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final int notificationCount;
  final bool isDark;

  const _DashboardHeader({
    required this.userName,
    required this.notificationCount,
    required this.isDark,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName => userName.split(' ').last;

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
                colors: [AppColors.brandPurple.withOpacity(0.06), AppColors.offWhite],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(name: userName, size: 44, showRing: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.white.withOpacity(0.5) : AppColors.gray500,
                          ),
                        ),
                        Text(
                          _firstName,
                          style: AppTextStyles.h4.copyWith(
                            color: isDark ? AppColors.white : AppColors.nearBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Icon(
                          PhosphorIconsBold.bell,
                          size: 20,
                          color: isDark ? AppColors.white : AppColors.nearBlack,
                        ),
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(PhosphorIconsBold.magnifyingGlass, size: 18,
                      color: isDark ? AppColors.white.withOpacity(0.4) : AppColors.gray400),
                    const SizedBox(width: 10),
                    Text(
                      'Search candidates, jobs...',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.white.withOpacity(0.35) : AppColors.gray400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIHighlightCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AIHighlightCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withOpacity(0.4),
              blurRadius: 24,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsBold.sparkle, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('AI POWERED', style: AppTextStyles.overline.copyWith(
                          color: Colors.white, fontSize: 10, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Generate interview\nquestions from JD',
                    style: AppTextStyles.h3.copyWith(color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste a job description and get a structured interview kit in seconds',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.75), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Generate Now →',
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.brandPurple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(PhosphorIconsBold.robot, size: 36, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewTile extends StatelessWidget {
  final dynamic interview;
  const _InterviewTile({required this.interview});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm').format(interview.scheduledAt);
    final date = DateFormat('MMM d').format(interview.scheduledAt);
    return AppElevatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppAvatar(name: interview.candidateName, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(interview.candidateName,
                  style: AppTextStyles.labelBold.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 2),
                Text(interview.jobTitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(time, style: AppTextStyles.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 2),
              Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final CandidateModel candidate;
  final VoidCallback onTap;
  const _CandidateTile({required this.candidate, required this.onTap});

  BadgeType get _stageBadgeType {
    switch (candidate.stage) {
      case CandidateStage.offer: return BadgeType.success;
      case CandidateStage.interview: return BadgeType.purple;
      case CandidateStage.screening: return BadgeType.info;
      case CandidateStage.applied: return BadgeType.teal;
      case CandidateStage.rejected: return BadgeType.danger;
    }
  }

  String get _stageLabel {
    switch (candidate.stage) {
      case CandidateStage.offer: return 'Offer';
      case CandidateStage.interview: return 'Interview';
      case CandidateStage.screening: return 'Screening';
      case CandidateStage.applied: return 'Applied';
      case CandidateStage.rejected: return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppElevatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppAvatar(name: candidate.name, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate.name, style: AppTextStyles.labelBold.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 2),
                Text(candidate.appliedRole, style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: candidate.skills.take(3).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s, style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandPurple, fontSize: 10)),
                  )).toList(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Match score ring
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: candidate.matchScore >= 80
                      ? AppColors.primaryGradient
                      : const LinearGradient(colors: [AppColors.amber, Color(0xFFF97316)]),
                ),
                child: Center(
                  child: Text(
                    '${candidate.matchScore}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AppStatusBadge(label: _stageLabel, type: _stageBadgeType),
            ],
          ),
        ],
      ),
    );
  }
}
