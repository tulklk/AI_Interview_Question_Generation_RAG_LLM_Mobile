import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/job_model.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(filteredJobsProvider);
    final filter = ref.watch(jobFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Job Postings', style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${jobs.length} jobs', style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
                  ),
                ],
              ).animate().fadeIn(),
            ),
            const SizedBox(height: 16),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: filter == null,
                    onTap: () => ref.read(jobFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: filter == JobStatus.active,
                    color: AppColors.success,
                    onTap: () => ref.read(jobFilterProvider.notifier).state = JobStatus.active,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Draft',
                    isSelected: filter == JobStatus.draft,
                    color: AppColors.amber,
                    onTap: () => ref.read(jobFilterProvider.notifier).state = JobStatus.draft,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Closed',
                    isSelected: filter == JobStatus.closed,
                    color: AppColors.error,
                    onTap: () => ref.read(jobFilterProvider.notifier).state = JobStatus.closed,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            // Job list
            Expanded(
              child: jobs.isEmpty
                  ? const AppEmptyState(
                      icon: PhosphorIconsBold.briefcase,
                      title: 'No jobs found',
                      subtitle: 'Create your first job posting to get started',
                      actionLabel: 'Create Job',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: jobs.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _JobCard(
                          job: jobs[i],
                          onTap: () {},
                        ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, end: 0),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _GradientFAB(
        onTap: () => context.push('/hr/jobs/create'),
      ).animate().scale(delay: 300.ms),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.brandPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  BadgeType get _statusBadge {
    switch (job.status) {
      case JobStatus.active: return BadgeType.success;
      case JobStatus.draft: return BadgeType.warning;
      case JobStatus.closed: return BadgeType.danger;
    }
  }

  String get _statusLabel {
    switch (job.status) {
      case JobStatus.active: return 'Active';
      case JobStatus.draft: return 'Draft';
      case JobStatus.closed: return 'Closed';
    }
  }

  String get _levelLabel {
    switch (job.level) {
      case ExperienceLevel.junior: return 'Junior';
      case ExperienceLevel.middle: return 'Mid-level';
      case ExperienceLevel.senior: return 'Senior';
      case ExperienceLevel.lead: return 'Lead';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppElevatedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(PhosphorIconsBold.briefcase, size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: AppTextStyles.h4.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack)),
                    const SizedBox(height: 2),
                    Text(job.department, style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500)),
                  ],
                ),
              ),
              AppStatusBadge(label: _statusLabel, type: _statusBadge),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(PhosphorIconsBold.mapPin, size: 13, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text(job.location, style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Icon(PhosphorIconsBold.users, size: 13, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text('${job.candidateCount} candidates', style: AppTextStyles.caption),
              if (job.isRemote) ...[
                const SizedBox(width: 12),
                AppStatusBadge(label: 'Remote', type: BadgeType.teal),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...job.skills.take(4).map((s) => AppSkillChip(label: s)),
              if (job.skills.length > 4)
                AppSkillChip(
                  label: '+${job.skills.length - 4}',
                  color: AppColors.gray400,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AppStatusBadge(label: _levelLabel, type: BadgeType.info),
              if (job.salaryRange != null) ...[
                const SizedBox(width: 8),
                Icon(PhosphorIconsBold.currencyDollar, size: 13, color: AppColors.success),
                const SizedBox(width: 2),
                Text(job.salaryRange!, style: AppTextStyles.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _GradientFAB({required this.onTap});

  @override
  State<_GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<_GradientFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(PhosphorIconsBold.plus, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
