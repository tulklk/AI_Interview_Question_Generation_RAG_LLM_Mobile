import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../hr_generate/data/generation_api.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DetailSession {
  final String id;
  final String? jobTitle;
  final String status;
  final String? failureMessage;
  final Map<String, dynamic>? planDraft;
  final List<Map<String, dynamic>> questions;

  const DetailSession({
    required this.id,
    this.jobTitle,
    required this.status,
    this.failureMessage,
    this.planDraft,
    this.questions = const [],
  });

  factory DetailSession.fromJson(Map<String, dynamic> j) {
    dynamic raw = j;
    if (j['data'] is Map) raw = j['data'];
    if ((raw as Map)['data'] is Map) raw = raw['data'];

    return DetailSession(
      id:             raw['id']?.toString() ?? '',
      jobTitle:       raw['jobTitle'] as String?,
      status:         raw['status']?.toString() ?? '',
      failureMessage: raw['failureMessage'] as String?,
      planDraft:      raw['planDraft'] as Map<String, dynamic>?,
    );
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class DetailState {
  final DetailSession? session;
  final List<Map<String, dynamic>> questions;
  final bool isLoading;
  final String? error;

  const DetailState({
    this.session,
    this.questions  = const [],
    this.isLoading  = true,
    this.error,
  });

  DetailState copyWith({
    DetailSession? session,
    List<Map<String, dynamic>>? questions,
    bool? isLoading,
    String? error,
  }) =>
      DetailState(
        session:   session   ?? this.session,
        questions: questions ?? this.questions,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DetailNotifier extends StateNotifier<DetailState> {
  final String sessionId;
  DetailNotifier(this.sessionId) : super(const DetailState()) { _load(); }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio  = buildGenerationDio();
      final resp = await dio.get(
          '/api/hr/question-generation-jobs/$sessionId');
      final session = DetailSession.fromJson(
          resp.data as Map<String, dynamic>);

      List<Map<String, dynamic>> questions = [];
      if (session.status == 'COMPLETED' ||
          session.status == 'DRAFT_SAVED') {
        try {
          final qResp = await dio.get(
              '/api/hr/question-generation-jobs/$sessionId/questions');
          final raw = qResp.data;
          List qList = [];
          if (raw is Map) {
            qList = raw['data'] ?? raw['questions'] ?? [];
          } else if (raw is List) {
            qList = raw;
          }
          questions = qList.cast<Map<String, dynamic>>();
        } catch (_) {}
      }

      state = state.copyWith(
          session: session, questions: questions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  Future<void> saveDraft() async {
    try {
      final dio = buildGenerationDio();
      await dio.post(
          '/api/hr/question-generation-jobs/$sessionId/save-draft');
      if (mounted) {
        state = state.copyWith(
          session: DetailSession(
            id:             state.session?.id ?? '',
            jobTitle:       state.session?.jobTitle,
            status:         'DRAFT_SAVED',
            planDraft:      state.session?.planDraft,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: _err(e));
    }
  }

  void clearError() => state = state.copyWith(error: null);

  static String _err(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String) return msg;
      return 'Network error';
    }
    return e.toString();
  }
}

final detailProvider = StateNotifierProvider.autoDispose
    .family<DetailNotifier, DetailState, String>(
  (_, id) => DetailNotifier(id),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class HistoryDetailScreen extends ConsumerWidget {
  final String sessionId;
  const HistoryDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final dState   = ref.watch(detailProvider(sessionId));
    final notifier = ref.read(detailProvider(sessionId).notifier);

    if (dState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dState.error!),
              backgroundColor: const Color(0xFFEF4444)));
        notifier.clearError();
      });
    }

    final session = dState.session;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF4F5FB),
      appBar: AppBar(
        backgroundColor:  isDark ? const Color(0xFF0B1020) : Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          session?.jobTitle ?? 'Session Detail',
          style: TextStyle(
              color:      isDark ? Colors.white : const Color(0xFF111827),
              fontSize:   17,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          if (session?.status == 'COMPLETED')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: notifier.saveDraft,
                icon:  const Icon(Icons.bookmark_add_outlined, size: 16),
                label: const Text('Save Draft'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: dState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C47FF)))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (session != null) ...[
                        _StatusBanner(session: session, isDark: isDark),
                        const SizedBox(height: 14),

                        // Plan card
                        if (session.planDraft != null)
                          _PlanCard(
                              plan: session.planDraft!, isDark: isDark),

                        // Questions
                        if (dState.questions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Questions (${dState.questions.length})',
                            style: TextStyle(
                                color:      isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize:   16,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          ...dState.questions.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _QuestionCard(
                                index:  e.key + 1,
                                data:   e.value,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final DetailSession session;
  final bool isDark;
  const _StatusBanner({required this.session, required this.isDark});

  Color get _color {
    switch (session.status) {
      case 'COMPLETED':
      case 'DRAFT_SAVED':   return const Color(0xFF10B981);
      case 'PLAN_PROPOSED': return const Color(0xFF3B82F6);
      case 'FAILED':        return const Color(0xFFEF4444);
      default:              return const Color(0xFFF59E0B);
    }
  }

  String get _label {
    switch (session.status) {
      case 'COMPLETED':     return '✓ Completed';
      case 'DRAFT_SAVED':   return '✓ Draft Saved';
      case 'PLAN_PROPOSED': return 'Plan Ready for Review';
      case 'FAILED':        return 'Generation Failed';
      default:              return session.status;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              session.status == 'FAILED'
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: _color,
              size:  18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label,
                      style: TextStyle(
                          color:      _color,
                          fontSize:   13,
                          fontWeight: FontWeight.w600)),
                  if (session.status == 'FAILED' &&
                      session.failureMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      session.failureMessage!,
                      style: TextStyle(
                          color:    _color.withValues(alpha: 0.8),
                          fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isDark;
  const _PlanCard({required this.plan, required this.isDark});

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
            Text('Interview Plan',
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (plan['roleTitle'] != null || plan['role'] != null)
                  _PlanChip(
                    label: plan['roleTitle'] ?? plan['role'],
                    icon:  Icons.work_outline_rounded,
                    isDark: isDark,
                  ),
                if (plan['experienceLevel'] != null || plan['level'] != null)
                  _PlanChip(
                    label: plan['experienceLevel'] ?? plan['level'],
                    icon:  Icons.signal_cellular_alt_rounded,
                    isDark: isDark,
                  ),
                if (plan['difficulty'] != null)
                  _PlanChip(
                    label:  plan['difficulty'],
                    icon:   Icons.speed_rounded,
                    isDark: isDark,
                  ),
                if (plan['totalQuestions'] != null ||
                    plan['questionCount'] != null)
                  _PlanChip(
                    label: '${plan['totalQuestions'] ?? plan['questionCount']} Questions',
                    icon:  Icons.quiz_outlined,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ),
      );
}

class _PlanChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  const _PlanChip(
      {required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color:        isDark
              ? const Color(0xFF111827)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size:  12,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(label.toString(),
                style: TextStyle(
                    color:    isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 11)),
          ],
        ),
      );
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isDark;
  const _QuestionCard({
    required this.index,
    required this.data,
    required this.isDark,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q    = widget.data;
    final diff = q['difficulty']?.toString() ?? '';
    final type = q['questionType']?.toString() ?? '';

    final diffColor = _diffColor(diff);

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isDark
                ? const Color(0xFF2D3562)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width:  28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:        const Color(0xFF6C47FF)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index}',
                          style: const TextStyle(
                              color:      Color(0xFF6C47FF),
                              fontSize:   12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (diff.isNotEmpty)
                      _SmallBadge(
                          label: diff, color: diffColor),
                    const SizedBox(width: 4),
                    if (type.isNotEmpty)
                      _SmallBadge(
                          label: _typeLabel(type),
                          color: const Color(0xFF3B82F6)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  q['question']?.toString() ?? '',
                  style: TextStyle(
                      color:      widget.isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize:   13,
                      height:     1.5),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color:  widget.isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB),
            ),
            if (q['rationale'] != null)
              _ExpandSection(
                title:  'Rationale',
                text:   q['rationale'].toString(),
                isDark: widget.isDark,
              ),
            if (q['sampleAnswer'] != null)
              _ExpandSection(
                title:  'Sample Answer',
                text:   q['sampleAnswer'].toString(),
                isDark: widget.isDark,
              ),
          ],
        ],
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':   return const Color(0xFF10B981);
      case 'hard':   return const Color(0xFFEF4444);
      default:       return const Color(0xFFF59E0B);
    }
  }

  String _typeLabel(String t) {
    switch (t.toLowerCase()) {
      case 'technical':      return 'Technical';
      case 'behavioral':     return 'Behavioral';
      case 'situational':    return 'Situational';
      case 'system_design':
      case 'system-design':  return 'System Design';
      case 'problem_solving':
      case 'problem-solving': return 'Problem Solving';
      default:               return t;
    }
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color:      color,
                fontSize:   10,
                fontWeight: FontWeight.w600)),
      );
}

class _ExpandSection extends StatelessWidget {
  final String title;
  final String text;
  final bool isDark;
  const _ExpandSection(
      {required this.title, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color:      isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(text,
                style: TextStyle(
                    color:    isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 12,
                    height:   1.5)),
          ],
        ),
      );
}
