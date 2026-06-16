import 'dart:math';
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
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F5FB),
      body: CustomScrollView(
        slivers: [
          // ── Premium header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              userName: user.name,
              notificationCount: notifications,
              isDark: isDark,
            ).animate().fadeIn(duration: 500.ms),
          ),

          // ── Stats grid ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                AppStatsCard(
                  title: 'Active Jobs',
                  value: '${jobs.length}',
                  icon: const Icon(PhosphorIconsBold.briefcase, size: 18),
                  iconColor: AppColors.brandPurple,
                  subtitle: '+2 this week',
                ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'Candidates',
                  value: '${candidates.length}',
                  icon: const Icon(PhosphorIconsBold.users, size: 18),
                  iconColor: AppColors.deepBlue,
                  subtitle: '+5 today',
                ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'Interviews Today',
                  value: '${interviews.length}',
                  icon: const Icon(PhosphorIconsBold.calendar, size: 18),
                  iconColor: AppColors.teal,
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.2, end: 0),
                AppStatsCard(
                  title: 'AI Question Sets',
                  value: '${kits.length}',
                  icon: const Icon(PhosphorIconsBold.sparkle, size: 18),
                  iconColor: AppColors.magenta,
                  subtitle: 'AI powered',
                ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.2, end: 0),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 140,
              ),
            ),
          ),

          // ── AI highlight card ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _AIHighlightCard(
                onTap: () => context.push('/hr/ai-generator'),
              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.15, end: 0),
            ),
          ),

          // ── Upcoming interviews ───────────────────────────────────────────
          if (interviews.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
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
                        .fadeIn(delay: (330 + i * 60).ms)
                        .slideX(begin: 0.08, end: 0),
                  ),
                  childCount: interviews.take(2).length,
                ),
              ),
            ),
          ],

          // ── Top candidates ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            sliver: SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Top Candidates',
                actionLabel: 'View all',
                onAction: () => context.go('/hr/candidates'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CandidateTile(
                    candidate: topCandidates[i],
                    onTap: () =>
                        context.push('/hr/candidates/${topCandidates[i].id}'),
                  )
                      .animate()
                      .fadeIn(delay: (380 + i * 60).ms)
                      .slideY(begin: 0.1, end: 0),
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

// ─── Dashboard header ─────────────────────────────────────────────────────────

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
                colors: [Color(0xFF0F1629), Color(0xFF080A16)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFFEEEAFF), Color(0xFFF4F5FB)],
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
              // ── Avatar row ───────────────────────────────────────────────
              Row(
                children: [
                  AppAvatar(name: userName, size: 46, showRing: true),
                  const SizedBox(width: 12),
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
                          _firstName,
                          style: AppTextStyles.h4.copyWith(
                            color: isDark
                                ? AppColors.white
                                : AppColors.nearBlack,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Notification bell ─────────────────────────────────
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
                                ? AppColors.brandPurple
                                    .withValues(alpha: 0.25)
                                : AppColors.gray200
                                    .withValues(alpha: 0.8),
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(
                            PhosphorIconsBold.bell,
                            size: 20,
                            color: isDark
                                ? AppColors.white
                                : AppColors.nearBlack,
                          ),
                        ),
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
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

              const SizedBox(height: 16),

              // ── Glass search bar ──────────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.brandPurple.withValues(alpha: 0.18)
                        : AppColors.gray200,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      PhosphorIconsBold.magnifyingGlass,
                      size: 18,
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.30)
                          : AppColors.gray400,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Search candidates, jobs...',
                      style: AppTextStyles.body.copyWith(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.30)
                            : AppColors.gray400,
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

// ─── AI Highlight card (floating robot icon) ──────────────────────────────────

class _AIHighlightCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AIHighlightCard({required this.onTap});

  @override
  State<_AIHighlightCard> createState() => _AIHighlightCardState();
}

class _AIHighlightCardState extends State<_AIHighlightCard>
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
              colors: [Color(0xFF6C3BFF), Color(0xFF2F80ED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3BFF)
                    .withValues(alpha: _pressed ? 0.22 : 0.48),
                blurRadius: _pressed ? 12 : 30,
                offset: Offset(0, _pressed ? 4 : 14),
              ),
              BoxShadow(
                color: const Color(0xFF2F80ED).withValues(alpha: 0.20),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
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
                          const Icon(PhosphorIconsBold.sparkle,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'AI POWERED',
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
                      'Generate interview\nquestions from JD',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        height: 1.3,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paste a job description and get\na structured kit in seconds',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CTA chip
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
                            'Generate Now',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.brandPurple),
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
                  width: 78,
                  height: 78,
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
                        size: 40, color: Colors.white),
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

// ─── Interview tile ───────────────────────────────────────────────────────────

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
                Text(
                  interview.candidateName,
                  style: AppTextStyles.labelBold.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  interview.jobTitle,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  time,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.gray400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Candidate tile ───────────────────────────────────────────────────────────

class _CandidateTile extends StatelessWidget {
  final CandidateModel candidate;
  final VoidCallback onTap;
  const _CandidateTile({required this.candidate, required this.onTap});

  BadgeType get _stageBadgeType {
    switch (candidate.stage) {
      case CandidateStage.offer:
        return BadgeType.success;
      case CandidateStage.interview:
        return BadgeType.purple;
      case CandidateStage.screening:
        return BadgeType.info;
      case CandidateStage.applied:
        return BadgeType.teal;
      case CandidateStage.rejected:
        return BadgeType.danger;
    }
  }

  String get _stageLabel {
    switch (candidate.stage) {
      case CandidateStage.offer:
        return 'Offer';
      case CandidateStage.interview:
        return 'Interview';
      case CandidateStage.screening:
        return 'Screening';
      case CandidateStage.applied:
        return 'Applied';
      case CandidateStage.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highScore = candidate.matchScore >= 80;
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
                Text(
                  candidate.name,
                  style: AppTextStyles.labelBold.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.appliedRole,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.gray500),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 4,
                  children: candidate.skills
                      .take(3)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandPurple
                                  .withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Match score circle with glow
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: highScore
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [AppColors.amber, Color(0xFFF97316)]),
                  boxShadow: [
                    BoxShadow(
                      color: (highScore
                              ? AppColors.brandPurple
                              : AppColors.amber)
                          .withValues(alpha: 0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${candidate.matchScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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
