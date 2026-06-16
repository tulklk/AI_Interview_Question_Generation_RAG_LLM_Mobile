import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_progress_ring.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/candidate_model.dart';

class CandidatesScreen extends ConsumerWidget {
  const CandidatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageFilter = ref.watch(candidateStageProvider);
    final candidates = ref.watch(filteredCandidatesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stages = [
      (null, 'All', AppColors.brandPurple),
      (CandidateStage.applied, 'Applied', AppColors.teal),
      (CandidateStage.screening, 'Screening', AppColors.deepBlue),
      (CandidateStage.interview, 'Interview', AppColors.brandPurple),
      (CandidateStage.offer, 'Offer', AppColors.success),
      (CandidateStage.rejected, 'Rejected', AppColors.error),
    ];

    // Count per stage
    final allCandidates = ref.watch(candidatesProvider);
    Map<CandidateStage?, int> counts = {null: allCandidates.length};
    for (final s in CandidateStage.values) {
      counts[s] = allCandidates.where((c) => c.stage == s).length;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: AppSectionHeader(
                title: 'Candidates',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${candidates.length} total',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(),
            ),
            const SizedBox(height: 16),
            // Stage tabs (horizontal scroll)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: stages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final (stage, label, color) = stages[i];
                  final isSelected = stageFilter == stage;
                  return GestureDetector(
                    onTap: () =>
                      ref.read(candidateStageProvider.notifier).state = stage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : color.withOpacity(0.2)),
                        boxShadow: isSelected ? [
                          BoxShadow(color: color.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${counts[stage] ?? 0}',
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : color)),
                          const SizedBox(height: 2),
                          Text(label,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected ? Colors.white.withOpacity(0.85) : color,
                              fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 100.ms),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: candidates.isEmpty
                ? const AppEmptyState(
                    icon: PhosphorIconsBold.users,
                    title: 'No candidates yet',
                    subtitle: 'Candidates who apply to your jobs will appear here',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: candidates.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CandidateCard(
                        candidate: candidates[i],
                        onTap: () => context.push('/hr/candidates/${candidates[i].id}'),
                      ).animate()
                          .fadeIn(delay: (i * 50).ms)
                          .slideY(begin: 0.1, end: 0),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final VoidCallback onTap;
  const _CandidateCard({required this.candidate, required this.onTap});

  String get _stageLabel => switch (candidate.stage) {
    CandidateStage.applied => 'Applied',
    CandidateStage.screening => 'Screening',
    CandidateStage.interview => 'Interview',
    CandidateStage.offer => 'Offer',
    CandidateStage.rejected => 'Rejected',
  };

  BadgeType get _stageBadge => switch (candidate.stage) {
    CandidateStage.applied => BadgeType.teal,
    CandidateStage.screening => BadgeType.info,
    CandidateStage.interview => BadgeType.purple,
    CandidateStage.offer => BadgeType.success,
    CandidateStage.rejected => BadgeType.danger,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppElevatedCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar with ring for high match
          AppAvatar(
            name: candidate.name,
            size: 52,
            showRing: candidate.matchScore >= 85,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(candidate.name,
                        style: AppTextStyles.h4.copyWith(
                          color: isDark ? AppColors.white : AppColors.nearBlack,
                          fontSize: 15)),
                    ),
                    AppStatusBadge(label: _stageLabel, type: _stageBadge),
                  ],
                ),
                const SizedBox(height: 3),
                Text(candidate.appliedRole,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(PhosphorIconsBold.clock, size: 12, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text('${candidate.yearsOfExperience} yrs exp',
                      style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5, runSpacing: 5,
                  children: candidate.skills.take(3)
                    .map((s) => AppSkillChip(label: s))
                    .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Match score ring
          AppProgressRing(
            progress: candidate.matchScore / 100,
            size: 56,
            strokeWidth: 5,
            gradientColors: candidate.matchScore >= 80
              ? [AppColors.brandPurple, AppColors.deepBlue]
              : [AppColors.amber, const Color(0xFFF97316)],
          ),
        ],
      ),
    );
  }
}
