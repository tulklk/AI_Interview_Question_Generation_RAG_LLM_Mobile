import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/studio_repository.dart';
import '../../domain/models/studio_models.dart';

// ── Persistence ───────────────────────────────────────────────────────────────

class _StudioPrefs {
  static const kView      = 'studio_v2_view';
  static const kProjectId = 'studio_v2_project_id';
  static const kPlanId    = 'studio_v2_plan_id';
  static const kRunId     = 'studio_v2_run_id';
  static const kPhase     = 'studio_v2_phase';

  static Future<void> save({
    String? view,
    String? projectId,
    String? planId,
    String? runId,
    String? phase,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (view      != null) await p.setString(kView,      view);
    if (projectId != null) await p.setString(kProjectId, projectId);
    if (planId    != null) await p.setString(kPlanId,    planId);
    if (runId     != null) await p.setString(kRunId,     runId);
    if (phase     != null) await p.setString(kPhase,     phase);
  }

  static Future<Map<String, String?>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      'view':      p.getString(kView),
      'projectId': p.getString(kProjectId),
      'planId':    p.getString(kPlanId),
      'runId':     p.getString(kRunId),
      'phase':     p.getString(kPhase),
    };
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.remove(kView),
      p.remove(kProjectId),
      p.remove(kPlanId),
      p.remove(kRunId),
      p.remove(kPhase),
    ]);
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

/// Views matching the original UI views so StudioWizardScreen wiring is trivial.
/// form | polling | plan_review | question_review | failed | draft_view
typedef StudioView = String;

class StudioGenState {
  final StudioView currentView;  // form|polling|plan_review|question_review|failed|draft_view
  final String pollingPhase;    // 'plan' | 'questions'
  final bool isLoading;
  final bool isRestoring;
  final String? error;
  final String? statusLabel;

  // Studio identifiers
  final String? projectId;
  final String? planId;
  final String? runId;

  // Data
  final StudioSettings? settings;
  final StudioPlanDetail? plan;
  final List<StudioQuestion> questions;
  final StudioGenerationRun? latestRun;

  // ── New UI state flags (spec §7.4 / §7.9) ────────────────────────────────
  /// True when side columns (docs + settings/questions) should be non-interactive.
  final bool sideColumnsLocked;
  /// True while streaming a chat reply from the assistant.
  final bool isStreaming;
  /// True while applying settings to plan.
  final bool isApplyingSettings;
  /// True while save draft API call is in-flight.
  final bool isSavingDraft;
  /// True after successful save; resets when questions/plan changes.
  final bool isDraftSaved;
  /// True when quota is exhausted and the quota dialog should be shown.
  final bool quotaBlocked;
  final String? quotaResetAt;  // ISO8601 string of when quota resets

  // ── Documents ─────────────────────────────────────────────────────────────
  final List<StudioDocument> documents;

  // ── Chat messages ─────────────────────────────────────────────────────────
  final List<StudioChatMessage> chatMessages;
  final String? chatSessionId;

  const StudioGenState({
    this.currentView        = 'form',
    this.pollingPhase       = 'plan',
    this.isLoading          = false,
    this.isRestoring        = false,
    this.error,
    this.statusLabel,
    this.projectId,
    this.planId,
    this.runId,
    this.settings,
    this.plan,
    this.questions          = const [],
    this.latestRun,
    this.sideColumnsLocked  = false,
    this.isStreaming         = false,
    this.isApplyingSettings  = false,
    this.isSavingDraft       = false,
    this.isDraftSaved        = false,
    this.quotaBlocked        = false,
    this.quotaResetAt,
    this.documents           = const [],
    this.chatMessages        = const [],
    this.chatSessionId,
  });

