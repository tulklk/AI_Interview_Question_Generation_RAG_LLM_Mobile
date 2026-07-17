import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../hr_generate/data/generation_api.dart';
import '../models/jobseeker_models.dart';

// ── Candidates Profile State ───────────────────────────────────────────────────

class CandidateProfileState {
  final CandidateProfileData? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const CandidateProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  CandidateProfileState copyWith({
    CandidateProfileData? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) =>
      CandidateProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error ?? this.error,
      );
}

// ── Profile Notifier ──────────────────────────────────────────────────────────

class CandidateProfileNotifier extends StateNotifier<CandidateProfileState> {
  CandidateProfileNotifier(this._ref) : super(const CandidateProfileState());

  final Ref _ref;

  static const _baseUrl = AppConstants.apiBaseUrl;

  Dio _dio(String token) => Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await StorageService.getAccessToken() ?? '';
      if (token.isEmpty) throw Exception('Not authenticated');

      final res = await _dio(token).get('/api/users/me');
      final raw = res.data;
      final Map<String, dynamic> data =
          raw is Map && raw['data'] is Map ? raw['data'] as Map<String, dynamic> : (raw as Map<String, dynamic>? ?? {});
      final email = (data['email'] ?? '').toString();
      final profile = CandidateProfileData.fromMap(data, email);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> save(CandidateProfileData updated) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final token = await StorageService.getAccessToken() ?? '';
      await _dio(token).patch(
        '/api/users/me/candidate-profile',
        data: updated.toUpdateMap(),
      );
      state = state.copyWith(profile: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final candidateProfileProvider =
    StateNotifierProvider<CandidateProfileNotifier, CandidateProfileState>(
  (ref) => CandidateProfileNotifier(ref),
);

// ── Practice Session State ────────────────────────────────────────────────────

class PracticeSessionState {
  final String setId;
  final String? serverSessionId;
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final Map<String, bool> submitted;
  final bool evaluating;
  final int timeLeft;
  final bool isLoading;
  final String? error;
  final String? submitError;
  final bool isSubmitting;
  final bool isCompleting;
  final bool isComplete;

  const PracticeSessionState({
    required this.setId,
    this.serverSessionId,
    this.questions = const [],
    this.currentIndex = 0,
    Map<String, String>? answers,
    Map<String, bool>? submitted,
    this.evaluating = false,
    this.timeLeft = 45 * 60,
    this.isLoading = true,
    this.error,
    this.submitError,
    this.isSubmitting = false,
    this.isCompleting = false,
    this.isComplete = false,
  })  : answers = answers ?? const {},
        submitted = submitted ?? const {};

  bool get allSubmitted =>
      questions.isNotEmpty &&
      questions.every((q) => submitted[q.id] == true);

  PracticeSessionState copyWith({
    String? serverSessionId,
    List<PracticeQuestion>? questions,
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, bool>? submitted,
    bool? evaluating,
    int? timeLeft,
    bool? isLoading,
    String? error,
    String? submitError,
    bool? isSubmitting,
    bool? isCompleting,
    bool? isComplete,
    bool clearError = false,
    bool clearSubmitError = false,
  }) =>
      PracticeSessionState(
        setId: setId,
        serverSessionId: serverSessionId ?? this.serverSessionId,
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        submitted: submitted ?? this.submitted,
        evaluating: evaluating ?? this.evaluating,
        timeLeft: timeLeft ?? this.timeLeft,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isCompleting: isCompleting ?? this.isCompleting,
        isComplete: isComplete ?? this.isComplete,
      );
}

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(String setId)
      : super(PracticeSessionState(setId: setId)) {
    _initSession();
  }

  static const _sessionMins = 45;

  // ── Init / Resume ───────────────────────────────────────────────────────────

  Future<void> _initSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = buildGenerationDio();

      // 1. Look for an IN_PROGRESS session for this set.
      String? sessionId;
      try {
        final res = await dio.get(
          '/api/candidate/practice-sessions',
          queryParameters: {
            'questionSetId': state.setId,
            'status': 'IN_PROGRESS',
          },
        );
        sessionId = _firstId(res.data);
      } on DioException catch (e) {
        if ((e.response?.statusCode ?? 0) != 404) rethrow;
      }

      // 2. If none found, create a new session.
      if (sessionId == null) {
        final res = await dio.post(
          '/api/candidate/practice-sessions',
          data: {'questionSetId': state.setId},
        );
        sessionId = _extractId(res.data);
      }

      if (sessionId == null) throw Exception('Không thể tạo phiên luyện tập');

      // 3. Fetch full session detail and hydrate state.
      final res = await dio.get('/api/candidate/practice-sessions/$sessionId');
      _hydrateFromSession(_unwrap(res.data), sessionId);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: _fmt(e));
      }
    }
  }

  void _hydrateFromSession(Map<String, dynamic> s, String sessionId) {
    // Questions
    final rawQ = s['questions'] ?? s['questionList'] ?? const [];
    final questions = (rawQ as List)
        .whereType<Map<String, dynamic>>()
        .map(PracticeQuestion.fromJson)
        .toList();

    // Hydrate already-submitted answers
    final rawA = s['answers'] ?? s['submittedAnswers'] ?? const [];
    final answers = <String, String>{};
    final submitted = <String, bool>{};
    for (final a in (rawA as List).whereType<Map<String, dynamic>>()) {
      final qId = (a['questionId'] ?? '').toString();
      final text = (a['answerText'] ?? a['answer'] ?? '').toString();
      if (qId.isNotEmpty) {
        answers[qId] = text;
        submitted[qId] = true;
      }
    }

    // Advance to first unanswered question
    int startIndex = 0;
    for (int i = 0; i < questions.length; i++) {
      if (submitted[questions[i].id] != true) {
        startIndex = i;
        break;
      }
    }

    // Timer is local-only — always start from full session time when (re)loading.
    // Calculating from server startedAt causes 00:00 on resumed old sessions.
    const timeLeft = _sessionMins * 60;

    if (mounted) {
      state = state.copyWith(
        serverSessionId: sessionId,
        questions: questions,
        currentIndex: startIndex,
        answers: answers,
        submitted: submitted,
        timeLeft: timeLeft,
        isLoading: false,
      );
    }
  }

  Future<void> retry() => _initSession();

  // ── Navigation ──────────────────────────────────────────────────────────────

  void goTo(int index) => state = state.copyWith(currentIndex: index);

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void next() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  // ── Answer ──────────────────────────────────────────────────────────────────

  void updateAnswer(String questionId, String text) {
    state = state.copyWith(answers: {...state.answers, questionId: text});
  }

  Future<void> submitAnswer(String questionId) async {
    final text = state.answers[questionId] ?? '';
    if (text.trim().isEmpty || state.isSubmitting) return;

    state = state.copyWith(
      evaluating: true,
      isSubmitting: true,
      clearSubmitError: true,
    );

    try {
      final sessionId = state.serverSessionId;
      if (sessionId == null) throw Exception('Session ID unavailable');

      final dio = buildGenerationDio();
      await dio.post(
        '/api/candidate/practice-sessions/$sessionId/answers',
        data: {'questionId': questionId, 'answerText': text},
      );

      final newSubmitted = {...state.submitted, questionId: true};
      if (mounted) {
        state = state.copyWith(
          evaluating: false,
          isSubmitting: false,
          submitted: newSubmitted,
        );
      }

      // Auto-advance after 600 ms if not on the last question
      final idx = state.questions.indexWhere((q) => q.id == questionId);
      if (idx >= 0 && idx < state.questions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) state = state.copyWith(currentIndex: idx + 1);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          evaluating: false,
          isSubmitting: false,
          submitError: e is DioException
              ? 'Lỗi mạng — không thể gửi câu trả lời. Kiểm tra kết nối và thử lại.'
              : 'Không thể gửi: ${e.toString()}',
        );
      }
    }
  }

  Future<void> retrySubmit(String questionId) => submitAnswer(questionId);

  void clearSubmitError() =>
      state = state.copyWith(clearSubmitError: true);

  // AC-04: POST complete → isComplete = true → screen navigates to result
  Future<void> completeSession() async {
    final sessionId = state.serverSessionId;
    if (sessionId == null || state.isCompleting) return;
    state = state.copyWith(isCompleting: true);
    try {
      final dio = buildGenerationDio();
      await dio.post(
          '/api/candidate/practice-sessions/$sessionId/complete');
      if (mounted) state = state.copyWith(isCompleting: false, isComplete: true);
    } catch (_) {
      // Soft failure — still navigate; the session answers are already submitted.
      if (mounted) state = state.copyWith(isCompleting: false, isComplete: true);
    }
  }

  void tick() {
    if (state.timeLeft > 0) {
      state = state.copyWith(timeLeft: state.timeLeft - 1);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String? _firstId(dynamic data) {
    List? list;
    if (data is List) list = data;
    else if (data is Map && data['data'] is List) list = data['data'] as List;
    else if (data is Map && data['items'] is List) list = data['items'] as List;
    if (list == null || list.isEmpty) return null;
    final s = list.first;
    if (s is Map) {
      final id = (s['id'] ?? s['sessionId'] ?? '').toString();
      return id.isNotEmpty ? id : null;
    }
    return null;
  }

  String? _extractId(dynamic data) {
    if (data is Map) {
      final inner = data['data'] is Map ? data['data'] as Map : data;
      final id = (inner['id'] ?? inner['sessionId'] ?? '').toString();
      return id.isNotEmpty ? id : null;
    }
    return null;
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  String _fmt(Object e) => e is DioException
      ? 'Lỗi kết nối (${e.response?.statusCode ?? 'network'})'
      : e.toString();
}

final practiceSessionProvider = StateNotifierProvider.family<
    PracticeSessionNotifier, PracticeSessionState, String>(
  (_, setId) => PracticeSessionNotifier(setId),
);

// ── CV State ──────────────────────────────────────────────────────────────────

class CvState {
  final CvData? cv;
  final bool isLoading;
  final bool isUploading;
  final bool isDeleting;
  final String? error;

  const CvState({
    this.cv,
    this.isLoading = false,
    this.isUploading = false,
    this.isDeleting = false,
    this.error,
  });

  bool get hasCV =>
      cv != null &&
      (cv!.cvFileName != null || cv!.cvUrl != null);

  CvState copyWith({
    CvData? cv,
    bool? isLoading,
    bool? isUploading,
    bool? isDeleting,
    String? error,
    bool clearCv = false,
    bool clearError = false,
  }) =>
      CvState(
        cv:          clearCv    ? null : (cv ?? this.cv),
        isLoading:   isLoading  ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        isDeleting:  isDeleting  ?? this.isDeleting,
        error:       clearError  ? null : (error ?? this.error),
      );
}

class CvNotifier extends StateNotifier<CvState> {
  CvNotifier(this._ref) : super(const CvState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/candidate/cv');
      final raw = res.data;
      if (raw == null ||
          (raw is Map && (raw['data'] == null || raw['data'] == false))) {
        state = state.copyWith(isLoading: false, clearCv: true);
        return;
      }
      final cv = CvData.fromJson(raw is Map<String, dynamic> ? raw : {});
      state = state.copyWith(isLoading: false, cv: cv);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(isLoading: false, clearCv: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Không tải được CV (${e.response?.statusCode ?? 'lỗi mạng'})',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns null on success, or an error message string.
  Future<String?> upload(String filePath, String fileName) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final dio = buildGenerationDio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await dio.post(
        '/api/candidate/cv',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final raw = res.data;
      final cv = CvData.fromJson(raw is Map<String, dynamic> ? raw : {});
      state = state.copyWith(isUploading: false, cv: cv);
      // Refresh profile to reflect updated techStack
      _ref.read(candidateProfileProvider.notifier).load();
      return null;
    } on DioException catch (e) {
      final msg = _dioMsg(e);
      state = state.copyWith(isUploading: false, error: msg);
      return msg;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(isUploading: false, error: msg);
      return msg;
    }
  }

  /// Returns true on success.
  Future<bool> delete() async {
    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      final dio = buildGenerationDio();
      await dio.delete('/api/candidate/cv');
      state = state.copyWith(isDeleting: false, clearCv: true);
      return true;
    } on DioException catch (e) {
      final msg = _dioMsg(e);
      state = state.copyWith(isDeleting: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }

  String _dioMsg(DioException e) {
    final code = e.response?.statusCode;
    if (code == 400) return 'File không hợp lệ (400).';
    if (code == 401 || code == 403) return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    return 'Lỗi mạng (${code ?? 'network'}).';
  }
}

final cvProvider =
    StateNotifierProvider<CvNotifier, CvState>((ref) => CvNotifier(ref));

// ── Company Detail ────────────────────────────────────────────────────────────

/// Returns null for 404 or empty companyId; throws for other errors.
final companyDetailProvider =
    FutureProvider.family<CompanyInfo?, String>((ref, companyId) async {
  if (companyId.isEmpty) return null;
  final dio = buildGenerationDio();
  try {
    final res = await dio.get('/api/companies/$companyId');
    return CompanyInfo.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ── Feedback / Result ─────────────────────────────────────────────────────────

/// Extracts the first session ID from various API response shapes, including
/// paginated responses: `{data: {content: [...]}}`
String? _extractFirstSessionId(dynamic data) {
  List? list;
  if (data is List) {
    list = data;
  } else if (data is Map) {
    final inner = data['data'];
    if (inner is List) {
      list = inner;
    } else if (inner is Map) {
      for (final key in ['content', 'items', 'data', 'result']) {
        if (inner[key] is List) {
          list = inner[key] as List;
          break;
        }
      }
    }
    if (list == null) {
      for (final key in ['content', 'items', 'result']) {
        if (data[key] is List) {
          list = data[key] as List;
          break;
        }
      }
    }
  }
  if (list == null || list.isEmpty) return null;
  final s = list.first;
  if (s is! Map) return null;
  final id = (s['id'] ?? s['sessionId'] ?? '').toString();
  return id.isNotEmpty ? id : null;
}

/// Loads feedback for the COMPLETED session belonging to [setId].
/// Priority order:
///   1. serverSessionId from the still-alive practiceSessionProvider state
///   2. API query for COMPLETED sessions
///   3. API query without status filter (handles race where status isn't COMPLETED yet)
final feedbackProvider =
    FutureProvider.family<FeedbackResult?, String>((ref, setId) async {
  final dio = buildGenerationDio();

  // 1. Reuse sessionId from the just-completed practice session (fastest path).
  String? sessionId =
      ref.read(practiceSessionProvider(setId)).serverSessionId;

  // 2. Query COMPLETED sessions from the API.
  if (sessionId == null) {
    try {
      final res = await dio.get(
        '/api/candidate/practice-sessions',
        queryParameters: {'questionSetId': setId, 'status': 'COMPLETED'},
      );
      sessionId = _extractFirstSessionId(res.data);
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) != 404) rethrow;
    }
  }

  // 3. Fallback — any session (handles race where status not yet updated).
  if (sessionId == null) {
    try {
      final res = await dio.get(
        '/api/candidate/practice-sessions',
        queryParameters: {'questionSetId': setId},
      );
      sessionId = _extractFirstSessionId(res.data);
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) != 404) rethrow;
    }
  }

  if (sessionId == null) return null;

  // 4. Fetch feedback for that session.
  final res = await dio.get(
    '/api/candidate/practice-sessions/$sessionId/feedback',
  );
  final raw = res.data;
  if (raw is Map<String, dynamic>) return FeedbackResult.fromJson(raw);
  return null;
});

// ── All In-Progress Sessions ──────────────────────────────────────────────────

/// Extracts a flat list from various paginated API response shapes.
List<dynamic> _extractSessionList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is! Map) return const [];
  final inner = raw['data'];
  if (inner is List) return inner;
  if (inner is Map) {
    for (final key in ['content', 'items', 'data', 'result']) {
      if (inner[key] is List) return inner[key] as List;
    }
  }
  for (final key in ['content', 'items', 'result']) {
    if (raw[key] is List) return raw[key] as List;
  }
  return const [];
}

/// Fetches all IN_PROGRESS practice sessions for the current user.
/// Used by the dashboard "Phiên đang dở" section.
final allInProgressSessionsProvider =
    FutureProvider<List<InProgressSummary>>((ref) async {
  try {
    final dio = buildGenerationDio();
    final res = await dio.get(
      '/api/candidate/practice-sessions',
      queryParameters: {'status': 'IN_PROGRESS'},
    );
    final list = _extractSessionList(res.data);
    // DEBUG: in-progress raw keys
    if (list.isNotEmpty && list.first is Map) {
      // ignore: avoid_print
      print('[DEBUG allInProgress] keys: ${(list.first as Map).keys.toList()}');
      // ignore: avoid_print
      print('[DEBUG allInProgress] first: ${list.first}');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(InProgressSummary.fromJson)
        .where((s) => s.sessionId.isNotEmpty && s.setId.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
});

// ── In-Progress Session Check (per set) ──────────────────────────────────────

/// Returns the server sessionId if an IN_PROGRESS session exists for [setId].
/// Returns null if none — callers use this to show "Continue" vs "Start new".
final inProgressSessionProvider =
    FutureProvider.family<String?, String>((_, setId) async {
  try {
    final dio = buildGenerationDio();
    final res = await dio.get(
      '/api/candidate/practice-sessions',
      queryParameters: {'questionSetId': setId, 'status': 'IN_PROGRESS'},
    );
    final data = res.data;
    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    }
    if (list != null && list.isNotEmpty) {
      final s = list.first;
      if (s is Map) {
        final id = (s['id'] ?? s['sessionId'] ?? '').toString();
        return id.isNotEmpty ? id : null;
      }
    }
    return null;
  } catch (_) {
    return null; // Non-critical — degrade gracefully to "Start new"
  }
});

// ── History filter state ──────────────────────────────────────────────────────

class HistoryFilterState {
  final String searchQuery;
  final String timeFilter; // 'all', 'week', 'month'

  const HistoryFilterState({
    this.searchQuery = '',
    this.timeFilter = 'all',
  });

  HistoryFilterState copyWith({String? searchQuery, String? timeFilter}) =>
      HistoryFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        timeFilter: timeFilter ?? this.timeFilter,
      );

  List<PracticeSession> apply(List<PracticeSession> sessions) {
    var result = sessions;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((s) =>
              s.setTitle.toLowerCase().contains(q) ||
              s.company.toLowerCase().contains(q))
          .toList();
    }
    if (timeFilter != 'all') {
      final now = DateTime.now();
      result = result.where((s) {
        // Parse date like "May 12, 2026"
        try {
          final parts = s.date.split(' ');
          final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          final month = months.indexOf(parts[0]) + 1;
          final day = int.parse(parts[1].replaceAll(',', ''));
          final year = int.parse(parts[2]);
          final date = DateTime(year, month, day);
          final diff = now.difference(date).inDays;
          if (timeFilter == 'week') return diff <= 7;
          if (timeFilter == 'month') return diff <= 30;
        } catch (_) {}
        return true;
      }).toList();
    }
    return result;
  }
}

class HistoryFilterNotifier extends StateNotifier<HistoryFilterState> {
  HistoryFilterNotifier() : super(const HistoryFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setTimeFilter(String f) => state = state.copyWith(timeFilter: f);
}

final historyFilterProvider =
    StateNotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
  (ref) => HistoryFilterNotifier(),
);

/// Fetches all COMPLETED practice sessions (default API behaviour).
final practiceHistoryProvider = FutureProvider<List<PracticeSession>>((ref) async {
  final dio = buildGenerationDio();
  final res = await dio.get('/api/candidate/practice-sessions');
  final list = _extractSessionList(res.data);
  // DEBUG: history raw keys
  if (list.isNotEmpty && list.first is Map) {
    // ignore: avoid_print
    print('[DEBUG practiceHistory] keys: ${(list.first as Map).keys.toList()}');
    // ignore: avoid_print
    print('[DEBUG practiceHistory] first: ${list.first}');
  }
  return list
      .whereType<Map<String, dynamic>>()
      .map(PracticeSession.fromJson)
      .where((s) => s.id.isNotEmpty)
      .toList();
});

/// Fetches aggregate stats (total sessions, best score, avg score).
final practiceStatsProvider = FutureProvider<PracticeStats?>((ref) async {
  try {
    final dio = buildGenerationDio();
    final res = await dio.get('/api/candidate/practice-sessions/stats');
    final raw = res.data;
    if (raw is Map<String, dynamic>) return PracticeStats.fromJson(raw);
    return null;
  } catch (_) {
    return null;
  }
});

/// Derived filtered sessions — derived from practiceHistoryProvider + filter.
final filteredSessionsProvider = Provider<List<PracticeSession>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  final sessions = ref.watch(practiceHistoryProvider).maybeWhen(
    data: (list) => list,
    orElse: () => const <PracticeSession>[],
  );
  return filter.apply(sessions);
});

