import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/job_model.dart';

class CandidateJobsScreen extends ConsumerStatefulWidget {
  const CandidateJobsScreen({super.key});

  @override
  ConsumerState<CandidateJobsScreen> createState() => _CandidateJobsScreenState();
}

class _CandidateJobsScreenState extends ConsumerState<CandidateJobsScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _activeFilters = {};
  String _query = '';

  static const _filters = ['Remote', 'Full-time', 'Junior', 'Flutter', 'Backend'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider).where((j) => j.status == JobStatus.active).where((j) {
      if (_query.isEmpty) return true;
      return j.title.toLowerCase().contains(_query.toLowerCase()) ||
          j.skills.any((s) => s.toLowerCase().contains(_query.toLowerCase()));
    }).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header + search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find Jobs', style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack))
                    .animate().fadeIn(),
                  const SizedBox(height: 4),
                  Text('${jobs.length} active positions',
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14))
                    .animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 14),
                      Icon(PhosphorIconsBold.magnifyingGlass, size: 18, color: AppColors.gray400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.white : AppColors.nearBlack, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search jobs, skills...',
                            hintStyle: AppTextStyles.body.copyWith(
                              color: isDark ? AppColors.white.withOpacity(0.3) : AppColors.gray400,
                              fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((f) {
                  final active = _activeFilters.contains(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (active) _activeFilters.remove(f);
                        else _activeFilters.add(f);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.brandPurple : AppColors.brandPurple.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? AppColors.brandPurple : AppColors.brandPurple.withOpacity(0.2)),
                        ),
                        child: Text(f, style: AppTextStyles.caption.copyWith(
                          color: active ? Colors.white : AppColors.brandPurple,
                          fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),
            // Job list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: jobs.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CandidateJobCard(
                    job: jobs[i],
                    onTap: () => context.push('/candidate/jobs/${jobs[i].id}'),
                  ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, end: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  const _CandidateJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mock match score
    final matchScore = 75 + (job.id.hashCode % 25).abs();

    return AppElevatedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(PhosphorIconsBold.briefcase, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 2),
                Text('FPT Software', style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$matchScore% match', style: AppTextStyles.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(PhosphorIconsBold.mapPin, size: 13, color: AppColors.gray400),
            const SizedBox(width: 4),
            Text(job.location, style: AppTextStyles.caption),
            const SizedBox(width: 10),
            if (job.isRemote) AppStatusBadge(label: 'Remote', type: BadgeType.teal),
            const Spacer(),
            if (job.salaryRange != null)
              Text(job.salaryRange!, style: AppTextStyles.caption.copyWith(
                color: AppColors.success, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: job.skills.take(4).map((s) => AppSkillChip(label: s)).toList(),
          ),
        ],
      ),
    );
  }
}