  StudioGenState copyWith({
    String?                  currentView,
    String?                  pollingPhase,
    bool?                    isLoading,
    bool?                    isRestoring,
    bool                     clearError          = false,
    String?                  error,
    String?                  statusLabel,
    String?                  projectId,
    String?                  planId,
    String?                  runId,
    StudioSettings?          settings,
    StudioPlanDetail?        plan,
    bool                     clearPlan           = false,
    List<StudioQuestion>?    questions,
    StudioGenerationRun?     latestRun,
    bool?                    sideColumnsLocked,
    bool?                    isStreaming,
    bool?                    isApplyingSettings,
    bool?                    isSavingDraft,
    bool?                    isDraftSaved,
    bool?                    quotaBlocked,
    String?                  quotaResetAt,
    List<StudioDocument>?    documents,
    List<StudioChatMessage>? chatMessages,
    String?                  chatSessionId,
  }) =>
      StudioGenState(
        currentView:        currentView        ?? this.currentView,
        pollingPhase:       pollingPhase       ?? this.pollingPhase,
        isLoading:          isLoading          ?? this.isLoading,
        isRestoring:        isRestoring        ?? this.isRestoring,
        error:              clearError         ? null : (error ?? this.error),
        statusLabel:        statusLabel        ?? this.statusLabel,
        projectId:          projectId          ?? this.projectId,
        planId:             planId             ?? this.planId,
        runId:              runId              ?? this.runId,
        settings:           settings           ?? this.settings,
        plan:               clearPlan          ? null : (plan ?? this.plan),
        questions:          questions          ?? this.questions,
        latestRun:          latestRun          ?? this.latestRun,
        sideColumnsLocked:  sideColumnsLocked  ?? this.sideColumnsLocked,
        isStreaming:        isStreaming         ?? this.isStreaming,
        isApplyingSettings: isApplyingSettings ?? this.isApplyingSettings,
        isSavingDraft:      isSavingDraft      ?? this.isSavingDraft,
        isDraftSaved:       isDraftSaved       ?? this.isDraftSaved,
        quotaBlocked:       quotaBlocked       ?? this.quotaBlocked,
        quotaResetAt:       quotaResetAt       ?? this.quotaResetAt,
        documents:          documents          ?? this.documents,
        chatMessages:       chatMessages       ?? this.chatMessages,
        chatSessionId:      chatSessionId      ?? this.chatSessionId,
      );

  // Convenience
  bool get hasProject     => projectId != null && projectId!.isNotEmpty;
  bool get hasPlan        => plan      != null;
  bool get hasQuestions   => questions.isNotEmpty;
  bool get isPlanApproved => plan?.isApproved ?? false;

  StudioReadiness get readiness =>
      settings?.readiness ?? const StudioReadiness();

