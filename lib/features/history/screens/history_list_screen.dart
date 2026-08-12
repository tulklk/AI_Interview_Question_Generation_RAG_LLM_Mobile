import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../hr_generate/data/generation_api.dart';
import '../../hr_generate/data/studio_repository.dart';
import '../../hr_generate/domain/models/studio_models.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class HistorySession {
  final String id;
  final String? jobTitle;
  final String? role;
  final String? level;
  final String? difficulty;
  final String status;
  final DateTime? createdAt;
  final int? questionCount;
  final String? questionSetId;
  final bool isPublished;
  final bool isBookmarked;

  const HistorySession({
    required this.id,
    this.jobTitle,
    this.role,
    this.level,
    this.difficulty,
    required this.status,
    this.createdAt,
    this.questionCount,
    this.questionSetId,
    this.isPublished  = false,
    this.isBookmarked = false,
  });

  HistorySession copyWith({bool? isPublished, bool? isBookmarked}) => HistorySession(
        id:            id,
        jobTitle:      jobTitle,
        role:          role,
        level:         level,
        difficulty:    difficulty,
        status:        status,
        createdAt:     createdAt,
        questionCount: questionCount,
        questionSetId: questionSetId,
        isPublished:   isPublished  ?? this.isPublished,
        isBookmarked:  isBookmarked ?? this.isBookmarked,
      );

  factory HistorySession.fromJson(Map<String, dynamic> j) {
    final plan    = j['planDraft'] ?? j['plan'] ?? const {};
    final input   = j['input'] is Map ? j['input'] as Map : const {};
    final meta    = j['meta']    is Map ? j['meta']    as Map : const {};
    final actions = j['actions'] is Map ? j['actions'] as Map : const {};

    final planRole = plan is Map
        ? (plan['roleTitle'] ?? plan['role'])?.toString()
        : null;

    final questionSetId = (meta['questionSetId']
            ?? actions['questionSetId']
            ?? j['questionSetId'])
        ?.toString();

    bool isPublished = j['isPublished'] as bool? ?? false;
    if (!isPublished) {
      final rawStatus = (j['status'] ?? '').toString().toUpperCase();
      final pubStatus = (j['publishStatus'] ?? j['publishedStatus'] ?? '').toString().toUpperCase();
      isPublished = rawStatus == 'PUBLISHED' ||
          pubStatus == 'PUBLISHED' ||
          j['publishedAt'] != null;
    }

    return HistorySession(
      id:         (j['jobId'] ?? j['id'] ?? j['job_id'])?.toString() ?? '',
      jobTitle:   j['jobTitle']?.toString()
          ?? j['title']?.toString()
          ?? j['name']?.toString()
          ?? planRole
          ?? input['jobTitle']?.toString()
          ?? input['position']?.toString(),
      role:       planRole,
      level:      plan is Map
          ? (plan['experienceLevel'] ?? plan['level'])?.toString()
          : null,
      difficulty: plan is Map ? plan['difficulty']?.toString() : null,
      status:     j['status']?.toString() ?? 'PENDING',
      createdAt:  j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      questionCount: j['questionCount'] as int?,
      questionSetId: questionSetId,
      isPublished:   isPublished,
    );
  }

  /// Build a [HistorySession] from a Studio V2 [StudioProject].
  factory HistorySession.fromStudioProject(StudioProject p) => HistorySession(
        id:            p.id,
        jobTitle:      p.name,
        status:        p.status.toApiString(),
        questionSetId: p.questionSetId,
        isPublished:   p.isPublished,
      );

  String get displayTitle => jobTitle ?? role ?? 'Interview';

  bool get isInProgress {
    final s = status.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    // V1 statuses
    if (s == 'PROCESSING' || s == 'QUEUED' ||
        s == 'PLAN_GENERATION_IN_PROGRESS' || s == 'QUESTION_GENERATION_IN_PROGRESS' ||
        s == 'WAITING_HR_APPROVAL' || s == 'PLAN_PROPOSED' ||
        s == 'PLAN_QUEUED' || s == 'CONFIRMED' ||
        s == 'QUESTION_QUEUED' || s == 'QUESTION_PROCESSING') return true;
    // Studio V2 statuses that are still in-progress
    if (s == 'DRAFT' || s == 'REFINING' || s == 'AWAITINGAPPROVAL' ||
        s == 'APPROVED') return true;
    return false;
  }

  /// Sessions that should reopen the Studio wizard at the current step.
  bool get canResumeGeneration {
    final s = status.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    const completed = {'COMPLETED', 'DONE', 'SUCCESS', 'GENERATED', 'ARCHIVED'};
    return !completed.contains(s);
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class HistoryState {
  final List<HistorySession> sessions;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String statusFilter;

  const HistoryState({
    this.sessions     = const [],
    this.isLoading    = true,
    this.error,
    this.searchQuery  = '',
    this.statusFilter = 'ALL',
  });

  HistoryState copyWith({
    List<HistorySession>? sessions,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) =>
      HistoryState(
        sessions:     sessions     ?? this.sessions,
        isLoading:    isLoading    ?? this.isLoading,
        error:        error,
        searchQuery:  searchQuery  ?? this.searchQuery,
        statusFilter: statusFilter ?? this.statusFilter,
      );

  List<HistorySession> get filtered {
    var list = sessions;
    if (statusFilter == 'BOOKMARKED') {
      list = list.where((s) => s.isBookmarked).toList();
    } else if (statusFilter != 'ALL') {
      list = list.where((s) => s.status == statusFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((s) =>
          s.displayTitle.toLowerCase().contains(q) ||
          (s.role?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  int get totalQuestions =>
      sessions.fold(0, (sum, s) => sum + (s.questionCount ?? 0));

  int get thisMonthCount {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.createdAt != null &&
            s.createdAt!.month == now.month &&
            s.createdAt!.year == now.year)
        .length;
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) { load(); }

  Timer? _poll;

  // ── Shared fetch logic used by both load() and poll ───────────────────────

  static Future<List<HistorySession>> _fetchMergedSessions() async {
    final repo = StudioRepository();
    final projects = await repo.listProjects();
    return projects
        .map((p) => HistorySession.fromStudioProject(p))
        .toList();
  }

  static Future<List<HistorySession>> _applyBookmarks(
      List<HistorySession> sessions) async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/hr/bookmarks');
      final list = _extractList(res.data);
      final bookmarkedIds = list
          .whereType<Map>()
          .map((m) =>
              (m['id'] ?? m['questionSetId'] ?? m['setId'])?.toString())
          .whereType<String>()
          .toSet();
      return sessions
          .map((s) => s.copyWith(
                isBookmarked: s.questionSetId != null &&
                    bookmarkedIds.contains(s.questionSetId),
              ))
          .toList();
    } catch (_) {
      return sessions;
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _fetchMergedSessions();
      final withBk   = await _applyBookmarks(sessions);
      state = state.copyWith(sessions: withBk, isLoading: false);
      _maybeStartPoll(withBk);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  void _maybeStartPoll(List<HistorySession> sessions) {
    _poll?.cancel();
    if (!sessions.any((s) => s.isInProgress)) return;
    _poll = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!state.sessions.any((s) => s.isInProgress)) {
        _poll?.cancel();
        return;
      }
      try {
        // Use the same merged fetch so poll doesn't strip title/publish data
        final updated = await _fetchMergedSessions();
        // Preserve bookmark state from current view
        final prev   = state.sessions;
        final merged = updated.map((s) {
          final ex = prev.firstWhere((e) => e.id == s.id, orElse: () => s);
          return s.copyWith(isBookmarked: ex.isBookmarked);
        }).toList();
        if (mounted) state = state.copyWith(sessions: merged);
      } catch (_) {}
    });
  }

  /// Handles common BE response shapes:
  ///   { data: [...] }
  ///   { data: { data: [...], total: N } }
  ///   { result: [...] }
  ///   { data: { items: [...] } }
  ///   [...]
  static List _extractList(dynamic raw) {
    if (raw is List) { return raw; }
    if (raw is! Map) { return []; }

    // Try top-level 'data' key
    final d = raw['data'];
    if (d is List) { return d; }
    if (d is Map) {
      for (final k in ['data', 'items', 'sessions', 'jobs', 'records']) {
        if (d[k] is List) { return d[k] as List; }
      }
    }

    // Try 'result' key
    final r = raw['result'];
    if (r is List) { return r; }
    if (r is Map) {
      for (final k in ['data', 'items', 'sessions', 'jobs']) {
        if (r[k] is List) { return r[k] as List; }
      }
    }

    // Try other common keys directly on root
    for (final k in ['sessions', 'jobs', 'items', 'records']) {
      if (raw[k] is List) { return raw[k] as List; }
    }

    return [];
  }

  Future<bool> deleteSession(String id) async {
    // Optimistic removal — restore on failure
    final previous = state.sessions;
    state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != id).toList());
    try {
      final dio = buildGenerationDio();
      await dio.delete('/api/hr/question-generation-plans/$id');
      return true;
    } catch (e) {
      state = state.copyWith(sessions: previous, error: _err(e));
      return false;
    }
  }

  void _setPublished(String sessionId, bool val) {
    state = state.copyWith(
      sessions: state.sessions
          .map((s) => s.id == sessionId ? s.copyWith(isPublished: val) : s)
          .toList(),
    );
  }

  Future<void> publishSession(String sessionId) async {
    final session = state.sessions.firstWhere((s) => s.id == sessionId,
        orElse: () => const HistorySession(id: '', status: ''));
    final qSetId = session.questionSetId;
    if (qSetId == null || qSetId.isEmpty) return;

    _setPublished(sessionId, true);
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$qSetId/publish');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return; // already published — our update is correct
      _setPublished(sessionId, false);
      state = state.copyWith(error: _err(e));
    } catch (e) {
      _setPublished(sessionId, false);
      state = state.copyWith(error: _err(e));
    }
  }

  Future<void> unpublishSession(String sessionId) async {
    final session = state.sessions.firstWhere((s) => s.id == sessionId,
        orElse: () => const HistorySession(id: '', status: ''));
    final qSetId = session.questionSetId;
    if (qSetId == null || qSetId.isEmpty) return;

    _setPublished(sessionId, false);
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$qSetId/unpublish');
    } catch (e) {
      _setPublished(sessionId, true);
      state = state.copyWith(error: _err(e));
    }
  }

  Future<void> toggleBookmark(String sessionId) async {
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => const HistorySession(id: '', status: ''),
    );
    final qSetId = session.questionSetId;
    if (qSetId == null || qSetId.isEmpty) return;
    final newVal = !session.isBookmarked;
    state = state.copyWith(
      sessions: state.sessions
          .map((s) => s.id == sessionId ? s.copyWith(isBookmarked: newVal) : s)
          .toList(),
    );
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$qSetId/bookmark');
    } catch (e) {
      state = state.copyWith(
        sessions: state.sessions
            .map((s) =>
                s.id == sessionId ? s.copyWith(isBookmarked: !newVal) : s)
            .toList(),
        error: _err(e),
      );
    }
  }

  Future<void> renameTitle(String sessionId, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => const HistorySession(id: '', status: ''),
    );
    final qSetId = session.questionSetId;
    if (qSetId == null || qSetId.isEmpty) return;
    try {
      final dio = buildGenerationDio();
      await dio.put('/api/hr/question-sets/$qSetId/title',
          data: {'title': trimmed});
      await load();
    } catch (e) {
      state = state.copyWith(error: _err(e));
    }
  }

  void setSearch(String q)    => state = state.copyWith(searchQuery: q);
  void setFilter(String f)    => state = state.copyWith(statusFilter: f);
  void clearError()           => state = state.copyWith(error: null);

  static String _err(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['detail'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      final code = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint('[History] API error ${e.type} $code: $data');
      }
      if (code != null) return 'Lỗi server ($code). Vui lòng thử lại.';
      return 'Lỗi kết nối. Vui lòng thử lại.';
    }
    return e.toString();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}

