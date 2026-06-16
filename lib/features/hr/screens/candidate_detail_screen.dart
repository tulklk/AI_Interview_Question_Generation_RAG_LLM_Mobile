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
import '../../../core/widgets/app_progress_ring.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/candidate_model.dart';

class CandidateDetailScreen extends ConsumerWidget {
  final String candidateId;
  const CandidateDetailScreen({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidates = ref.watch(candidatesProvider);
    final candidate = candidates.firstWhere((c) => c.id == candidateId,
      orElse: () => candidates.first);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandPurple.withOpacity(0.15),
                      isDark ? AppColors.darkBg : AppColors.offWhite,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Row(
                      children: [
                        AppAvatar(name: candidate.name, size: 72, showRing: true),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(candidate.name,
                                style: AppTextStyles.h2.copyWith(
                                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                              const SizedBox(height: 4),
                              Text(candidate.appliedRole,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.brandPurple, fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  AppStatusBadge(
                                    label: _stageLabel(candidate.stage),
                                    type: _stageBadge(candidate.stage)),
                                  const SizedBox(width: 8),
                                  AppStatusBadge(
                                    label: '${candidate.yearsOfExperience} yrs',
                                    type: BadgeType.info),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AppProgressRing(
                          progress: candidate.matchScore / 100,
                          size: 64,
                          strokeWidth: 5,
                          label: 'match',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Skills
                _Section(
                  title: 'Skills',
                  icon: PhosphorIconsBold.code,
                  isDark: isDark,
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: candidate.skills
                      .map((s) => AppSkillChip(label: s))
                      .toList(),
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),

                // Summary
                if (candidate.summary != null)
                  _Section(
                    title: 'Summary',
                    icon: PhosphorIconsBold.fileText,
                    isDark: isDark,
                    child: Text(candidate.summary!,
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.white.withOpacity(0.8) : AppColors.gray500,
                        height: 1.65, fontSize: 14)),
                  ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),

                // AI Evaluation score
                _Section(
                  title: 'AI Match Analysis',
                  icon: PhosphorIconsBold.sparkle,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _ScoreBar(label: 'Technical Skills',
                        score: candidate.matchScore / 100 * 0.95, color: AppColors.brandPurple),
                      const SizedBox(height: 10),
                      _ScoreBar(label: 'Experience Fit',
                        score: candidate.yearsOfExperience / 8, color: AppColors.deepBlue),
                      const SizedBox(height: 10),
                      _ScoreBar(label: 'Skill Coverage',
                        score: candidate.skills.length / 8, color: AppColors.teal),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Contact links
                _Section(
                  title: 'Contact & Links',
                  icon: PhosphorIconsBold.link,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: PhosphorIconsBold.envelopeSimple,
                        label: candidate.email, color: AppColors.brandPurple),
                      if (candidate.linkedIn != null) ...[
                        const SizedBox(height: 8),
                        _ContactRow(
                          icon: PhosphorIconsBold.linkedinLogo,
                          label: candidate.linkedIn!, color: AppColors.deepBlue),
                      ],
                      if (candidate.github != null) ...[
                        const SizedBox(height: 8),
                        _ContactRow(
                          icon: PhosphorIconsBold.githubLogo,
                          label: candidate.github!, color: AppColors.nearBlack),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 24),

                // Action buttons
                AppGradientButton(
                  label: 'Schedule Interview',
                  onTap: () {},
                  height: 52,
                  icon: const Icon(PhosphorIconsBold.calendar,
                    size: 18, color: Colors.white),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Move Stage',
                        onTap: () => _showMoveStageSheet(context, candidate, isDark),
                        icon: Icon(PhosphorIconsBold.arrowRight,
                          size: 16, color: AppColors.brandPurple),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Reject',
                        onTap: () {},
                        textColor: AppColors.error,
                        borderColor: AppColors.error.withOpacity(0.3),
                        icon: Icon(PhosphorIconsBold.x,
                          size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _stageLabel(CandidateStage s) => switch (s) {
    CandidateStage.applied => 'Applied',
    CandidateStage.screening => 'Screening',
    CandidateStage.interview => 'Interview',
    CandidateStage.offer => 'Offer',
    CandidateStage.rejected => 'Rejected',
  };

  BadgeType _stageBadge(CandidateStage s) => switch (s) {
    CandidateStage.applied => BadgeType.teal,
    CandidateStage.screening => BadgeType.info,
    CandidateStage.interview => BadgeType.purple,
    CandidateStage.offer => BadgeType.success,
    CandidateStage.rejected => BadgeType.danger,
  };

  void _showMoveStageSheet(BuildContext ctx, CandidateModel c, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move to Stage', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            ...CandidateStage.values.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(PhosphorIconsBold.arrowRight,
                  size: 16, color: AppColors.brandPurple),
              ),
              title: Text(_stageLabel(s),
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
              onTap: () => Navigator.pop(ctx),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;
  const _Section({required this.title, required this.icon,
    required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) => AppElevatedCard(
    interactive: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.brandPurple),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.labelBold.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack)),
        ]),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _ScoreBar extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _anim = Tween<double>(begin: 0, end: widget.score.clamp(0, 1))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(widget.label, style: AppTextStyles.caption),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Text('${(_anim.value * 100).round()}%',
            style: AppTextStyles.caption.copyWith(
              color: widget.color, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => LinearProgressIndicator(
            value: _anim.value,
            minHeight: 6,
            backgroundColor: isDark
              ? widget.color.withOpacity(0.12)
              : widget.color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(widget.color),
          ),
        ),
      ),
    ]);
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ContactRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 10),
      Text(label, style: AppTextStyles.label.copyWith(
        color: isDark ? AppColors.white.withOpacity(0.85) : AppColors.nearBlack)),
    ]);
  }
}