  // Expose jobId alias so existing view widgets compile unchanged
  String? get jobId => projectId;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StudioGenerationNotifier extends StateNotifier<StudioGenState> {
  final StudioRepository _repo;
  Timer? _pollTimer;
  bool   _pollInFlight = false;

  // Spec §7.5 — poll every 2500ms, timeout 5 min
  static const _pollInterval  = Duration(milliseconds: 2500);
  static const _pollMaxMs     = 5 * 60 * 1000; // 5 minutes
  static const _errorInterval = Duration(seconds: 8);

  int    _pollElapsedMs = 0;

  StudioGenerationNotifier(this._repo) : super(const StudioGenState());

  @override
  void dispose() {
    _cancelPoll();
    super.dispose();
  }

  void _cancelPoll() { _pollTimer?.cancel(); _pollTimer = null; }

  // ── Storage helpers ────────────────────────────────────────────────────────

  Future<void> _persist({
    String? view,
    String? projectId,
    String? planId,
    String? runId,
    String? phase,
  }) => _StudioPrefs.save(
        view:      view      ?? state.currentView,
        projectId: projectId ?? state.projectId,
        planId:    planId    ?? state.planId,
        runId:     runId     ?? state.runId,
        phase:     phase     ?? state.pollingPhase,
      );

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> restoreFromStorage() async {
    final saved     = await _StudioPrefs.load();
    final projectId = saved['projectId'];
    if (projectId == null || projectId.isEmpty) return;

    state = state.copyWith(
      projectId:   projectId,
      planId:      saved['planId'],
      runId:       saved['runId'],
      currentView: saved['view'] ?? 'form',
      pollingPhase: saved['phase'] ?? 'plan',
      isRestoring: true,
    );

    try {
      await _loadProjectState(projectId);
    } catch (_) {
      await _StudioPrefs.clearAll();
      state = const StudioGenState();
    }
  }

  /// Load settings + current plan for an existing project, then decide view.
  Future<void> _loadProjectState(String projectId) async {
    StudioSettings? settings;
    StudioPlanDetail? plan;

    try {
      settings = await _repo.getSettings(projectId);
    } catch (_) {}

    try {
      plan = await _repo.getCurrentPlan(projectId);
    } catch (_) {}

    if (!mounted) return;

    final newPlanId = plan?.id ?? state.planId;

    // Check if there is an active run
    StudioGenerationRun? activeRun;
    if (state.runId != null && state.runId!.isNotEmpty) {
      try {
        activeRun = await _repo.getGenerationRun(projectId, state.runId!);
        if (activeRun.status.isTerminal) activeRun = null;
      } catch (_) {}
    }
    if (activeRun == null) {
      try {
        final latest = await _repo.getLatestGenerationRun(projectId);
        if (latest != null && latest.status.isRunning) activeRun = latest;
      } catch (_) {}
    }

    if (!mounted) return;

    // Also load documents, chat messages, and questions (if plan approved) in background
    List<StudioDocument> docs = [];
    List<StudioChatMessage> msgs = [];
    List<StudioQuestion> questions = [];
    try { docs = await _repo.listDocuments(projectId); } catch (_) {}
    try { msgs = await _repo.getChatMessages(projectId); } catch (_) {}
    if (plan != null && (plan.isApproved || plan.status.toLowerCase() == 'generated')) {
      try { questions = await _repo.listQuestions(projectId, planId: plan.id); } catch (_) {}
    }

    if (!mounted) return;

    state = state.copyWith(
      isRestoring:  false,
      projectId:    projectId,
      planId:       newPlanId,
      runId:        activeRun?.id ?? state.runId,
      settings:     settings,
      plan:         plan,
      documents:    docs,
      chatMessages: msgs,
      questions:    questions,
    );

    if (activeRun != null) {
      final phase = _phaseFromRun(activeRun, plan);
      state = state.copyWith(
          currentView: 'polling', pollingPhase: phase, latestRun: activeRun);
      await _persist(view: 'polling', phase: phase, runId: activeRun.id);
      _startPolling(phase, activeRun.id);
      return;
    }

    final view = _viewFromProjectState(settings, plan);
    state = state.copyWith(currentView: view);
    await _persist(view: view, planId: newPlanId);
  }

  String _phaseFromRun(StudioGenerationRun run, StudioPlanDetail? plan) =>
      (plan != null && plan.isApproved) ? 'questions' : 'plan';

  String _viewFromProjectState(
      StudioSettings? settings, StudioPlanDetail? plan) {
    if (plan == null) return 'form';
    // If we already have questions loaded, show question_review
    if (state.questions.isNotEmpty) return 'question_review';
    // plan_review covers: draft, refining, awaitingApproval, approved
    return 'plan_review';
  }

  // ── Step 1: Submit JD (creates project + saves JD + generates plan) ─────────

  Future<void> submitJob({
    required String jd,
    String? projectName,
    int numberOfQuestions = 15,
    String difficulty = 'Medium',
    List<String> questionTypes = const [
      'technical', 'system_design', 'problem_solving', 'behavioral'
    ],
  }) async {
    if (jd.trim().length < 50) {
      state = state.copyWith(
          error: 'Mô tả công việc phải có ít nhất 50 ký tự');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Create project
      final name = (projectName?.trim().isNotEmpty == true)
          ? projectName!
          : 'Phỏng vấn ${DateTime.now().year}';

      final project = await _repo.createProject(name: name);
      final projectId = project.id;

      // 2. Save JD
      await _repo.saveJobDescription(projectId, content: jd);

      // 3. Push settings (all required fields per backend validation)
      await _repo.updateSettings(projectId, {
        'numberOfQuestions':     numberOfQuestions,
        'difficulty':            difficulty,
        'questionTypes':         questionTypes,
        'includeSampleAnswers':  true,
        'includeScoringRubric':  true,
        'outputLanguage':        'Vietnamese',
        'outputFormat':          'Structured',
        'questionTone':          'Professional',
        'interviewLengthMinutes': 60,
        'contentMode':           'Mixed',
      });

      // 4. Generate plan
      await _repo.generatePlan(projectId);

      state = state.copyWith(
        isLoading:    false,
        projectId:    projectId,
        currentView:  'polling',
        pollingPhase: 'plan',
      );
      await _persist(view: 'polling', phase: 'plan', projectId: projectId);
      _startPolling('plan', null);
    } catch (e) {
      if (!_handleQuota(e)) {
        state = state.copyWith(isLoading: false, error: _friendly(e));
      }
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling(String phase, String? runId) {
    _cancelPoll();
    _pollElapsedMs = 0;
    _pollTimer = Timer(_pollInterval, () => _doPoll(phase, runId));
  }

  Future<void> _doPoll(String phase, String? runId) async {
    final projectId = state.projectId;
    if (projectId == null || !mounted || _pollInFlight) return;

    _pollElapsedMs += _pollInterval.inMilliseconds;
    if (_pollElapsedMs >= _pollMaxMs) {
      state = state.copyWith(
          currentView: 'failed',
          error: 'Hết thời gian chờ. Vui lòng thử lại.',
          statusLabel: null);
      return;
    }

    _pollInFlight = true;
    try {
      if (phase == 'plan') {
        await _doPollPlan(projectId);
      } else {
        await _doPollQuestions(projectId, runId);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(statusLabel: 'Đang thử lại...');
      _pollTimer = Timer(_errorInterval, () => _doPoll(phase, runId));
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _doPollPlan(String projectId) async {
    final plan = await _repo.getCurrentPlan(projectId);
    if (!mounted) return;

    if (plan == null) {
      state = state.copyWith(statusLabel: 'Đang sinh plan...');
      // Schedule next poll through _doPoll so timeout is respected
      _pollTimer = Timer(_pollInterval, () => _doPoll('plan', null));
      return;
    }

    final status = plan.status.toLowerCase();

    if (status == 'approved') {
      // Plan already approved — show plan_review
      state = state.copyWith(
          plan: plan, planId: plan.id, currentView: 'plan_review',
          statusLabel: null, clearError: true);
      await _persist(view: 'plan_review', planId: plan.id);
      return;
    }

    if (status == 'awaitingapproval' || status == 'draft' ||
        status == 'refining') {
      state = state.copyWith(
          plan: plan, planId: plan.id, currentView: 'plan_review',
          statusLabel: null, clearError: true);
      await _persist(view: 'plan_review', planId: plan.id);
      return;
    }

    // Unknown / intermediate — keep polling through _doPoll
    state = state.copyWith(plan: plan, statusLabel: 'Đang sinh plan...');
    _pollTimer = Timer(_pollInterval, () => _doPoll('plan', null));
  }

  Future<void> _doPollQuestions(String projectId, String? runId) async {
    StudioGenerationRun? run;
    if (runId != null && runId.isNotEmpty) {
      try {
        run = await _repo.getGenerationRun(projectId, runId);
      } catch (_) {}
    }
    run ??= await _repo.getLatestGenerationRun(projectId);

    if (!mounted) return;

    if (run == null) {
      state = state.copyWith(statusLabel: 'Đang tạo câu hỏi...');
      _pollTimer = Timer(_pollInterval, () => _doPoll('questions', runId));
      return;
    }

    state = state.copyWith(
        latestRun:   run,
        runId:       run.id,
        statusLabel: _runLabel(run));

    if (run.status.isRunning) {
      _pollTimer = Timer(_pollInterval, () => _doPoll('questions', run!.id));
      return;
    }

    if (run.status == GenerationRunStatus.completed) {
      final planId = state.planId ?? run.planId;
      List<StudioQuestion> qs = [];
      try {
        qs = await _repo.listQuestions(projectId, planId: planId);
      } catch (_) {}

      if (qs.isEmpty) {
        // Retry once after 2500ms (spec §7.6)
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;
        try { qs = await _repo.listQuestions(projectId, planId: planId); } catch (_) {}
      }

      state = state.copyWith(
          questions:    qs,
          currentView:  'question_review',
          statusLabel:  null,
          clearError:   true);
      await _persist(view: 'question_review');
      return;
    }

    // Failed / Cancelled
    state = state.copyWith(
        currentView:  'failed',
        error:        run.errorMessage ?? 'Sinh câu hỏi thất bại.',
        statusLabel:  null);
    await _persist(view: 'failed');
  }

  String _runLabel(StudioGenerationRun run) {
    if (run.generatedQuestionCount > 0) {
      return 'Đã tạo ${run.generatedQuestionCount}/${run.requestedQuestionCount} câu...';
    }
    return 'Đang tạo câu hỏi...';
  }

  // ── Approve plan ───────────────────────────────────────────────────────────

  Future<void> approvePlan({String? notes}) async {
    final projectId = state.projectId;
    final plan      = state.plan;
    if (projectId == null || plan == null) return;

    state = state.copyWith(
        isLoading: true, clearError: true,
        currentView: 'polling', pollingPhase: 'questions');
    await _persist(view: 'polling', phase: 'questions');

    try {
      await _repo.approvePlan(
        projectId,
        plan.id,
        revision:           plan.revision,
        concurrencyVersion: plan.concurrencyVersion,
        notes:              notes,
      );

      final settings = state.settings;
      final planId   = plan.id;
      final runId = await _repo.generateQuestions(
        projectId,
        planId:              planId,
        replaceExisting:     true,
        includeSampleAnswers: settings?.includeSampleAnswers ?? true,
        includeScoringRubric: settings?.includeScoringRubric ?? true,
      );

      state = state.copyWith(
          isLoading: false, runId: runId, planId: planId);
      await _persist(runId: runId, planId: planId);
      _startPolling('questions', runId);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          currentView: 'plan_review',
          error: _friendly(e));
      await _persist(view: 'plan_review');
    }
  }

  // ── Retry plan ─────────────────────────────────────────────────────────────

  Future<void> retryPlan() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.generatePlan(projectId);
      state = state.copyWith(
          isLoading: false, currentView: 'polling', pollingPhase: 'plan',
          clearPlan: true);
      await _persist(view: 'polling', phase: 'plan');
      _startPolling('plan', null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
    }
  }

  // ── Retry questions ────────────────────────────────────────────────────────

  Future<void> retryQuestions() async {
    final projectId = state.projectId;
    final planId    = state.planId;
    if (projectId == null || planId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final settings = state.settings;
      final runId = await _repo.generateQuestions(
        projectId,
        planId:              planId,
        replaceExisting:     true,
        includeSampleAnswers: settings?.includeSampleAnswers ?? true,
        includeScoringRubric: settings?.includeScoringRubric ?? true,
      );
      state = state.copyWith(
          isLoading: false, runId: runId,
          currentView: 'polling', pollingPhase: 'questions');
      await _persist(view: 'polling', phase: 'questions', runId: runId);
      _startPolling('questions', runId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
    }
  }

  // ── Resubmit JD ───────────────────────────────────────────────────────────

  Future<void> resubmitInput(String jd, {String? hrNote}) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.saveJobDescription(projectId, content: jd);
      await _repo.generatePlan(projectId);
      state = state.copyWith(
          isLoading: false, currentView: 'polling', pollingPhase: 'plan',
          clearPlan: true);
      await _persist(view: 'polling', phase: 'plan');
      _startPolling('plan', null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
    }
  }

  // ── Question CRUD ──────────────────────────────────────────────────────────

  Future<void> updateQuestion(StudioQuestion q) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      final updated = await _repo.updateQuestion(projectId, q.id, q.toUpdateJson());
      final qs = state.questions.map((e) => e.id == q.id
          ? updated.copyWith(isEdited: true)
          : e).toList();
      state = state.copyWith(questions: qs, isDraftSaved: false);
    } catch (e) {
      state = state.copyWith(error: _friendly(e));
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      await _repo.deleteQuestion(projectId, questionId);
      state = state.copyWith(
          questions: state.questions.where((q) => q.id != questionId).toList(),
          isDraftSaved: false);
    } catch (e) {
      state = state.copyWith(error: _friendly(e));
    }
  }

  Future<void> regenerateQuestion(String questionId) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      final settings = state.settings;
      final updated  = await _repo.regenerateQuestion(
        projectId,
        questionId,
        includeSampleAnswers: settings?.includeSampleAnswers ?? true,
        includeScoringRubric: settings?.includeScoringRubric ?? true,
      );
      if (updated != null) {
        // Spec §7.10: after regenerate, reload full list (pageSize 100)
        final planId = state.planId;
        final qs = planId != null
            ? await _repo.listQuestions(projectId, planId: planId)
            : state.questions.map((e) => e.id == questionId ? updated : e).toList();
        if (!mounted) return;
        state = state.copyWith(questions: qs, isDraftSaved: false);
      }
    } catch (e) {
      state = state.copyWith(error: _friendly(e));
    }
  }

