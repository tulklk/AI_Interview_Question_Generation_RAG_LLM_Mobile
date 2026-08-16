// ── Interview Studio — 3-tab mobile UI ───────────────────────────────────────
// Tabs: Sources (JD + docs) | Plan (plan + AI chat) | Settings (config)
// Stepper: 4 steps — JD → Create Plan → Approve Plan → Questions

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../gen_colors.dart';
import '../providers/badge_provider.dart';
import '../providers/studio_generation_provider.dart';
import '../views/studio_draft_saved_view.dart';
import '../views/studio_failed_view.dart';
import '../views/studio_polling_view.dart';
import '../../../../features/subscription/subscription_provider.dart';
import '../../domain/models/studio_models.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

class StudioWizardScreen extends ConsumerStatefulWidget {
  final String? resumeJobId;
  const StudioWizardScreen({super.key, this.resumeJobId});

  @override
  ConsumerState<StudioWizardScreen> createState() => _StudioWizardScreenState();
}

class _StudioWizardScreenState extends ConsumerState<StudioWizardScreen> {

  String? _loadedJobId;
  int _tabIndex = 0;

  final _jdCtrl   = TextEditingController();
  final _chatCtrl = TextEditingController();
  bool _jdPasteMode = true;

  // ── Local settings state (synced from API once on first load) ─────────────
  int    _duration      = 60;
  int    _questionCount = 10;
  String _difficulty    = 'Medium';
  final _questionTypes  = <String>{'technical', 'system_design', 'problem_solving', 'behavioral'};
  String _questionTone  = 'Professional';
  String _outputFormat  = 'StructuredInterviewKit';
  String _contentMode   = 'Mixed';
  final _codeTemplates  = <String>{'CODE_COMPLETION', 'BUG_DETECTION', 'REFACTORING', 'PERFORMANCE_ANALYSIS'};
  String _language      = 'Vietnamese';
  bool   _sampleAnswers = true;
  bool   _scoringRubric = true;
  bool   _settingsSynced = false;

  // Tracks which sub-tab inside the Plan tab is active (Plan=0, AI=1, Questions=2)
  int _planSubIndex = 0;

  void _syncSettings(StudioSettings? s) {
    if (s == null || _settingsSynced) return;
    _settingsSynced = true;
    setState(() {
      _duration      = s.interviewLengthMinutes;
      _questionCount = s.numberOfQuestions;
      _difficulty    = s.difficulty.toApiString();
      _questionTypes.clear();  _questionTypes.addAll(s.questionTypes);
      _questionTone  = s.questionTone;
      _outputFormat  = s.outputFormat;
      _contentMode   = s.contentMode;
      _codeTemplates.clear(); _codeTemplates.addAll(s.enabledCodeTemplates);
      _language      = s.outputLanguage;
      _sampleAnswers = s.includeSampleAnswers;
      _scoringRubric = s.includeScoringRubric;
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _jdCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(badgeProvider.notifier).setGenerationScreenActive(true);
      _syncSession();
    });
  }

