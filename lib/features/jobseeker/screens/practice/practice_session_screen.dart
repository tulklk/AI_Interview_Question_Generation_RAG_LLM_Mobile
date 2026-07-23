import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

const _kPrimary = Color(0xFF6C47FF);

// ── Theme colours ─────────────────────────────────────────────────────────────

class _PracticeColors {
  final Color bg;
  final Color card;
  final Color border;
  final Color muted;
  final Color primaryText;
  final Color secondaryText;
  final Color dotInactive;
  final Color nextBtn;
  final Color nextBtnDisabled;
  final Color hintText;
  final Color submittedText;
  final Color dialogBg;
  final Color divider;

  const _PracticeColors._({
    required this.bg,
    required this.card,
    required this.border,
    required this.muted,
    required this.primaryText,
    required this.secondaryText,
    required this.dotInactive,
    required this.nextBtn,
    required this.nextBtnDisabled,
    required this.hintText,
    required this.submittedText,
    required this.dialogBg,
    required this.divider,
  });

  factory _PracticeColors.of(bool isDark) => isDark ? _dark : _light;

  static const _dark = _PracticeColors._(
    bg:               Color(0xFF080B14),
    card:             Color(0xFF0D1117),
    border:           Color(0xFF1E2640),
    muted:            Color(0xFF4A5578),
    primaryText:      Colors.white,
    secondaryText:    Color(0xFF9CAAC4),
    dotInactive:      Color(0xFF2D3562),
    nextBtn:          Color(0xFF1A1F35),
    nextBtnDisabled:  Color(0xFF111827),
    hintText:         Color(0xFF4A5578),
    submittedText:    Color(0xFFD1D5DB),
    dialogBg:         Color(0xFF1A1F35),
    divider:          Color(0xFF1E2640),
  );