final historyProvider =
    StateNotifierProvider.autoDispose<HistoryNotifier, HistoryState>(
        (_) => HistoryNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────

class HistoryListScreen extends ConsumerStatefulWidget {
  const HistoryListScreen({super.key});

  @override
  ConsumerState<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends ConsumerState<HistoryListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<HistoryState>(historyProvider, (prev, next) {
      final err = next.error;
      if (err == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      ref.read(historyProvider.notifier).clearError();
    });

    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final hState   = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return Stack(
      children: [
        RefreshIndicator(
      onRefresh: notifier.load,
      color:     const Color(0xFF6C47FF),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats row ──────────────────────────────────────────────
                Row(
                  children: [
                    _QuickStat(
                      label: 'Total',
                      value: '${hState.sessions.length}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _QuickStat(
                      label: 'Questions',
                      value: '${hState.totalQuestions}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _QuickStat(
                      label: 'This Month',
                      value: '${hState.thisMonthCount}',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Search ─────────────────────────────────────────────────
                TextField(
                  controller: _searchCtrl,
                  onChanged:  notifier.setSearch,
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText:      'Search sessions…',
                    hintStyle:     const TextStyle(color: Color(0xFF6B7280)),
                    prefixIcon:    const Icon(Icons.search_rounded,
                        color: Color(0xFF6B7280), size: 20),
                    filled:        true,
                    fillColor:     isDark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF9FAFB),
                    border:        OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   BorderSide(
                          color: isDark
                              ? const Color(0xFF2D3562)
                              : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6C47FF)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Status filter chips ────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters(context.l10n).map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label:    f.label,
                        value:    f.value,
                        selected: hState.statusFilter == f.value,
                        isDark:   isDark,
                        onTap:    () => notifier.setFilter(f.value),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // ── List ───────────────────────────────────────────────────
                if (hState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child:   CircularProgressIndicator(
                          color: Color(0xFF6C47FF)),
                    ),
                  )
                else if (hState.filtered.isEmpty)
                  _EmptyState(isDark: isDark)
                else
                  ...hState.filtered.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:   _SessionCard(
                          key:         ValueKey(s.id),
                          session:     s,
                          isDark:      isDark,
                          onView:      () => _openSession(context, s),
                          onDelete:    () => _confirmDelete(context, s, notifier),
                          onRename:    () => _showRenameDialog(context, s, notifier),
                          onPublish:   () => notifier.publishSession(s.id),
                          onUnpublish: () => notifier.unpublishSession(s.id),
                          onBookmark:  () => notifier.toggleBookmark(s.id),
                        ),
                      )),

                // Extra bottom padding so last card doesn't hide behind FAB
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    ),
        // ── FAB: Tạo bộ câu hỏi mới ──────────────────────────────────────
        Positioned(
          bottom: 16,
          left:   16,
          right:  16,
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: () => context.go('/hr/generate-question'),
              icon:  const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Tạo bộ câu hỏi mới',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                foregroundColor: Colors.white,
                minimumSize:    const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF6C47FF).withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSession(BuildContext context, HistorySession s) async {
    if (s.canResumeGeneration) {
      // Open Studio wizard to resume editing this project
      context.go('/hr/generate-question?projectId=${Uri.encodeComponent(s.id)}');
    } else {
      context.push('/hr/history/${s.id}');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HistorySession s,
    HistoryNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   const Text('Delete session?'),
        content: Text('Remove "${s.displayTitle}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await notifier.deleteSession(s.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phiên thành công'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<_StatusFilter> _statusFilters(AppLocalizations l) => [
    _StatusFilter(label: l.allSessions,             value: 'ALL'),
    _StatusFilter(label: l.completed,               value: 'COMPLETED'),
    const _StatusFilter(label: 'Plan Ready',        value: 'PLAN_PROPOSED'),
    _StatusFilter(label: l.inProgress,              value: 'PROCESSING'),
    _StatusFilter(label: l.failed,                  value: 'FAILED'),
    const _StatusFilter(label: 'Đã lưu',            value: 'BOOKMARKED'),
  ];

  Future<void> _showRenameDialog(
    BuildContext context,
    HistorySession s,
    HistoryNotifier notifier,
  ) async {
    if (s.questionSetId == null) return;
    final ctrl = TextEditingController(text: s.displayTitle);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
          title: Text('Đổi tên bộ câu hỏi',
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827))),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 500,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: const InputDecoration(hintText: 'Tên mới...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Hủy',
                  style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280))),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF)),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    final title = ctrl.text;
    ctrl.dispose();
    await notifier.renameTitle(s.id, title);
  }
}

class _StatusFilter {
  final String label;
  final String value;
  const _StatusFilter({required this.label, required this.value});
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F35) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF2D3562)
                    : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   20,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C47FF)
                : isDark
                    ? const Color(0xFF1A1F35)
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C47FF)
                  : isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
              fontSize:   12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

