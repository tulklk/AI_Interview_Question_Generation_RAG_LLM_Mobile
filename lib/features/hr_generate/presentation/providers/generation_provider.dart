import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/generation_repository.dart';
import '../../domain/enums/generation_status.dart';
import '../../domain/models/generated_question.dart';
import '../../domain/models/generation_session.dart';
import '../../domain/models/plan_draft.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────────

class GenStorage {
  static const kJob          = 'hr_gen_job';
  static const kView         = 'hr_gen_view';
  static const kPlan         = 'hr_gen_plan';
  static const kJd           = 'hr_gen_jd';
  static const kPollingPhase = 'hr_gen_polling_phase';
  static const kBadgeDismissed = 'hr_gen_badge_dismissed';

  static Future<void> save({
    String? jobId,
    String? view,
    PlanDraft? plan,
    String? jd,
    String? pollingPhase,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (jobId != null)       await p.setString(kJob, jobId);
    if (view != null)        await p.setString(kView, view);
    if (plan != null)        await p.setString(kPlan, plan.toStorageJson());
    if (jd != null)          await p.setString(kJd, jd);
    if (pollingPhase != null) await p.setString(kPollingPhase, pollingPhase);
  }

  static Future<Map<String, String?>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      'jobId':        p.getString(kJob),
      'view':         p.getString(kView),
      'plan':         p.getString(kPlan),
      'jd':           p.getString(kJd),
      'pollingPhase': p.getString(kPollingPhase),
    };
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.remove(kJob),
      p.remove(kView),
      p.remove(kPlan),
      p.remove(kJd),
      p.remove(kPollingPhase),
    ]);
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class GenerationState {
  final String currentView; // form|polling|plan_review|question_review|failed|draft_view
  final String? jobId;
  final String pollingPhase; // plan | questions
  final GenerationSession? session;
  final List<GeneratedQuestion> questions;
  final bool isLoading;
  final bool isRestoring;
  final String? error;
  final String? statusLabel;
  final String? savedDraftId;
  final PlanDraft? localPlan; // user edits, takes priority over server plan

  const GenerationState({
    this.currentView   = 'form',
    this.jobId,
    this.pollingPhase  = 'plan',
    this.session,
    this.questions     = const [],
    this.isLoading     = false,
    this.isRestoring   = false,
    this.error,
    this.statusLabel,
    this.savedDraftId,
    this.localPlan,
  });

  GenerationState copyWith({
    String? currentView,
    String? jobId,
    String? pollingPhase,
    GenerationSession? session,
    List<GeneratedQuestion>? questions,
    bool? isLoading,
    bool? isRestoring,
    String? error,
    String? statusLabel,
    String? savedDraftId,
    PlanDraft? localPlan,
    bool clearError = false,
    bool clearSession = false,
    bool clearLocalPlan = false,
  }) =>
      GenerationState(
        currentView:  currentView ?? this.currentView,
        jobId:        jobId ?? this.jobId,
        pollingPhase: pollingPhase ?? this.pollingPhase,
        session:      clearSession ? null : (session ?? this.session),
        questions:    questions ?? this.questions,
        isLoading:    isLoading ?? this.isLoading,
        isRestoring:  isRestoring ?? this.isRestoring,
        error:        clearError ? null : (error ?? this.error),
        statusLabel:  statusLabel ?? this.statusLabel,
        savedDraftId: savedDraftId ?? this.savedDraftId,
        localPlan:    clearLocalPlan ? null : (localPlan ?? this.localPlan),
      );

  PlanDraft? get effectivePlan {
    final server = session?.planDraft;
    if (localPlan == null) return server;
    if (server == null) return localPlan;
    return localPlan!.mergeWith(server);
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class GenerationNotifier extends StateNotifier<GenerationState> {
  final GenerationRepository _repo;
  Timer? _pollTimer;

  static const _pollInterval  = Duration(seconds: 3);
  static const _errorInterval = Duration(seconds: 5);

  GenerationNotifier(this._repo) : super(const GenerationState()) {
    _restore();
  }

  @override
  void dispose() {
    _cancelPoll();
    super.dispose();
  }

  void _cancelPoll() { _pollTimer?.cancel(); _pollTimer = null; }

  // ── Session restore ────────────────────────────────────────────────────────

  Future<void> _restore() async {
    final saved = await GenStorage.load();
    final jobId = saved['jobId'];
    if (jobId == null || jobId.isEmpty) return;

    state = state.copyWith(
      jobId:        jobId,
      currentView:  saved['view'] ?? 'form',
      pollingPhase: saved['pollingPhase'] ?? 'plan',
      localPlan:    saved['plan'] != null
          ? PlanDraft.fromStorageJson(saved['plan']!) : null,
      isRestoring:  true,
    );

    try {
      final session = await _repo.getSession(jobId);
      if (!mounted) return;

      // Determine correct view from server state
      final action = (session.suggestedAction ?? '').toUpperCase();
      final st     = session.status;

      if (session.isPolling) {
        final phase = st.isPlanPhase ? 'plan' : 'questions';
        state = state.copyWith(
            isRestoring: false, session: session,
            currentView: 'polling', pollingPhase: phase);
        await GenStorage.save(view: 'polling', pollingPhase: phase);
        _startPolling(phase);
        return;
      }

      if (action == 'REVIEW_PLAN') {
        state = state.copyWith(
            isRestoring: false, session: session, currentView: 'plan_review');
        await GenStorage.save(view: 'plan_review');
        return;
      }
      if (action == 'REVIEW_QUESTIONS' || st == GenerationStatus.completed) {
        final qs = session.generatedQuestions.isNotEmpty
            ? session.generatedQuestions
            : await _repo.getQuestions(jobId);
        state = state.copyWith(
            isRestoring: false, session: session,
            questions: qs, currentView: 'question_review');
        await GenStorage.save(view: 'question_review');
        return;
      }
      if (action == 'VIEW_DRAFT') {
        state = state.copyWith(
            isRestoring: false, session: session, currentView: 'draft_view');
        await GenStorage.save(view: 'draft_view');
        return;
      }
      if (action == 'RETRY_PLAN' || action == 'RETRY_QUESTIONS' ||
          action == 'EDIT_INPUT' || st == GenerationStatus.failed) {
        state = state.copyWith(
            isRestoring: false, session: session, currentView: 'failed');
        await GenStorage.save(view: 'failed');
        return;
      }
      if (st.isPlanPhase) {
        state = state.copyWith(
            isRestoring: false, session: session,
            currentView: 'polling', pollingPhase: 'plan');
        await GenStorage.save(view: 'polling', pollingPhase: 'plan');
        _startPolling('plan');
        return;
      }
      if (st.isQuestionPhase) {
        state = state.copyWith(
            isRestoring: false, session: session,
            currentView: 'polling', pollingPhase: 'questions');
        await GenStorage.save(view: 'polling', pollingPhase: 'questions');
        _startPolling('questions');
        return;
      }

      state = state.copyWith(isRestoring: false, session: session);
    } catch (_) {
      // jobId not found or network error → clear and show form
      await GenStorage.clearAll();
      state = const GenerationState();
    }
  }

  // ── Step 1: Submit job ─────────────────────────────────────────────────────

  Future<void> submitJob({
    required String jd,
    String? hrNote,
    int numberOfQuestions = 10,
    String difficulty = 'medium',
    List<String> questionTypes = const ['technical', 'behavioral'],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobId = await _repo.createJob(
        jobDescription:  jd,
        hrNote:          hrNote,
        numberOfQuestions: numberOfQuestions,
        difficulty:      difficulty,
        questionTypes:   questionTypes,
      );
      if (jobId.isEmpty) throw Exception('Server không trả về job ID');
      state = state.copyWith(
        isLoading:    false,
        jobId:        jobId,
        currentView:  'polling',
        pollingPhase: 'plan',
      );
      await GenStorage.save(jobId: jobId, view: 'polling',
          pollingPhase: 'plan', jd: jd);
      _startPolling('plan');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: GenerationRepository.friendlyError(e));
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling(String phase) {
    _cancelPoll();
    _pollTimer = Timer(_pollInterval, () => _doPoll(phase));
  }

  Future<void> _doPoll(String phase) async {
    final jobId = state.jobId;
    if (jobId == null || !mounted) return;
    try {
      final session = await _repo.getSession(jobId);
      if (!mounted) return;

      state = state.copyWith(
          session: session,
          statusLabel: session.statusLabel,
          clearError: true);

      // isPolling is single source of truth — keep polling
      if (session.isPolling) {
        _startPolling(phase);
        return;
      }

      final action = (session.suggestedAction ?? '').toUpperCase();
      final st     = session.status;

      // Plan phase transitions
      if (phase == 'plan') {
        if (action == 'REVIEW_PLAN') {
          await _transitionTo('plan_review', pollingPhase: 'plan',
              session: session);
          return;
        }
        if (action == 'RETRY_PLAN' || action == 'EDIT_INPUT') {
          await _transitionTo('failed', session: session);
          return;
        }
        if (st == GenerationStatus.failed) {
          await _transitionTo('failed', session: session);
          return;
        }
      }

      // Question phase transitions
      if (phase == 'questions') {
        if (action == 'REVIEW_QUESTIONS' || st == GenerationStatus.completed) {
          final qs = session.generatedQuestions.isNotEmpty
              ? session.generatedQuestions
              : await _repo.getQuestions(jobId);
          if (qs.isEmpty) {
            // Retry once after 2.5s
            await Future<void>.delayed(const Duration(milliseconds: 2500));
            if (!mounted) return;
            final qs2 = await _repo.getQuestions(jobId);
            if (!mounted) return;
            await _transitionTo('question_review',
                session: session, questions: qs2);
          } else {
            await _transitionTo('question_review',
                session: session, questions: qs);
          }
          return;
        }
        if (action == 'RETRY_QUESTIONS') {
          await _transitionTo('failed', session: session);
          return;
        }
        if (st == GenerationStatus.failed) {
          await _transitionTo('failed', session: session);
          return;
        }
        if (action == 'VIEW_DRAFT') {
          await _transitionTo('draft_view', session: session);
          return;
        }
      }

      // Default: keep polling
      _startPolling(phase);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(error: 'Mất kết nối, đang thử lại...');
      _pollTimer = Timer(_errorInterval, () => _doPoll(phase));
    }
  }

  Future<void> _transitionTo(
    String view, {
    GenerationSession? session,
    List<GeneratedQuestion>? questions,
    String? pollingPhase,
  }) async {
    state = state.copyWith(
      currentView:  view,
      session:      session,
      questions:    questions,
      pollingPhase: pollingPhase,
    );
    await GenStorage.save(
        view: view, pollingPhase: pollingPhase ?? state.pollingPhase);
  }

  // ── Step 3: Approve plan ───────────────────────────────────────────────────

  Future<void> approvePlan(PlanDraft edited) async {
    final jobId = state.jobId;
    if (jobId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.updatePlan(jobId, edited);
      await _repo.approvePlan(jobId);
      state = state.copyWith(
        isLoading:    false,
        currentView:  'polling',
        pollingPhase: 'questions',
        localPlan:    edited,
      );
      await GenStorage.save(
          view: 'polling', pollingPhase: 'questions', plan: edited);
      _startPolling('questions');
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: GenerationRepository.friendlyError(e));
    }
  }

  // ── Recovery ───────────────────────────────────────────────────────────────

  Future<void> retryPlan() async {
    final jobId = state.jobId;
    if (jobId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.retryPlan(jobId);
      state = state.copyWith(
          isLoading: false, currentView: 'polling', pollingPhase: 'plan');
      await GenStorage.save(view: 'polling', pollingPhase: 'plan');
      _startPolling('plan');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: GenerationRepository.friendlyError(e));
    }
  }

  Future<void> retryQuestions() async {
    final jobId = state.jobId;
    if (jobId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.retryQuestions(jobId);
      state = state.copyWith(
          isLoading: false, currentView: 'polling', pollingPhase: 'questions');
      await GenStorage.save(view: 'polling', pollingPhase: 'questions');
      _startPolling('questions');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: GenerationRepository.friendlyError(e));
    }
  }

  Future<void> resubmitInput(String jd, {String? hrNote}) async {
    final jobId = state.jobId;
    if (jobId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.updateInput(jobId, jobDescription: jd, hrNote: hrNote);
      state = state.copyWith(
          isLoading: false, currentView: 'polling', pollingPhase: 'plan');
      await GenStorage.save(view: 'polling', pollingPhase: 'plan', jd: jd);
      _startPolling('plan');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: GenerationRepository.friendlyError(e));
    }
  }

  // ── Step 5: Question management ────────────────────────────────────────────

  Future<void> updateQuestion(GeneratedQuestion q) async {
    final jobId = state.jobId;
    if (jobId == null) return;
    try {
      final updated = await _repo.updateQuestion(jobId, q);
      final qs = state.questions
          .map((e) => e.id == q.id ? updated.copyWith(isEdited: true) : e)
          .toList();
      state = state.copyWith(questions: qs);
    } catch (e) {
      state = state.copyWith(error: GenerationRepository.friendlyError(e));
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    final jobId = state.jobId;
    if (jobId == null) return;
    try {
      await _repo.deleteQuestion(jobId, questionId);
      state = state.copyWith(
          questions: state.questions.where((q) => q.id != questionId).toList());
    } catch (e) {
      state = state.copyWith(error: GenerationRepository.friendlyError(e));
    }
  }

  Future<void> addQuestion(GeneratedQuestion q) async {
    final jobId = state.jobId;
    if (jobId == null) return;
    try {
      final added =
          await _repo.addQuestion(jobId, q, state.questions.length + 1);
      state = state.copyWith(questions: [...state.questions, added]);
    } catch (e) {
      state = state.copyWith(error: GenerationRepository.friendlyError(e));
    }
  }

  // ── Save draft ─────────────────────────────────────────────────────────────

  Future<void> saveDraft() async {
    final jobId = state.jobId;
    if (jobId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = await _repo.saveDraft(jobId);
      state = state.copyWith(
          isLoading: false,
          savedDraftId: id ?? 'saved',
          currentView: 'draft_view');
      await GenStorage.save(view: 'draft_view');
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: GenerationRepository.friendlyError(e));
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    _cancelPoll();
    await GenStorage.clearAll();
    state = const GenerationState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  void updateLocalPlan(PlanDraft plan) =>
      state = state.copyWith(localPlan: plan);

  void goBackToForm() {
    _cancelPoll();
    state = state.copyWith(currentView: 'form');
    GenStorage.save(view: 'form');
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final generationRepositoryProvider =
    Provider<GenerationRepository>((ref) => GenerationRepository());

final generationProvider = StateNotifierProvider.autoDispose<
    GenerationNotifier, GenerationState>((ref) {
  return GenerationNotifier(ref.watch(generationRepositoryProvider));
});
