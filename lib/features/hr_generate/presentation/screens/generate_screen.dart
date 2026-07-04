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
      body: RepaintBoundary(
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
