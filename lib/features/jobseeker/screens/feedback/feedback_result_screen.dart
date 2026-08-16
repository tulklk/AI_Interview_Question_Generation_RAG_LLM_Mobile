import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/grid_background.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../hr_generate/data/generation_api.dart';
import '../../../subscription/payment/upgrade_payment_sheet.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/candidate_subscription_provider.dart';
import '../../../../core/widgets/app_skeleton.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF6C47FF);
const _kGold    = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF10B981);
const _kRed     = Color(0xFFEF4444);

// ── Theme palette ─────────────────────────────────────────────────────────────

class _C {
  final Color bg;
  final Color card;
  final Color surface;
  final Color border;
  final Color innerBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color divider;
  final Color ringTrack;
  final Color chipBg;

  const _C._({
    required this.bg,
    required this.card,
    required this.surface,
    required this.border,
    required this.innerBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.divider,
    required this.ringTrack,
    required this.chipBg,
  });

  factory _C.of(bool isDark) => isDark ? _dark : _light;

  static const _dark = _C._(
    bg:            Color(0xFF080B14),
    card:          Color(0xFF0D1117),
    surface:       AppColors.darkCard,
    border:        AppColors.darkChip,
    innerBorder:   AppColors.darkCardBorder,
    primaryText:   Colors.white,
    secondaryText: Color(0xFF9CAAC4),
    mutedText:     Color(0xFF4A5578),
    divider:       AppColors.darkChip,
    ringTrack:     AppColors.darkCardBorder,
    chipBg:        AppColors.darkCard,
  );

  static const _light = _C._(
    bg:            AppColors.surfaceLight,
    card:          Colors.white,
    surface:       AppColors.gray100,
    border:        AppColors.gray200,
    innerBorder:   Color(0xFFE5E7EB),
    primaryText:   AppColors.nearBlack,
    secondaryText: Color(0xFF6B7280),
    mutedText:     Color(0xFF9CA3AF),
    divider:       AppColors.gray200,
    ringTrack:     Color(0xFFE5E7EB),
    chipBg:        AppColors.gray100,
  );
}

// ── FeedbackResultScreen ──────────────────────────────────────────────────────

class FeedbackResultScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const FeedbackResultScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FeedbackResultScreen> createState() =>
      _FeedbackResultScreenState();
}