  @override
  void dispose() {
    _jdCtrl.dispose();
    _chatCtrl.dispose();
    final badge = ref.read(badgeProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      badge.setGenerationScreenActive(false);
    });
    super.dispose();
  }

  @override
  void didUpdateWidget(StudioWizardScreen old) {
    super.didUpdateWidget(old);
    if (widget.resumeJobId != old.resumeJobId) {
      _loadedJobId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSession());
    }
  }

  // ── Session bootstrap ─────────────────────────────────────────────────────

  String? _jobIdFromRoute() {
    final fromWidget = widget.resumeJobId;
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    try {
      return GoRouterState.of(context).uri.queryParameters['jobId'];
    } catch (_) { return null; }
  }

  Future<void> _syncSession() async {
    final jobId    = _jobIdFromRoute();
    final notifier = ref.read(studioGenerationProvider.notifier);
    final current  = ref.read(studioGenerationProvider);

    if (jobId != null && jobId.isNotEmpty) {
      if (current.jobId == jobId &&
          current.currentView != 'form' &&
          !current.isRestoring) {
        _loadedJobId = jobId;
        return;
      }
      if (_loadedJobId == jobId && current.isRestoring) return;
      _loadedJobId = jobId;
      await notifier.resumeProject(jobId);
      return;
    }

    if (_loadedJobId != null) return;
    _loadedJobId = '__storage__';
    await notifier.restoreFromStorage();
  }

  Future<void> _minimizeAndExit() async {
    final view = ref.read(studioGenerationProvider).currentView;
    if (view != 'form') {
      await ref.read(studioGenerationProvider.notifier).minimize();
      ref.read(badgeProvider.notifier).syncNow();
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/hr/dashboard');
    }
  }

  // ── CTA actions ───────────────────────────────────────────────────────────

  void _showQuotaDialog(String? msg) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CooldownDialog(message: msg),
    ).then((_) {
      if (mounted) ref.read(studioGenerationProvider.notifier).clearQuotaBlock();
    });
  }

  Future<void> _saveAndAnalyze() async {
    final jd = _jdCtrl.text.trim();
    if (jd.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nhập ít nhất 50 ký tự mô tả công việc.')));
      return;
    }
    await ref.read(studioGenerationProvider.notifier).saveAndAnalyzeJd(jd);
  }

  Future<void> _createPlan() async {
    if (!ref.read(canGenerateNowProvider)) {
      _showQuotaDialog(ref.read(studioGenerationProvider).error);
      return;
    }
    await ref.read(studioGenerationProvider.notifier).createPlanWithSettings(
      numberOfQuestions:    _questionCount,
      difficulty:           _difficulty,
      questionTypes:        _questionTypes.toList(),
      interviewLengthMinutes: _duration,
      questionTone:         _questionTone,
      outputFormat:         _outputFormat,
      contentMode:          _contentMode,
      enabledCodeTemplates: _codeTemplates.toList(),
      outputLanguage:       _language,
      includeSampleAnswers: _sampleAnswers,
      includeScoringRubric: _scoringRubric,
    );
    ref.read(subscriptionProvider.notifier).onGenerationSuccess();
  }

  // Slide PageView to tab [i] with animation and sync the tab-bar indicator
  void _goToTabAnimated(int i) {
    if (!mounted) return;
    setState(() => _tabIndex = i);
  }

  // Slide to Plan tab first, then kick off plan creation (shows polling screen)
  Future<void> _createPlanWithAnimation() async {
    if (_tabIndex != 1) {
      _goToTabAnimated(1);
      await Future.delayed(const Duration(milliseconds: 380));
    }
    await _createPlan();
  }

  Future<void> _approvePlan() async {
    await ref.read(studioGenerationProvider.notifier).approvePlan();
    if (!mounted) return;
    final err = ref.read(studioGenerationProvider).error;
    if (err != null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
        'Plan approved — chat is now locked. Re-create plan to edit.',
      ),
      backgroundColor: const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: '×',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
  }

  Future<void> _generateQuestions() async {
    if (_tabIndex != 1) _goToTabAnimated(1);
    setState(() => _planSubIndex = 2);
    await ref.read(studioGenerationProvider.notifier).startQuestionGeneration();
  }

  Future<void> _applyPlan() async {
    await ref.read(studioGenerationProvider.notifier).applySettings(
      numberOfQuestions:    _questionCount,
      difficulty:           _difficulty,
      questionTypes:        _questionTypes.toList(),
      interviewLengthMinutes: _duration,
      questionTone:         _questionTone,
      outputFormat:         _outputFormat,
      contentMode:          _contentMode,
      enabledCodeTemplates: _codeTemplates.toList(),
      outputLanguage:       _language,
      includeSampleAnswers: _sampleAnswers,
      includeScoringRubric: _scoringRubric,
    );
    if (!mounted) return;
    final err = ref.read(studioGenerationProvider).error;
    if (err != null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Settings applied to plan.'),
      backgroundColor: const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: '×',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
    _goToTabAnimated(1);
    setState(() => _planSubIndex = 0);
  }

  // ── Start new project while current one is in queue ───────────────────────

  Future<void> _handleStartNew() async {
    final wasPolling = ref.read(studioGenerationProvider).currentView == 'polling';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ConfirmNewSetDialog(wasPolling: wasPolling),
    );
    if (confirmed != true || !mounted) return;

    // Reset provider (stops local polling; server queue continues processing)
    await ref.read(studioGenerationProvider.notifier).reset();

    // Reset local wizard UI state
    _jdCtrl.clear();
    _chatCtrl.clear();
    _loadedJobId    = null;
    _settingsSynced = false;
    setState(() {
      _tabIndex      = 0;
      _jdPasteMode   = true;
      _duration      = 60;
      _questionCount = 10;
      _difficulty    = 'Medium';
      _questionTone  = 'Professional';
      _outputFormat  = 'StructuredInterviewKit';
      _contentMode   = 'Mixed';
      _language      = 'Vietnamese';
      _sampleAnswers = true;
      _scoringRubric = true;
      _questionTypes
        ..clear()
        ..addAll({'technical', 'system_design', 'problem_solving', 'behavioral'});
      _codeTemplates
        ..clear()
        ..addAll({'CODE_COMPLETION', 'BUG_DETECTION', 'REFACTORING', 'PERFORMANCE_ANALYSIS'});
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasPolling
              ? 'Bộ câu hỏi cũ đang xử lý trong hàng đợi. '
                'Xem kết quả tại Lịch sử khi hoàn tất.'
              : 'Đã tạo phiên mới. Nhập JD để bắt đầu.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Step calculation ──────────────────────────────────────────────────────

  static int _currentStep(StudioGenState s) {
    if (!s.hasJd) return 1;
    if (s.plan == null) return 2;
    if (!s.isPlanApproved) return 3;
    return 4;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Quota dialog
    ref.listen(
      studioGenerationProvider.select((s) => s.quotaBlocked),
      (_, next) {
        if (next == true) _showQuotaDialog(ref.read(studioGenerationProvider).error);
      },
    );

    // Sync settings from API (once)
    ref.listen(
      studioGenerationProvider.select((s) => s.settings),
      (_, s) => _syncSettings(s),
    );

    // Keep Plan/Questions sub-tabs in sync while polling or when done
    ref.listen(
      studioGenerationProvider.select((s) => (s.currentView, s.pollingPhase)),
      (prev, next) {
        final view = next.$1;
        final phase = next.$2;
        if (!mounted) return;
        if (view == 'polling' && phase == 'plan') {
          if (_tabIndex != 1) _goToTabAnimated(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _planSubIndex = 0);
          });
          return;
        }
        final goQuestions = view == 'question_review' ||
            (view == 'polling' && phase == 'questions');
        if (goQuestions) {
          if (_tabIndex != 1) _goToTabAnimated(1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _planSubIndex = 2);
          });
        }
      },
    );

    // Pre-fill JD after this frame — avoid setState during build
    ref.listen(
      studioGenerationProvider.select((s) => s.jdContent),
      (_, jdContent) {
        if (jdContent == null || jdContent.isEmpty || _jdCtrl.text.isNotEmpty) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _jdCtrl.text.isNotEmpty) return;
          _jdCtrl.text = jdContent;
        });
      },
    );

    final state       = ref.watch(studioGenerationProvider);
    final currentView = state.currentView;
    final c           = GenColors.of(context);
    final isTabView   = currentView == 'form' ||
        currentView == 'plan_review' ||
        currentView == 'question_review' ||
        (currentView == 'polling' &&
            (state.pollingPhase == 'plan' ||
                state.pollingPhase == 'questions'));
    final step        = _currentStep(state);

    if (state.isRestoring) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: GenColors.primary),
            const SizedBox(height: 16),
            Text('Đang khôi phục phiên...',
                style: TextStyle(color: c.textSub, fontSize: 13)),
          ]),
        ),
      );
    }

    return PopScope(
      canPop: currentView == 'form',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentView != 'form') _minimizeAndExit();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor:  c.bg,
          elevation:        0,
          surfaceTintColor: Colors.transparent,
          centerTitle:      false,
          leading: currentView == 'form'
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: c.muted),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/hr/dashboard'),
                )
              : IconButton(
                  icon:      Icon(Icons.close_rounded, color: c.muted),
                  onPressed: _minimizeAndExit,
                ),
          title: Text(
            'Generate question set',
            style: TextStyle(
                color: c.text, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
                if (isTabView) ...[
                  // "Tạo mới" — only when there's already an active session
                  if (state.hasJd) ...[
                    _NewSetBtn(c: c, onTap: _handleStartNew),
                    const SizedBox(width: 6),
                  ],
                  _AppBarBtn(Icons.folder_open_rounded, c: c, onTap: () {}),
                  _AppBarBtn(Icons.edit_rounded,        c: c, onTap: () {}),
                  _AppBarBtn(Icons.save_outlined,       c: c, onTap: () {
                    if (state.projectId != null) {
                      ref.read(studioGenerationProvider.notifier).saveDraft();
                    }
                  }),
                  _AppBarBtn(Icons.share_rounded,       c: c, onTap: () {}),
                  const SizedBox(width: 4),
                ],
                if (currentView == 'polling') ...[
                  _NewSetBtn(c: c, onTap: _handleStartNew),
                  const SizedBox(width: 8),
                ],
              ],
        ),
        body: isTabView
            ? Column(
                children: [
                  _StepIndicator4(currentStep: step),
                  _StudioTabBar(
                    index: _tabIndex,
                    c: c,
                    onChanged: _goToTabAnimated,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tabIndex,
                      children: _buildTabPages(state, c),
                    ),
                  ),
                ],
              )
            : _buildNonTabBody(currentView),
        bottomNavigationBar: isTabView ? _buildBottomBar(state, c) : null,
      ),
    );
  }

  // ── PageView pages ────────────────────────────────────────────────────────

  List<Widget> _buildTabPages(StudioGenState state, GenColors c) => [
    _buildJdListView(state, c),
    SizedBox.expand(
      child: _PlanTab(
        chatCtrl:           _chatCtrl,
        onCreatePlan:       _createPlanWithAnimation,
        onApprovePlan:      _approvePlan,
        planSubIndex:       _planSubIndex,
        onPlanSubChanged:   (i) => setState(() => _planSubIndex = i),
      ),
    ),
    _StudioSettingsTab(
      duration:      _duration,
      questionCount: _questionCount,
      difficulty:    _difficulty,
      questionTypes: _questionTypes,
      questionTone:  _questionTone,
      outputFormat:  _outputFormat,
      contentMode:   _contentMode,
      codeTemplates: _codeTemplates,
      language:      _language,
      sampleAnswers: _sampleAnswers,
      scoringRubric: _scoringRubric,
      showApply:     state.hasPlan && !state.isPlanApproved,
      isApplying:    state.isApplyingSettings,
      isLocked:      state.isPlanApproved,
      onApply:       _applyPlan,
      onDurationChanged:      (v) => setState(() => _duration = v),
      onQuestionCountChanged: (v) => setState(() => _questionCount = v),
      onDifficultyChanged:    (v) => setState(() => _difficulty = v),
      onQuestionTypesChanged: (v) => setState(() {
        _questionTypes.clear();
        _questionTypes.addAll(v);
      }),
      onQuestionToneChanged:  (v) => setState(() => _questionTone = v),
      onOutputFormatChanged:  (v) => setState(() => _outputFormat = v),
      onContentModeChanged:   (v) => setState(() => _contentMode = v),
      onCodeTemplatesChanged: (v) => setState(() {
        _codeTemplates.clear();
        _codeTemplates.addAll(v);
      }),
      onLanguageChanged:      (v) => setState(() => _language = v),
      onSampleAnswersChanged: (v) => setState(() => _sampleAnswers = v),
      onScoringRubricChanged: (v) => setState(() => _scoringRubric = v),
    ),
  ];

  // ── Adaptive bottom bar ───────────────────────────────────────────────────
  //
  //  • !hasPlan              → Create Plan
  //  • hasPlan && !approved  → Approve Plan
  //  • approved, no questions → Generate Questions
  //  • questions ready on Q tab → Publish

  Widget _buildBottomBar(StudioGenState state, GenColors c) {
    final bool onSources   = _tabIndex == 0;
    final bool jdReady     = state.hasJd;
    final bool analyzing   = state.isAnalyzingJd;
    final bool canAnalyze  = _jdCtrl.text.length >= 50;
    final bool hasPlan     = state.hasPlan;
    final bool approved    = state.isPlanApproved;
    final bool loading     = state.isLoading;
    final bool creatingPlan = (state.currentView == 'polling' &&
            state.pollingPhase == 'plan') ||
        (loading && !hasPlan);

    // Hide primary CTA while plan is being created (stay on Plan tab loading)
    if (creatingPlan) {
      return const SizedBox.shrink();
    }

    final bool modeAnalyze = onSources && !jdReady && !hasPlan;
    final bool modeApprove = hasPlan && !approved;
    final bool modeGenerate = approved && state.questions.isEmpty && !loading;
    final bool modePublish = approved && state.questions.isNotEmpty
        && _tabIndex == 1 && _planSubIndex == 2;

    late IconData icon;
    late String   label;
    late VoidCallback? onPressed;

    if (modeAnalyze) {
      icon      = Icons.analytics_outlined;
      label     = 'Save & Analyze';
      onPressed = (!analyzing && canAnalyze) ? _saveAndAnalyze : null;
    } else if (modeApprove) {
      icon      = Icons.check_circle_outline_rounded;
      label     = 'Approve Plan';
      onPressed = loading ? null : _approvePlan;
    } else if (modePublish) {
      icon      = Icons.publish_rounded;
      label     = 'Đăng bộ câu hỏi';
      onPressed = () => ref.read(studioGenerationProvider.notifier).publishProject();
    } else if (modeGenerate) {
      icon      = Icons.quiz_outlined;
      label     = 'Generate Questions';
      onPressed = _generateQuestions;
    } else if (!hasPlan) {
      icon      = Icons.auto_awesome_rounded;
      label     = 'Create Plan';
      onPressed = _createPlanWithAnimation;
    } else {
      icon      = Icons.quiz_outlined;
      label     = 'Generate Questions';
      onPressed = loading ? null : _generateQuestions;
    }

    return Material(
      color: c.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: modePublish
              ? Row(children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(studioGenerationProvider.notifier).saveDraft(),
                    icon: state.isSavingDraft
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      state.isDraftSaved ? 'Đã lưu' : 'Lưu',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.text,
                      side: BorderSide(color: c.border),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => ref
                          .read(studioGenerationProvider.notifier)
                          .publishProject(),
                      icon: const Icon(Icons.publish_rounded, size: 18),
                      label: const Text('Đăng bộ câu hỏi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: GenColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ])
              : FilledButton.icon(
            onPressed: onPressed,
            icon: (analyzing && modeAnalyze)
                ? const SizedBox(
                    width:  16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2))
                : Icon(icon, size: 18),
            label: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: onPressed != null
                  ? GenColors.primary
                  : GenColors.primary.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              minimumSize:     const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJdListView(StudioGenState state, GenColors c) {
    final charCount = _jdCtrl.text.length;
    final wordCount = _jdCtrl.text.trim().isEmpty
        ? 0
        : _jdCtrl.text.trim().split(RegExp(r'\s+')).length;
    final analysis = state.jdAnalysis;
    final docs = state.documents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Job Description',
                style: TextStyle(
                    color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
            _StatusBadge('Required',
                bg: GenColors.primary.withValues(alpha: 0.15),
                textColor: GenColors.primary),
            if (state.hasJd)
              _StatusBadge('✓ OK',
                  bg: const Color(0xFF10B981).withValues(alpha: 0.15),
                  textColor: const Color(0xFF10B981)),
            _SampleJdBtn(ctrl: _jdCtrl, c: c),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Row(children: [
            Expanded(
                child: _ModeBtn(
                    label: 'Paste',
                    active: _jdPasteMode,
                    onTap: _jdPasteMode
                        ? null
                        : () => setState(() => _jdPasteMode = true),
                    c: c)),
            Expanded(
                child: _ModeBtn(
                    label: 'Upload file',
                    active: !_jdPasteMode,
                    onTap: !_jdPasteMode
                        ? null
                        : () => setState(() => _jdPasteMode = false),
                    c: c)),
          ]),
        ),
        const SizedBox(height: 10),
        if (_jdPasteMode) ...[
          TextField(
            controller: _jdCtrl,
            minLines: 8,
            maxLines: 14,
            style: TextStyle(color: c.text, fontSize: 13, height: 1.6),
            cursorColor: GenColors.primary,
            decoration: InputDecoration(
              hintText: 'Paste job description here...',
              hintStyle: TextStyle(color: c.hint, fontSize: 13, height: 1.6),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.borderFoc, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('$wordCount words · $charCount characters',
                style: TextStyle(color: c.muted, fontSize: 11)),
            const Spacer(),
            if (state.isAnalyzingJd)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: GenColors.primary, strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Đang phân tích...',
                    style: TextStyle(color: c.muted, fontSize: 11)),
              ]),
          ]),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_upload_outlined, size: 36, color: c.muted),
              const SizedBox(height: 8),
              Text('Click to upload or drag & drop',
                  style: TextStyle(color: c.textSub, fontSize: 13)),
              const SizedBox(height: 4),
              Text('PDF, DOCX, TXT, JPG, PNG',
                  style: TextStyle(color: c.muted, fontSize: 11)),
            ]),
          ),
        const SizedBox(height: 18),
        Text('Auto-detected',
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (analysis != null)
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (analysis.detectedRole != null)
              _AutoChip(label: analysis.detectedRole!, c: c),
            if (analysis.detectedSeniority != null)
              _AutoChip(label: analysis.detectedSeniority!, c: c),
            if (analysis.detectedLanguage != null)
              _AutoChip(label: analysis.detectedLanguage!, c: c),
            ...analysis.skills.take(5).map((s) => _AutoChip(label: s, c: c)),
          ])
        else
          Container(
            width: double.infinity,
            height: 28,
            decoration: BoxDecoration(
              color: c.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        const SizedBox(height: 20),
        Text('Additional Documents',
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          Text(
            'No documents. Upload or attach from KB for AI context.',
            style: TextStyle(color: c.muted, fontSize: 12),
          )
        else
          ...docs.map((doc) => _DocTile(doc: doc, c: c)),
      ],
    );
  }

  Widget _buildNonTabBody(String view) {
    switch (view) {
      case 'polling':
        return const StudioPollingView(key: ValueKey('polling'));
      case 'failed':
        return const StudioFailedView(key: ValueKey('failed'));
      case 'draft_view':
        return const StudioDraftSavedView(key: ValueKey('draft'));
      default:
        return const SizedBox.shrink(key: ValueKey('empty'));
    }
  }
}

