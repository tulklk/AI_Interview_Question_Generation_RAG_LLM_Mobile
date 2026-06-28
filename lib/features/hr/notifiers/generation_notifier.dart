import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/generation_repository.dart';
import '../models/generation_models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class GenerationState {
  final GenerationFlowState flowState;
  final String? jobId;
  final GenerationJob? job;
  final List<GeneratedQuestion> questions;
  final bool isLoading;
  final String? error;
  final String? savedDraftId;
  // Current edits on plan review screen (tracks user's changes before approve)
  final PlanDraft? editedPlan;

  const GenerationState({
    this.flowState = GenerationFlowState.form,
    this.jobId,
    this.job,
    this.questions = const [],
    this.isLoading = false,
    this.error,
    this.savedDraftId,
    this.editedPlan,
  });

  bool get isPolling =>
      flowState == GenerationFlowState.pollingPlan ||
      flowState == GenerationFlowState.pollingQuestions;

  GenerationState copyWith({
    GenerationFlowState? flowState,
    String? jobId,
    GenerationJob? job,
    List<GeneratedQuestion>? questions,
    bool? isLoading,
    String? error,
    String? savedDraftId,
    PlanDraft? editedPlan,
    bool clearError = false,
    bool clearEditedPlan = false,
    bool clearSavedDraft = false,
  }) =>
      GenerationState(
        flowState:    flowState ?? this.flowState,
        jobId:        jobId ?? this.jobId,
        job:          job ?? this.job,
        questions:    questions ?? this.questions,
        isLoading:    isLoading ?? this.isLoading,
        error:        clearError ? null : (error ?? this.error),
        savedDraftId: clearSavedDraft ? null : (savedDraftId ?? this.savedDraftId),
        editedPlan:   clearEditedPlan ? null : (editedPlan ?? this.editedPlan),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GenerationNotifier extends ChangeNotifier {
  final GenerationRepository _repo;
  GenerationState _state = const GenerationState();
  Timer? _pollTimer;

  static const _pollInterval  = Duration(seconds: 3);
  static const _errorInterval = Duration(seconds: 5);

  GenerationNotifier(this._repo);

  GenerationState get state => _state;

  void _emit(GenerationState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelPoll();
    super.dispose();
  }

  void _cancelPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Step 1: Submit job ─────────────────────────────────────────────────────

  Future<void> submitJob(GenerationFormInput input) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final jobId = await _repo.createJob(input);
      if (jobId.isEmpty) throw Exception('Server không trả về job ID');
      _emit(_state.copyWith(
        isLoading: false,
        jobId:     jobId,
        flowState: GenerationFlowState.pollingPlan,
      ));
      _startPolling();
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  // Resume an in-progress job (deep link or app resume)
  Future<void> resumeJob(String jobId) async {
    _emit(_state.copyWith(jobId: jobId, isLoading: true, clearError: true));
    try {
      final job    = await _repo.getJob(jobId);
      final next   = _determine(job);
      _emit(_state.copyWith(isLoading: false, job: job, flowState: next));
      if (next == GenerationFlowState.pollingPlan ||
          next == GenerationFlowState.pollingQuestions) {
        _startPolling();
      } else if (next == GenerationFlowState.questionReview) {
        await _fetchQuestions(jobId);
      }
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    _cancelPoll();
    _pollTimer = Timer(_pollInterval, _doPoll);
  }

  Future<void> _doPoll() async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    try {
      final job  = await _repo.getJob(jobId);
      final next = _determine(job);

      if (next == GenerationFlowState.pollingPlan ||
          next == GenerationFlowState.pollingQuestions) {
        _emit(_state.copyWith(job: job, flowState: next, clearError: true));
        _startPolling();
      } else if (next == GenerationFlowState.questionReview) {
        _emit(_state.copyWith(job: job, flowState: next));
        await _fetchQuestions(jobId);
      } else {
        // planReview or failed — stop polling
        _emit(_state.copyWith(job: job, flowState: next));
      }
    } catch (_) {
      // Network error — show warning but keep polling after 5s
      _emit(_state.copyWith(error: 'Mất kết nối, đang thử lại...'));
      _pollTimer = Timer(_errorInterval, _doPoll);
    }
  }

  Future<void> _fetchQuestions(String jobId) async {
    try {
      var questions = await _repo.getQuestions(jobId);
      if (questions.isEmpty) {
        // Wait 2.5s then retry once
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        questions = await _repo.getQuestions(jobId);
      }
      _emit(_state.copyWith(questions: questions));
    } catch (e) {
      _emit(_state.copyWith(error: _errMsg(e)));
    }
  }

  GenerationFlowState _determine(GenerationJob job) {
    // isPolling flag takes priority — BE says keep polling
    if (job.isPolling) {
      return job.isPlanPhase
          ? GenerationFlowState.pollingPlan
          : GenerationFlowState.pollingQuestions;
    }

    final action = (job.suggestedAction ?? '').toUpperCase();
    final status = job.rawStatus.toUpperCase();

    switch (action) {
      case 'REVIEW_PLAN':
        return GenerationFlowState.planReview;
      case 'REVIEW_QUESTIONS':
        return GenerationFlowState.questionReview;
      case 'RETRY_PLAN':
      case 'RETRY_QUESTIONS':
      case 'EDIT_INPUT':
        return GenerationFlowState.failed;
    }

    // Status-based fallback
    if (status == 'PLAN_PROPOSED' || status == 'WAITING_HR_APPROVAL' ||
        status == 'PLANPROPOSED') {
      return GenerationFlowState.planReview;
    }
    if (status == 'COMPLETED' || status == 'DONE' || status == 'SUCCESS') {
      return GenerationFlowState.questionReview;
    }
    if (status == 'FAILED' || status == 'ERROR') {
      return GenerationFlowState.failed;
    }
    if (status.contains('QUESTION') || status == 'CONFIRMED' ||
        status == 'PROCESSING' || status == 'APPROVED') {
      return GenerationFlowState.pollingQuestions;
    }
    return GenerationFlowState.pollingPlan;
  }

  // ── Step 3: Approve plan ───────────────────────────────────────────────────

  Future<void> approvePlan(PlanDraft edited) async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _repo.updatePlan(jobId, edited);
      await _repo.approvePlan(jobId);
      _emit(_state.copyWith(
        isLoading:    false,
        flowState:    GenerationFlowState.pollingQuestions,
        clearEditedPlan: true,
      ));
      _startPolling();
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  // ── Step 5: Save draft ─────────────────────────────────────────────────────

  Future<void> saveDraft() async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final draftId = await _repo.saveDraft(jobId);
      _emit(_state.copyWith(isLoading: false, savedDraftId: draftId ?? 'saved'));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  // ── Recovery ───────────────────────────────────────────────────────────────

  Future<void> retryPlan() async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _repo.retryPlan(jobId);
      _emit(_state.copyWith(
          isLoading: false, flowState: GenerationFlowState.pollingPlan));
      _startPolling();
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  Future<void> retryQuestions() async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _repo.retryQuestions(jobId);
      _emit(_state.copyWith(
          isLoading: false, flowState: GenerationFlowState.pollingQuestions));
      _startPolling();
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  Future<void> editAndResubmit(GenerationFormInput input) async {
    final jobId = _state.jobId;
    if (jobId == null) {
      await submitJob(input);
      return;
    }
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _repo.editInput(jobId, input);
      _emit(_state.copyWith(
          isLoading: false, flowState: GenerationFlowState.pollingPlan));
      _startPolling();
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: _errMsg(e)));
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    final jobId = _state.jobId;
    if (jobId == null) return;
    try {
      await _repo.deleteQuestion(jobId, questionId);
      final updated =
          _state.questions.where((q) => q.id != questionId).toList();
      _emit(_state.copyWith(questions: updated));
    } catch (e) {
      _emit(_state.copyWith(error: _errMsg(e)));
    }
  }

  void updateEditedPlan(PlanDraft plan) =>
      _emit(_state.copyWith(editedPlan: plan));

  // Call on app resume when polling was in progress
  Future<void> onAppResume() async {
    if (!_state.isPolling) return;
    _cancelPoll();
    await _doPoll();
  }

  void reset() {
    _cancelPoll();
    _emit(const GenerationState());
  }

  void clearError() => _emit(_state.copyWith(clearError: true));

  // ── Error helper ───────────────────────────────────────────────────────────

  static String _errMsg(Object e) {
    if (e is DioException) {
      final body = e.response?.data;
      if (body is Map) {
        return (body['message'] ?? body['error'] ?? body['title'] ??
                'Lỗi từ máy chủ')
            .toString();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Hết thời gian kết nối. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không có kết nối mạng. Vui lòng kiểm tra internet.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
