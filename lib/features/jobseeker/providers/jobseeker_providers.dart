import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/storage_service.dart';
import '../data/jobseeker_mock.dart';
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
  final int currentIndex;
  final Map<String, String> answers;   // questionId → answer text
  final Map<String, bool> submitted;   // questionId → submitted
  final bool evaluating;
  final int timeLeft; // seconds remaining

  const PracticeSessionState({
    required this.setId,
    this.currentIndex = 0,
    Map<String, String>? answers,
    Map<String, bool>? submitted,
    this.evaluating = false,
    this.timeLeft = 45 * 60,
  })  : answers = answers ?? const {},
        submitted = submitted ?? const {};

  PracticeSessionState copyWith({
    int? currentIndex,
    Map<String, String>? answers,
    Map<String, bool>? submitted,
    bool? evaluating,
    int? timeLeft,
  }) =>
      PracticeSessionState(
        setId: setId,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        submitted: submitted ?? this.submitted,
        evaluating: evaluating ?? this.evaluating,
        timeLeft: timeLeft ?? this.timeLeft,
      );

  bool get allSubmitted {
    final set = findSetById(setId);
    if (set == null) return false;
    return set.questions.every((q) => submitted[q.id] == true);
  }
}

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(String setId)
      : super(PracticeSessionState(setId: setId));

  void goTo(int index) => state = state.copyWith(currentIndex: index);
  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void next() {
    final set = findSetById(state.setId);
    if (set != null && state.currentIndex < set.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void updateAnswer(String questionId, String text) {
    state = state.copyWith(
      answers: {...state.answers, questionId: text},
    );
  }

  Future<void> submitAnswer(String questionId) async {
    state = state.copyWith(evaluating: true);
    await Future.delayed(const Duration(milliseconds: 2000));
    final newSubmitted = {...state.submitted, questionId: true};
    state = state.copyWith(evaluating: false, submitted: newSubmitted);

    // Auto-advance after 600ms if not last question
    final set = findSetById(state.setId);
    if (set != null) {
      final idx = set.questions.indexWhere((q) => q.id == questionId);
      if (idx < set.questions.length - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          state = state.copyWith(currentIndex: idx + 1);
        }
      }
    }
  }

  void tick() {
    if (state.timeLeft > 0) {
      state = state.copyWith(timeLeft: state.timeLeft - 1);
    }
  }
}

// Provider is created per-session using family
final practiceSessionProvider = StateNotifierProvider.family<
    PracticeSessionNotifier, PracticeSessionState, String>(
  (ref, setId) => PracticeSessionNotifier(setId),
);

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

// Derived filtered sessions
final filteredSessionsProvider = Provider<List<PracticeSession>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  return filter.apply(practiceSessions.toList());
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

final filteredSetsProvider = Provider<List<QuestionSet>>((ref) {
  final filter = ref.watch(marketplaceFilterProvider);
  return filter.apply(questionSets.toList());
});