// ── AppBar icon button ────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final GenColors c;
  final VoidCallback onTap;

  const _AppBarBtn(this.icon, {required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: Icon(icon, size: 15, color: c.textSub),
    ),
  );
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _StudioTabBar extends StatelessWidget {
  final int index;
  final GenColors c;
  final ValueChanged<int> onChanged;
  const _StudioTabBar({
    required this.index,
    required this.c,
    required this.onChanged,
  });

  static const _icons = [
    Icons.storage_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.tune_rounded,
  ];

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: c.border),
    ),
    child: Row(
      children: List.generate(_icons.length, (i) {
        final selected = index == i;
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? GenColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Icon(
                    _icons[i],
                    size: 17,
                    color: selected ? Colors.white : c.textSub,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

// ── 4-step indicator ──────────────────────────────────────────────────────────

class _StepIndicator4 extends StatelessWidget {
  final int currentStep; // 1–4
  const _StepIndicator4({required this.currentStep});

  static const _labels = ['Nhập JD', 'Tạo Plan', 'Duyệt Plan', 'Câu hỏi'];

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      color:   c.bg,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftStep = (i ~/ 2) + 1;
            final done     = currentStep > leftStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: done
                      ? const LinearGradient(colors: [
                          Color(0xFF10B981), Color(0xFF6C47FF)])
                      : null,
                  color:        done ? null : c.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step   = (i ~/ 2) + 1;
          final done   = currentStep > step;
          final active = currentStep == step;
          return _Dot(
              step: step, label: _labels[step - 1],
              done: done, active: active, c: c);
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int step;
  final String label;
  final bool done, active;
  final GenColors c;

  const _Dot({
    required this.step, required this.label,
    required this.done, required this.active, required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF10B981)
        : active ? GenColors.primary : c.border;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width:  active ? 26 : 20, height: active ? 26 : 20,
        decoration: BoxDecoration(
          color:     color, shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: GenColors.primary.withValues(alpha: 0.45),
                  blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
              : Text('$step',
                  style: TextStyle(
                    color:      active ? Colors.white : c.muted,
                    fontSize:   active ? 10 : 9,
                    fontWeight: FontWeight.w700,
                  )),
        ),
      ),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(
            color:      active ? c.text : done ? const Color(0xFF10B981) : c.muted,
            fontSize:   8,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 0 — Sources (JD + Additional Documents)
// ══════════════════════════════════════════════════════════════════════════════

class _SourcesTab extends ConsumerStatefulWidget {
  final TextEditingController jdCtrl;
  final bool jdPasteMode;
  final VoidCallback onToggleMode;
  final VoidCallback onSaveAndAnalyze;

  const _SourcesTab({
    required this.jdCtrl,
    required this.jdPasteMode,
    required this.onToggleMode,
    required this.onSaveAndAnalyze,
  });

  @override
  ConsumerState<_SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends ConsumerState<_SourcesTab> {
  bool _showLibrary = false;
  List<StudioLibraryDocument> _libraryDocs = [];
  final _selectedLibIds = <String>{};
  bool _loadingLibrary  = false;
  bool _jdFocused       = false;

  @override
  void initState() {
    super.initState();
    widget.jdCtrl.addListener(_onJdChanged);
  }

  @override
  void dispose() {
    widget.jdCtrl.removeListener(_onJdChanged);
    super.dispose();
  }

  void _onJdChanged() => setState(() {});

  Future<void> _pickAndUploadDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    await ref.read(studioGenerationProvider.notifier).uploadDocument(File(path));
  }

  Future<void> _loadLibrary() async {
    final pid = ref.read(studioGenerationProvider).projectId;
    if (pid == null) return;
    setState(() => _loadingLibrary = true);
    try {
      _libraryDocs = await ref.read(studioRepositoryProvider).listLibraryDocuments(pid);
    } catch (_) {}
    if (mounted) setState(() => _loadingLibrary = false);
  }

  Future<void> _attachSelected() async {
    if (_selectedLibIds.isEmpty) return;
    await ref.read(studioGenerationProvider.notifier)
        .attachLibraryDocuments(_selectedLibIds.toList());
    if (mounted) setState(() { _showLibrary = false; _selectedLibIds.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final c          = GenColors.of(context);
    final state      = ref.watch(studioGenerationProvider);
    final docs       = state.documents;
    final jdOk       = state.hasJd;
    final analyzing  = state.isAnalyzingJd;
    final analysis   = state.jdAnalysis;
    final charCount  = widget.jdCtrl.text.length;
    final wordCount  = widget.jdCtrl.text.trim().isEmpty
        ? 0
        : widget.jdCtrl.text.trim().split(RegExp(r'\s+')).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Job Description header ──────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Job Description',
                style: TextStyle(
                    color: c.text, fontSize: 14, fontWeight: FontWeight.w700)),
            _StatusBadge('Required', bg: GenColors.primary.withValues(alpha: 0.15),
                textColor: GenColors.primary),
            if (jdOk)
              _StatusBadge('✓ OK',
                  bg: const Color(0xFF10B981).withValues(alpha: 0.15),
                  textColor: const Color(0xFF10B981)),
            _SampleJdBtn(ctrl: widget.jdCtrl, c: c),
          ],
        ),
        const SizedBox(height: 12),

        // ── Paste / Upload file toggle ──────────────────────────────────────
        Container(
          height: 36,
          decoration: BoxDecoration(
            color:        c.card,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: c.border),
          ),
          child: Row(children: [
            Expanded(child: _ModeBtn(
              label: 'Paste', active: widget.jdPasteMode,
              onTap: widget.jdPasteMode ? null : widget.onToggleMode, c: c)),
            Expanded(child: _ModeBtn(
              label: 'Upload file', active: !widget.jdPasteMode,
              onTap: widget.jdPasteMode ? widget.onToggleMode : null, c: c)),
          ]),
        ),
        const SizedBox(height: 10),

        // ── JD text area or upload dropzone ────────────────────────────────
        if (widget.jdPasteMode) ...[
          Focus(
            onFocusChange: (v) => setState(() => _jdFocused = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:        c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _jdFocused ? c.borderFoc : c.border,
                    width: _jdFocused ? 1.5 : 1),
                boxShadow: _jdFocused
                    ? [BoxShadow(
                        color:      GenColors.primary.withValues(alpha: 0.10),
                        blurRadius: 8)]
                    : null,
              ),
              child: TextField(
                controller: widget.jdCtrl,
                minLines:   9, maxLines: 15,
                style: TextStyle(color: c.text, fontSize: 13, height: 1.6),
                cursorColor: GenColors.primary,
                decoration: InputDecoration(
                  hintText: 'Paste job description here...',
                  hintStyle: TextStyle(color: c.hint, fontSize: 13, height: 1.6),
                  filled:         true,
                  fillColor:      c.card,
                  border:         InputBorder.none,
                  enabledBorder:  InputBorder.none,
                  focusedBorder:  InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('$wordCount words · $charCount characters',
                style: TextStyle(color: c.muted, fontSize: 11)),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: analyzing
                  ? Row(key: const ValueKey('loading'), mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                              color: GenColors.primary, strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text('Đang phân tích...',
                          style: TextStyle(color: c.muted, fontSize: 11)),
                    ])
                  : _SaveAnalyzeBtn(
                      key: const ValueKey('btn'),
                      enabled: charCount >= 50,
                      onTap: widget.onSaveAndAnalyze,
                      c: c,
                    ),
            ),
          ]),
        ] else ...[
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
              );
              if (result != null && result.files.isNotEmpty) {
                // handle upload
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color:        c.card,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: c.border, style: BorderStyle.solid),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_upload_outlined, size: 36, color: c.muted),
                const SizedBox(height: 8),
                Text('Click to upload or drag & drop',
                    style: TextStyle(color: c.textSub, fontSize: 13)),
                const SizedBox(height: 4),
                Text('PDF, DOCX, TXT, JPG, PNG',
                    style: TextStyle(color: c.muted, fontSize: 11)),
              ]),
            ),
          ),
        ],

        // ── Auto-detected ───────────────────────────────────────────────────
        const SizedBox(height: 18),
        Text('Auto-detected',
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (analysis != null) ...[
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (analysis.detectedRole     != null)
              _AutoChip(label: analysis.detectedRole!, c: c),
            if (analysis.detectedSeniority != null)
              _AutoChip(label: analysis.detectedSeniority!, c: c),
            if (analysis.detectedLanguage != null)
              _AutoChip(label: analysis.detectedLanguage!, c: c),
            ...analysis.skills.take(5).map((s) => _AutoChip(label: s, c: c)),
          ]),
        ] else
          Container(
            width: double.infinity, height: 28,
            decoration: BoxDecoration(
              color:        c.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),

        // ── Additional Documents ────────────────────────────────────────────
        const SizedBox(height: 20),
        Row(children: [
          Text('Additional Documents',
              style: TextStyle(
                  color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _StatusBadge('Optional', bg: c.border.withValues(alpha: 0.4),
              textColor: c.textSub),
        ]),
        const SizedBox(height: 10),

        // From KB | Upload file
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () async {
              setState(() => _showLibrary = !_showLibrary);
              if (_showLibrary && _libraryDocs.isEmpty) await _loadLibrary();
            },
            icon:  Icon(Icons.library_books_outlined, size: 14, color: c.textSub),
            label: Text('From KB',
                style: TextStyle(color: c.textSub, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side:  BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              foregroundColor: c.textSub,
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: _pickAndUploadDoc,
            icon:  Icon(Icons.upload_rounded, size: 14, color: c.textSub),
            label: Text('Upload file',
                style: TextStyle(color: c.textSub, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side:  BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              foregroundColor: c.textSub,
            ),
          )),
        ]),

        // Library picker (inline)
        if (_showLibrary) ...[
          const SizedBox(height: 8),
          _LibraryPickerInline(
            docs:     _libraryDocs,
            loading:  _loadingLibrary,
            selected: _selectedLibIds,
            onToggle: (id) => setState(() {
              _selectedLibIds.contains(id)
                  ? _selectedLibIds.remove(id)
                  : _selectedLibIds.add(id);
            }),
            onAttach: _attachSelected,
            onClose:  () => setState(() { _showLibrary = false; }),
            c: c,
          ),
        ],

        const SizedBox(height: 10),
        // Document list or empty state
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No documents. Upload or attach from KB for AI context.',
              style: TextStyle(color: c.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...docs.map((doc) => _DocTile(doc: doc, c: c)),

      ]),
    );
  }
}