  // ── Documents (RAG) ───────────────────────────────────────────────────────

  Future<void> loadDocuments() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      final docs = await _repo.listDocuments(projectId);
      if (!mounted) return;
      state = state.copyWith(documents: docs);
    } catch (_) {}
  }

  Future<void> uploadDocument(dynamic file) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      final doc = await _repo.uploadDocument(projectId, file as dynamic);
      if (!mounted) return;
      state = state.copyWith(documents: [...state.documents, doc]);
      // Poll until doc is Completed/Failed
      _pollDocumentStatus(projectId, doc.id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: _friendly(e));
    }
  }

  Future<void> _pollDocumentStatus(String projectId, String docId) async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      try {
        final docs = await _repo.listDocuments(projectId);
        if (!mounted) return;
        state = state.copyWith(documents: docs);
        final doc = docs.where((d) => d.id == docId).firstOrNull;
        if (doc == null || !doc.status.isProcessing) return;
      } catch (_) {}
    }
  }

  Future<void> deleteDocument(String docId) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      await _repo.deleteDocument(projectId, docId);
      if (!mounted) return;
      state = state.copyWith(
          documents: state.documents.where((d) => d.id != docId).toList());
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: _friendly(e));
    }
  }

  Future<void> toggleDocumentSelection(String docId) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    final doc = state.documents.where((d) => d.id == docId).firstOrNull;
    if (doc == null) return;
    final newSelected = !doc.isSelected;
    state = state.copyWith(
        documents: state.documents.map((d) =>
            d.id == docId ? d.copyWith(isSelected: newSelected) : d).toList());
    try {
      await _repo.setDocumentSelection(projectId, docId, isSelected: newSelected);
    } catch (_) {
      // Revert on error
      state = state.copyWith(
          documents: state.documents.map((d) =>
              d.id == docId ? d.copyWith(isSelected: doc.isSelected) : d).toList());
    }
  }

  Future<void> loadLibraryDocuments() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    // Returned only for UI — caller uses listLibraryDocuments directly
  }

  Future<void> attachLibraryDocuments(List<String> knowledgeDocumentIds) async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      await _repo.attachLibraryDocuments(projectId, knowledgeDocumentIds);
      await loadDocuments();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: _friendly(e));
    }
  }

  // ── Chat / Refine ─────────────────────────────────────────────────────────

  Future<void> loadChatMessages() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    try {
      final msgs = await _repo.getChatMessages(projectId);
      if (!mounted) return;
      state = state.copyWith(chatMessages: msgs);
    } catch (_) {}
  }

  Future<void> sendRefinement(String message) async {
    final projectId = state.projectId;
    if (projectId == null || state.isPlanApproved) return;

    // Optimistic: add user msg + streaming placeholder
    final userMsg = StudioChatMessage(
      id:        'tmp_u_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: state.chatSessionId ?? '',
      role:      ChatMessageRole.user,
      content:   message,
      status:    ChatMessageStatus.completed,
      createdAt: DateTime.now().toIso8601String(),
    );
    final placeholder = StudioChatMessage.streamingPlaceholder(
        text: 'Đang phân tích...');

    state = state.copyWith(
      chatMessages: [...state.chatMessages, userMsg, placeholder],
      isStreaming:  true,
      sideColumnsLocked: true,
    );

    try {
      final msgs = await _repo.refinePlan(projectId, message);
      if (!mounted) return;
      // Also refresh plan
      StudioPlanDetail? plan;
      try { plan = await _repo.getCurrentPlan(projectId); } catch (_) {}
      state = state.copyWith(
        chatMessages:      msgs,
        isStreaming:       false,
        sideColumnsLocked: false,
        plan:              plan,
        isDraftSaved:      false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming:       false,
        sideColumnsLocked: false,
        error:             _friendly(e),
        chatMessages:      state.chatMessages
            .where((m) => m.id != placeholder.id).toList(),
      );
    }
  }

  Future<void> applySettings() async {
    final projectId = state.projectId;
    final planId    = state.planId ?? state.plan?.id;
    if (projectId == null || planId == null || state.isPlanApproved) return;

    state = state.copyWith(isApplyingSettings: true, sideColumnsLocked: true);
    try {
      await _repo.applySettingsToPlan(projectId, planId);
      StudioPlanDetail? plan;
      try { plan = await _repo.getCurrentPlan(projectId); } catch (_) {}
      if (!mounted) return;
      state = state.copyWith(
        isApplyingSettings: false,
        sideColumnsLocked:  false,
        plan:               plan,
        isDraftSaved:       false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isApplyingSettings: false,
        sideColumnsLocked:  false,
        error:              _friendly(e),
      );
    }
  }

  // ── Save draft / publish ───────────────────────────────────────────────────

  Future<void> saveDraft() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    state = state.copyWith(isSavingDraft: true, clearError: true);
    try {
      await _repo.saveProject(projectId);
      state = state.copyWith(
          isSavingDraft: false, isDraftSaved: true);
    } catch (e) {
      state = state.copyWith(isSavingDraft: false, error: _friendly(e));
    }
  }

  Future<void> publishProject() async {
    final projectId = state.projectId;
    if (projectId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.publishProject(projectId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
    }
  }

  // ── Resume existing project ────────────────────────────────────────────────

  Future<void> resumeProject(String projectId) async {
    if (projectId.isEmpty) return;
    _cancelPoll();
    state = state.copyWith(projectId: projectId, isRestoring: true,
        clearError: true);
    await _StudioPrefs.save(projectId: projectId);
    try {
      await _loadProjectState(projectId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isRestoring: false, error: _friendly(e));
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void goBackToForm() {
    _cancelPoll();
    state = state.copyWith(currentView: 'form');
    _StudioPrefs.save(view: 'form');
  }

  Future<void> minimize() async {
    final projectId = state.projectId;
    if (projectId == null || state.currentView == 'form') return;
    await _persist();
    if (state.currentView == 'polling' && _pollTimer == null) {
      _startPolling(state.pollingPhase, state.runId);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    _cancelPoll();
    await _StudioPrefs.clearAll();
    state = const StudioGenState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  void clearQuotaBlock() => state = state.copyWith(
      quotaBlocked: false, clearError: true);

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Returns true if the error is a quota/cooldown block (403 COOLDOWN_ACTIVE).
  /// Sets quotaBlocked + quotaResetAt on state and returns true so caller can skip
  /// setting generic error message.
  bool _handleQuota(Object e) {
    if (e is! DioException) return false;
    final status = e.response?.statusCode;
    if (status != 403) return false;
    final data = e.response?.data;
    final errorCode = (data is Map)
        ? (data['errorCode'] ?? data['ErrorCode'] ?? '').toString()
        : '';
    if (errorCode != 'COOLDOWN_ACTIVE') return false;
    // Extract human-readable title from backend response
    final title = (data is Map)
        ? (data['title'] ?? data['Title'] ?? 'Bạn đã đạt giới hạn tạo câu hỏi.').toString()
        : 'Bạn đã đạt giới hạn tạo câu hỏi.';
    state = state.copyWith(
      isLoading:    false,
      quotaBlocked: true,
      error:        title,
    );
    return true;
  }

  static String _friendly(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data   = e.response?.data;
      // Extract backend error message when available
      if (data is Map) {
        final msg = data['title'] ?? data['error'] ?? data['message'];
        if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      }
      if (status == 401) return 'Phiên đăng nhập hết hạn. Hãy đăng nhập lại.';
      if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
      if (status == 404) return 'Không tìm thấy dữ liệu. Vui lòng thử lại.';
      if (status == 500) return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Quá thời gian chờ. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
      }
    }
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final studioRepositoryProvider =
    Provider<StudioRepository>((ref) => StudioRepository());

final studioGenerationProvider =
    StateNotifierProvider<StudioGenerationNotifier, StudioGenState>((ref) {
  return StudioGenerationNotifier(ref.watch(studioRepositoryProvider));
});