// ── Marketplace filter state ──────────────────────────────────────────────────

class MarketplaceFilterState {
  final String searchQuery;
  final String categoryFilter; // 'All', 'Frontend', etc.
  final String difficultyFilter; // 'All', 'Easy', 'Medium', 'Hard'

  const MarketplaceFilterState({
    this.searchQuery = '',
    this.categoryFilter = 'All',
    this.difficultyFilter = 'All',
  });

  MarketplaceFilterState copyWith({
    String? searchQuery,
    String? categoryFilter,
    String? difficultyFilter,
  }) =>
      MarketplaceFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        categoryFilter: categoryFilter ?? this.categoryFilter,
        difficultyFilter: difficultyFilter ?? this.difficultyFilter,
      );

  List<QuestionSet> apply(List<QuestionSet> sets) {
    var result = sets;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.company.toLowerCase().contains(q) ||
              s.skills.any((sk) => sk.toLowerCase().contains(q)))
          .toList();
    }
    if (categoryFilter != 'All') {
      result = result.where((s) => s.category == categoryFilter).toList();
    }
    if (difficultyFilter != 'All') {
      result = result
          .where((s) => s.difficulty.name == difficultyFilter)
          .toList();
    }
    return result;
  }
}

class MarketplaceFilterNotifier extends StateNotifier<MarketplaceFilterState> {
  MarketplaceFilterNotifier() : super(const MarketplaceFilterState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(String c) => state = state.copyWith(categoryFilter: c);
  void setDifficulty(String d) => state = state.copyWith(difficultyFilter: d);
}

final marketplaceFilterProvider =
    StateNotifierProvider<MarketplaceFilterNotifier, MarketplaceFilterState>(
  (ref) => MarketplaceFilterNotifier(),
);

// ── Marketplace API ───────────────────────────────────────────────────────────

class MarketplaceApiState {
  final List<QuestionSet> sets;
  final bool isLoading;
  final String? error;