// ── Helper widgets for Sources tab ────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  const _StatusBadge(this.text, {required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _SampleJdBtn extends StatelessWidget {
  final TextEditingController ctrl;
  final GenColors c;
  const _SampleJdBtn({required this.ctrl, required this.c});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => showModalBottomSheet<void>(
      context:       context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _SampleJdSheet(ctrl: ctrl),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: GenColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.article_outlined, size: 11, color: GenColors.primary),
        SizedBox(width: 4),
        Text('Sample JD',
            style: TextStyle(
                color:      GenColors.primary,
                fontSize:   11,
                fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Sample JD bottom sheet ─────────────────────────────────────────────────────

class _SampleJdSheet extends StatefulWidget {
  final TextEditingController ctrl;
  const _SampleJdSheet({required this.ctrl});

  @override
  State<_SampleJdSheet> createState() => _SampleJdSheetState();
}

class _SampleJdSheetState extends State<_SampleJdSheet> {
  int _selected = 0;

  // ── Sample data ──────────────────────────────────────────────────────────────
  static final _samples = [
    (
      role:  'Fullstack Developer',
      icon:  Icons.code_rounded,
      color: Color(0xFF7C3AED),
      tags:  ['Node.js', 'React', 'PostgreSQL'],
      jd:
        'Chúng tôi đang tìm kiếm một Fullstack Developer có 1–3 năm kinh nghiệm. '
        'Trách nhiệm: Xây dựng RESTful API bằng ASP.NET Core hoặc Node.js, phát triển '
        'giao diện React.js/Next.js, thiết kế database PostgreSQL/MySQL, tích hợp xác '
        'thực JWT, phối hợp với QA và Product Team.\n\n'
        'Yêu cầu: Kinh nghiệm C#/Node.js, thành thạo React.js & TypeScript, hiểu REST '
        'API, JWT, database design, Git, Docker.',
    ),
    (
      role:  'Backend Developer',
      icon:  Icons.dns_rounded,
      color: Color(0xFF2563EB),
      tags:  ['Java', 'Spring Boot', 'MySQL'],
      jd:
        'Chúng tôi tìm kiếm Backend Developer Java có 2–4 năm kinh nghiệm phát triển '
        'hệ thống microservices quy mô lớn.\n\n'
        'Trách nhiệm: Thiết kế và triển khai các microservices với Spring Boot, tối ưu '
        'truy vấn MySQL/Redis, xây dựng CI/CD pipeline với Jenkins/GitHub Actions, viết '
        'unit test và integration test.\n\n'
        'Yêu cầu: Thành thạo Java 17+, Spring Boot, JPA/Hibernate, Docker/Kubernetes, '
        'kinh nghiệm làm việc với message queue (Kafka/RabbitMQ), hiểu về Clean Architecture.',
    ),
    (
      role:  'Mobile Developer',
      icon:  Icons.phone_android_rounded,
      color: Color(0xFF059669),
      tags:  ['Flutter', 'Dart', 'Firebase'],
      jd:
        'Tìm kiếm Mobile Developer (Flutter) có kinh nghiệm 1–3 năm xây dựng ứng dụng '
        'di động đa nền tảng iOS & Android.\n\n'
        'Trách nhiệm: Phát triển tính năng mới bằng Flutter/Dart, tích hợp REST API và '
        'Firebase, tối ưu hiệu năng và trải nghiệm người dùng, viết code có unit test.\n\n'
        'Yêu cầu: Thành thạo Flutter & Dart, hiểu state management (Riverpod/BLoC), '
        'kinh nghiệm tích hợp Firebase Auth/Firestore, publish app lên App Store & Play '
        'Store, biết Git workflow.',
    ),
    (
      role:  'AI / ML Engineer',
      icon:  Icons.psychology_rounded,
      color: Color(0xFFD97706),
      tags:  ['Python', 'LLM', 'RAG'],
      jd:
        'Chúng tôi tìm kiếm AI/ML Engineer đam mê LLM và hệ thống RAG để tham gia '
        'xây dựng các sản phẩm AI thế hệ mới.\n\n'
        'Trách nhiệm: Thiết kế và triển khai pipeline RAG (Retrieval-Augmented Generation), '
        'fine-tune mô hình ngôn ngữ lớn, xây dựng API inference tốc độ cao với FastAPI, '
        'đánh giá và cải thiện chất lượng mô hình qua benchmark.\n\n'
        'Yêu cầu: Thành thạo Python, PyTorch/TensorFlow, kinh nghiệm với LangChain/'
        'LlamaIndex, hiểu về vector database (Qdrant/Weaviate/Pinecone), nền tảng toán '
        'học vững (xác suất, đại số tuyến tính), tiếng Anh đọc hiểu tài liệu kỹ thuật.',
    ),
    (
      role:  'DevOps Engineer',
      icon:  Icons.cloud_done_rounded,
      color: Color(0xFF0891B2),
      tags:  ['AWS', 'Kubernetes', 'Terraform'],
      jd:
        'Tìm kiếm DevOps Engineer có 2–5 năm kinh nghiệm quản trị hạ tầng cloud và '
        'tự động hóa quy trình phát triển phần mềm.\n\n'
        'Trách nhiệm: Thiết kế và vận hành hạ tầng AWS/GCP bằng Terraform, xây dựng '
        'CI/CD pipeline với GitHub Actions/Jenkins, quản lý cluster Kubernetes (EKS/GKE), '
        'giám sát hệ thống với Prometheus/Grafana, đảm bảo bảo mật và SLA.\n\n'
        'Yêu cầu: Thành thạo Linux, Docker, Kubernetes, Terraform, có kinh nghiệm với '
        'AWS hoặc GCP (Certificate là lợi thế), hiểu networking (VPC, Load Balancer, DNS), '
        'kinh nghiệm xử lý sự cố hệ thống production.',
    ),
  ];

  void _applyAndClose() {
    final jd = _samples[_selected].jd;
    widget.ctrl.text = jd;
    widget.ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: jd.length));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c    = GenColors.of(context);
    final item = _samples[_selected];
    final mq   = MediaQuery.of(context);

    return Container(
      height:      mq.size.height * 0.82,
      decoration:  BoxDecoration(
        color:        c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // ── Handle ────────────────────────────────────────────────────────
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            const Icon(Icons.article_rounded, size: 18, color: GenColors.primary),
            const SizedBox(width: 8),
            Text('Chọn JD mẫu',
                style: TextStyle(
                    color:      c.text,
                    fontSize:   16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.close_rounded, color: c.muted, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Role chips ────────────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            padding:          const EdgeInsets.symmetric(horizontal: 16),
            itemCount:        _samples.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s        = _samples[i];
              final selected = _selected == i;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration:   const Duration(milliseconds: 150),
                  padding:    const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:        selected
                        ? s.color.withValues(alpha: 0.15)
                        : c.bg,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(
                        color: selected
                            ? s.color
                            : c.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(s.icon, size: 12,
                        color: selected ? s.color : c.muted),
                    const SizedBox(width: 5),
                    Text(s.role,
                        style: TextStyle(
                            color:      selected ? s.color : c.textSub,
                            fontSize:   12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── Tags row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            ...item.tags.map((t) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        item.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(t, style: TextStyle(
                  color:      item.color,
                  fontSize:   10,
                  fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
        const SizedBox(height: 10),

        // ── JD preview card ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key:    ValueKey(_selected),
                width:  double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        c.bg,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: c.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    item.jd,
                    style: TextStyle(
                        color:  c.text,
                        fontSize: 13,
                        height: 1.65),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Use this sample button ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, mq.padding.bottom + 12),
          child: FilledButton.icon(
            onPressed: _applyAndClose,
            icon:  const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sử dụng mẫu này',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: GenColors.primary,
              foregroundColor: Colors.white,
              minimumSize:     const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final GenColors c;
  const _ModeBtn({required this.label, required this.active,
      required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color:        active ? GenColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
              color:      active ? Colors.white : c.textSub,
              fontSize:   13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    ),
  );
}

class _SaveAnalyzeBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final GenColors c;
  const _SaveAnalyzeBtn({super.key, required this.enabled, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:        enabled
            ? GenColors.primary
            : GenColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Save & Analyze',
          style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

class _AutoChip extends StatelessWidget {
  final String label;
  final GenColors c;
  const _AutoChip({required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(20),
      border:       Border.all(color: c.border),
    ),
    child: Text(label,
        style: TextStyle(color: c.textSub, fontSize: 11)),
  );
}

class _DocTile extends ConsumerWidget {
  final StudioDocument doc;
  final GenColors c;
  const _DocTile({required this.doc, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dotColor = _statusColor(doc.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => ref.read(studioGenerationProvider.notifier)
              .toggleDocumentSelection(doc.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16, height: 16,
            decoration: BoxDecoration(
              color:        doc.isSelected ? GenColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: doc.isSelected ? GenColors.primary : c.border, width: 1.5),
            ),
            child: doc.isSelected
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          doc.isLibraryLink
              ? Icons.library_books_outlined
              : Icons.description_outlined,
          size: 14, color: c.muted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.fileName,
                style: TextStyle(color: c.text, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(doc.status.displayLabel,
                  style: TextStyle(color: dotColor, fontSize: 9)),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () => ref.read(studioGenerationProvider.notifier).deleteDocument(doc.id),
          child: Icon(Icons.close_rounded, size: 14, color: c.muted),
        ),
      ]),
    );
  }

  Color _statusColor(StudioDocumentStatus s) {
    switch (s) {
      case StudioDocumentStatus.completed:  return const Color(0xFF10B981);
      case StudioDocumentStatus.processing: return const Color(0xFFF59E0B);
      case StudioDocumentStatus.failed:     return const Color(0xFFEF4444);
      case StudioDocumentStatus.pending:    return const Color(0xFF9CA3AF);
    }
  }
}

class _LibraryPickerInline extends StatelessWidget {
  final List<StudioLibraryDocument> docs;
  final bool loading;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onAttach, onClose;
  final GenColors c;

  const _LibraryPickerInline({
    required this.docs, required this.loading, required this.selected,
    required this.onToggle, required this.onAttach, required this.onClose,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: c.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Library Documents',
            style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        GestureDetector(onTap: onClose,
            child: Icon(Icons.close_rounded, size: 14, color: c.muted)),
      ]),
      const SizedBox(height: 6),
      if (loading)
        const Center(child: SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(color: GenColors.primary, strokeWidth: 2)))
      else if (docs.isEmpty)
        Text('No documents in library.', style: TextStyle(color: c.muted, fontSize: 11))
      else
        ...docs.map((d) {
          final sel = selected.contains(d.knowledgeDocumentId);
          return GestureDetector(
            onTap: () => onToggle(d.knowledgeDocumentId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color:        sel ? GenColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color: sel ? GenColors.primary : c.border, width: 1.5),
                  ),
                  child: sel
                      ? const Icon(Icons.check, size: 9, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(d.fileName,
                      style: TextStyle(color: c.text, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (d.alreadyAttached)
                  Text('Attached', style: TextStyle(color: c.muted, fontSize: 9)),
              ]),
            ),
          );
        }),
      if (selected.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAttach,
            style: ElevatedButton.styleFrom(
              backgroundColor: GenColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Attach ${selected.length} document${selected.length > 1 ? "s" : ""}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Plan (plan content + AI assistant)
// ══════════════════════════════════════════════════════════════════════════════

class _PlanTab extends ConsumerStatefulWidget {
  final TextEditingController chatCtrl;
  final VoidCallback onCreatePlan;
  final VoidCallback onApprovePlan;
  final int planSubIndex;
  final ValueChanged<int> onPlanSubChanged;

  const _PlanTab({
    required this.chatCtrl,
    required this.onCreatePlan,
    required this.onApprovePlan,
    required this.planSubIndex,
    required this.onPlanSubChanged,
  });

  @override
  ConsumerState<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<_PlanTab> {
  late int _planSubIndex;

  @override
  void initState() {
    super.initState();
    _planSubIndex = widget.planSubIndex;
  }

  @override
  void didUpdateWidget(_PlanTab old) {
    super.didUpdateWidget(old);
    if (widget.planSubIndex != old.planSubIndex &&
        widget.planSubIndex != _planSubIndex) {
      setState(() => _planSubIndex = widget.planSubIndex);
    }
  }

  void _setSubIndex(int i) {
    setState(() => _planSubIndex = i);
    widget.onPlanSubChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final c        = GenColors.of(context);
    final state    = ref.watch(studioGenerationProvider);
    final plan     = state.plan;
    final qCount   = state.questions.length;

    return Column(children: [
      // ── Sub-tab bar ─────────────────────────────────────────────────────
      Container(
        height: 40,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(children: [
          _PlanSubTab(
            label:    'Plan',
            selected: _planSubIndex == 0,
            c:        c,
            onTap:    () => _setSubIndex(0),
          ),
          _PlanSubTab(
            label:    'AI Assistant',
            selected: _planSubIndex == 1,
            c:        c,
            onTap:    () => _setSubIndex(1),
          ),
          _PlanSubTab(
            label:    'Questions',
            count:    qCount > 0 ? qCount : null,
            selected: _planSubIndex == 2,
            c:        c,
            onTap:    () => _setSubIndex(2),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      // ── Sub-tab body ─────────────────────────────────────────────────────
      Expanded(
        child: switch (_planSubIndex) {
          1 => _AiAssistantPanel(
              chatCtrl: widget.chatCtrl,
              messages: state.chatMessages,
              isStream: state.isStreaming,
              isLocked: state.isPlanApproved || !state.hasPlan,
              c:        c,
            ),
          2 => _QuestionsPanel(c: c),
          _ => () {
              final creatingPlan =
                  (state.currentView == 'polling' &&
                      state.pollingPhase == 'plan') ||
                  (state.isLoading && plan == null);
              if (creatingPlan) {
                return const StudioPollingView();
              }
              if (plan == null) {
                return _PlanEmptyState(
                  hasJd:        state.hasJd,
                  isLoading:    state.isLoading,
                  onCreatePlan: widget.onCreatePlan,
                  c:            c,
                );
              }
              return _PlanContent(
                plan:          plan,
                isLocked:      state.isPlanApproved,
                isLoading:     state.isLoading,
                chatMessages:  state.chatMessages,
                isStreaming:   state.isStreaming,
                chatCtrl:      widget.chatCtrl,
                onApprovePlan: widget.onApprovePlan,
                c:             c,
              );
            }(),
        },
      ),
    ]);
  }
}

class _PlanSubTab extends StatelessWidget {
  final String label;
  final int?   count;   // optional badge number
  final bool   selected;
  final GenColors c;
  final VoidCallback onTap;
  const _PlanSubTab({
    required this.label,
    this.count,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? GenColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: TextStyle(
              fontSize:   13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color:      selected ? GenColors.primary : c.textSub,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:        selected
                    ? GenColors.primary
                    : c.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color:      selected ? Colors.white : c.textSub,
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ]),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Questions panel — embedded in Plan tab sub-tab 2
// ══════════════════════════════════════════════════════════════════════════════

class _QuestionsPanel extends ConsumerWidget {
  final GenColors c;
  const _QuestionsPanel({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(studioGenerationProvider);
    final notifier  = ref.read(studioGenerationProvider.notifier);
    final questions = state.questions;
    final generating = state.currentView == 'polling' &&
        state.pollingPhase == 'questions';

    if (generating) {
      return const StudioPollingView();
    }

    if (questions.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.quiz_outlined, size: 40, color: c.muted),
          const SizedBox(height: 10),
          Text('Chưa có câu hỏi nào',
              style: TextStyle(color: c.textSub, fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Phê duyệt kế hoạch rồi nhấn Generate.',
              style: TextStyle(color: c.muted, fontSize: 12)),
        ]),
      );
    }

    // Stats row
    final easy   = questions.where((q) =>
        q.difficulty == StudioQuestionDifficulty.easy).length;
    final hard   = questions.where((q) =>
        q.difficulty == StudioQuestionDifficulty.hard).length;
    final edited = questions.where((q) => q.isEdited).length;

    return Column(children: [
      // ── Stats bar ───────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color:  c.card,
            border: Border(bottom: BorderSide(color: c.border))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QStat(label: 'Tổng',   value: '${questions.length}', color: c.text),
            _QStat(label: 'Dễ',     value: '$easy',  color: const Color(0xFF10B981)),
            _QStat(label: 'Khó',    value: '$hard',  color: const Color(0xFFEF4444)),
            _QStat(label: 'Đã sửa', value: '$edited',color: const Color(0xFFF59E0B)),
          ],
        ),
      ),
      // ── Question list ────────────────────────────────────────────────────
      Expanded(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${questions.length} câu hỏi được tạo',
                  style: TextStyle(
                      color:      c.text,
                      fontSize:   14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final q = questions[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudioQuestionCard(
                        question: q,
                        index:    i + 1,
                        onUpdate: (upd) => notifier.updateQuestion(upd),
                        onDelete: ()    => notifier.deleteQuestion(q.id),
                        onRegen:  ()    => notifier.regenerateQuestion(q.id),
                        c: c,
                      ),
                    );
                  },
                  childCount: questions.length,
                ),
              ),
            ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    padding:    const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color:  const Color(0xFFEF4444).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
                    child: Text(state.error!,
                        style: const TextStyle(
                            color: Color(0xFFEF4444), fontSize: 12)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    ]);
  }
}

// Small stat cell used inside _QuestionsPanel
class _QStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 18,
          fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(
          color: Color(0xFF9CA3AF), fontSize: 11)),
    ]);
}

// Question card — identical to the one in StudioQuestionReviewView
class _StudioQuestionCard extends StatefulWidget {
  final StudioQuestion question;
  final int index;
  final void Function(StudioQuestion) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onRegen;
  final GenColors c;
  const _StudioQuestionCard({
    required this.question, required this.index,
    required this.onUpdate, required this.onDelete,
    required this.onRegen,  required this.c,
  });
  @override
  State<_StudioQuestionCard> createState() => _StudioQuestionCardState();
}

class _StudioQuestionCardState extends State<_StudioQuestionCard> {
  bool _expanded = false;
  bool _editing  = false;
  late final _ctrl = TextEditingController(text: widget.question.content);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _save() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onUpdate(widget.question.copyWith(
        content: _ctrl.text.trim(), isEdited: true));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final c = widget.c;

    return Container(
      decoration: BoxDecoration(
          color:        c.card,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
              color: q.isEdited
                  ? GenColors.primary.withValues(alpha: 0.5)
                  : c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Index badge
            Container(
              width: 26, height: 26,
              margin: const EdgeInsets.only(right: 10, top: 1),
              decoration: BoxDecoration(
                  color: GenColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Center(child: Text('${widget.index}',
                  style: const TextStyle(
                      color:      GenColors.primary,
                      fontSize:   11,
                      fontWeight: FontWeight.w800))),
            ),
            // Difficulty + type chips
            Expanded(
              child: Wrap(spacing: 5, runSpacing: 4, children: [
                _qBadge(q.difficulty.displayName, _diffColor(q.difficulty)),
                _qBadge(q.type.displayName, const Color(0xFF3B82F6)),
              ]),
            ),
            // Action icons
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: c.textSub, onPressed: widget.onRegen,
                tooltip: 'Tạo lại', padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: c.textSub,
                onPressed: () => setState(() {
                  _editing = !_editing; _expanded = true;
                  if (!_editing) _ctrl.text = q.content;
                }),
                tooltip: 'Sửa', padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 18),
                color: const Color(0xFFEF4444), onPressed: widget.onDelete,
                tooltip: 'Xóa', padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
            ]),
          ]),
        ),
        // Question content
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: _editing
              ? TextField(
                  controller: _ctrl,
                  maxLines:   null,
                  autofocus:  true,
                  style:      TextStyle(color: c.text, fontSize: 14),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nội dung câu hỏi...',
                      hintStyle: TextStyle(color: c.textSub),
                      filled: true, fillColor: c.bg.withValues(alpha: 0.5)),
                )
              : GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(q.content,
                      maxLines: _expanded ? null : 3,
                      overflow:  _expanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.text, fontSize: 14, height: 1.5)),
                ),
        ),
        // Edit action bar
        if (_editing)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () =>
                    setState(() { _editing = false; _ctrl.text = q.content; }),
                child: Text('Huỷ', style: TextStyle(color: c.textSub)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: GenColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10)),
                child: const Text('Lưu'),
              ),
            ]),
          )
        else
          const SizedBox(height: 12),
        // Expected answer (collapsible)
        if (_expanded && q.expectedAnswer != null &&
            q.expectedAnswer!.isNotEmpty) ...[
          Divider(color: c.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Đáp án mẫu', style: TextStyle(
                  color: c.textSub, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(q.expectedAnswer!, style: TextStyle(
                  color: c.text, fontSize: 13, height: 1.5)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _qBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withValues(alpha: 0.3))),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Color _diffColor(StudioQuestionDifficulty d) => switch (d) {
    StudioQuestionDifficulty.easy   => const Color(0xFF10B981),
    StudioQuestionDifficulty.medium => const Color(0xFFF59E0B),
    StudioQuestionDifficulty.hard   => const Color(0xFFEF4444),
  };
}