  static const _light = _PracticeColors._(
    bg:               Color(0xFFF8FAFC),
    card:             Colors.white,
    border:           Color(0xFFE5E7EB),
    muted:            Color(0xFF9CA3AF),
    primaryText:      Color(0xFF111827),
    secondaryText:    Color(0xFF6B7280),
    dotInactive:      Color(0xFFD1D5DB),
    nextBtn:          Color(0xFFF3F4F6),
    nextBtnDisabled:  Color(0xFFE5E7EB),
    hintText:         Color(0xFF9CA3AF),
    submittedText:    Color(0xFF374151),
    dialogBg:         Colors.white,
    divider:          Color(0xFFE5E7EB),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String setId;
  const PracticeSessionScreen({super.key, required this.setId});

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState
    extends ConsumerState<PracticeSessionScreen> {
  Timer? _timer;
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final st = ref.read(practiceSessionProvider(widget.setId));
      if (!st.evaluating) {
        ref.read(practiceSessionProvider(widget.setId).notifier).tick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showExitDialog() {
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (_) => _ExitDialog(setId: widget.setId),
    ).then((_) => _exitDialogOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final colors  = _PracticeColors.of(isDark);
    final state   = ref.watch(practiceSessionProvider(widget.setId));
    final notifier = ref.read(practiceSessionProvider(widget.setId).notifier);
    final l10n    = context.l10n;

    // Navigate to result when session completes
    ref.listen<PracticeSessionState>(
      practiceSessionProvider(widget.setId),
      (prev, next) {
        if (next.isComplete && !(prev?.isComplete ?? false)) {
          context.go('/jobseeker/practice/${widget.setId}/result');
        }
      },
    );

    // Submit-error toast with Retry
    ref.listen<PracticeSessionState>(
      practiceSessionProvider(widget.setId),
      (prev, next) {
        if (next.submitError != null && prev?.submitError == null) {
          final qId = next.questions.isNotEmpty
              ? next.questions[next.currentIndex].id
              : '';
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(next.submitError!),
                backgroundColor: const Color(0xFFEF4444),
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Thử lại',
                  textColor: Colors.white,
                  onPressed: () => notifier.retrySubmit(qId),
                ),
              ),
            );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) notifier.clearSubmitError();
          });
        }
      },
    );

    // ── Loading ──────────────────────────────────────────────────────────────
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.bg,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: colors.secondaryText),
              onPressed: () => context.go('/jobseeker'),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                'Đang tải phiên luyện tập...',
                style: TextStyle(color: colors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (state.error != null) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 52, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải phiên luyện tập',
                  style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: notifier.retry,
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      label: const Text('Thử lại'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => context.go('/jobseeker'),
                      child: Text('Quay lại',
                          style: TextStyle(color: colors.muted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Empty questions guard ────────────────────────────────────────────────
    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Phiên không có câu hỏi.',
                  style: TextStyle(color: colors.muted)),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () => context.go('/jobseeker'),
                  child: const Text('Quay lại')),
            ],
          ),
        ),
      );
    }

    // ── Main practice UI ─────────────────────────────────────────────────────
    final questions   = state.questions;
    final currentQ    = questions[state.currentIndex.clamp(0, questions.length - 1)];
    final isSubmitted = state.submitted[currentQ.id] == true;
    final currentAnswer = state.answers[currentQ.id] ?? '';

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: _AppBarTitle(state: state, colors: colors),
        actions: [
          _TimerDisplay(timeLeft: state.timeLeft, colors: colors),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.secondaryText),
            onPressed: _showExitDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: _ProgressSection(
            current: state.currentIndex + 1,
            total: questions.length,
            l10n: l10n,
            colors: colors,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuestionCard(question: currentQ, colors: colors),
                  const SizedBox(height: 16),
                  if (state.evaluating)
                    _EvaluatingWidget(l10n: l10n, colors: colors)
                  else if (isSubmitted)
                    _SubmittedWidget(
                        answer: currentAnswer, l10n: l10n, colors: colors)
                  else
                    _AnswerInput(
                      key: ValueKey(currentQ.id),
                      questionId: currentQ.id,
                      initialValue: currentAnswer,
                      onChanged: (v) =>
                          notifier.updateAnswer(currentQ.id, v),
                      onSubmit: () => notifier.submitAnswer(currentQ.id),
                      l10n: l10n,
                      colors: colors,
                    ),
                ],
              ),
            ),
          ),
          _DotNavigator(
            questions: questions,
            currentIndex: state.currentIndex,
            submitted: state.submitted,
            onTap: notifier.goTo,
            colors: colors,
          ),
          _BottomBar(
            currentIndex: state.currentIndex,
            total: questions.length,
            allSubmitted: state.allSubmitted,
            isCompleting: state.isCompleting,
            setId: widget.setId,
            onPrevious: notifier.previous,
            onNext: notifier.next,
            onFinish: notifier.completeSession,
            l10n: l10n,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ── AppBar title ──────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final PracticeSessionState state;
  final _PracticeColors colors;
  const _AppBarTitle({required this.state, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('P',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phiên luyện tập',
                style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${state.questions.length} câu hỏi',
                style: TextStyle(
                    color: colors.secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Progress section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int current;
  final int total;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _ProgressSection({
    required this.current,
    required this.total,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total > 0 ? current / total : 0,
              backgroundColor: colors.border,
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.questionNofTotal(current, total),
            style:
                TextStyle(color: colors.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Timer ─────────────────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final int timeLeft;
  final _PracticeColors colors;
  const _TimerDisplay({required this.timeLeft, required this.colors});

  @override
  Widget build(BuildContext context) {
    final minutes = timeLeft ~/ 60;
    final seconds = timeLeft % 60;
    final label =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isRed = timeLeft < 300;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        style: TextStyle(
          color: isRed ? const Color(0xFFEF4444) : colors.primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final PracticeQuestion question;
  final _PracticeColors colors;
  const _QuestionCard({required this.question, required this.colors});

  @override
  Widget build(BuildContext context) {
    final catColor = categoryColor(question.category);
    final difColor = difficultyColor(question.difficulty);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: colors.bg == const Color(0xFFF8FAFC)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(label: categoryLabel(question.category), color: catColor),
              const SizedBox(width: 8),
              _Pill(
                  label: difficultyLabel(question.difficulty),
                  color: difColor),
            ],
          ),
          const SizedBox(height: 14),
          _QuestionText(text: question.text, colors: colors),
        ],
      ),
    );
  }
}

// ── Question text with code-block rendering ───────────────────────────────────

class _TextSegment {
  final bool isCode;
  final String content;
  final String? lang;
  const _TextSegment({required this.isCode, required this.content, this.lang});
}

List<_TextSegment> _parseQuestionText(String text) {
  final result = <_TextSegment>[];
  final re = RegExp(r'```(\w+)?\n?([\s\S]*?)```', multiLine: true);
  int lastEnd = 0;
  for (final match in re.allMatches(text)) {
    if (match.start > lastEnd) {
      result.add(_TextSegment(isCode: false, content: text.substring(lastEnd, match.start)));
    }
    result.add(_TextSegment(
      isCode: true,
      lang: match.group(1),
      content: (match.group(2) ?? '').trimRight(),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    result.add(_TextSegment(isCode: false, content: text.substring(lastEnd)));
  }
  return result.isEmpty ? [_TextSegment(isCode: false, content: text)] : result;
}

class _QuestionText extends StatelessWidget {
  final String text;
  final _PracticeColors colors;
  const _QuestionText({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    final segments = _parseQuestionText(text);
    final isDark = colors.bg == const Color(0xFF080B14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (seg.isCode) {
          return _CodeBlock(code: seg.content, lang: seg.lang, isDark: isDark, colors: colors);
        }
        final trimmed = seg.content.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            trimmed,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String? lang;
  final bool isDark;
  final _PracticeColors colors;
  const _CodeBlock({required this.code, this.lang, required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3562) : const Color(0xFF374151),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lang != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F35) : const Color(0xFF2D3748),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Text(
                lang!,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.65,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer input ──────────────────────────────────────────────────────────────

class _AnswerInput extends StatefulWidget {
  final String questionId;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _AnswerInput({
    super.key,
    required this.questionId,
    required this.initialValue,
    required this.onChanged,
    required this.onSubmit,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_AnswerInput> createState() => _AnswerInputState();
}

class _AnswerInputState extends State<_AnswerInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _ctrl.addListener(() {
      setState(() {});
      widget.onChanged(_ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c       = widget.colors;
    final len     = _ctrl.text.length;
    final isEmpty = _ctrl.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
            boxShadow: c.bg == const Color(0xFFF8FAFC)
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 8,
            minLines: 5,
            style: TextStyle(
                color: c.primaryText, fontSize: 14, height: 1.6),
            cursorColor: _kPrimary,
            decoration: InputDecoration(
              hintText: widget.l10n.answerPlaceholder,
              hintStyle:
                  TextStyle(color: c.hintText, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.l10n.charsCount(len) +
              (len >= 150 ? '' : widget.l10n.charsRecommended),
          style: TextStyle(
            color: len >= 150 ? const Color(0xFF10B981) : c.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: isEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)]),
              color: isEmpty ? c.nextBtn : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: isEmpty ? null : widget.onSubmit,
              icon: Icon(Icons.send_rounded,
                  size: 16, color: isEmpty ? c.muted : Colors.white),
              label: Text(
                widget.l10n.submitAnswer,
                style: TextStyle(
                  color: isEmpty ? c.muted : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Evaluating ────────────────────────────────────────────────────────────────

class _EvaluatingWidget extends StatelessWidget {
  final AppLocalizations l10n;
  final _PracticeColors colors;
  const _EvaluatingWidget({required this.l10n, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: _kPrimary, strokeWidth: 2.5),
            const SizedBox(height: 12),
            Text(
              l10n.evaluating_,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Submitted ─────────────────────────────────────────────────────────────────

class _SubmittedWidget extends StatelessWidget {
  final String answer;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _SubmittedWidget(
      {required this.answer, required this.l10n, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.answerSubmitted,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: TextStyle(
                color: colors.submittedText, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ── Question grid navigator ───────────────────────────────────────────────────

class _DotNavigator extends StatelessWidget {
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final Map<String, bool> submitted;
  final ValueChanged<int> onTap;
  final _PracticeColors colors;

  const _DotNavigator({
    required this.questions,
    required this.currentIndex,
    required this.submitted,
    required this.onTap,
    required this.colors,
  });

  static const _cellSize   = 36.0;
  static const _cellGap    = 6.0;

  @override
  Widget build(BuildContext context) {
    final doneCount    = submitted.values.where((v) => v).length;
    final pendingCount = questions.length - doneCount;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Legend row
          Row(
            children: [
              _LegendDot(color: _kPrimary,                   label: 'Đang làm'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFF10B981),     label: 'Đã làm ($doneCount)'),
              const SizedBox(width: 12),
              _LegendDot(color: colors.dotInactive,          label: 'Chưa làm ($pendingCount)'),
            ],
          ),
          const SizedBox(height: 8),
          // Grid
          Wrap(
            spacing: _cellGap,
            runSpacing: _cellGap,
            children: questions.asMap().entries.map((e) {
              final i         = e.key;
              final q         = e.value;
              final isCurrent = i == currentIndex;
              final isDone    = submitted[q.id] == true;

              final Color bgColor;
              final Color textColor;
              final bool hasBorder;

              if (isCurrent) {
                bgColor   = _kPrimary;
                textColor = Colors.white;
                hasBorder = false;
              } else if (isDone) {
                bgColor   = const Color(0xFF10B981).withValues(alpha: 0.15);
                textColor = const Color(0xFF10B981);
                hasBorder = false;
              } else {
                bgColor   = Colors.transparent;
                textColor = colors.muted;
                hasBorder = true;
              }

              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _cellSize,
                  height: _cellSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: hasBorder
                        ? Border.all(color: colors.dotInactive, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: isDone && !isCurrent
                        ? Icon(Icons.check_rounded,
                            size: 14, color: const Color(0xFF10B981))
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool allSubmitted;
  final bool isCompleting;
  final String setId;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function() onFinish;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _BottomBar({
    required this.currentIndex,
    required this.total,
    required this.allSubmitted,
    required this.isCompleting,
    required this.setId,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: currentIndex > 0 ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primaryText,
                disabledForegroundColor: c.muted,
                side: BorderSide(
                  color: currentIndex > 0 ? c.border : c.nextBtnDisabled,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.previous),
            ),
          ),
          const SizedBox(width: 12),
          if (allSubmitted) ...[
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleting
                        ? [const Color(0xFF4B2D9F), const Color(0xFF4B2D9F)]
                        : [const Color(0xFF7C3AED), const Color(0xFF6C47FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: isCompleting ? null : onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l10n.finishGetFeedback,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: currentIndex < total - 1 ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.nextBtn,
                  disabledBackgroundColor: c.nextBtnDisabled,
                  foregroundColor: c.primaryText,
                  disabledForegroundColor: c.muted,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(l10n.next),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Exit dialog ───────────────────────────────────────────────────────────────

class _ExitDialog extends StatelessWidget {
  final String setId;
  const _ExitDialog({required this.setId});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final colors  = _PracticeColors.of(isDark);
    final l10n    = context.l10n;

    return AlertDialog(
      backgroundColor: colors.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        l10n.exitPractice,
        style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
      content: Text(
        l10n.exitPracticeBody,
        style: TextStyle(
            color: colors.muted, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.stay,
              style: TextStyle(color: colors.muted)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/jobseeker/sets/$setId');
          },
          child: Text(
            l10n.exit,
            style: const TextStyle(
                color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ── Pill widget ───────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