class _SessionCard extends StatefulWidget {
  final HistorySession session;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final Future<void> Function() onRename;
  final Future<void> Function() onPublish;
  final Future<void> Function() onUnpublish;
  final Future<void> Function() onBookmark;

  const _SessionCard({
    super.key,
    required this.session,
    required this.isDark,
    required this.onView,
    required this.onDelete,
    required this.onRename,
    required this.onPublish,
    required this.onUnpublish,
    required this.onBookmark,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _toggling = false;

  Color get _statusColor {
    switch (widget.session.status) {
      case 'COMPLETED':     return const Color(0xFF10B981);
      case 'PLAN_PROPOSED': return const Color(0xFF3B82F6);
      case 'FAILED':        return const Color(0xFFEF4444);
      default:              return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(BuildContext context) {
    final l = context.l10n;
    switch (widget.session.status) {
      case 'COMPLETED':     return l.completed;
      case 'PLAN_PROPOSED': return 'Plan Ready';
      case 'FAILED':        return l.failed;
      case 'PROCESSING':    return '${l.processing}…';
      case 'QUEUED':        return 'Queued…';
      default:              return widget.session.status;
    }
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    if (widget.session.isPublished) {
      await widget.onUnpublish();
    } else {
      await widget.onPublish();
    }
    if (mounted) setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final s         = widget.session;
    final isDark    = widget.isDark;
    final canPublish = s.status.toUpperCase() == 'COMPLETED' && s.questionSetId != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFEEEFF2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: widget.onRename,
                    child: Text(
                      s.displayTitle,
                      style: TextStyle(
                          color:      isDark ? Colors.white : const Color(0xFF111827),
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          height:     1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(label: _statusLabel(context), color: _statusColor),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Meta chips ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (s.questionCount != null)
                  _MetaChip(label: '${s.questionCount} câu', isDark: isDark),
                if (s.level != null)
                  _MetaChip(label: s.level!, isDark: isDark),
                if (s.difficulty != null)
                  _MetaChip(label: s.difficulty!, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Divider ────────────────────────────────────────────────
          Divider(height: 1, thickness: 1,
              color: isDark ? const Color(0xFF252D47) : const Color(0xFFF3F4F6)),

          // ── Footer ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            child: Row(
              children: [
                // Date
                Text(_relativeDate(s.createdAt),
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),

                // Publish pill (completed sessions only)
                if (canPublish) ...[
                  const SizedBox(width: 8),
                  _toggling
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Color(0xFF6C47FF)))
                      : GestureDetector(
                          onTap: _toggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: s.isPublished
                                  ? const Color(0xFF10B981).withValues(alpha: 0.10)
                                  : isDark
                                      ? const Color(0xFF252D47)
                                      : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  s.isPublished
                                      ? Icons.public_rounded
                                      : Icons.upload_rounded,
                                  size: 11,
                                  color: s.isPublished
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.isPublished ? 'Marketplace' : 'Publish',
                                  style: TextStyle(
                                    fontSize:   10,
                                    fontWeight: FontWeight.w600,
                                    color: s.isPublished
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],

                const Spacer(),

                // Bookmark
                SizedBox(
                  width: 30, height: 30,
                  child: IconButton(
                    onPressed: widget.onBookmark,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      s.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 17,
                      color: s.isBookmarked
                          ? const Color(0xFF6C47FF)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ),

                // View button
                TextButton(
                  onPressed: widget.onView,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C47FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('${context.l10n.viewDetail} →',
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),

                // Delete
                SizedBox(
                  width: 32, height: 32,
                  child: IconButton(
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 17, color: Color(0xFFD1D5DB)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_months[dt.month - 1]} '
        '${dt.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color:      color,
                fontSize:   10,
                fontWeight: FontWeight.w600)),
      );
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MetaChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color:        isDark
              ? const Color(0xFF111827)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(5),
          border:       Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                color:    isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 11)),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 56,
                  color: isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFD1D5DB)),
              const SizedBox(height: 12),
              Text(context.l10n.noHistory,
                  style: TextStyle(
                      color:      isDark ? Colors.white : const Color(0xFF111827),
                      fontSize:   16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                context.l10n.noHistoryHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color:  Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/hr/generate-question'),
                icon:  const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tạo bộ câu hỏi mới'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF)),
              ),
            ],
          ),
        ),
      );
}