// ── Plan empty state ───────────────────────────────────────────────────────────

class _PlanEmptyState extends StatelessWidget {
  final bool hasJd, isLoading;
  final VoidCallback onCreatePlan;
  final GenColors c;
  const _PlanEmptyState({
    required this.hasJd, required this.isLoading,
    required this.onCreatePlan, required this.c});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color:        GenColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: GenColors.primary, size: 32),
        ),
        const SizedBox(height: 18),
        Text('JD Ready',
            style: TextStyle(
                color: c.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          'AI will analyze the JD and build an interview plan suited to the role and level.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSub, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: hasJd && !isLoading ? onCreatePlan : null,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded, size: 17),
            label: Text(
              isLoading ? 'Đang tạo kế hoạch...' : 'Create Interview Plan',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GenColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    ),
  );
}

class _PlanContent extends StatelessWidget {
  final StudioPlanDetail plan;
  final bool isLocked, isLoading, isStreaming;
  final List<StudioChatMessage> chatMessages;
  final TextEditingController chatCtrl;
  final VoidCallback onApprovePlan;
  final GenColors c;

  const _PlanContent({
    required this.plan, required this.isLocked, required this.isLoading,
    required this.isStreaming, required this.chatMessages,
    required this.chatCtrl, required this.onApprovePlan, required this.c,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // ── Plan header card ─────────────────────────────────────────────
          _PlanHeaderCard(plan: plan, c: c),

          const SizedBox(height: 20),

          // ── Interview Structure ──────────────────────────────────────────
          if (plan.sections.isNotEmpty) ...[
            Row(children: [
              Text('INTERVIEW STRUCTURE',
                  style: TextStyle(
                      color:       c.muted, fontSize: 10,
                      fontWeight:  FontWeight.w700, letterSpacing: 0.8)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Text('${plan.sections.length} sections',
                    style: TextStyle(
                        color: c.textSub, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            ...List.generate(plan.sections.length,
                (i) => _SectionCard(index: i + 1, section: plan.sections[i], c: c)),
          ],

          // ── Evaluation Focus (RAG) ───────────────────────────────────────
          if (plan.focusAreas.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('EVALUATION FOCUS (RAG)',
                style: TextStyle(
                    color: c.muted, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ...plan.focusAreas.map((fa) => _FocusAreaRow(area: fa, c: c)),
          ],

          // ── Sources Used ─────────────────────────────────────────────────
          if (plan.sourcesUsed.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('SOURCES USED',
                style: TextStyle(
                    color: c.muted, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: plan.sourcesUsed
                  .map((s) => _SourceUsedChip(label: s, c: c))
                  .toList(),
            ),
          ],

          // ── Approved / locked banner ─────────────────────────────────────
          if (isLocked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded, size: 13, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Expanded(child: Text('Kế hoạch đã duyệt — chat tinh chỉnh bị khoá.',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 12))),
              ]),
            ),
          ],

          // ── Chat messages ────────────────────────────────────────────────
          if (chatMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Tinh chỉnh plan',
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...chatMessages.map((m) => _ChatBubble(msg: m, c: c)),
          ],
        ],
      ),
    ),
    if (!isLocked) ...[
      _ChatInputBar(ctrl: chatCtrl, isStream: isStreaming, c: c),
      _ApprovePlanBar(isLoading: isLoading, onApprove: onApprovePlan, c: c),
    ],
  ]);
}

// ── Plan header card ─────────────────────────────────────────────────────────

class _PlanHeaderCard extends StatelessWidget {
  final StudioPlanDetail plan;
  final GenColors c;
  const _PlanHeaderCard({required this.plan, required this.c});