class _FeedbackResultScreenState extends ConsumerState<FeedbackResultScreen>
    with SingleTickerProviderStateMixin {
  // ── Data state ──────────────────────────────────────────────────────────────
  PracticeSessionDetail? _session;
  SessionFeedback?       _feedback;

  bool    _loading    = true;
  bool    _scoring    = false;
  bool    _error      = false;
  String? _errorMsg;
  bool    _refetching = false;

  // ── Score poll ──────────────────────────────────────────────────────────────
  Timer? _pollTimer;
  int    _pollAttempts = 0;
  static const _maxAttempts  = 8;
  static const _pollInterval = Duration(milliseconds: 3000);

  // ── Score animation ─────────────────────────────────────────────────────────
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Loading ──────────────────────────────────────────────────────────────────

  Future<void> _loadData({bool refetch = false}) async {
    if (refetch) {
      setState(() => _refetching = true);
    } else {
      setState(() { _loading = true; _error = false; });
    }
    try {
      final results = await Future.wait([_fetchSession(), _fetchFeedback()]);
      if (!mounted) return;
      setState(() {
        _session    = results[0] as PracticeSessionDetail?;
        _feedback   = results[1] as SessionFeedback?;
        _loading    = false;
        _refetching = false;
        _error      = false;
      });
      if (_session?.overallScore == null) {
        setState(() => _scoring = true);
        _startPolling();
      } else {
        _ringCtrl..reset()..forward();
        if (!refetch) {
          Future.delayed(const Duration(milliseconds: 1500), _checkRating);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading    = false;
          _refetching = false;
          _error      = true;
          _errorMsg   = e.toString();
        });
      }
    }
  }

  Future<PracticeSessionDetail?> _fetchSession() async {
    final dio = buildGenerationDio();
    final res = await dio.get('/api/candidate/practice-sessions/${widget.sessionId}');
    final data = res.data;
    if (data == null) return null;
    return PracticeSessionDetail.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<SessionFeedback?> _fetchFeedback() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/candidate/practice-sessions/${widget.sessionId}/feedback');
      final data = res.data;
      if (data == null) return null;
      return SessionFeedback.fromJson(data is Map<String, dynamic> ? data : {});
    } catch (_) {
      return null;
    }
  }

  // ── Polling ──────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer = Timer(_pollInterval, () async {
      if (!mounted) return;
      if (_pollAttempts >= _maxAttempts) {
        setState(() => _scoring = false);
        return;
      }
      _pollAttempts++;
      try {
        final session = await _fetchSession();
        if (!mounted) return;
        setState(() => _session = session);
        if (session?.overallScore != null) {
          setState(() => _scoring = false);
          _ringCtrl..reset()..forward();
          Future.delayed(const Duration(milliseconds: 1500), _checkRating);
        } else {
          _schedulePoll();
        }
      } catch (_) {
        if (mounted) _schedulePoll();
      }
    });
  }

  // ── Rating ───────────────────────────────────────────────────────────────────

  Future<void> _checkRating() async {
    if (!mounted) return;
    final setId = _session?.questionSetId;
    if (setId == null || setId.isEmpty) return;
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/question-sets/$setId/feedback/me');
      final data = res.data;
      final alreadyRated = data != null &&
          data is Map &&
          (data['data'] != null || data['rating'] != null);
      if (!alreadyRated && mounted) _showRatingDialog(setId);
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) == 404 && mounted) {
        _showRatingDialog(setId);
      }
    } catch (_) {}
  }

  void _showRatingDialog(String setId) {
    final l10n = context.l10n;
    int? selected;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: _kGold, size: 40),
                const SizedBox(height: 12),
                Text(l10n.rateSession,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 8),
                Text(l10n.rateSessionBody,
                    style: TextStyle(
                        color: isDark ? const Color(0xFF9CAAC4) : const Color(0xFF6B7280),
                        fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setSt(() => selected = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          selected != null && star <= selected!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: _kGold,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.skipRating,
                          style: const TextStyle(color: _kPrimary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: selected == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              try {
                                final dio = buildGenerationDio();
                                await dio.post(
                                  '/api/question-sets/$setId/feedback',
                                  data: {'rating': selected},
                                );
                              } catch (_) {}
                            },
                      style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(l10n.submitRating),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Upgrade ──────────────────────────────────────────────────────────────────

  Future<void> _startUpgrade() async {
    final notifier = ref.read(candidateSubscriptionProvider.notifier);
    try {
      final intent = await notifier.upgrade();
      if (!mounted || intent == null) return;
      final userId = ref.read(authProvider).user?.id ?? '';
      final config = PaymentWaitConfig(
        pollInterval:     kCandidatePollInterval,
        checkStatus:      (code) => notifier.checkOrderStatus(code),
        onPaidRefresh:    () async {
          await notifier.refresh();
          if (mounted) await _loadData(refetch: true);
        },
        onCelebration:    (ctx) => notifier.maybeShowCelebration(ctx, userId: userId),
        onCreateNewOrder: () => notifier.upgrade(),
      );
      ref.read(navBarVisibleProvider.notifier).state = false;
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UpgradePaymentSheet(intent: intent, config: config),
      ).whenComplete(() {
        if (mounted) ref.read(navBarVisibleProvider.notifier).state = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.error)),
        );
      }
    }
  }

  // ── Gating (§4) ──────────────────────────────────────────────────────────────

  PracticeFeedbackAccessLevel get _accessLevel =>
      _feedback?.accessLevel ?? PracticeFeedbackAccessLevel.freeTeaser;

  bool _isLocked(AnswerEvaluation? fb) {
    final isFT = _accessLevel == PracticeFeedbackAccessLevel.freeTeaser;
    return (fb?.isLocked ?? false) ||
        (isFT &&
            !(fb?.isTeaser ?? false) &&
            !(fb != null && fb.evaluationStatus == 'Succeeded' && fb.score != null));
  }

  bool _isTeaser(AnswerEvaluation? fb, bool isLocked) {
    final isFT = _accessLevel == PracticeFeedbackAccessLevel.freeTeaser;
    return (fb?.isTeaser ?? false) ||
        (isFT && !isLocked && fb?.evaluationStatus == 'Succeeded');
  }

  bool _hasEval(AnswerEvaluation? fb, bool isLocked) =>
      !isLocked && fb != null && fb.evaluationStatus == 'Succeeded' && fb.score != null;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c      = _C.of(isDark);
    final l10n   = context.l10n;

    if (_loading) return FeedbackResultSkeleton(isDark: isDark);
    if (_error)   return _buildError(c, l10n);
    if (_session == null) return _buildNotFound(c, l10n);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(c, l10n),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadData(),
                    color: _kPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildScoreHeader(c, l10n, isDark),
                          const SizedBox(height: 14),
                          _buildInsightOrUpsell(c, l10n, isDark),
                          if (_accessLevel == PracticeFeedbackAccessLevel.full) ...[
                            const SizedBox(height: 14),
                            _buildRadarSection(c, l10n, isDark),
                            const SizedBox(height: 14),
                            _buildActionPlan(c, l10n, isDark),
                          ],
                          const SizedBox(height: 14),
                          _buildQASection(c, l10n, isDark),
                          const SizedBox(height: 14),
                          _buildFooterActions(c, l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_refetching)
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────────

  Widget _buildAppBar(_C c, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primaryText, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/jobseeker/history'),
          ),
          Expanded(
            child: Text(
              l10n.practiceResult,
              style: TextStyle(
                  color: c.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Score header ──────────────────────────────────────────────────────────────

  Widget _buildScoreHeader(_C c, AppLocalizations l10n, bool isDark) {
    final score      = _session?.overallScore;
    final scoreInt   = score?.round() ?? 0;
    final scoreColor = _scoreColor(scoreInt);
    final qCount     = _session!.questions.length;
    final answered   = _session!.questions
        .where((q) => q.answerText != null && q.answerText!.isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Score ring
          SizedBox(
            width: 150,
            height: 150,
            child: _scoring
                ? _buildScoringRing(c)
                : AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _RingPainter(
                        progress: CurvedAnimation(
                          parent: _ringCtrl,
                          curve: Curves.easeOutCubic,
                        ).value * (score != null ? score / 100.0 : 0.0),
                        trackColor: c.ringTrack,
                        fillColor: scoreColor,
                        strokeWidth: 11,
                      ),
                      child: Center(
                        child: score == null
                            ? Text('—',
                                style: TextStyle(color: c.mutedText, fontSize: 28, fontWeight: FontWeight.bold))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$scoreInt',
                                    style: TextStyle(
                                        color: scoreColor,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        height: 1),
                                  ),
                                  Text('/100',
                                      style: TextStyle(
                                          color: c.mutedText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          // Level badge
          if (_scoring)
            _scoringBadge(c, l10n)
          else if (score != null)
            _ScoreBadge(score: scoreInt, color: scoreColor, label: _scoreLevelLabel(scoreInt, l10n)),

          const SizedBox(height: 16),

          // Stats row — 2 or 3 metrics
          Row(
            children: [
              _ScoreStat(
                icon: Icons.quiz_outlined,
                label: l10n.questions,
                value: '$qCount',
                color: _kPrimary,
                c: c,
              ),
              _vDivider(c),
              _ScoreStat(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.answered,
                value: '$answered',
                color: _kGreen,
                c: c,
              ),
              if (score != null) ...[
                _vDivider(c),
                _ScoreStat(
                  icon: Icons.emoji_events_outlined,
                  label: l10n.scoreLabel,
                  value: '${scoreInt}%',
                  color: scoreColor,
                  c: c,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider(_C c) =>
      Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 8), color: c.divider);

  Widget _buildScoringRing(_C c) {
    return CustomPaint(
      painter: _RingPainter(
        progress: 0,
        trackColor: c.ringTrack,
        fillColor: _kPrimary,
        strokeWidth: 11,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoringBadge(_C c, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(l10n.aiScoring,
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return _kGreen;
    if (s >= 65) return _kPrimary;
    if (s >= 50) return _kGold;
    return _kRed;
  }

  String _scoreLevelLabel(int score, AppLocalizations l10n) {
    if (score >= 80) return l10n.excellent;
    if (score >= 65) return l10n.good;
    if (score >= 50) return l10n.fair;
    return l10n.needsWork;
  }

  // ── Insight / Upsell ─────────────────────────────────────────────────────────

  Widget _buildInsightOrUpsell(_C c, AppLocalizations l10n, bool isDark) {
    if (_accessLevel == PracticeFeedbackAccessLevel.full) {
      final insight = _feedback?.aiInsight;
      if (insight == null) return const SizedBox.shrink();
      return _InsightBox(insight: insight, c: c, isVi: l10n.isVi);
    }
    return _UpsellBox(l10n: l10n, c: c, onUpgrade: _startUpgrade);
  }

  // ── Radar + bars (Premium only) ───────────────────────────────────────────────

  Widget _buildRadarSection(_C c, AppLocalizations l10n, bool isDark) {
    final dims = _aggregateDimensions();
    if (dims.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      c: c,
      title: l10n.skillAnalysis,
      subtitle: l10n.skillAnalysisDesc,
      icon: Icons.radar_rounded,
      iconColor: _kPrimary,
      child: _SkillAnalysis(dims: dims, isDark: isDark, c: c),
    );
  }

  Map<String, double> _aggregateDimensions() {
    final fb = _feedback;
    if (fb == null) return {};
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final eval in fb.evaluations.values) {
      final dims = eval.dimensionScores;
      if (dims == null) continue;
      dims.forEach((k, v) {
        totals[k] = (totals[k] ?? 0) + v;
        counts[k] = (counts[k] ?? 0) + 1;
      });
    }
    final result = <String, double>{};
    totals.forEach((k, total) => result[k] = total / counts[k]!);
    return result;
  }

  // ── Action plan (Premium only) ────────────────────────────────────────────────

  Widget _buildActionPlan(_C c, AppLocalizations l10n, bool isDark) {
    final fb = _feedback;
    if (fb == null || fb.evaluations.isEmpty) return const SizedBox.shrink();

    final questions = _session!.questions;
    final weakest   = questions
        .map((q) => (q, fb.evaluations[q.id]))
        .where((pair) =>
            pair.$2 != null &&
            pair.$2!.evaluationStatus == 'Succeeded' &&
            pair.$2!.score != null &&
            !_isLocked(pair.$2))
        .toList()
      ..sort((a, b) => a.$2!.score!.compareTo(b.$2!.score!));

    final top3 = weakest.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      c: c,
      title: l10n.actionPlan,
      subtitle: l10n.actionPlanDesc,
      icon: Icons.lightbulb_rounded,
      iconColor: _kGold,
      child: Column(
        children: top3.indexed.map((pair) {
          final (i, item) = pair;
          final (q, eval) = item;
          return _ActionPlanItem(
            index:       i + 1,
            question:    q.question,
            score:       eval!.score!.round(),
            improvement: eval.improvements.isNotEmpty ? eval.improvements.first : null,
            c: c,
          );
        }).toList(),
      ),
    );
  }

  // ── Q&A section ───────────────────────────────────────────────────────────────

  Widget _buildQASection(_C c, AppLocalizations l10n, bool isDark) {
    final questions = _session!.questions;
    final fb        = _feedback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.list_alt_rounded, color: c.mutedText, size: 17),
          const SizedBox(width: 6),
          Text(l10n.questionReview,
              style: TextStyle(
                  color: c.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        ...questions.asMap().entries.map((entry) {
          final idx  = entry.key;
          final q    = entry.value;
          final eval = fb?.evaluations[q.id];
          final locked  = _isLocked(eval);
          final teaser  = _isTeaser(eval, locked);
          final hasEval = _hasEval(eval, locked);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QACard(
              index:     idx + 1,
              question:  q,
              eval:      eval,
              isLocked:  locked,
              isTeaser:  teaser,
              hasEval:   hasEval,
              onUpgrade: _startUpgrade,
              c:         c,
              l10n:      l10n,
            ),
          );
        }),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────

  Widget _buildFooterActions(_C c, AppLocalizations l10n) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.apps_rounded, size: 18),
      label: Text(l10n.practiceOtherSet),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kPrimary,
        side: BorderSide(color: _kPrimary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => context.go('/jobseeker'),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────────

  Widget _buildError(_C c, AppLocalizations l10n) => Scaffold(
    backgroundColor: c.bg,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: _kRed, size: 40),
          ),
          const SizedBox(height: 16),
          Text(l10n.error,
              style: TextStyle(
                  color: c.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_errorMsg ?? '',
              style: TextStyle(color: c.secondaryText, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
            style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _loadData,
          ),
        ]),
      ),
    ),
  );

  Widget _buildNotFound(_C c, AppLocalizations l10n) => Scaffold(
    backgroundColor: c.bg,
    body: Center(child: Text(l10n.sessionNotFound,
        style: TextStyle(color: c.secondaryText))),
  );
}

// ── Score ring painter ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  trackColor;
  final Color  fillColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap  = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = fillColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}

// ── Score badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int    score;
  final Color  color;
  final String label;

  const _ScoreBadge({required this.score, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final emoji = score >= 80 ? '🏆' : score >= 65 ? '⭐' : score >= 50 ? '💪' : '📈';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}

// ── Score stat chip ───────────────────────────────────────────────────────────

class _ScoreStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final _C       c;

  const _ScoreStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(color: c.mutedText, fontSize: 11)),
      ]),
    );
  }
}

// ── AI Insight box (Premium) ──────────────────────────────────────────────────

class _InsightBox extends StatelessWidget {
  final SessionAiInsight insight;
  final _C  c;
  final bool isVi;

  const _InsightBox({required this.insight, required this.c, required this.isVi});

  @override
  Widget build(BuildContext context) {
    final text   = isVi ? insight.vi : insight.en;
    final skills = isVi ? insight.skillsToImproveVi : insight.skillsToImproveEn;
    if (text.isEmpty && skills.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary.withValues(alpha: 0.08), _kPrimary.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: _kPrimary, size: 16),
          ),
          const SizedBox(width: 10),
          Text('AI Insight',
              style: TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: c.primaryText, height: 1.55, fontSize: 14)),
        ],
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
              ),
              child: Text(s,
                  style: const TextStyle(
                      color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ]),
    );
  }
}

