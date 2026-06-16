import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/application_model.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(applicationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final grouped = <ApplicationStatus, List<ApplicationModel>>{};
    for (final a in apps) {
      grouped.putIfAbsent(a.status, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Applications', style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack))
                    .animate().fadeIn(),
                  const SizedBox(height: 4),
                  Text('${apps.length} total applications',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray500, fontSize: 14))
                    .animate().fadeIn(delay: 60.ms),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Pipeline indicator
            _PipelineIndicator(apps: apps, isDark: isDark)
              .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            // Applications list
            Expanded(
              child: apps.isEmpty
                ? const AppEmptyState(
                    icon: PhosphorIconsBold.clipboardText,
                    title: 'No applications yet',
                    subtitle: 'Apply to jobs and track your progress here',
                    actionLabel: 'Browse Jobs',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: apps.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ApplicationCard(app: apps[i], isDark: isDark)
                        .animate().fadeIn(delay: (i * 60).ms)
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

class _PipelineIndicator extends StatelessWidget {
  final List<ApplicationModel> apps;
  final bool isDark;
  const _PipelineIndicator({required this.apps, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (ApplicationStatus.applied, 'Applied', AppColors.teal),
      (ApplicationStatus.cvScreening, 'Screening', AppColors.deepBlue),
      (ApplicationStatus.interview, 'Interview', AppColors.brandPurple),
      (ApplicationStatus.offer, 'Offer', AppColors.success),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: stages.map((s) {
            final count = apps.where((a) => a.status == s.$1).length;
            return Expanded(
              child: Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: count > 0 ? s.$3 : s.$3.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Text('$count', style: TextStyle(
                      color: count > 0 ? Colors.white : s.$3,
                      fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.$2, style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: isDark ? AppColors.white.withOpacity(0.5) : AppColors.gray400)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  final bool isDark;
  const _ApplicationCard({required this.app, required this.isDark});

  String get _statusLabel => switch (app.status) {
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.cvScreening => 'CV Review',
    ApplicationStatus.interview => 'Interview',
    ApplicationStatus.offer => 'Offer',
    ApplicationStatus.rejected => 'Rejected',
  };

  BadgeType get _badgeType => switch (app.status) {
    ApplicationStatus.applied => BadgeType.teal,
    ApplicationStatus.cvScreening => BadgeType.info,
    ApplicationStatus.interview => BadgeType.purple,
    ApplicationStatus.offer => BadgeType.success,
    ApplicationStatus.rejected => BadgeType.danger,
  };

  Color get _statusColor => switch (app.status) {
    ApplicationStatus.applied => AppColors.teal,
    ApplicationStatus.cvScreening => AppColors.deepBlue,
    ApplicationStatus.interview => AppColors.brandPurple,
    ApplicationStatus.offer => AppColors.success,
    ApplicationStatus.rejected => AppColors.error,
  };

  List<(String, String, bool)> get _timeline => [
    ('Applied', DateFormat('MMM d').format(app.appliedAt), true),
    ('CV Review', app.status != ApplicationStatus.applied ? '✓' : 'Pending',
      app.status != ApplicationStatus.applied),
    ('Interview', app.interviewDate != null
        ? DateFormat('MMM d').format(app.interviewDate!) : 'Pending',
      app.interviewDate != null),
    ('Decision', app.status == ApplicationStatus.offer ? 'Offer!' :
      app.status == ApplicationStatus.rejected ? 'Rejected' : 'Pending',
      app.status == ApplicationStatus.offer || app.status == ApplicationStatus.rejected),
  ];

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsBold.briefcase,
                size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.jobTitle, style: AppTextStyles.labelBold.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                Text(app.company, style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AppStatusBadge(label: _statusLabel, type: _badgeType),
              const SizedBox(height: 4),
              Text(DateFormat('MMM d').format(app.appliedAt),
                style: AppTextStyles.caption),
            ]),
          ]),
          const SizedBox(height: 16),
          // Mini timeline
          Row(
            children: _timeline.asMap().entries.map((e) {
              final (label, date, done) = e.value;
              final isLast = e.key == _timeline.length - 1;
              return Expanded(child: Row(children: [
                Expanded(child: Column(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? _statusColor : AppColors.gray200,
                    ),
                    child: Icon(
                      done ? PhosphorIconsBold.check : PhosphorIconsBold.circle,
                      size: 10,
                      color: done ? Colors.white : AppColors.gray400),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: AppTextStyles.caption.copyWith(
                    fontSize: 9, color: done ? _statusColor : AppColors.gray400,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w400),
                    textAlign: TextAlign.center),
                ])),
                if (!isLast)
                  Expanded(child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: AppColors.gray200,
                  )),
              ]));
            }).toList(),
          ),
          if (app.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(PhosphorIconsBold.notepad, size: 13, color: _statusColor),
                const SizedBox(width: 6),
                Expanded(child: Text(app.notes!, style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.white.withOpacity(0.7) : AppColors.gray500,
                  height: 1.5))),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