  @override
  Widget build(BuildContext context) {
    final mix = plan.difficultyMix;
    String mixLabel = '';
    if (mix != null) {
      final e = (mix.easy   * 100).round();
      final m = (mix.medium * 100).round();
      final h = (mix.hard   * 100).round();
      if (e > 0 || m > 0 || h > 0) mixLabel = '${e}E·${m}M·${h}H';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PlanStatusChip(status: plan.status),
          const Spacer(),
          _InfoChip('${plan.totalQuestions} questions', c: c),
          const SizedBox(width: 6),
          _InfoChip('${plan.interviewLengthMinutes} min', c: c),
          if (mixLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            _InfoChip(mixLabel, c: c),
          ],
        ]),
        const SizedBox(height: 8),
        Text(plan.title,
            style: TextStyle(
                color: c.text, fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final GenColors c;
  const _InfoChip(this.label, {required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.border),
    ),
    child: Text(label,
        style: TextStyle(
            color: c.textSub, fontSize: 10, fontWeight: FontWeight.w500)),
  );
}

// ── Section card (expandable, with difficulty chip) ───────────────────────────

class _SectionCard extends StatefulWidget {
  final int index;
  final StudioPlanSection section;
  final GenColors c;
  const _SectionCard({required this.index, required this.section, required this.c});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final diff      = widget.section.difficulty;
    final diffColor = _diffColor(diff);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        widget.c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: widget.c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(children: [
              // Number badge
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color:        GenColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${widget.index}',
                      style: const TextStyle(
                          color: GenColors.primary, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.section.name,
                      style: TextStyle(
                          color: widget.c.text, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.section.numberOfQuestions} questions'
                    ' · ${widget.section.estimatedMinutes} min',
                    style: TextStyle(color: widget.c.muted, fontSize: 11)),
                ]),
              ),
              const SizedBox(width: 8),
              // Difficulty chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: diffColor.withValues(alpha: 0.3)),
                ),
                child: Text(diff.toApiString(),
                    style: TextStyle(
                        color:      diffColor,
                        fontSize:   10,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns:    _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: widget.c.muted),
              ),
            ]),
          ),
        ),
        if (_expanded &&
            widget.section.description != null &&
            widget.section.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 14, 12),
            child: Text(widget.section.description!,
                style: TextStyle(
                    color: widget.c.textSub, fontSize: 12, height: 1.4)),
          ),
      ]),
    );
  }

  Color _diffColor(StudioQuestionDifficulty d) {
    switch (d) {
      case StudioQuestionDifficulty.easy: return const Color(0xFF10B981);
      case StudioQuestionDifficulty.hard: return const Color(0xFFEF4444);
      default:                            return const Color(0xFFF59E0B);
    }
  }
}

// ── Focus area row (Evaluation Focus / RAG) ───────────────────────────────────

class _FocusAreaRow extends StatelessWidget {
  final StudioFocusArea area;
  final GenColors c;
  const _FocusAreaRow({required this.area, required this.c});

