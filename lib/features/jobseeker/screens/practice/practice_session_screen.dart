import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/grid_background.dart';
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
    border:           AppColors.darkChip,
    muted:            Color(0xFF4A5578),
    primaryText:      Colors.white,
    secondaryText:    Color(0xFF9CAAC4),
    dotInactive:      AppColors.darkCardBorder,
    nextBtn:          AppColors.darkCard,
    nextBtnDisabled:  AppColors.nearBlack,
    hintText:         Color(0xFF4A5578),
    submittedText:    Color(0xFFD1D5DB),
    dialogBg:         AppColors.darkCard,
    divider:          AppColors.darkChip,
  );

  static const _light = _PracticeColors._(
    bg:               AppColors.surfaceLight,
    card:             Colors.white,
    border:           AppColors.gray200,
    muted:            Color(0xFF9CA3AF),
    primaryText:      AppColors.nearBlack,
    secondaryText:    Color(0xFF6B7280),
    dotInactive:      Color(0xFFD1D5DB),
    nextBtn:          AppColors.gray100,
    nextBtnDisabled:  AppColors.gray200,
    hintText:         Color(0xFF9CA3AF),
    submittedText:    Color(0xFF374151),
    dialogBg:         Colors.white,
    divider:          AppColors.gray200,
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
      if (_exitDialogOpen) return; // freeze while exit confirm is open
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

  // ── Exit overlay (no showDialog — avoids Navigator lifecycle conflicts) ─────
  //
  // Root cause of all _ElementLifecycle.inactive crashes: showDialog pushes a
  // route onto the same Navigator that go_router manages. When context.go()
  // replaces the route stack, the navigator processes two operations at once
  // (dialog pop + page replacement) → elements activate/deactivate out of order.
  //
  // Fix: render the "dialog" as a Stack overlay INSIDE the practice screen's
  // own widget tree. context.go() then removes the entire screen (scaffold +
  // overlay) in one atomic operation — no navigator conflict.

  void _showExitDialog() {
    if (_exitDialogOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _exitDialogOpen = true);
  }

  void _closeExitDialog() {
    if (mounted) setState(() => _exitDialogOpen = false);
  }

  /// Close overlay first, then pop (or go fallback) on the next frame.
  void _leaveToSetDetail({required bool cancelSession}) {
    _timer?.cancel();
    _timer = null;
    if (_exitDialogOpen) setState(() => _exitDialogOpen = false);

    final router = GoRouter.of(context);
    final setId = widget.setId;
    final canPop = Navigator.of(context).canPop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (cancelSession) {
        ref.invalidate(inProgressSessionProvider(setId));
        ref.invalidate(allInProgressSessionsProvider);
      }
      if (canPop) {
        router.pop();
      } else {
        router.go('/jobseeker/sets/$setId');
      }
    });
  }

  void _handleSaveAndExit() => _leaveToSetDetail(cancelSession: false);

  void _handleCancelSession() => _leaveToSetDetail(cancelSession: true);

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final colors  = _PracticeColors.of(isDark);
    final state   = ref.watch(practiceSessionProvider(widget.setId));
    final notifier = ref.read(practiceSessionProvider(widget.setId).notifier);
    final l10n    = context.l10n;

    // Navigate to result when session completes.
    // Use serverSessionId (not setId) so the result screen can call
    // /practice-sessions/:sessionId/feedback directly — no extra lookup.
    ref.listen<PracticeSessionState>(
      practiceSessionProvider(widget.setId),
      (prev, next) {
        if (next.isComplete && !(prev?.isComplete ?? false)) {
          final sessionId = next.serverSessionId ?? widget.setId;
          context.go('/jobseeker/practice/$sessionId/result');
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

    // Stack-based overlay — see _showExitDialog() comment for why we avoid
    // showDialog here. Android back: if overlay is open → close it ("Ở lại");
    // otherwise → open it (never pop the route directly, spec §8 E1).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_exitDialogOpen) _closeExitDialog();
          else _showExitDialog();
        }
      },
      child: Stack(
        children: [
      Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: _AppBarTitle(setId: widget.setId, state: state, colors: colors),
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
      body: GridBackdrop(
        child: Column(
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
                        answer: currentAnswer,
                        isCode: currentQ.needsCodeAnswer,
                        l10n: l10n,
                        colors: colors)
                  else
                    _AnswerInput(
                      key: ValueKey(currentQ.id),
                      question: currentQ,
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
      ),
      ), // Scaffold — first child of Stack
          // ── Exit overlay ───────────────────────────────────────────────────
          if (_exitDialogOpen)
            _ExitOverlay(
              onStay: _closeExitDialog,
              onSaveAndExit: _handleSaveAndExit,
              onCancelSession: _handleCancelSession,
            ),
        ], // Stack children
      ), // Stack
    ); // PopScope
  }
}

