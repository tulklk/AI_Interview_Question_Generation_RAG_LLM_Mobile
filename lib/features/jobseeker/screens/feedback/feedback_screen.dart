import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';

const _kBg     = Color(0xFF080B14);
const _kCard   = Color(0xFF0D1117);
const _kBorder = Color(0xFF1E2640);
const _kSurface = Color(0xFF1A1F35);

class FeedbackScreen extends StatelessWidget {
  final String setId;
  const FeedbackScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context) {
    final session = findSessionForResult(setId);
    final l10n = context.l10n;

    if (session == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          title: Text(l10n.aiFeedbackTitle,
              style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.go('/jobseeker/history'),
          ),
        ),
        body: Center(
          child: Text('No session found',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.aiFeedbackTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF9CA3AF)),
          onPressed: () => context.go('/jobseeker/history'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 8.1 Score header
            _ScoreHeader(session: session, setId: setId, l10n: l10n)
                .animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),

            // 8.2 Skill breakdown
            _SectionHeading(title: l10n.skillBreakdown)
                .animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 12),
            _SkillBreakdown()
                .animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 28),

            // 8.3 Question-by-question review
            if (session.answers.isNotEmpty) ...[
              _SectionHeading(title: l10n.questionReview)
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              _QAReview(session: session, l10n: l10n)
                  .animate().fadeIn(delay: 240.ms),
              const SizedBox(height: 24),
            ],

            // Back link
            GestureDetector(
              onTap: () => context.go('/jobseeker/history'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 15, color: Color(0xFF6C47FF)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.backToHistory,
                    style: const TextStyle(
                      color: Color(0xFF6C47FF),
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
  }
}

// ── Score Header ──────────────────────────────────────────────────────────────

class _ScoreHeader extends StatefulWidget {
  final PracticeSession session;
  final String setId;
  final AppLocalizations l10n;

  const _ScoreHeader({
    required this.session,
    required this.setId,
    required this.l10n,
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
    final s = widget.session;
    final l10n = widget.l10n;
    final sc = scoreColor(s.score);
    final level = scoreLevel(s.score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          // Ring + score
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _ScoreRingPainter(
                  progress: _anim.value * s.score / 100,
                  color: sc,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${s.score}',
                        style: TextStyle(
                          color: sc,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        '/ 100',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            l10n.overallScore,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          // Level badge
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
                color: sc,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Set info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: s.companyColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    s.companyInitials,
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
                  '${s.setTitle} · ${s.company}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // AI Insight box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3562)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: Color(0xFF6C47FF)),
                    const SizedBox(width: 5),
                    Text(
                      l10n.aiInsight,
                      style: const TextStyle(
                        color: Color(0xFF6C47FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiInsightForScore(s.score),
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/jobseeker/practice/${widget.setId}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C47FF),
                    side: const BorderSide(color: Color(0xFF6C47FF)),
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
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFF2D3562)),
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

  const _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 20) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background
    canvas.drawArc(
      rect,
      -3.14159 / 2,
      3.14159 * 2,
      false,
      Paint()
        ..color = const Color(0xFF2D3562)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Progress
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
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ── Skill Breakdown ───────────────────────────────────────────────────────────

class _SkillBreakdown extends StatelessWidget {
  const _SkillBreakdown();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 680;

    final radarWidget = Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(
              color: Color(0xFF2D3562), fontSize: 8),
          radarBorderData: const BorderSide(color: Color(0xFF2D3562)),
          gridBorderData: const BorderSide(color: Color(0xFF1E2640)),
          titleTextStyle: const TextStyle(
              color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.w600),
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF6C47FF).withValues(alpha: 0.15),
              borderColor: const Color(0xFF6C47FF),
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: skillRadarData
                  .map((s) => RadarEntry(value: s.score.toDouble()))
                  .toList(),
            ),
          ],
          getTitle: (index, angle) => RadarChartTitle(
            text: skillRadarData[index].skill,
            angle: angle,
          ),
        ),
      ),
    );

    final barsWidget = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: skillRadarData.asMap().entries.map((e) {
          final s = e.value;
          Color barColor;
          if (s.score >= 85) {
            barColor = const Color(0xFF10B981);
          } else if (s.score >= 70) {
            barColor = const Color(0xFF6C47FF);
          } else {
            barColor = const Color(0xFFF59E0B);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.skill,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                    Text(
                      '${s.score}%',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: s.score / 100,
                    backgroundColor: const Color(0xFF2D3562),
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
      children: [
        radarWidget,
        const SizedBox(height: 14),
        barsWidget,
      ],
    );
  }
}

// ── Q&A Review ────────────────────────────────────────────────────────────────

class _QAReview extends StatefulWidget {
  final PracticeSession session;
  final AppLocalizations l10n;

  const _QAReview({required this.session, required this.l10n});

  @override
  State<_QAReview> createState() => _QAReviewState();
}

class _QAReviewState extends State<_QAReview> {
  int? _expanded = 0;

  @override
  Widget build(BuildContext context) {
    final answers = widget.session.answers;
    final l10n = widget.l10n;

    return Column(
      children: answers.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value;
        final isOpen = _expanded == i;
        final sc = scoreColor(a.aiScore);
        final catColor = categoryColor(a.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                // Header
                GestureDetector(
                  onTap: () =>
                      setState(() => _expanded = isOpen ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Category pill
                        _MiniPill(
                            label: categoryLabel(a.category),
                            color: catColor),
                        const SizedBox(width: 6),
                        // Q number
                        Text(
                          'Q${i + 1}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.questionText,
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Score badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${a.aiScore}/100',
                            style: TextStyle(
                              color: sc,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: const Color(0xFF4A5578),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                if (isOpen) ...[
                  const Divider(height: 1, color: Color(0xFF1E2640)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Your answer
                        _ReviewLabel(label: l10n.yourAnswer),
                        const SizedBox(height: 6),
                        Text(
                          a.answer,
                          style: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Strengths
                        _ReviewLabel(label: l10n.strengths, color: const Color(0xFF10B981)),
                        const SizedBox(height: 6),
                        ...a.strengths.map((s) => _BulletItem(
                            text: s, color: const Color(0xFF10B981))),
                        const SizedBox(height: 14),

                        // Improvements
                        _ReviewLabel(label: l10n.areasToImprove_, color: const Color(0xFFF59E0B)),
                        const SizedBox(height: 6),
                        ...a.improvements.map((s) => _BulletItem(
                            text: s, color: const Color(0xFFF59E0B))),
                        const SizedBox(height: 14),

                        // AI Suggestion
                        _ReviewLabel(label: l10n.aiSuggestion),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6C47FF).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            a.suggestion,
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
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
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReviewLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _ReviewLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color ?? const Color(0xFF9CA3AF),
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
              style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
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
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
