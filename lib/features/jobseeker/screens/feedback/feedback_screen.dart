import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

const _kPrimary = Color(0xFF6C47FF);

// ── Theme colours ─────────────────────────────────────────────────────────────

class _FeedbackColors {
  final Color bg;
  final Color card;
  final Color surface;
  final Color border;
  final Color innerBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color answerText;
  final Color divider;
  final Color ringTrack;
  final Color radarBorder;
  final Color radarGrid;
  final Color radarTickText;
  final Color radarTitle;
  final Color barTrack;
  final Color expandIcon;

  const _FeedbackColors._({
    required this.bg,
    required this.card,
    required this.surface,
    required this.border,
    required this.innerBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.answerText,
    required this.divider,
    required this.ringTrack,
    required this.radarBorder,
    required this.radarGrid,
    required this.radarTickText,
    required this.radarTitle,
    required this.barTrack,
    required this.expandIcon,
  });

  factory _FeedbackColors.of(bool isDark) => isDark ? _dark : _light;

  static const _dark = _FeedbackColors._(
    bg:           Color(0xFF080B14),
    card:         Color(0xFF0D1117),
    surface:      Color(0xFF1A1F35),
    border:       Color(0xFF1E2640),
    innerBorder:  Color(0xFF2D3562),
    primaryText:  Colors.white,
    secondaryText: Color(0xFF6B7280),
    mutedText:    Color(0xFF9CA3AF),
    answerText:   Color(0xFFD1D5DB),
    divider:      Color(0xFF1E2640),
    ringTrack:    Color(0xFF2D3562),
    radarBorder:  Color(0xFF2D3562),
    radarGrid:    Color(0xFF1E2640),
    radarTickText: Color(0xFF2D3562),
    radarTitle:   Color(0xFF6B7280),
    barTrack:     Color(0xFF2D3562),
    expandIcon:   Color(0xFF4A5578),
  );