  @override
  Widget build(BuildContext context) {
    final pct    = (area.weight * 100).round();
    final source = area.sourceFiles.isNotEmpty ? area.sourceFiles.first : null;
    final label  = source != null ? '${area.name} — $source' : area.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: c.text, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('$pct%',
              style: const TextStyle(
                  color:      GenColors.primary,
                  fontSize:   12,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value:           area.weight.clamp(0.0, 1.0),
            minHeight:       4,
            backgroundColor: GenColors.primary.withValues(alpha: 0.10),
            valueColor:      const AlwaysStoppedAnimation<Color>(GenColors.primary),
          ),
        ),
      ]),
    );
  }
}

// ── Source used chip ──────────────────────────────────────────────────────────

class _SourceUsedChip extends StatelessWidget {
  final String label;
  final GenColors c;
  const _SourceUsedChip({required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: c.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.description_outlined, size: 11, color: c.muted),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(color: c.textSub, fontSize: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _PlanStatusChip extends StatelessWidget {
  final String status;
  const _PlanStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status.toLowerCase()) {
      case 'approved':
        label = 'Đã duyệt'; color = const Color(0xFF10B981);
      case 'awaitingapproval': case 'awaiting_approval':
        label = 'Chờ duyệt'; color = const Color(0xFFF59E0B);
      case 'archived':
        label = 'Lưu trữ'; color = const Color(0xFF6B7280);
      default:
        label = 'Nháp'; color = const Color(0xFF9CA3AF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final StudioChatMessage msg;
  final GenColors c;
  const _ChatBubble({required this.msg, required this.c});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? GenColors.primary : c.card,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(12),
            topRight:    const Radius.circular(12),
            bottomLeft:  Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
          border: isUser ? null : Border.all(color: c.border),
        ),
        child: msg.isStreaming
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(color: c.text, strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Đang xử lý...',
                    style: TextStyle(
                        color: c.muted, fontSize: 12, fontStyle: FontStyle.italic)),
              ])
            : Text(msg.content,
                style: TextStyle(
                    color: isUser ? Colors.white : c.text, fontSize: 12, height: 1.5)),
      ),
    );
  }
}

class _ChatInputBar extends ConsumerWidget {
  final TextEditingController ctrl;
  final bool isStream;
  final GenColors c;
  const _ChatInputBar({required this.ctrl, required this.isStream, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color:  c.card,
      border: Border(top: BorderSide(color: c.border)),
    ),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
              color: c.bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border)),
          child: TextField(
            controller: ctrl,
            enabled:    !isStream,
            minLines: 1, maxLines: 3,
            style: TextStyle(color: c.text, fontSize: 13),
            cursorColor: GenColors.primary,
            decoration: InputDecoration(
              hintText:       'Tinh chỉnh kế hoạch...',
              hintStyle:      TextStyle(color: c.hint, fontSize: 13),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              if (!isStream) {
                final msg = ctrl.text.trim();
                if (msg.isNotEmpty) {
                  ctrl.clear();
                  ref.read(studioGenerationProvider.notifier).sendRefinement(msg);
                }
              }
            },
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: isStream ? null : () {
          final msg = ctrl.text.trim();
          if (msg.isNotEmpty) {
            ctrl.clear();
            ref.read(studioGenerationProvider.notifier).sendRefinement(msg);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: isStream ? c.border : GenColors.primary, shape: BoxShape.circle),
          child: isStream
              ? const Center(child: SizedBox(width: 15, height: 15,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
        ),
      ),
    ]),
  );
}