  const MarketplaceApiState({
    this.sets = const [],
    this.isLoading = true,
    this.error,
  });

  MarketplaceApiState copyWith({
    List<QuestionSet>? sets,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      MarketplaceApiState(
        sets: sets ?? this.sets,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class MarketplaceApiNotifier extends StateNotifier<MarketplaceApiState> {
  MarketplaceApiNotifier(this._ref) : super(const MarketplaceApiState()) {
    _load();
  }

  final Ref _ref;
  Timer? _debounce;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final filter = _ref.read(marketplaceFilterProvider);
      final params = <String, dynamic>{};
      if (filter.searchQuery.isNotEmpty) params['keyword'] = filter.searchQuery;
      if (filter.difficultyFilter != 'All') {
        params['difficulty'] = filter.difficultyFilter;
      }
      if (filter.categoryFilter != 'All') {
        params['skills'] = filter.categoryFilter;
      }

      final dio = buildGenerationDio();
      final res = await dio.get(
        '/api/candidate/question-sets',
        queryParameters: params.isEmpty ? null : params,
      );
      final raw = res.data;
      final list = _extractList(raw);
      final sets = list
          .whereType<Map<String, dynamic>>()
          .map(QuestionSet.fromJson)
          .toList();
      if (mounted) state = state.copyWith(sets: sets, isLoading: false);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e is DioException
              ? 'Không thể tải danh sách (${e.response?.statusCode ?? 'lỗi mạng'})'
              : e.toString(),
        );
      }
    }
  }