  static const _light = _FeedbackColors._(
    bg:           Color(0xFFF8FAFC),
    card:         Colors.white,
    surface:      Color(0xFFF1F5F9),
    border:       Color(0xFFE5E7EB),
    innerBorder:  Color(0xFFD1D5DB),
    primaryText:  Color(0xFF111827),
    secondaryText: Color(0xFF6B7280),
    mutedText:    Color(0xFF9CA3AF),
    answerText:   Color(0xFF374151),
    divider:      Color(0xFFE5E7EB),
    ringTrack:    Color(0xFFE5E7EB),
    radarBorder:  Color(0xFFD1D5DB),
    radarGrid:    Color(0xFFE5E7EB),
    radarTickText: Color(0xFFD1D5DB),
    radarTitle:   Color(0xFF9CA3AF),
    barTrack:     Color(0xFFE5E7EB),
    expandIcon:   Color(0xFF9CA3AF),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FeedbackScreen extends ConsumerWidget {
  final String setId;
  const FeedbackScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n   = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c      = _FeedbackColors.of(isDark);
    final async  = ref.watch(feedbackProvider(setId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: c.bg,
        appBar: _buildAppBar(context, l10n, c),
        body: const Center(
          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: c.bg,
        appBar: _buildAppBar(context, l10n, c),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải kết quả',
                  style: TextStyle(
                      color: c.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(feedbackProvider(setId)),
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Thử lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (result) {
        if (result == null) {
          return Scaffold(
            backgroundColor: c.bg,
            appBar: _buildAppBar(context, l10n, c),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      size: 48, color: c.expandIcon),
                  const SizedBox(height: 16),
                  Text(
                    'Kết quả chưa sẵn sàng',
                    style: TextStyle(
                        color: c.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phiên luyện tập chưa được hoàn thành hoặc đang được xử lý.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.mutedText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => ref.invalidate(feedbackProvider(setId)),
                    child: const Text('Thử lại'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/jobseeker/history'),
                    child: Text(l10n.backToHistory),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: c.bg,
          appBar: _buildAppBar(context, l10n, c),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreHeader(result: result, setId: setId, l10n: l10n, colors: c)
                    .animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 28),

                if (result.skillStats.isNotEmpty) ...[
                  _SectionHeading(title: l10n.skillBreakdown, colors: c)
                      .animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 12),
                  _SkillBreakdown(stats: result.skillStats, colors: c)
                      .animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 28),
                ],

                if (result.questionFeedbacks.isNotEmpty) ...[
                  _SectionHeading(title: l10n.questionReview, colors: c)
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  _QAReview(
                          feedbacks: result.questionFeedbacks,
                          l10n: l10n,
                          colors: c)
                      .animate().fadeIn(delay: 240.ms),
                  const SizedBox(height: 24),
                ],

                GestureDetector(
                  onTap: () => context.go('/jobseeker/history'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          size: 15, color: _kPrimary),
                      const SizedBox(width: 4),
                      Text(
                        l10n.backToHistory,
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n,
      _FeedbackColors c) {
    return AppBar(
      backgroundColor: c.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.aiFeedbackTitle,
        style: TextStyle(
            color: c.primaryText, fontSize: 17, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: c.mutedText),
        onPressed: () => context.go('/jobseeker/history'),
      ),
    );
  }
}

// ── Score Header ──────────────────────────────────────────────────────────────

class _ScoreHeader extends StatefulWidget {
  final FeedbackResult result;
  final String setId;
  final AppLocalizations l10n;
  final _FeedbackColors colors;

  const _ScoreHeader({
    required this.result,
    required this.setId,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_ScoreHeader> createState() => _ScoreHeaderState();
}

class _ScoreHeaderState extends State<_ScoreHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r    = widget.result;
    final l10n = widget.l10n;
    final c    = widget.colors;
    final sc   = scoreColor(r.overallScore);
    final level = scoreLevel(r.overallScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Score ring ──────────────────────────────────────────────────────
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _ScoreRingPainter(
                  progress: _anim.value * r.overallScore / 100,
                  color: sc,
                  trackColor: c.ringTrack,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.overallScore}',
                        style: TextStyle(
                            color: sc,
                            fontSize: 32,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '/ 100',
                        style:
                            TextStyle(color: c.secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Title + level pill ──────────────────────────────────────────────
          Text(
            l10n.overallScore,
            style: TextStyle(
                color: c.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: sc.withValues(alpha: 0.35)),
            ),
            child: Text(
              level,
              style: TextStyle(
                  color: sc, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),

          // ── Company badge ───────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: r.companyColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    r.companyInitials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  r.setTitle.isNotEmpty
                      ? '${r.setTitle} · ${r.company}'
                      : r.company,
                  style: TextStyle(color: c.secondaryText, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── AI insight box ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.innerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: _kPrimary),
                    const SizedBox(width: 5),
                    Text(
                      l10n.aiInsight,
                      style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiInsightForScore(r.overallScore),
                  style: TextStyle(
                      color: c.answerText, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Action buttons ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.go('/jobseeker/practice/${widget.setId}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.practiceAgain,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondaryText,
                    side: BorderSide(color: c.innerBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.shareResult,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Score ring painter ────────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = (size.width - 20) / 2;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    canvas.drawArc(
      rect,
      -3.14159 / 2,
      3.14159 * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -3.14159 / 2,
        3.14159 * 2 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}

// ── Skill Breakdown ───────────────────────────────────────────────────────────

class _SkillBreakdown extends StatelessWidget {
  final List<SkillStat> stats;
  final _FeedbackColors colors;
  const _SkillBreakdown({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c      = colors;
    final isWide = MediaQuery.of(context).size.width > 680;

    final radarWidget = Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: TextStyle(color: c.radarTickText, fontSize: 8),
          radarBorderData: BorderSide(color: c.radarBorder),
          gridBorderData: BorderSide(color: c.radarGrid),
          titleTextStyle: TextStyle(
              color: c.radarTitle, fontSize: 9, fontWeight: FontWeight.w600),
          dataSets: [
            RadarDataSet(
              fillColor: _kPrimary.withValues(alpha: 0.15),
              borderColor: _kPrimary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: stats
                  .map((s) => RadarEntry(value: s.score.toDouble()))
                  .toList(),
            ),
          ],
          getTitle: (index, angle) =>
              RadarChartTitle(text: stats[index].skill, angle: angle),
        ),
      ),
    );

    final barsWidget = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: stats.map((s) {
          final barColor = s.score >= 85
              ? const Color(0xFF10B981)
              : s.score >= 70
                  ? _kPrimary
                  : const Color(0xFFF59E0B);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.skill,
                        style: TextStyle(color: c.mutedText, fontSize: 12)),
                    Text(
                      '${s.score}%',
                      style: TextStyle(
                          color: barColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: s.score / (s.fullMark > 0 ? s.fullMark : 100),
                    backgroundColor: c.barTrack,
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: radarWidget),
          const SizedBox(width: 14),
          Expanded(child: barsWidget),
        ],
      );
    }

    return Column(
      children: [radarWidget, const SizedBox(height: 14), barsWidget],
    );
  }
}

// ── Q&A Review ────────────────────────────────────────────────────────────────

class _QAReview extends StatefulWidget {
  final List<QuestionFeedback> feedbacks;
  final AppLocalizations l10n;
  final _FeedbackColors colors;

  const _QAReview({
    required this.feedbacks,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_QAReview> createState() => _QAReviewState();
}

class _QAReviewState extends State<_QAReview> {
  int? _expanded = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final c    = widget.colors;

    return Column(
      children: widget.feedbacks.asMap().entries.map((e) {
        final i     = e.key;
        final a     = e.value;
        final isOpen = _expanded == i;
        final sc    = scoreColor(a.score);
        final catColor = categoryColor(a.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                // ── Collapsed header row ──────────────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _expanded = isOpen ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _MiniPill(
                            label: categoryLabel(a.category),
                            color: catColor),
                        const SizedBox(width: 6),
                        Text(
                          'Q${i + 1}',
                          style: TextStyle(
                              color: c.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.questionText,
                            style: TextStyle(
                                color: c.answerText, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${a.score}/100',
                            style: TextStyle(
                                color: sc,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: c.expandIcon,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expanded detail ───────────────────────────────────────────
                if (isOpen) ...[
                  Divider(height: 1, color: c.divider),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReviewLabel(label: l10n.yourAnswer, colors: c),
                        const SizedBox(height: 6),
                        Text(
                          a.answerText,
                          style: TextStyle(
                              color: c.answerText,
                              fontSize: 13,
                              height: 1.6),
                        ),
                        if (a.strengths.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ReviewLabel(
                              label: l10n.strengths,
                              color: const Color(0xFF10B981),
                              colors: c),
                          const SizedBox(height: 6),
                          ...a.strengths.map((s) => _BulletItem(
                              text: s, color: const Color(0xFF10B981))),
                        ],
                        if (a.improvements.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ReviewLabel(
                              label: l10n.areasToImprove_,
                              color: const Color(0xFFF59E0B),
                              colors: c),
                          const SizedBox(height: 6),
                          ...a.improvements.map((s) => _BulletItem(
                              text: s, color: const Color(0xFFF59E0B))),
                        ],
                        if (a.suggestion.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ReviewLabel(
                              label: l10n.aiSuggestion, colors: c),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _kPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              a.suggestion,
                              style: TextStyle(
                                  color: c.answerText,
                                  fontSize: 13,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final String title;
  final _FeedbackColors colors;
  const _SectionHeading({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          color: colors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w700),
    );
  }
}

class _ReviewLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final _FeedbackColors colors;
  const _ReviewLabel(
      {required this.label, this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color ?? colors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