class _ApprovePlanBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onApprove;
  final GenColors c;
  const _ApprovePlanBar({required this.isLoading, required this.onApprove, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
    decoration: BoxDecoration(
        color: c.bg, border: Border(top: BorderSide(color: c.border))),
    child: SizedBox(
      width: double.infinity, height: 46,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onApprove,
        icon: isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_circle_outline_rounded, size: 17),
        label: const Text('Duyệt & Tạo câu hỏi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    ),
  );
}

class _AiAssistantPanel extends ConsumerWidget {
  final TextEditingController chatCtrl;
  final List<StudioChatMessage> messages;
  final bool isStream, isLocked;
  final GenColors c;
  const _AiAssistantPanel({required this.chatCtrl, required this.messages,
      required this.isStream, required this.isLocked, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
    Expanded(
      child: messages.isEmpty
          ? Center(
              child: Text(
                isLocked
                    ? 'Kế hoạch đã được duyệt.\nKhông thể chỉnh sửa thêm.'
                    : 'Chat với AI để tinh chỉnh kế hoạch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) => _ChatBubble(msg: messages[i], c: c),
            ),
    ),
    if (!isLocked)
      _ChatInputBar(ctrl: chatCtrl, isStream: isStream, c: c),
  ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Settings (Plan Configuration + Output Options)
// ══════════════════════════════════════════════════════════════════════════════

class _StudioSettingsTab extends StatefulWidget {
  final int duration, questionCount;
  final String difficulty, questionTone, outputFormat, contentMode, language;
  final Set<String> questionTypes, codeTemplates;
  final bool sampleAnswers, scoringRubric;
  final bool showApply, isApplying, isLocked;
  final VoidCallback? onApply;

  final ValueChanged<int>         onDurationChanged;
  final ValueChanged<int>         onQuestionCountChanged;
  final ValueChanged<String>      onDifficultyChanged;
  final ValueChanged<Set<String>> onQuestionTypesChanged;
  final ValueChanged<String>      onQuestionToneChanged;
  final ValueChanged<String>      onOutputFormatChanged;
  final ValueChanged<String>      onContentModeChanged;
  final ValueChanged<Set<String>> onCodeTemplatesChanged;
  final ValueChanged<String>      onLanguageChanged;
  final ValueChanged<bool>        onSampleAnswersChanged;
  final ValueChanged<bool>        onScoringRubricChanged;

  const _StudioSettingsTab({
    required this.duration, required this.questionCount,
    required this.difficulty, required this.questionTone,
    required this.outputFormat, required this.contentMode,
    required this.language, required this.questionTypes,
    required this.codeTemplates, required this.sampleAnswers,
    required this.scoringRubric,
    this.showApply = false,
    this.isApplying = false,
    this.isLocked = false,
    this.onApply,
    required this.onDurationChanged, required this.onQuestionCountChanged,
    required this.onDifficultyChanged, required this.onQuestionTypesChanged,
    required this.onQuestionToneChanged, required this.onOutputFormatChanged,
    required this.onContentModeChanged, required this.onCodeTemplatesChanged,
    required this.onLanguageChanged, required this.onSampleAnswersChanged,
    required this.onScoringRubricChanged,
  });

  @override
  State<_StudioSettingsTab> createState() => _StudioSettingsTabState();
}

class _StudioSettingsTabState extends State<_StudioSettingsTab> {
  late final TextEditingController _durationCtrl;
  late final TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    _durationCtrl = TextEditingController(text: widget.duration.toString());
    _countCtrl    = TextEditingController(text: widget.questionCount.toString());
  }

  @override
  void didUpdateWidget(_StudioSettingsTab old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) {
      _durationCtrl.text = widget.duration.toString();
    }
    if (widget.questionCount != old.questionCount) {
      _countCtrl.text = widget.questionCount.toString();
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);

    return IgnorePointer(
      ignoring: widget.isLocked,
      child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ══ Plan Configuration ════════════════════════════════════════════
        Row(children: [
          Expanded(child: _SectionHeader('Plan Configuration', c: c)),
          if (widget.isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Locked',
                  style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),

        // Duration
        const SizedBox(height: 12),
        _SettingLabel('Duration', c: c),
        const SizedBox(height: 8),
        _NumberInput(
          ctrl:    _durationCtrl,
          suffix:  'min',
          min: 15, max: 180,
          c: c,
          onChanged: (v) => widget.onDurationChanged(v),
        ),
        const SizedBox(height: 8),
        _QuickChips(
          values:   const [30, 45, 60, 75, 90, 120],
          selected: widget.duration,
          onTap: (v) {
            widget.onDurationChanged(v);
            _durationCtrl.text = v.toString();
          },
          c: c,
        ),

        // Question Count
        const SizedBox(height: 16),
        _SettingLabel('Question Count', c: c),
        const SizedBox(height: 8),
        _NumberInput(
          ctrl:   _countCtrl,
          suffix: 'questions',
          min: 5, max: 50,
          c: c,
          onChanged: (v) => widget.onQuestionCountChanged(v),
        ),
        const SizedBox(height: 8),
        _QuickChips(
          values:   const [5, 10, 15, 20, 25, 30],
          selected: widget.questionCount,
          onTap: (v) {
            widget.onQuestionCountChanged(v);
            _countCtrl.text = v.toString();
          },
          c: c,
        ),

        // Difficulty
        const SizedBox(height: 16),
        _SettingLabel('Difficulty', c: c),
        const SizedBox(height: 8),
        _DropdownField<String>(
          value: widget.difficulty,
          items: const [
            DropdownMenuItem(value: 'Easy',   child: Text('Easy — beginner')),
            DropdownMenuItem(value: 'Medium', child: Text('Medium — standard')),
            DropdownMenuItem(value: 'Hard',   child: Text('Hard — advanced')),
          ],
          onChanged: widget.onDifficultyChanged,
          c: c,
        ),

        // Question types
        const SizedBox(height: 16),
        Row(children: [
          _SettingLabel('Question types', c: c),
          const Spacer(),
          Text('${widget.questionTypes.length}/5 ··−3 per type',
              style: TextStyle(color: c.muted, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _TypeChip(label: 'Tech',     value: 'technical',      sel: widget.questionTypes, onToggle: _toggleType, c: c),
          _TypeChip(label: 'Design',   value: 'system_design',  sel: widget.questionTypes, onToggle: _toggleType, c: c),
          _TypeChip(label: 'Problem',  value: 'problem_solving', sel: widget.questionTypes, onToggle: _toggleType, c: c),
          _TypeChip(label: 'Behavior', value: 'behavioral',     sel: widget.questionTypes, onToggle: _toggleType, c: c),
          _TypeChip(label: 'Situation',value: 'situational',    sel: widget.questionTypes, onToggle: _toggleType, c: c),
        ]),

        // ══ Output Options ════════════════════════════════════════════════
        const SizedBox(height: 22),
        _SectionHeader('Output Options', c: c),

        // Question Tone
        const SizedBox(height: 12),
        _SettingLabel('Question Tone', c: c),
        const SizedBox(height: 8),
        _DropdownField<String>(
          value: widget.questionTone,
          items: const [
            DropdownMenuItem(value: 'Professional', child: Text('Professional')),
            DropdownMenuItem(value: 'Friendly',     child: Text('Friendly')),
            DropdownMenuItem(value: 'Academic',     child: Text('Academic')),
            DropdownMenuItem(value: 'Technical',    child: Text('Technical')),
          ],
          onChanged: widget.onQuestionToneChanged,
          c: c,
        ),

        // Output Format
        const SizedBox(height: 14),
        _SettingLabel('Output Format', c: c),
        const SizedBox(height: 8),
        _DropdownField<String>(
          value: widget.outputFormat,
          items: const [
            DropdownMenuItem(value: 'StructuredInterviewKit', child: Text('Structured Interview Kit')),
            DropdownMenuItem(value: 'QuestionList',           child: Text('Question List')),
          ],
          onChanged: widget.onOutputFormatChanged,
          c: c,
        ),

        // Question content mode
        const SizedBox(height: 14),
        _SettingLabel('Question content mode', c: c),
        const SizedBox(height: 8),
        _DropdownField<String>(
          value: widget.contentMode,
          items: const [
            DropdownMenuItem(value: 'Mixed',      child: Text('Mix theory + code')),
            DropdownMenuItem(value: 'TheoryOnly', child: Text('Theory only')),
            DropdownMenuItem(value: 'CodeOnly',   child: Text('Code only')),
          ],
          onChanged: widget.onContentModeChanged,
          c: c,
        ),

        // Code templates
        const SizedBox(height: 14),
        Row(children: [
          _SettingLabel('Code templates', c: c),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text('Choose templates enabled for AI generation and manual builder.',
              style: TextStyle(color: c.muted, fontSize: 11)),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _TemplateChip(label: 'Code completion',    value: 'CODE_COMPLETION',    sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
          _TemplateChip(label: 'Bug detection',      value: 'BUG_DETECTION',      sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
          _TemplateChip(label: 'Refactoring',        value: 'REFACTORING',        sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
          _TemplateChip(label: 'Test case design',   value: 'TEST_CASE_DESIGN',   sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
          _TemplateChip(label: 'Performance analysis', value: 'PERFORMANCE_ANALYSIS', sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
          _TemplateChip(label: 'System design',      value: 'SYSTEM_DESIGN',      sel: widget.codeTemplates, onToggle: _toggleTemplate, c: c),
        ]),

        // Question Language
        const SizedBox(height: 14),
        _SettingLabel('Question Language', c: c),
        const SizedBox(height: 8),
        _DropdownField<String>(
          value: widget.language,
          items: const [
            DropdownMenuItem(value: 'Vietnamese', child: Text('Tiếng Việt')),
            DropdownMenuItem(value: 'English',    child: Text('English')),
          ],
          onChanged: widget.onLanguageChanged,
          c: c,
        ),

        // Sample answers toggle
        const SizedBox(height: 14),
        _ToggleRow(
          label:    'Sample answers',
          subtitle: 'Suggested sample answers',
          value:    widget.sampleAnswers,
          onChanged: widget.onSampleAnswersChanged,
          c: c,
        ),

        // Scoring rubric toggle
        const SizedBox(height: 8),
        _ToggleRow(
          label:    'Scoring rubric',
          subtitle: 'Answer evaluation criteria',
          value:    widget.scoringRubric,
          onChanged: widget.onScoringRubricChanged,
          c: c,
        ),

        if (widget.showApply) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.isApplying ? null : widget.onApply,
              icon: widget.isApplying
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                widget.isApplying ? 'Đang áp dụng...' : 'Apply to plan',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: GenColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    ),
    );
  }

  void _toggleType(String value) {
    final copy = Set<String>.from(widget.questionTypes);
    if (copy.contains(value)) {
      if (copy.length > 1) copy.remove(value);
    } else {
      copy.add(value);
    }
    widget.onQuestionTypesChanged(copy);
  }

  void _toggleTemplate(String value) {
    final copy = Set<String>.from(widget.codeTemplates);
    if (copy.contains(value)) {
      copy.remove(value);
    } else {
      copy.add(value);
    }
    widget.onCodeTemplatesChanged(copy);
  }
}

// ── Settings sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final GenColors c;
  const _SectionHeader(this.title, {required this.c});

  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(color: c.muted, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _SettingLabel extends StatelessWidget {
  final String label;
  final GenColors c;
  const _SettingLabel(this.label, {required this.c});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600));
}

class _NumberInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String suffix;
  final int min, max;
  final GenColors c;
  final ValueChanged<int> onChanged;
  const _NumberInput({required this.ctrl, required this.suffix,
      required this.min, required this.max, required this.c, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: c.border),
    ),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RangeFormatter(min, max),
          ],
          style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
          cursorColor: GenColors.primary,
          decoration: const InputDecoration(
            border:         InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14),
          ),
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= min && n <= max) onChanged(n);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(suffix, style: TextStyle(color: c.muted, fontSize: 12)),
      ),
    ]),
  );
}

class _QuickChips extends StatelessWidget {
  final List<int> values;
  final int selected;
  final void Function(int) onTap;
  final GenColors c;
  const _QuickChips({required this.values, required this.selected,
      required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6, runSpacing: 6,
    children: values.map((v) {
      final sel = v == selected;
      return GestureDetector(
        onTap: () => onTap(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color:        sel ? GenColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? GenColors.primary : c.border, width: 1.5),
          ),
          child: Text('$v',
              style: TextStyle(
                color:      sel ? Colors.white : c.textSub,
                fontSize:   12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              )),
        ),
      );
    }).toList(),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final GenColors c;
  const _DropdownField({required this.value, required this.items,
      required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: c.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value:         value,
        isExpanded:    true,
        dropdownColor: c.card,
        icon:          Icon(Icons.keyboard_arrow_down_rounded, color: c.muted, size: 18),
        style:         TextStyle(color: c.text, fontSize: 13),
        items:         items,
        onChanged:     (v) { if (v != null) onChanged(v); },
      ),
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final String label, value;
  final Set<String> sel;
  final void Function(String) onToggle;
  final GenColors c;
  const _TypeChip({required this.label, required this.value,
      required this.sel, required this.onToggle, required this.c});

  @override
  Widget build(BuildContext context) {
    final active = sel.contains(value);
    return GestureDetector(
      onTap: () => onToggle(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        active ? GenColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? GenColors.primary : c.border, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (active) ...[
            const Icon(Icons.check, size: 11, color: GenColors.primary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color:      active ? GenColors.primary : c.textSub,
                  fontSize:   12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label, value;
  final Set<String> sel;
  final void Function(String) onToggle;
  final GenColors c;
  const _TemplateChip({required this.label, required this.value,
      required this.sel, required this.onToggle, required this.c});

  @override
  Widget build(BuildContext context) {
    final active = sel.contains(value);
    return GestureDetector(
      onTap: () => onToggle(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        active ? GenColors.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? GenColors.primary : c.border, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (active)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: GenColors.primary, shape: BoxShape.circle),
                child: Center(child: Icon(Icons.check, size: 9, color: Colors.white)),
              ),
            ),
          Text(label,
              style: TextStyle(
                  color:      active ? GenColors.primary : c.textSub,
                  fontSize:   12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final GenColors c;
  const _ToggleRow({required this.label, required this.subtitle,
      required this.value, required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: c.muted, fontSize: 11)),
      ],
    )),
    Switch(
      value:            value,
      onChanged:        onChanged,
      activeThumbColor: GenColors.primary,
      activeTrackColor: GenColors.primary.withValues(alpha: 0.35),
    ),
  ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// Quota / cooldown dialog
// ══════════════════════════════════════════════════════════════════════════════

class _CooldownDialog extends StatelessWidget {
  final String? message;
  const _CooldownDialog({this.message});

  @override
  Widget build(BuildContext context) {
    final c      = GenColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msg    = message ??
        'Bạn đã đạt giới hạn tạo câu hỏi. Vui lòng thử lại sau hoặc nâng cấp gói dịch vụ.';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded,
                color: Color(0xFF111827), size: 36),
          ),
          const SizedBox(height: 20),
          Text('Giới hạn tạo câu hỏi',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSub, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/hr/settings?tab=billing');
              },
              icon:  const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Đi tới gói dịch vụ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GenColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng', style: TextStyle(color: c.muted, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

// ── "Tạo bộ mới" AppBar button (shown during polling) ────────────────────────

class _NewSetBtn extends StatelessWidget {
  final GenColors c;
  final VoidCallback onTap;
  const _NewSetBtn({required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: GenColors.primary.withValues(alpha: 0.35)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, size: 14, color: GenColors.primary),
        SizedBox(width: 4),
        Text('Tạo mới',
            style: TextStyle(
                color:      GenColors.primary,
                fontSize:   12,
                fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Confirm "start new" dialog ────────────────────────────────────────────────

class _ConfirmNewSetDialog extends StatelessWidget {
  final bool wasPolling;
  const _ConfirmNewSetDialog({this.wasPolling = false});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: c.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color:        GenColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
                wasPolling ? Icons.queue_rounded : Icons.add_circle_outline_rounded,
                size: 28, color: GenColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Tạo bộ câu hỏi mới?',
              style: TextStyle(
                  color: c.text, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            wasPolling
                ? 'Bộ câu hỏi đang tạo sẽ tiếp tục được xử lý '
                  'trong hàng đợi. Bạn có thể xem kết quả '
                  'tại Lịch sử sau khi hoàn tất.'
                : 'Phiên hiện tại sẽ bị xoá và bạn sẽ bắt đầu '
                  'lại từ đầu. Kết quả đã lưu vẫn còn trong Lịch sử.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.textSub, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor:  c.textSub,
                  side:             BorderSide(color: c.border),
                  padding: const    EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Huỷ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon:  const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tạo bộ mới'),
                style: FilledButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Range formatter ───────────────────────────────────────────────────────────

class _RangeFormatter extends TextInputFormatter {
  final int min, max;
  _RangeFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;
    final n = int.tryParse(newVal.text);
    if (n == null) return old;
    if (n > max) {
      final s = max.toString();
      return newVal.copyWith(
          text: s, selection: TextSelection.collapsed(offset: s.length));
    }
    return newVal;
  }
}
