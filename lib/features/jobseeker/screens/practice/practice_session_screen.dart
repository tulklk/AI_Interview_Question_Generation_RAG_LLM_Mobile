import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

// Dark bg constants
const _kBg     = Color(0xFF080B14);
const _kCard   = Color(0xFF0D1117);
const _kBorder = Color(0xFF1E2640);
const _kPrimary = Color(0xFF6C47FF);
const _kMuted  = Color(0xFF4A5578);

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
      ref.read(practiceSessionProvider(widget.setId).notifier).tick();
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
    final set = findSetById(widget.setId);
    if (set == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Text('Set not found',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final state = ref.watch(practiceSessionProvider(widget.setId));
    final notifier = ref.read(practiceSessionProvider(widget.setId).notifier);
    final l10n = context.l10n;

    final questions = set.questions;
    if (questions.isEmpty) {
      return const Scaffold(backgroundColor: _kBg);
    }

    final currentQ = questions[state.currentIndex];
    final isSubmitted = state.submitted[currentQ.id] == true;
    final currentAnswer = state.answers[currentQ.id] ?? '';
    final timeLeft = state.timeLeft;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            // Company avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: set.companyColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  set.companyInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    set.company,
                    style: const TextStyle(
                      color: Color(0xFF9CAAC4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Timer
          _TimerDisplay(timeLeft: timeLeft),
          // Close / Exit
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CAAC4)),
            onPressed: _showExitDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: _ProgressSection(
            current: state.currentIndex + 1,
            total: questions.length,
            l10n: l10n,
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
                  // Question card
                  _QuestionCard(question: currentQ),
                  const SizedBox(height: 16),

                  // Answer area
                  if (state.evaluating)
                    _EvaluatingWidget(l10n: l10n)
                  else if (isSubmitted)
                    _SubmittedWidget(answer: currentAnswer, l10n: l10n)
                  else
                    _AnswerInput(
                      key: ValueKey(currentQ.id),
                      questionId: currentQ.id,
                      initialValue: currentAnswer,
                      onChanged: (v) => notifier.updateAnswer(currentQ.id, v),
                      onSubmit: () => notifier.submitAnswer(currentQ.id),
                      l10n: l10n,
                    ),
                ],
              ),
            ),
          ),

          // Dot navigator
          _DotNavigator(
            questions: questions,
            currentIndex: state.currentIndex,
            submitted: state.submitted,
            onTap: notifier.goTo,
          ),

          // Bottom nav bar
          _BottomBar(
            currentIndex: state.currentIndex,
            total: questions.length,
            allSubmitted: state.allSubmitted,
            setId: widget.setId,
            onPrevious: notifier.previous,
            onNext: notifier.next,
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}

// ── Progress section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int current;
  final int total;
  final AppLocalizations l10n;

  const _ProgressSection({
    required this.current,
    required this.total,
    required this.l10n,
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
              backgroundColor: _kBorder,
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.questionNofTotal(current, total),
            style: const TextStyle(color: Color(0xFF9CAAC4), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Timer ─────────────────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final int timeLeft;
  const _TimerDisplay({required this.timeLeft});

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
          color: isRed ? const Color(0xFFEF4444) : Colors.white,
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
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final catColor = categoryColor(question.category);
    final difColor = difficultyColor(question.difficulty);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(label: categoryLabel(question.category), color: catColor),
              const SizedBox(width: 8),
              _Pill(label: difficultyLabel(question.difficulty), color: difColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
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

  const _AnswerInput({
    super.key,
    required this.questionId,
    required this.initialValue,
    required this.onChanged,
    required this.onSubmit,
    required this.l10n,
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
    final len = _ctrl.text.length;
    final isEmpty = _ctrl.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
            cursorColor: _kPrimary,
            decoration: InputDecoration(
              hintText: widget.l10n.answerPlaceholder,
              hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Char counter
        Text(
          widget.l10n.charsCount(len) +
              (len >= 150 ? '' : widget.l10n.charsRecommended),
          style: TextStyle(
            color: len >= 150 ? const Color(0xFF10B981) : _kMuted,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 12),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: isEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)]),
              color: isEmpty ? const Color(0xFF1A1F35) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: isEmpty ? null : widget.onSubmit,
              icon: Icon(
                Icons.send_rounded,
                size: 16,
                color: isEmpty ? _kMuted : Colors.white,
              ),
              label: Text(
                widget.l10n.submitAnswer,
                style: TextStyle(
                  color: isEmpty ? _kMuted : Colors.white,
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
  const _EvaluatingWidget({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
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
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
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

  const _SubmittedWidget({required this.answer, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
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
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot navigator ─────────────────────────────────────────────────────────────

class _DotNavigator extends StatelessWidget {
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final Map<String, bool> submitted;
  final ValueChanged<int> onTap;

  const _DotNavigator({
    required this.questions,
    required this.currentIndex,
    required this.submitted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            final isCurrent = i == currentIndex;
            final isDone = submitted[q.id] == true;

            Color color;
            double width;
            double height = 10;

            if (isCurrent) {
              color = _kPrimary;
              width = 32;
            } else if (isDone) {
              color = const Color(0xFF10B981);
              width = 10;
            } else {
              color = const Color(0xFF2D3562);
              width = 10;
            }

            return GestureDetector(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool allSubmitted;
  final String setId;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final AppLocalizations l10n;

  const _BottomBar({
    required this.currentIndex,
    required this.total,
    required this.allSubmitted,
    required this.setId,
    required this.onPrevious,
    required this.onNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: OutlinedButton(
              onPressed: currentIndex > 0 ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: currentIndex > 0
                      ? const Color(0xFF2D3562)
                      : const Color(0xFF1A1F35),
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
            // Finish
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () =>
                      context.go('/jobseeker/practice/$setId/result'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    l10n.finishGetFeedback,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Next
            Expanded(
              child: ElevatedButton(
                onPressed:
                    currentIndex < total - 1 ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1F35),
                  disabledBackgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
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
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        l10n.exitPractice,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Text(
        l10n.exitPracticeBody,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.stay,
            style: const TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/jobseeker/sets/$setId');
          },
          child: Text(
            l10n.exit,
            style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
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
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
