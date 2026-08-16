import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../gen_colors.dart';
import '../providers/badge_provider.dart';
import '../providers/generation_provider.dart';
import '../views/step1_jd_input_view.dart';
import '../views/polling_view.dart';
import '../views/plan_review_view.dart';
import '../views/question_review_view.dart';
import '../views/failed_view.dart';
import '../views/draft_saved_view.dart';
import '../widgets/step_indicator.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  final String? resumeJobId;

  const GenerateScreen({super.key, this.resumeJobId});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  String? _loadedJobId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(badgeProvider.notifier).setGenerationScreenActive(true);
      _syncSession();
    });
  }

  @override
  void dispose() {
    final badge = ref.read(badgeProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      badge.setGenerationScreenActive(false);
    });
    super.dispose();
  }

  @override
  void didUpdateWidget(GenerateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumeJobId != oldWidget.resumeJobId) {
      _loadedJobId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSession());
    }
  }

  String? _jobIdFromRoute() {
    final fromWidget = widget.resumeJobId;
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    try {
      return GoRouterState.of(context).uri.queryParameters['jobId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncSession() async {
    final jobId = _jobIdFromRoute();
    final notifier = ref.read(generationProvider.notifier);
    final current = ref.read(generationProvider);

    if (jobId != null && jobId.isNotEmpty) {
      if (current.jobId == jobId &&
          current.currentView != 'form' &&
          !current.isRestoring &&
          current.session != null) {
        _loadedJobId = jobId;
        return;
      }
      if (_loadedJobId == jobId && current.isRestoring) return;
      _loadedJobId = jobId;
      await notifier.resumeJob(jobId);
      return;
    }

    if (_loadedJobId != null) return;
    _loadedJobId = '__storage__';
    await notifier.restoreFromStorage();
  }

  Future<void> _minimizeAndExit() async {
    final view = ref.read(generationProvider).currentView;
    if (view != 'form') {
      await ref.read(generationProvider.notifier).minimize();
      ref.read(badgeProvider.notifier).syncNow();
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/hr/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRestoring = ref.watch(
      generationProvider.select((s) => s.isRestoring),
    );
    final currentView = ref.watch(
      generationProvider.select((s) => s.currentView),
    );
    final pollingPhase = ref.watch(
      generationProvider.select((s) => s.pollingPhase),
    );
    final c = GenColors.of(context);

    if (isRestoring) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: GenColors.primary),
              const SizedBox(height: 16),
              Text(context.l10n.restoringSession,
                  style: TextStyle(color: c.textSub, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final currentStep = viewToStep(currentView, pollingPhase);
    final showStep    = currentView != 'draft_view';
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: currentView == 'form',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentView != 'form') {
          _minimizeAndExit();
        }
      },
      child: Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor:  c.bg,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        centerTitle:      true,
        title: Text(
          context.l10n.createAIQuestions,
          style: TextStyle(
              color:      c.text,
              fontSize:   17,
              fontWeight: FontWeight.w700),
        ),
        leading: currentView != 'form'
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: c.muted),
                onPressed: _minimizeAndExit,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: c.muted),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/hr/dashboard');
                  }
                },
              ),
        bottom: showStep
            ? PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child:         StepIndicator(currentStep: currentStep),
              )
            : null,
      ),
      body: Column(
        children: [
          if (currentView == 'form')
            _ModeToggleBar(isAiMode: true, isDark: isDark),
          Expanded(
            child: RepaintBoundary(
              child: AnimatedSwitcher(
              duration:        const Duration(milliseconds: 200),
              switchInCurve:   Curves.easeOut,
              switchOutCurve:  Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child:   child,
              ),
              child: _buildView(currentView),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildView(String currentView) {
    switch (currentView) {
      case 'polling':
        return const PollingView(key: ValueKey('polling'));
      case 'plan_review':
        return const PlanReviewView(key: ValueKey('plan_review'));
      case 'question_review':
        return const QuestionReviewView(key: ValueKey('question_review'));
      case 'failed':
        return const FailedView(key: ValueKey('failed'));
      case 'draft_view':
        return const DraftSavedView(key: ValueKey('draft_view'));
      case 'form':
      default:
        return const Step1JdInputView(key: ValueKey('form'));
    }
  }
}

// ── Mode Toggle Bar ───────────────────────────────────────────────────────────

class _ModeToggleBar extends StatelessWidget {
  final bool isAiMode;
  final bool isDark;
  const _ModeToggleBar({required this.isAiMode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: isDark ? const Color(0xFF0B1020) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color:  isDark ? const Color(0xFF111827) : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE2E4EA),
          ),
        ),
        child: Row(children: [
          _ModeTab(
            icon:     Icons.auto_awesome_rounded,
            label:    l10n.generateQuestions,
            active:   isAiMode,
            isDark:   isDark,
            onTap:    isAiMode ? null : () => context.go('/hr/generate'),
          ),
          _ModeTab(
            icon:     Icons.edit_note_rounded,
            label:    l10n.manualCreate,
            active:   !isAiMode,
            isDark:   isDark,
            onTap:    isAiMode ? () => context.go('/hr/manual-builder') : null,
          ),
        ]),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final bool     isDark;
  final VoidCallback? onTap;
  const _ModeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = GenColors.primary;
    final inactiveColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: active
              ? BoxDecoration(
                  color: isDark ? const Color(0xFF1E2640) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? GenColors.primary.withValues(alpha: 0.35)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                  color: active ? activeColor : inactiveColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color:      active ? activeColor : inactiveColor,
                  fontSize:   12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
