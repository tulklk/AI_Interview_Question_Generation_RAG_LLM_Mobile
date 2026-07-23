import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/candidate_recommendation.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/recommendation_shared_widgets.dart';

class RecommendationDetailScreen extends ConsumerWidget {
  final String recommendationId;
  const RecommendationDetailScreen({super.key, required this.recommendationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = ref.watch(selectedRecommendationProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF4F5FB),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0B1020) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          item?.candidateName ?? 'Chi tiết ứng viên',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: item == null
          ? _ErrorState(onBack: () => context.pop())
          : _DetailBody(
              item: item,
              isDark: isDark,
              recommendationId: recommendationId,
            ),
    );
  }
}

// ── Detail body ────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final CandidateRecommendation item;
  final bool isDark;
  final String recommendationId;

  const _DetailBody({
    required this.item,
    required this.isDark,
    required this.recommendationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(item: item, isDark: isDark)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.04, curve: Curves.easeOut),

          const SizedBox(height: 12),

          _ActionCard(
            item: item,
            isDark: isDark,
            recommendationId: recommendationId,
          ).animate(delay: 60.ms).fadeIn(duration: 300.ms),

          if (item.recommendationReason != null &&
              item.recommendationReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AiReasonCard(reason: item.recommendationReason!, isDark: isDark)
                .animate(delay: 100.ms)
                .fadeIn(duration: 300.ms),
          ],

          if (item.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SkillsCard(skills: item.skills, isDark: isDark)
                .animate(delay: 140.ms)
                .fadeIn(duration: 300.ms),
          ],

          if (item.questionScores.isNotEmpty) ...[
            const SizedBox(height: 12),
            _QuestionsCard(scores: item.questionScores, isDark: isDark)
                .animate(delay: 180.ms)
                .fadeIn(duration: 300.ms),
          ],
        ],
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final CandidateRecommendation item;
  final bool isDark;
  const _ProfileCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    const bannerH = 72.0;
    const avatarSize = 58.0;
    const overlap = avatarSize / 2; // avatar overlaps banner by half

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + overlapping avatar via Stack
          SizedBox(
            height: bannerH + overlap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient banner (top portion only)
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: bannerH,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
                            : [const Color(0xFF6C47FF), const Color(0xFF4F46E5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    // Score pill anchored inside the banner, right side
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.overallScore.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.scoreLabel,
                            style: const TextStyle(
                              color: Color(0xDDFFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Avatar overlapping banner bottom
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 3),
                    ),
                    child: CandidateAvatarWidget(item: item, size: avatarSize),
                  ),
                ),
              ],
            ),
          ),

          // Content below avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.candidateName,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.candidateEmail != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        item.candidateEmail!,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                    ],
                  ),
                ],
                if (item.questionSetTitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.quiz_outlined,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.questionSetTitle,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _StatItem(
                      value: '${item.answeredQuestions}/${item.totalQuestions}',
                      label: 'Câu trả lời',
                      isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatItem(
                      value: item.formattedDate.isNotEmpty
                          ? item.formattedDate
                          : '—',
                      label: 'Ngày nộp',
                      isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatItem(
                      value: item.skills.length.toString(),
                      label: 'Kỹ năng',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  const _StatItem(
      {required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: isDark ? const Color(0xFF2A3350) : const Color(0xFFE5E7EB),
      );
}

// ── Action card ────────────────────────────────────────────────────────────────

class _ActionCard extends ConsumerStatefulWidget {
  final CandidateRecommendation item;
  final bool isDark;
  final String recommendationId;

  const _ActionCard({
    required this.item,
    required this.isDark,
    required this.recommendationId,
  });

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard> {
  late RecommendationStatus _current;

  @override
  void initState() {
    super.initState();
    _current = widget.item.status;
  }

  Future<void> _run(RecommendationAction action) async {
    final notifier = ref.read(recommendationActionProvider.notifier);
    final id = widget.recommendationId;

    bool ok = false;
    RecommendationStatus? next;

    if (action == RecommendationAction.invite) {
      final msg = await _inviteDialog();
      if (msg == null) return;
      ok = await notifier.invite(id, message: msg.isEmpty ? null : msg);
      next = RecommendationStatus.invited;
    } else if (action == RecommendationAction.shortlist) {
      ok = await notifier.shortlist(id);
      next = RecommendationStatus.shortlisted;
    } else {
      ok = await notifier.dismiss(id);
      next = RecommendationStatus.dismissed;
    }

    if (!mounted) return;
    if (ok && next != null) {
      setState(() => _current = next!);
      ref.read(recommendationListProvider.notifier).updateItemStatus(id, next);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${action.label} thành công'),
        backgroundColor: action.color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thao tác thất bại, thử lại.'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<String?> _inviteDialog() => showDialog<String>(
        context: context,
        builder: (ctx) {
          final isDark = widget.isDark;
          final ctrl = TextEditingController();
          return AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF111827) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Gửi lời mời phỏng vấn',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 2000,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Lời nhắn tùy chọn…',
                hintStyle:
                    const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A2035)
                    : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A3350)
                          : const Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A3350)
                          : const Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF6C47FF)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Huỷ',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(ctrl.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isLoading = ref.watch(recommendationActionProvider).isLoading;
    final actions = _current.availableActions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _current.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _current.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _current.label,
                  style: TextStyle(
                    color: _current.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action buttons or loading
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF6C47FF)),
            )
          else if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions.map((a) {
                final isLast = a == actions.last;
                return Padding(
                  padding: EdgeInsets.only(left: isLast ? 6 : 0),
                  child: _ActionButton(
                    action: a,
                    onTap: () => _run(a),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'Đã hoàn thành',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final RecommendationAction action;
  final VoidCallback onTap;
  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: action.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 13, color: action.color),
              const SizedBox(width: 5),
              Text(
                action.label,
                style: TextStyle(
                  color: action.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── AI Reason card ─────────────────────────────────────────────────────────────

class _AiReasonCard extends StatefulWidget {
  final String reason;
  final bool isDark;
  const _AiReasonCard({required this.reason, required this.isDark});

  @override
  State<_AiReasonCard> createState() => _AiReasonCardState();
}

class _AiReasonCardState extends State<_AiReasonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isLong = widget.reason.length > 180;

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Color(0xFF6C47FF)),
              ),
              const SizedBox(width: 8),
              Text(
                'Đánh giá AI',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.reason,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Thu gọn' : 'Xem thêm',
                style: const TextStyle(
                  color: Color(0xFF6C47FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skills card ────────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  final List<String> skills;
  final bool isDark;
  const _SkillsCard({required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context) => _Card(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(icon: Icons.code_rounded, title: 'Kỹ năng', isDark: isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2035)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF374151),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}

// ── Questions card ─────────────────────────────────────────────────────────────

class _QuestionsCard extends StatefulWidget {
  final List<QuestionScore> scores;
  final bool isDark;
  const _QuestionsCard({required this.scores, required this.isDark});

  @override
  State<_QuestionsCard> createState() => _QuestionsCardState();
}

class _QuestionsCardState extends State<_QuestionsCard> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.quiz_outlined,
            title: 'Điểm từng câu hỏi',
            isDark: isDark,
            trailing: Text(
              '${widget.scores.length} câu',
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          ...widget.scores.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isOpen = _open == i;

            return GestureDetector(
              onTap: () => setState(() => _open = isOpen ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isOpen
                      ? s.categoryColor.withValues(alpha: 0.06)
                      : isDark
                          ? const Color(0xFF1A2035)
                          : const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(10),
                  border: isOpen
                      ? Border.all(
                          color: s.categoryColor.withValues(alpha: 0.25))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Category dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Question text
                          Expanded(
                            child: Text(
                              s.questionText,
                              maxLines: isOpen ? null : 2,
                              overflow: isOpen ? null : TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Score
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: s.scoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${s.score.round()}%',
                              style: TextStyle(
                                color: s.scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isOpen
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                    if (isOpen) ...[
                      Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: isDark
                            ? const Color(0xFF2A3350)
                            : const Color(0xFFE5E7EB),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _QuestionDetail(score: s, isDark: isDark),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuestionDetail extends StatelessWidget {
  final QuestionScore score;
  final bool isDark;
  const _QuestionDetail({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (score.answerText != null && score.answerText!.isNotEmpty) ...[
          Text('Câu trả lời',
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(score.answerText!,
              style: TextStyle(
                  color: textColor, fontSize: 12, height: 1.5)),
          const SizedBox(height: 10),
        ],
        if (score.feedback != null && score.feedback!.isNotEmpty) ...[
          Text('Nhận xét AI',
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(score.feedback!,
              style: TextStyle(
                  color: textColor, fontSize: 12, height: 1.5)),
          const SizedBox(height: 10),
        ],
        if (score.strengths.isNotEmpty) ...[
          Text('Điểm mạnh',
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          ...score.strengths.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Expanded(
                        child: Text(t,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                height: 1.4))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],
        if (score.improvements.isNotEmpty) ...[
          Text('Cần cải thiện',
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          ...score.improvements.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.north_rounded,
                        size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    Expanded(
                        child: Text(t,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget? trailing;
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 15,
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      );
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorState({required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded,
                size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text('Không tìm thấy thông tin ứng viên.',
                style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF)),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
}
