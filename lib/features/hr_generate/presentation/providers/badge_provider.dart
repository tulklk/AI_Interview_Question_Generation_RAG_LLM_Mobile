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

// ── Notifier ──────────────────────────────────────────────────────────────────

class BadgeNotifier extends StateNotifier<BadgeState> {
  final GenerationRepository _repo;
  Timer? _syncTimer;
  Timer? _pollTimer;

  static const _syncInterval = Duration(milliseconds: 800);
  static const _pollInterval = Duration(seconds: 3);

  BadgeNotifier(this._repo) : super(const BadgeState()) {
    _startSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startSync() {
    _syncTimer = Timer.periodic(_syncInterval, (_) => _syncFromPrefs());
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
      return; // no change
    }

    state = state.copyWith(
      jobId:        jobId,
      currentView:  view,
      pollingPhase: phase,
      isDismissed:  isDismissed,
    );

    // Start/stop badge polling based on view
    if (view == 'polling' && !isDismissed && jobId != null) {
      _ensurePollRunning(jobId, phase);
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _ensurePollRunning(String jobId, String phase) {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _doBadgePoll(jobId, phase));
  }

  Future<void> _doBadgePoll(String jobId, String phase) async {
    if (!mounted) return;
    try {
      final session = await _repo.getSession(jobId);
      if (!mounted) return;

      state = state.copyWith(session: session);

      if (session.isPolling) return; // keep polling

      final action = (session.suggestedAction ?? '').toUpperCase();
      final st     = session.status;

      String? newView;
      if (action == 'REVIEW_PLAN') {
        newView = 'plan_review';
      } else if (action == 'REVIEW_QUESTIONS' ||
          st == GenerationStatus.completed) {
        newView = 'question_review';
      } else if (action == 'VIEW_DRAFT') {
        newView = 'draft_view';
      } else if (action == 'RETRY_PLAN' || action == 'RETRY_QUESTIONS' ||
          action == 'EDIT_INPUT' || st == GenerationStatus.failed) {
        newView = 'failed';
      }

      if (newView != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(GenStorage.kView, newView);
        state = state.copyWith(currentView: newView);
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      // Silent on network error — badge continues
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
  return BadgeNotifier(ref.watch(generationRepositoryProvider));
});
