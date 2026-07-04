import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/generation_repository.dart';
import '../../domain/enums/generation_status.dart';
import '../../domain/models/generation_session.dart';
import 'generation_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class BadgeState {
  final String? jobId;
  final String currentView; // matches GenStorage.kView
  final String pollingPhase;
  final GenerationSession? session;
  final bool isDismissed;

  const BadgeState({
    this.jobId,
    this.currentView = 'form',
    this.pollingPhase = 'plan',
    this.session,
    this.isDismissed = false,
  });

  bool get shouldShow =>
      jobId != null &&
      jobId!.isNotEmpty &&
      currentView != 'form' &&
      !isDismissed;

  BadgeState copyWith({
    String? jobId,
    String? currentView,
    String? pollingPhase,
    GenerationSession? session,
    bool? isDismissed,
  }) =>
      BadgeState(
        jobId:        jobId ?? this.jobId,
        currentView:  currentView ?? this.currentView,
        pollingPhase: pollingPhase ?? this.pollingPhase,
        session:      session ?? this.session,
        isDismissed:  isDismissed ?? this.isDismissed,
      );
}

// ── Session → view resolver (mirrors generation_provider) ─────────────────────

String? resolveViewFromSession(GenerationSession session) {
  if (session.isPolling) return null;

  final action = (session.suggestedAction ?? '').toUpperCase();
  final st     = session.status;
  final raw    = session.rawPhase.toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  if (action == 'REVIEW_PLAN' ||
      st == GenerationStatus.planProposed ||
      session.isWaitingPlanReview ||
      raw == 'WAITING_HR_APPROVAL' ||
      raw == 'PLAN_PROPOSED' ||
      raw == 'PLANPROPOSED') {
    return 'plan_review';
  }
  if (action == 'REVIEW_QUESTIONS' || st == GenerationStatus.completed) {
    return 'question_review';
  }
  if (action == 'VIEW_DRAFT') return 'draft_view';
  if (action == 'RETRY_PLAN' ||
      action == 'RETRY_QUESTIONS' ||
      action == 'EDIT_INPUT' ||
      st == GenerationStatus.failed) {
    return 'failed';
  }
  if (session.planDraft != null && session.generatedQuestions.isEmpty) {
    return 'plan_review';
  }
  return null;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BadgeNotifier extends StateNotifier<BadgeState> {
  final GenerationRepository _repo;
  Timer? _syncTimer;
  Timer? _pollTimer;
  bool _generationScreenActive = false;
  bool _pollInFlight = false;

  static const _syncIntervalActive = Duration(seconds: 4);
  static const _syncIntervalIdle   = Duration(seconds: 12);
  static const _pollInterval = Duration(seconds: 5);

  BadgeNotifier(this._repo) : super(const BadgeState()) {
    _scheduleSync(_syncIntervalIdle);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void setGenerationScreenActive(bool active) {
    _generationScreenActive = active;
    if (active) {
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      _managePolling(state.jobId, state.currentView, state.pollingPhase,
          state.isDismissed);
    }
  }

  /// Mirrors generation state without an extra API call.
  void syncFromGenerationState(GenerationState gen) {
    if (gen.jobId == null || gen.jobId!.isEmpty || gen.currentView == 'form') {
      return;
    }
    if (state.jobId == gen.jobId &&
        state.currentView == gen.currentView &&
        state.pollingPhase == gen.pollingPhase &&
        state.session?.rawPhase == gen.session?.rawPhase) {
      return;
    }
    state = state.copyWith(
      jobId:        gen.jobId,
      currentView:  gen.currentView,
      pollingPhase: gen.pollingPhase,
      session:      gen.session,
    );
  }

  void _scheduleSync(Duration delay) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () async {
      await _syncFromPrefs();
    });
  }

  /// Immediately sync badge from SharedPreferences (called after view changes).
  Future<void> syncNow() async {
    _syncTimer?.cancel();
    await _syncFromPrefs();
  }

  Future<void> _syncFromPrefs() async {
    if (!mounted) return;
    final prefs  = await SharedPreferences.getInstance();
    final jobId  = prefs.getString(GenStorage.kJob);
    final view   = prefs.getString(GenStorage.kView) ?? 'form';
    final phase  = prefs.getString(GenStorage.kPollingPhase) ?? 'plan';
    final dismissed = prefs.getString(GenStorage.kBadgeDismissed);
    final isDismissed = dismissed != null && dismissed == jobId;

    if (state.jobId == jobId &&
        state.currentView == view &&
        state.pollingPhase == phase &&
        state.isDismissed == isDismissed) {
      final isIdle =
          (jobId == null || jobId.isEmpty) && view == 'form';
      _scheduleSync(isIdle ? _syncIntervalIdle : _syncIntervalActive);
      _managePolling(jobId, view, phase, isDismissed);
      return;
    }

    state = state.copyWith(
      jobId:        jobId,
      currentView:  view,
      pollingPhase: phase,
      isDismissed:  isDismissed,
    );

    final isIdle = (jobId == null || jobId.isEmpty) && view == 'form';
    _scheduleSync(isIdle ? _syncIntervalIdle : _syncIntervalActive);
    _managePolling(jobId, view, phase, isDismissed);
  }

  void _managePolling(
    String? jobId,
    String view,
    String phase,
    bool isDismissed,
  ) {
    if (_generationScreenActive ||
        isDismissed ||
        jobId == null ||
        jobId.isEmpty) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    // Only poll in background when user left the generate screen.
    final shouldPoll = view == 'polling';

    if (shouldPoll) {
      _ensurePollRunning(jobId, phase);
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _ensurePollRunning(String jobId, String phase) {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(
        _pollInterval, (_) => _doBadgePoll(jobId, phase));
  }

  Future<void> _doBadgePoll(String jobId, String phase) async {
    if (!mounted || _pollInFlight || _generationScreenActive) return;
    _pollInFlight = true;
    try {
      final session = await _repo.getSession(jobId);
      if (!mounted) return;

      state = state.copyWith(session: session);

      if (session.isPolling) {
        final newPhase = session.status.isPlanPhase ? 'plan' : 'questions';
        if (newPhase != state.pollingPhase) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(GenStorage.kPollingPhase, newPhase);
          state = state.copyWith(pollingPhase: newPhase);
        }
        return;
      }

      final newView = resolveViewFromSession(session);
      if (newView != null && newView != state.currentView) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(GenStorage.kView, newView);
        state = state.copyWith(currentView: newView);
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      // Silent on network error — badge continues
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final jobId = state.jobId ?? '';
    await prefs.setString(GenStorage.kBadgeDismissed, jobId);
    state = state.copyWith(isDismissed: true);
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}

// ── Provider (global, never disposed) ─────────────────────────────────────────

final badgeProvider =
    StateNotifierProvider<BadgeNotifier, BadgeState>((ref) {
  final notifier = BadgeNotifier(ref.watch(generationRepositoryProvider));

  ref.listen<GenerationState>(generationProvider, (prev, next) {
    if (prev?.currentView != next.currentView ||
        prev?.jobId != next.jobId ||
        prev?.pollingPhase != next.pollingPhase ||
        prev?.session?.rawPhase != next.session?.rawPhase) {
      scheduleMicrotask(() {
        notifier.syncFromGenerationState(next);
        notifier.syncNow();
      });
    }
  });

  return notifier;
});