// ── AppBar title ──────────────────────────────────────────────────────────────

class _AppBarTitle extends ConsumerWidget {
  final String setId;
  final PracticeSessionState state;
  final _PracticeColors colors;
  const _AppBarTitle({
    required this.setId,
    required this.state,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final set = ref.watch(setDetailProvider(setId)).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );
    final title = (set != null && set.title.trim().isNotEmpty)
        ? set.title
        : 'Phiên luyện tập';
    final logoUrl = set?.companyLogo;
    final initials = set?.companyInitials ?? 'P';
    final companyColor = set?.companyColor ?? _kPrimary;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 32,
            height: 32,
            child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _LogoFallback(
                      initials: initials,
                      color: companyColor,
                    ),
                  )
                : _LogoFallback(initials: initials, color: companyColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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

class _LogoFallback extends StatelessWidget {
  final String initials;
  final Color color;
  const _LogoFallback({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      color: color,
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials[0].toUpperCase() : 'P',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
    final catColor  = categoryColor(question.category);
    final difColor  = difficultyColor(question.difficulty);
    final isDark    = colors.bg == const Color(0xFF080B14);
    final hasSnippet = (question.codeSnippet?.trim().isNotEmpty ?? false);
    final isCode    = question.needsCodeAnswer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: colors.bg == AppColors.surfaceLight
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
              _Pill(label: difficultyLabel(question.difficulty), color: difColor),
              if (isCode) ...[
                const SizedBox(width: 8),
                _Pill(label: 'Code', color: const Color(0xFF06B6D4)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _QuestionText(text: question.text, colors: colors),
          // Code snippet block (only when not locked)
          if (hasSnippet && !question.isLocked) ...[
            const SizedBox(height: 12),
            _CodeSnippetView(
              snippet: question.codeSnippet!,
              lang: question.codeTemplateType?.toLowerCase(),
              isDark: isDark,
              colors: colors,
            ),
          ],
          // Attached image (only when not locked)
          if ((question.attachedImageUrl?.isNotEmpty ?? false) && !question.isLocked) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                question.attachedImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
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
          color: isDark ? AppColors.darkCardBorder : const Color(0xFF374151),
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
                color: isDark ? AppColors.darkCard : const Color(0xFF2D3748),
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
                color: AppColors.gray200,
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

// ── Code snippet display (read-only, horizontally scrollable) ─────────────────

class _CodeSnippetView extends StatelessWidget {
  final String snippet;
  final String? lang;
  final bool isDark;
  final _PracticeColors colors;

  const _CodeSnippetView({
    required this.snippet,
    this.lang,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeCodeEscapes(snippet);
    // Pick a readable label: "ĐỀ BÀI / {LANG}" matching web design
    final langLabel = lang != null && lang!.isNotEmpty
        ? 'ĐỀ BÀI / ${lang!.toUpperCase()}'
        : 'ĐỀ BÀI';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : const Color(0xFF374151),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : const Color(0xFF2D3748),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded,
                    size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                  langLabel,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable code body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              normalized,
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
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

// ── Answer input (branches on needsCodeAnswer) ────────────────────────────────

class _AnswerInput extends StatefulWidget {
  final PracticeQuestion question;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _AnswerInput({
    super.key,
    required this.question,
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
  String? _validationError;

  bool get _isCode => widget.question.needsCodeAnswer;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    _ctrl.addListener(() {
      setState(() {
        // Clear validation error as user types
        if (_validationError != null && _ctrl.text.trim().length >= kMinAnswerChars) {
          _validationError = null;
        }
      });
      widget.onChanged(_ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final errorKey = validateAnswerText(_ctrl.text, isCode: _isCode);
    if (errorKey != null) {
      setState(() {
        _validationError = errorKey == 'validationTooShort'
            ? widget.l10n.validationTooShort
            : widget.l10n.validationTooFewWords;
      });
      return;
    }
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    // Free-tier lock — show upsell block instead of input
    if (widget.question.isLocked && _isCode) {
      return _LockedCodeBlock(l10n: widget.l10n, colors: widget.colors);
    }

    return _isCode
        ? _CodeAnswerField(
            ctrl: _ctrl,
            validationError: _validationError,
            onSubmit: _handleSubmit,
            l10n: widget.l10n,
            colors: widget.colors,
          )
        : _TextAnswerField(
            ctrl: _ctrl,
            validationError: _validationError,
            onSubmit: _handleSubmit,
            l10n: widget.l10n,
            colors: widget.colors,
          );
  }
}

// ── Locked code block (Free-tier upsell) ─────────────────────────────────────

class _LockedCodeBlock extends StatelessWidget {
  final AppLocalizations l10n;
  final _PracticeColors colors;
  const _LockedCodeBlock({required this.l10n, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1040), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C5CFC).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 32),
          const SizedBox(height: 12),
          Text(
            l10n.lockedQuestionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.lockedQuestionBody,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/jobseeker/subscription'),
              icon: const Icon(Icons.workspace_premium_rounded,
                  size: 16, color: Colors.white),
              label: Text(
                l10n.upgradeToPremium,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text answer field ─────────────────────────────────────────────────────────

class _TextAnswerField extends StatelessWidget {
  final TextEditingController ctrl;
  final String? validationError;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _TextAnswerField({
    required this.ctrl,
    required this.validationError,
    required this.onSubmit,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c       = colors;
    final len     = ctrl.text.length;
    final isEmpty = ctrl.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: validationError != null
                  ? const Color(0xFFEF4444)
                  : c.border,
            ),
            boxShadow: c.bg == AppColors.surfaceLight
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
            controller: ctrl,
            maxLines: 8,
            minLines: 5,
            style: TextStyle(
                color: c.primaryText, fontSize: 14, height: 1.6),
            cursorColor: _kPrimary,
            decoration: InputDecoration(
              hintText: l10n.answerPlaceholder,
              hintStyle: TextStyle(color: c.hintText, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (validationError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              validationError!,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
        Text(
          l10n.charsCount(len) +
              (len >= 150 ? '' : l10n.charsRecommended),
          style: TextStyle(
            color: len >= 150 ? const Color(0xFF10B981) : c.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _SubmitButton(
          isEmpty: isEmpty,
          onSubmit: onSubmit,
          l10n: l10n,
          colors: c,
        ),
      ],
    );
  }
}

// ── Code answer field ─────────────────────────────────────────────────────────

class _CodeAnswerField extends StatefulWidget {
  final TextEditingController ctrl;
  final String? validationError;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _CodeAnswerField({
    required this.ctrl,
    required this.validationError,
    required this.onSubmit,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_CodeAnswerField> createState() => _CodeAnswerFieldState();
}

class _CodeAnswerFieldState extends State<_CodeAnswerField> {
  final _focusNode = FocusNode();

  static const _kToolbarSymbols = [
    '{', '}', '[', ']', '(', ')',
    '<', '>', ';', '=', '"', "'", '`',
  ];

  void _insertText(String s) {
    final ctrl   = widget.ctrl;
    final sel    = ctrl.selection;
    final text   = ctrl.text;
    final start  = sel.start.clamp(0, text.length);
    final end    = sel.end.clamp(0, text.length);
    final newText = text.replaceRange(start, end, s);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + s.length),
    );
  }

  void _insertTab() => _insertText('    ');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.colors;
    final isDark = c.bg == const Color(0xFF080B14);
    final len    = widget.ctrl.text.length;
    final isEmpty = widget.ctrl.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  size: 14, color: Color(0xFF06B6D4)),
              const SizedBox(width: 6),
              Text(
                widget.l10n.codeAnswerLabel,
                style: const TextStyle(
                  color: Color(0xFF06B6D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        // Code text field
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.validationError != null
                  ? const Color(0xFFEF4444)
                  : isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFF374151),
            ),
          ),
          child: Column(
            children: [
              // Keyboard toolbar
              _CodeKeyboardToolbar(
                isDark: isDark,
                symbols: _kToolbarSymbols,
                onSymbol: _insertText,
                onTab: _insertTab,
              ),
              // Text input
              TextField(
                controller: widget.ctrl,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 8,
                // ── Mobile keyboard hardening ──
                autocorrect: false,
                enableSuggestions: false,
                spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.multiline,
                // ── Style ──────────────────────
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.65,
                  letterSpacing: 0.2,
                ),
                cursorColor: const Color(0xFF06B6D4),
                decoration: InputDecoration(
                  hintText: widget.l10n.codeAnswerPlaceholder,
                  hintStyle: const TextStyle(
                    color: Color(0xFF4A5578),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    height: 1.65,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        if (widget.validationError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.validationError!,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
        Text(
          widget.l10n.charsCount(len),
          style: TextStyle(
            color: len >= kMinAnswerChars ? const Color(0xFF10B981) : c.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _SubmitButton(
          isEmpty: isEmpty,
          onSubmit: widget.onSubmit,
          l10n: widget.l10n,
          colors: c,
        ),
      ],
    );
  }
}

// ── Mobile keyboard toolbar for code symbols ──────────────────────────────────

class _CodeKeyboardToolbar extends StatelessWidget {
  final bool isDark;
  final List<String> symbols;
  final ValueChanged<String> onSymbol;
  final VoidCallback onTab;

  const _CodeKeyboardToolbar({
    required this.isDark,
    required this.symbols,
    required this.onSymbol,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? const Color(0xFF0D1117) : const Color(0xFF2D3748);
    final btnBg   = isDark ? const Color(0xFF1A2035) : const Color(0xFF374151);
    final btnText = const Color(0xFFD1D5DB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkCardBorder : const Color(0xFF4B5563),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Symbol buttons
            ...symbols.map((sym) => _ToolbarKey(
              label: sym,
              bg: btnBg,
              textColor: btnText,
              onTap: () => onSymbol(sym),
            )),
            const SizedBox(width: 6),
            // Tab button
            _ToolbarKey(
              label: '⇥ Tab',
              bg: btnBg,
              textColor: const Color(0xFF06B6D4),
              onTap: onTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarKey extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final VoidCallback onTap;
  const _ToolbarKey({
    required this.label,
    required this.bg,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Shared submit button ──────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isEmpty;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _SubmitButton({
    required this.isEmpty,
    required this.onSubmit,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return SizedBox(
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
          onPressed: isEmpty ? null : onSubmit,
          icon: Icon(Icons.send_rounded,
              size: 16, color: isEmpty ? c.muted : Colors.white),
          label: Text(
            l10n.submitAnswer,
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
  final bool isCode;
  final AppLocalizations l10n;
  final _PracticeColors colors;

  const _SubmittedWidget({
    required this.answer,
    required this.isCode,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colors.bg == const Color(0xFF080B14);

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
          if (isCode)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : const Color(0xFF374151),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Text(
                  answer,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    height: 1.65,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            )
          else
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

// ── Exit overlay ──────────────────────────────────────────────────────────────
//
// Rendered as a Stack child inside PracticeSessionScreen — NOT via showDialog.
// This removes all navigator interactions: onStay/onSaveAndExit/onCancelSession
// are callbacks that setState or context.go() on the PARENT screen directly.
// When context.go() fires, go_router removes the entire screen (scaffold +
// this overlay) in one atomic operation — no _ElementLifecycle.inactive.

class _ExitOverlay extends StatefulWidget {
  final VoidCallback onStay;
  final VoidCallback onSaveAndExit;
  final VoidCallback onCancelSession;

  const _ExitOverlay({
    required this.onStay,
    required this.onSaveAndExit,
    required this.onCancelSession,
  });

  @override
  State<_ExitOverlay> createState() => _ExitOverlayState();
}

class _ExitOverlayState extends State<_ExitOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF111827) : Colors.white;
    final border   = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final mutedCol = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final bodyCol  = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final titleCol = isDark ? Colors.white : const Color(0xFF111827);

    // SelectionContainer.disabled cancels selection scope from parent.
    // DefaultTextStyle.merge forces decoration:none so no yellow underlines
    // bleed from any ancestor SelectableText / SelectionArea widget.
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration:      TextDecoration.none,
        decorationColor: Colors.transparent,
      ),
      child: SelectionContainer.disabled(
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: widget.onStay,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.5 : 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Header ───────────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 14, 0),
                              child: Row(
                                children: [
                                  // Warning icon badge
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 20,
                                        color: Color(0xFFEF4444)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Thoát buổi luyện tập?',
                                      style: TextStyle(
                                        color: titleCol,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  // X close
                                  GestureDetector(
                                    onTap: widget.onStay,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.close_rounded,
                                          size: 20, color: mutedCol),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Body text ─────────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 14, 20, 20),
                              child: Text(
                                'Bạn có thể tiếp tục phiên này sau. Câu trả lời đã gõ được giữ nháp trên thiết bị này (và có thể đã đồng bộ lên server khi bạn chuyển câu). Chỉ khi bấm Nộp bài thì AI mới chấm điểm.',
                                style: TextStyle(
                                  color: bodyCol,
                                  fontSize: 13.5,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            Divider(height: 1, color: border),

                            // ── Buttons ───────────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Row(
                                children: [
                                  // Ở lại
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: widget.onStay,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                        side:
                                            BorderSide(color: border, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                      ),
                                      child: const Text('Ở lại',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Lưu & Thoát
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: widget.onSaveAndExit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                      ),
                                      child: const Text('Lưu & Thoát',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Hủy phiên link ────────────────────────────
                            GestureDetector(
                              onTap: widget.onCancelSession,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 16),
                                child: Text(
                                  'Hủy phiên này luôn (tiến trình sẽ không được lưu)',
                                  style: TextStyle(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.85),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ), // SelectionContainer.disabled
    ); // DefaultTextStyle.merge
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
