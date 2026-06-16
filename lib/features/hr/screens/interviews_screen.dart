import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/interview_model.dart';

class InterviewsScreen extends ConsumerStatefulWidget {
  const InterviewsScreen({super.key});

  @override
  ConsumerState<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends ConsumerState<InterviewsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final interviews = ref.watch(interviewsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build 7-day strip around today
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i - 2)));

    final todayInterviews = interviews
        .where((i) =>
            i.scheduledAt.year == _selectedDate.year &&
            i.scheduledAt.month == _selectedDate.month &&
            i.scheduledAt.day == _selectedDate.day)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('Interviews',
                style: AppTextStyles.h2.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack))
                  .animate().fadeIn(),
            ),
            const SizedBox(height: 20),

            // Calendar strip
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final isSelected = d.day == _selectedDate.day &&
                      d.month == _selectedDate.month;
                  final isToday = d.day == today.day && d.month == today.month;
                  final hasInterview = interviews.any((iv) =>
                      iv.scheduledAt.day == d.day &&
                      iv.scheduledAt.month == d.month);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 52,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.darkCard : AppColors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday && !isSelected
                              ? AppColors.brandPurple
                              : isSelected
                                  ? Colors.transparent
                                  : AppColors.cardBorder,
                          width: isToday && !isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(d).substring(0, 3),
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.gray400,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.day}',
                            style: AppTextStyles.h4.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.white : AppColors.nearBlack),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasInterview
                                  ? (isSelected
                                      ? Colors.white
                                      : AppColors.brandPurple)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Date label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDate),
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack),
                ),
                const SizedBox(width: 10),
                if (todayInterviews.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${todayInterviews.length} scheduled',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
            const SizedBox(height: 16),

            // Interview list for selected day
            Expanded(
              child: todayInterviews.isEmpty
                  ? AppEmptyState(
                      icon: PhosphorIconsBold.calendar,
                      title: 'No interviews',
                      subtitle: 'No interviews scheduled for ${DateFormat('MMM d').format(_selectedDate)}',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: todayInterviews.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InterviewDetailCard(
                          interview: todayInterviews[i],
                          isDark: isDark,
                        ).animate().fadeIn(delay: (i * 80).ms)
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

class _InterviewDetailCard extends StatefulWidget {
  final InterviewModel interview;
  final bool isDark;
  const _InterviewDetailCard({required this.interview, required this.isDark});

  @override
  State<_InterviewDetailCard> createState() => _InterviewDetailCardState();
}

class _InterviewDetailCardState extends State<_InterviewDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(widget.interview.scheduledAt);
    final scores = widget.interview.scores;

    return AppElevatedCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppAvatar(name: widget.interview.candidateName, size: 48),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.interview.candidateName,
                  style: AppTextStyles.h4.copyWith(
                    color: widget.isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 2),
                Text(widget.interview.jobTitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(time, style: AppTextStyles.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              AppStatusBadge(
                label: widget.interview.status == InterviewStatus.scheduled
                    ? 'Scheduled' : 'Completed',
                type: widget.interview.status == InterviewStatus.scheduled
                    ? BadgeType.teal : BadgeType.success,
              ),
            ]),
          ]),

          if (_expanded) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text('Scorecard', style: AppTextStyles.labelBold.copyWith(
              color: widget.isDark ? AppColors.white : AppColors.nearBlack)),
            const SizedBox(height: 14),
            if (scores.isNotEmpty)
              ...scores.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScoreRow(score: s, isDark: widget.isDark),
              ))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(PhosphorIconsBold.clipboardText,
                    size: 16, color: AppColors.gray400),
                  const SizedBox(width: 8),
                  Text('Scorecard not filled yet',
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
                ]),
              ),

            if (widget.interview.overallRecommendation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(PhosphorIconsBold.checkCircle,
                    size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(widget.interview.overallRecommendation!,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ],

          const SizedBox(height: 4),
          Center(child: Icon(
            _expanded ? PhosphorIconsBold.caretUp : PhosphorIconsBold.caretDown,
            size: 14, color: AppColors.gray400)),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final ScoreCategory score;
  final bool isDark;
  const _ScoreRow({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = score.score / 10;
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(score.name, style: AppTextStyles.caption),
            Text('${score.score}/10', style: AppTextStyles.caption.copyWith(
              color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.brandPurple.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                pct >= 0.8 ? AppColors.success
                    : pct >= 0.6 ? AppColors.brandPurple
                    : AppColors.amber),
            ),
          ),
        ],
      )),
    ]);
  }
}