  /// Called by the screen when search/filter changes.
  /// [immediate] = true skips debounce (used for pill-button filters).
  void scheduleRefresh({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _load();
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), _load);
    }
  }

  Future<void> refresh() => _load();

  /// Extracts a flat list from various API response shapes:
  /// - Direct `[...]`
  /// - `{data: [...]}`  or  `{items: [...]}`  or  `{result: [...]}`  or  `{content: [...]}`
  /// - Spring Boot Page: `{content: [...], totalElements: N}`
  /// - Wrapped pagination: `{data: {content: [...], ...}}`
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map) return const [];
    // Top-level list values
    for (final key in ['data', 'items', 'content', 'result']) {
      if (raw[key] is List) return raw[key] as List;
    }
    // Wrapped pagination: data is a Map with a nested list
    if (raw['data'] is Map) {
      final inner = raw['data'] as Map;
      for (final key in ['content', 'items', 'data', 'result']) {
        if (inner[key] is List) return inner[key] as List;
      }
    }
    return const [];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final marketplaceApiProvider =
    StateNotifierProvider<MarketplaceApiNotifier, MarketplaceApiState>(
  (ref) => MarketplaceApiNotifier(ref),
);

// Server-side filtering — API already applied params, sets are the final result.
final filteredSetsProvider = Provider<List<QuestionSet>>((ref) {
  return ref.watch(marketplaceApiProvider).sets;
});

// ── Set Detail API ────────────────────────────────────────────────────────────

/// Returns null for 404, throws for other errors.
final setDetailProvider =
    FutureProvider.family<QuestionSet?, String>((ref, id) async {
  final dio = buildGenerationDio();
  try {
    final res = await dio.get('/api/candidate/question-sets/$id');
    final raw = res.data;
    final Map<String, dynamic> data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      data = raw['data'] as Map<String, dynamic>;
    } else if (raw is Map<String, dynamic>) {
      data = raw;
    } else {
      throw const FormatException('Unexpected response format');
    }
    return QuestionSet.fromJson(data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