// ── Freemium upsell ───────────────────────────────────────────────────────────

class _UpsellBox extends StatelessWidget {
  final AppLocalizations l10n;
  final _C c;
  final VoidCallback onUpgrade;

  const _UpsellBox({required this.l10n, required this.c, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0E0928)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kGold.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium_rounded, color: _kGold, size: 14),
            const SizedBox(width: 5),
            const Text('Premium',
                style: TextStyle(
                    color: _kGold, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 12),
        Text(l10n.freemiumUpsellHeadline,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(l10n.freemiumUpsellBody,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.55)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.lock_open_rounded, size: 17),
            label: Text(l10n.freemiumUpsellCta),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onUpgrade,
          ),
        ),
      ]),
    );
  }
}

// ── Skill analysis (radar + bars) ─────────────────────────────────────────────

class _SkillAnalysis extends StatelessWidget {
  final Map<String, double> dims;
  final bool isDark;
  final _C c;

  const _SkillAnalysis({required this.dims, required this.isDark, required this.c});

  @override
  Widget build(BuildContext context) {
    final keys   = dims.keys.toList();
    final values = dims.values.toList();

    // Always show bars; add radar only when ≥3 dimensions
    final Widget bars = Column(
      children: keys.indexed.map((pair) {
        final (i, k) = pair;
        final v = values[i];
        final barColor = v >= 80 ? _kGreen : v >= 60 ? _kPrimary : _kGold;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  k,
                  style: TextStyle(
                      color: c.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (v / 100).clamp(0.0, 1.0),
                    backgroundColor: c.ringTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text(
                  '${v.round()}',
                  style: TextStyle(
                      color: barColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (keys.length < 3) return bars;

    // Radar + bars
    final radarColor = isDark ? const Color(0xFF2A2260) : const Color(0xFFEDE9FE);
    final gridColor  = isDark ? const Color(0xFF2D3748) : const Color(0xFFDDD6FE);

    return Column(children: [
      SizedBox(
        height: 200,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle: TextStyle(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                fontSize: 7),
            radarBorderData: BorderSide(color: gridColor, width: 1.2),
            gridBorderData:  BorderSide(color: gridColor, width: 1.2),
            titleTextStyle: TextStyle(
                color: c.secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600),
            dataSets: [
              RadarDataSet(
                fillColor: radarColor,
                borderColor: _kPrimary,
                borderWidth: 2.5,
                entryRadius: 4,
                dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
              ),
            ],
            getTitle: (index, angle) {
              final label = keys[index % keys.length];
              return RadarChartTitle(
                text: label.length > 9 ? '${label.substring(0, 8)}…' : label,
                angle: angle,
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(height: 1, color: c.innerBorder),
      const SizedBox(height: 14),
      bars,
    ]);
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final _C       c;
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    iconColor;
  final Widget   child;

  const _SectionCard({
    required this.c,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: c.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.mutedText, fontSize: 11)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Action plan item ──────────────────────────────────────────────────────────

class _ActionPlanItem extends StatelessWidget {
  final int     index;
  final String  question;
  final int     score;
  final String? improvement;
  final _C      c;

  const _ActionPlanItem({
    required this.index,
    required this.question,
    required this.score,
    this.improvement,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = score >= 65 ? _kGold : _kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.innerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number with score ring
          Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text('$index',
                    style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ]),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: c.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                if (improvement != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: _kGold),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(improvement!,
                            style: TextStyle(
                                color: c.secondaryText,
                                fontSize: 12,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Score chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$score',
                style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ── Q&A Card ──────────────────────────────────────────────────────────────────

class _QACard extends StatelessWidget {
  final int                     index;
  final PracticeSessionQuestion question;
  final AnswerEvaluation?       eval;
  final bool                    isLocked;
  final bool                    isTeaser;
  final bool                    hasEval;
  final VoidCallback            onUpgrade;
  final _C                      c;
  final AppLocalizations        l10n;

  const _QACard({
    required this.index,
    required this.question,
    required this.eval,
    required this.isLocked,
    required this.isTeaser,
    required this.hasEval,
    required this.onUpgrade,
    required this.c,
    required this.l10n,
  });

  Color get _scoreColor {
    final s = eval?.score?.round() ?? 0;
    if (s >= 80) return _kGreen;
    if (s >= 65) return _kPrimary;
    if (s >= 50) return _kGold;
    return _kRed;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isTeaser
        ? _kPrimary.withValues(alpha: 0.4)
        : isLocked
            ? _kGold.withValues(alpha: 0.3)
            : c.border;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: _QIndex(index: index),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge row
              if (isTeaser || isLocked) ...[
                _badge(isTeaser, l10n),
                const SizedBox(height: 4),
              ],
              Text(
                question.question,
                style: TextStyle(
                    color: c.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasEval) ...[
                const SizedBox(height: 4),
                _ScoreChip(score: eval!.score!.round(), color: _scoreColor),
              ],
            ],
          ),
          children: [
            const SizedBox(height: 4),
            if (isLocked)
              _LockedBlock(l10n: l10n, onUpgrade: onUpgrade, c: c)
            else if (hasEval)
              _EvalContent(eval: eval!, c: c, l10n: l10n)
            else
              Text(
                eval == null ? l10n.loadingFeedback : eval!.evaluationStatus,
                style: TextStyle(color: c.mutedText, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool isTeaser, AppLocalizations l10n) {
    final color = isTeaser ? _kPrimary : _kGold;
    final label = isTeaser ? l10n.freemiumTeaserBadge : l10n.freemiumLockedBadge;
    final icon  = isTeaser ? Icons.visibility_rounded : Icons.lock_rounded;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
    ]);
  }
}

class _QIndex extends StatelessWidget {
  final int index;
  const _QIndex({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text('$index',
            style: const TextStyle(
                color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int   score;
  final Color color;
  const _ScoreChip({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text('$score / 100',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ── Locked block ──────────────────────────────────────────────────────────────

class _LockedBlock extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback     onUpgrade;
  final _C               c;

  const _LockedBlock({required this.l10n, required this.onUpgrade, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGold.withValues(alpha: 0.06), _kPrimary.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.lock_rounded, color: _kGold, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.freemiumLockedTitle,
                style: const TextStyle(
                    color: _kGold, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(l10n.freemiumLockedHint,
            style: TextStyle(color: c.secondaryText, fontSize: 12, height: 1.5)),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.workspace_premium_rounded, size: 15),
          label: Text(l10n.freemiumUpsellCta, style: const TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onUpgrade,
        ),
      ]),
    );
  }
}

// ── Eval content ──────────────────────────────────────────────────────────────

class _EvalContent extends StatelessWidget {
  final AnswerEvaluation eval;
  final _C               c;
  final AppLocalizations l10n;

  const _EvalContent({required this.eval, required this.c, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answer text
        if (eval.answerText != null && eval.answerText!.isNotEmpty) ...[
          _evalSectionLabel(
            icon: Icons.person_outline_rounded,
            label: l10n.yourAnswer,
            color: c.secondaryText,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.innerBorder),
            ),
            child: Text(eval.answerText!,
                style: TextStyle(color: c.primaryText, fontSize: 13, height: 1.55)),
          ),
          const SizedBox(height: 12),
        ],

        // Strengths
        if (eval.strengths.isNotEmpty) ...[
          _evalSectionLabel(
            icon: Icons.thumb_up_outlined,
            label: l10n.strengths,
            color: _kGreen,
          ),
          const SizedBox(height: 6),
          ...eval.strengths.map((s) => _bullet(s, _kGreen, c)),
          const SizedBox(height: 12),
        ],

        // Improvements
        if (eval.improvements.isNotEmpty) ...[
          _evalSectionLabel(
            icon: Icons.trending_up_rounded,
            label: l10n.areasToImprove_,
            color: _kRed,
          ),
          const SizedBox(height: 6),
          ...eval.improvements.map((s) => _bullet(s, _kRed, c)),
          const SizedBox(height: 12),
        ],

        // AI Suggestion
        if (eval.suggestion != null && eval.suggestion!.isNotEmpty) ...[
          _evalSectionLabel(
            icon: Icons.auto_awesome_outlined,
            label: l10n.aiSuggestion,
            color: _kPrimary,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
            ),
            child: Text(eval.suggestion!,
                style: TextStyle(color: c.primaryText, fontSize: 13, height: 1.55)),
          ),
        ],
      ],
    );
  }

  Widget _evalSectionLabel({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _bullet(String text, Color color, _C c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: c.primaryText, fontSize: 13, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
