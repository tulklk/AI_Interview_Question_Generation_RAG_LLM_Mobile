import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/recommendation_repository.dart';
import '../../domain/models/candidate_recommendation.dart';

// ── Repository singleton ───────────────────────────────────────────────────────

final _repoProvider = Provider<RecommendationRepository>(
  (_) => RecommendationRepository(),
);

// ── Filter state ───────────────────────────────────────────────────────────────

class RecommendationFilter {
  final String? questionSetId;
  final RecommendationStatus? status;
  final int? minScore;

  const RecommendationFilter({
    this.questionSetId,
    this.status,
    this.minScore,
  });

  RecommendationFilter copyWith({
    Object? questionSetId = _sentinel,
    Object? status = _sentinel,
    Object? minScore = _sentinel,
  }) =>
      RecommendationFilter(
        questionSetId: questionSetId == _sentinel
            ? this.questionSetId
            : questionSetId as String?,
        status: status == _sentinel ? this.status : status as RecommendationStatus?,
        minScore: minScore == _sentinel ? this.minScore : minScore as int?,
      );

  bool get isEmpty =>
      questionSetId == null && status == null && minScore == null;
}

const _sentinel = Object();

class RecommendationFilterNotifier
    extends StateNotifier<RecommendationFilter> {
  RecommendationFilterNotifier() : super(const RecommendationFilter());

  void setStatus(RecommendationStatus? s) =>
      state = state.copyWith(status: s);

  void setMinScore(int? score) =>
      state = state.copyWith(minScore: score);

  void setQuestionSetId(String? id) =>
      state = state.copyWith(questionSetId: id);

  void reset() => state = const RecommendationFilter();
}

final recommendationFilterProvider =
    StateNotifierProvider<RecommendationFilterNotifier, RecommendationFilter>(
  (_) => RecommendationFilterNotifier(),
);

// ── Paginated list state ───────────────────────────────────────────────────────

class RecommendationListState {
  final List<CandidateRecommendation> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const RecommendationListState({
    this.items = const [],
    this.totalElements = 0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage + 1 < totalPages;

  RecommendationListState copyWith({
    List<CandidateRecommendation>? items,
    int? totalElements,
    int? totalPages,
    int? currentPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) =>
      RecommendationListState(
        items:          items          ?? this.items,
        totalElements:  totalElements  ?? this.totalElements,
        totalPages:     totalPages     ?? this.totalPages,
        currentPage:    currentPage    ?? this.currentPage,
        isLoading:      isLoading      ?? this.isLoading,
        isLoadingMore:  isLoadingMore  ?? this.isLoadingMore,
        error:          clearError ? null : (error ?? this.error),
      );
}

class RecommendationListNotifier
    extends StateNotifier<RecommendationListState> {
  RecommendationListNotifier(this._repo)
      : super(const RecommendationListState());

  final RecommendationRepository _repo;
  RecommendationFilter _filter = const RecommendationFilter();

  Future<void> load(RecommendationFilter filter) async {
    _filter = filter;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.list(
        questionSetId: filter.questionSetId,
        status:        filter.status?.toApiString,
        minScore:      filter.minScore,
        page:          0,
      );
      state = state.copyWith(
        items:         page.items,
        totalElements: page.totalElements,
        totalPages:    page.totalPages,
        currentPage:   0,
        isLoading:     false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     _repo.friendlyError(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.list(
        questionSetId: _filter.questionSetId,
        status:        _filter.status?.toApiString,
        minScore:      _filter.minScore,
        page:          nextPage,
      );
      state = state.copyWith(
        items:         [...state.items, ...page.items],
        totalElements: page.totalElements,
        totalPages:    page.totalPages,
        currentPage:   nextPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateItemStatus(String id, RecommendationStatus status) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.id == id ? (item..status = status) : item)
          .toList(),
    );
  }
}

final recommendationListProvider = StateNotifierProvider<
    RecommendationListNotifier, RecommendationListState>(
  (ref) => RecommendationListNotifier(ref.read(_repoProvider)),
);

// ── Selected item (passed from list → detail without extra API call) ───────────

final selectedRecommendationProvider =
    StateProvider<CandidateRecommendation?>((_) => null);

// ── Action notifier (shortlist / dismiss / invite) ────────────────────────────

class RecommendationActionNotifier extends StateNotifier<AsyncValue<void>> {
  RecommendationActionNotifier(this._repo) : super(const AsyncValue.data(null));
  final RecommendationRepository _repo;

  Future<bool> shortlist(String id) => _run(() => _repo.shortlist(id));
  Future<bool> dismiss(String id)   => _run(() => _repo.dismiss(id));
  Future<bool> invite(String id, {String? message}) =>
      _run(() => _repo.invite(id, message: message));

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recommendationActionProvider =
    StateNotifierProvider<RecommendationActionNotifier, AsyncValue<void>>(
  (ref) => RecommendationActionNotifier(ref.read(_repoProvider)),
);
