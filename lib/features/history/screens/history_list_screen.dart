import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../hr_generate/data/generation_api.dart';

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

  const HistorySession({
    required this.id,
    this.jobTitle,
    this.role,
    this.level,
    this.difficulty,
    required this.status,
    this.createdAt,
    this.questionCount,
  });

  factory HistorySession.fromJson(Map<String, dynamic> j) {
    final plan = j['planDraft'] ?? j['plan'] ?? const {};
    return HistorySession(
      id:            j['id']?.toString() ?? '',
      jobTitle:      j['jobTitle'] ?? j['title'] as String?,
      role:          (plan is Map ? plan['roleTitle'] ?? plan['role'] : null)
                         as String?,
      level:         (plan is Map ? plan['experienceLevel'] ?? plan['level'] : null)
                         as String?,
      difficulty:    (plan is Map ? plan['difficulty'] : null) as String?,
      status:        j['status']?.toString() ?? 'PENDING',
      createdAt:     j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      questionCount: j['questionCount'] as int?,
    );
  }

  String get displayTitle => jobTitle ?? (role != null ? '$role Interview' : 'Interview');

  bool get isInProgress =>
      status == 'PROCESSING' ||
      status == 'QUEUED' ||
      status == 'PLAN_GENERATION_IN_PROGRESS' ||
      status == 'QUESTION_GENERATION_IN_PROGRESS';
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
    if (statusFilter != 'ALL') {
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

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio  = buildGenerationDio();
      final resp = await dio.get('/api/hr/question-generation-jobs');
      final list = _extractList(resp.data);
      final sessions = list
          .map((e) => HistorySession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          final ta = a.createdAt ?? DateTime(0);
          final tb = b.createdAt ?? DateTime(0);
          return tb.compareTo(ta);
        });
      state = state.copyWith(sessions: sessions, isLoading: false);
      _maybeStartPoll(sessions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  void _maybeStartPoll(List<HistorySession> sessions) {
    _poll?.cancel();
    if (!sessions.any((s) => s.isInProgress)) return;
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!state.sessions.any((s) => s.isInProgress)) {
        _poll?.cancel();
        return;
      }
      try {
        final dio  = buildGenerationDio();
        final resp = await dio.get('/api/hr/question-generation-jobs');
        final sessions = _extractList(resp.data)
            .map((e) => HistorySession.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            final ta = a.createdAt ?? DateTime(0);
            final tb = b.createdAt ?? DateTime(0);
            return tb.compareTo(ta);
          });
        state = state.copyWith(sessions: sessions);
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

  Future<void> deleteSession(String id) async {
    try {
      final dio = buildGenerationDio();
      await dio.delete('/api/hr/question-generation-jobs/$id');
      state = state.copyWith(
          sessions: state.sessions.where((s) => s.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: _err(e));
    }
  }

  void setSearch(String q)    => state = state.copyWith(searchQuery: q);
  void setFilter(String f)    => state = state.copyWith(statusFilter: f);
  void clearError()           => state = state.copyWith(error: null);

  static String _err(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String) return msg;
      return 'Network error';
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
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final hState   = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    if (hState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hState.error!),
              backgroundColor: const Color(0xFFEF4444)));
        notifier.clearError();
      });
    }

    return RefreshIndicator(
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
                          session:  s,
                          isDark:   isDark,
                          onView:   () => context.push('/hr/history/${s.id}'),
                          onDelete: () =>
                              _confirmDelete(context, s, notifier),
                        ),
                      )),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HistorySession s,
    HistoryNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete session?'),
        content: Text('Remove "${s.displayTitle}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await notifier.deleteSession(s.id);
  }

  List<_StatusFilter> _statusFilters(AppLocalizations l) => [
    _StatusFilter(label: l.allSessions,  value: 'ALL'),
    _StatusFilter(label: l.completed,    value: 'COMPLETED'),
    _StatusFilter(label: 'Plan Ready',   value: 'PLAN_PROPOSED'),
    _StatusFilter(label: l.inProgress,   value: 'PROCESSING'),
    _StatusFilter(label: l.failed,       value: 'FAILED'),
  ];
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

class _SessionCard extends StatelessWidget {
  final HistorySession session;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.onView,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (session.status) {
      case 'COMPLETED':    return const Color(0xFF10B981);
      case 'PLAN_PROPOSED': return const Color(0xFF3B82F6);
      case 'FAILED':       return const Color(0xFFEF4444);
      default:             return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(BuildContext context) {
    final l = context.l10n;
    switch (session.status) {
      case 'COMPLETED':     return l.completed;
      case 'PLAN_PROPOSED': return 'Plan Ready';
      case 'FAILED':        return l.failed;
      case 'PROCESSING':    return '${l.processing}…';
      case 'QUEUED':        return 'Queued…';
      default:              return session.status;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.displayTitle,
                    style: TextStyle(
                        color:      isDark ? Colors.white : const Color(0xFF111827),
                        fontSize:   14,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(label: _statusLabel(context), color: _statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (session.level != null)
                  _MetaChip(label: session.level!, isDark: isDark),
                if (session.difficulty != null)
                  _MetaChip(label: session.difficulty!, isDark: isDark),
                if (session.questionCount != null)
                  _MetaChip(
                      label:  '${session.questionCount} Qs',
                      isDark: isDark),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _relativeDate(session.createdAt),
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 11),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onView,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C47FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('${context.l10n.viewDetail} →',
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon:      const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFF6B7280)),
                  padding:   EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ],
        ),
      );

  String _relativeDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0)  return 'Today';
    if (diff.inDays == 1)  return 'Yesterday';
    if (diff.inDays < 7)   return '${diff.inDays} days ago';
    return '${dt.day.toString().padLeft(2,'0')} '
        '${_months[dt.month - 1]} '
        '${dt.year}';
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
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
                onPressed: () => context.go('/hr/generate'),
                icon:  const Icon(Icons.add_rounded, size: 16),
                label: const Text('Generate Questions'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF)),
              ),
            ],
          ),
        ),
      );
}
