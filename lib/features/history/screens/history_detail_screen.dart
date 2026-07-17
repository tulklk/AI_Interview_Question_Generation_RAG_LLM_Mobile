import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../hr_generate/ask_ai/widgets/ask_ai_panel.dart';
import '../../hr_generate/data/generation_api.dart';
import '../../hr_generate/data/generation_repository.dart';
import '../../hr_generate/domain/enums/difficulty_level.dart';
import '../../hr_generate/domain/enums/question_type.dart';
import '../../hr_generate/domain/models/generated_question.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DetailSession {
  final String id;
  final String? jobTitle;
  final String status;
  final String? failureMessage;
  final Map<String, dynamic>? planDraft;
  final String? questionSetId;

  const DetailSession({
    required this.id,
    this.jobTitle,
    required this.status,
    this.failureMessage,
    this.planDraft,
    this.questionSetId,
  });

  factory DetailSession.fromJson(Map<String, dynamic> j) {
    dynamic raw = j;
    for (var i = 0; i < 4; i++) {
      if (raw is Map && raw['data'] is Map) {
        raw = raw['data'];
        continue;
      }
      if (raw is Map && raw['result'] is Map) {
        raw = raw['result'];
        continue;
      }
      break;
    }
    if (raw is! Map) raw = <String, dynamic>{};

    final actions = raw['actions'];
    final qSetId = (actions is Map
            ? (actions['questionSetId'] ??
                actions['planId'] ??
                raw['questionSetId'] ??
                raw['planId'])
            : raw['questionSetId'] ?? raw['planId'])
        ?.toString();

    return DetailSession(
      id: (raw['jobId'] ?? raw['id'] ?? raw['job_id'] ?? '').toString(),
      jobTitle:       raw['jobTitle'] as String?,
      status:         (raw['phase'] ?? raw['status'] ?? '').toString(),
      failureMessage: raw['failureMessage'] as String?,
      planDraft:      (raw['planDraft'] ?? raw['plan'] ?? raw['planInfo'])
          as Map<String, dynamic>?,
      questionSetId:  qSetId,
    );
  }
}

class EditableQuestion {
  final String? id;       // null for new (not yet posted)
  Map<String, dynamic> data;
  bool isDeleted;
  bool isDirty;
  bool isNew;
  bool expanded;
  bool editing;

  EditableQuestion({
    this.id,
    required this.data,
    this.isDeleted = false,
    this.isDirty   = false,
    this.isNew     = false,
    this.expanded  = false,
    this.editing   = false,
  });

  EditableQuestion copyWith({
    Map<String, dynamic>? data,
    bool? isDeleted,
    bool? isDirty,
    bool? isNew,
    bool? expanded,
    bool? editing,
  }) =>
      EditableQuestion(
        id:         id,
        data:       data       ?? this.data,
        isDeleted:  isDeleted  ?? this.isDeleted,
        isDirty:    isDirty    ?? this.isDirty,
        isNew:      isNew      ?? this.isNew,
        expanded:   expanded   ?? this.expanded,
        editing:    editing    ?? this.editing,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class DetailState {
  final DetailSession? session;
  final List<EditableQuestion> questions;
  final bool isLoading;
  final bool isSaving;
  final bool isExporting;
  final bool isPublishing;
  final bool isPublished;
  final String? error;
  final String? successMsg;

  const DetailState({
    this.session,
    this.questions   = const [],
    this.isLoading   = true,
    this.isSaving    = false,
    this.isExporting = false,
    this.isPublishing = false,
    this.isPublished  = false,
    this.error,
    this.successMsg,
  });

  DetailState copyWith({
    DetailSession? session,
    List<EditableQuestion>? questions,
    bool? isLoading,
    bool? isSaving,
    bool? isExporting,
    bool? isPublishing,
    bool? isPublished,
    String? error,
    String? successMsg,
    bool clearMsg = false,
  }) =>
      DetailState(
        session:      session      ?? this.session,
        questions:    questions    ?? this.questions,
        isLoading:    isLoading    ?? this.isLoading,
        isSaving:     isSaving     ?? this.isSaving,
        isExporting:  isExporting  ?? this.isExporting,
        isPublishing: isPublishing ?? this.isPublishing,
        isPublished:  isPublished  ?? this.isPublished,
        error:        error,
        successMsg:   clearMsg ? null : (successMsg ?? this.successMsg),
      );

  bool get hasUnsaved =>
      questions.any((q) => q.isDeleted || q.isDirty || q.isNew);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DetailNotifier extends StateNotifier<DetailState> {
  final String sessionId;
  final GenerationRepository _repo = GenerationRepository();

  DetailNotifier(this.sessionId) : super(const DetailState()) { _load(); }

  static bool _shouldLoadQuestions(String status) {
    final s = status.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    const withQuestions = {
      'COMPLETED', 'DONE', 'SUCCESS', 'DRAFT_SAVED', 'DRAFT',
    };
    return withQuestions.contains(s) || s.contains('COMPLET');
  }

  static EditableQuestion _fromGenerated(GeneratedQuestion q) =>
      EditableQuestion(
        id:   q.id.isNotEmpty ? q.id : null,
        data: {
          'id':           q.id,
          'question':     q.question,
          'questionType': q.questionType.toApiString(),
          'difficulty':   q.difficulty.toApiString(),
          if (q.rationale != null) 'rationale': q.rationale,
          if (q.sampleAnswer != null) 'sampleAnswer': q.sampleAnswer,
          'orderIndex': q.orderIndex,
          'order':      q.orderIndex,
        },
      );

  static List<EditableQuestion> _fromRawQuestionList(dynamic raw) {
    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      var m = raw;
      for (var i = 0; i < 4; i++) {
        if (m['data'] is Map) {
          m = m['data'] as Map;
          continue;
        }
        if (m['result'] is Map) {
          m = m['result'] as Map;
          continue;
        }
        break;
      }
      if (m['questions'] is List) {
        list = m['questions'] as List;
      } else if (m['items'] is List) {
        list = m['items'] as List;
      } else if (m['data'] is List) {
        list = m['data'] as List;
      }
    }
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((q) => _fromGenerated(GeneratedQuestion.fromJson(q)))
        .toList();
  }

  Future<List<EditableQuestion>> _fetchQuestions(
    String jobId,
    String? questionSetId,
    List<GeneratedQuestion> inline,
  ) async {
    if (inline.isNotEmpty) {
      return inline.map(_fromGenerated).toList();
    }

    for (final id in [jobId, if (questionSetId != null && questionSetId != jobId) questionSetId]) {
      try {
        final qs = await _repo.getQuestions(id);
        if (qs.isNotEmpty) return qs.map(_fromGenerated).toList();
      } catch (_) {}

      try {
        final dio = buildGenerationDio();
        final qRes = await dio.get(
            '/api/hr/question-generation-jobs/$id/questions');
        final parsed = _fromRawQuestionList(qRes.data);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }

    return [];
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final genSession = await _repo.getSession(sessionId);

      final session = DetailSession(
        id: genSession.id.isNotEmpty ? genSession.id : sessionId,
        jobTitle: genSession.jobTitle.isNotEmpty ? genSession.jobTitle : null,
        status: genSession.rawPhase.isNotEmpty
            ? genSession.rawPhase
            : genSession.status.name,
        planDraft: genSession.planDraft?.toJson(),
        questionSetId: genSession.questionSetId,
      );

      List<EditableQuestion> questions = [];
      if (_shouldLoadQuestions(session.status)) {
        questions = await _fetchQuestions(
          session.id.isNotEmpty ? session.id : sessionId,
          session.questionSetId,
          genSession.generatedQuestions,
        );
      }

      if (mounted) {
        state = state.copyWith(
          session:     session,
          questions:   questions,
          isLoading:   false,
          isPublished: session.status.toUpperCase() == 'PUBLISHED',
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, error: _err(e));
    }
  }

  void toggleExpand(int index) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated[index] = updated[index].copyWith(
        expanded: !updated[index].expanded, editing: false);
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  void startEdit(int index) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated[index] =
        updated[index].copyWith(expanded: true, editing: true);
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  void cancelEdit(int index) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated[index] = updated[index].copyWith(editing: false);
    state = state.copyWith(questions: updated);
  }

  void saveEdit(int index, Map<String, dynamic> newData) {
    final updated = List<EditableQuestion>.from(state.questions);
    final q = updated[index];
    updated[index] = EditableQuestion(
      id:        q.id,
      data:      newData,
      isDirty:   !q.isNew,
      isNew:     q.isNew,
      expanded:  false,
      editing:   false,
    );
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  void markDelete(int index) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated[index] = updated[index].copyWith(isDeleted: true, editing: false);
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  void undoDelete(int index) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated[index] = updated[index].copyWith(isDeleted: false);
    state = state.copyWith(questions: updated);
  }

  void addQuestion(Map<String, dynamic> qData) {
    final updated = List<EditableQuestion>.from(state.questions);
    updated.add(EditableQuestion(
      id:    null,
      data:  qData,
      isNew: true,
    ));
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  void reorder(int oldIdx, int newIdx) {
    final live = state.questions
        .where((q) => !q.isDeleted)
        .toList();
    if (newIdx >= live.length) return;
    final moved = live.removeAt(oldIdx);
    live.insert(newIdx, moved);

    // rebuild full list preserving deleted items at end
    final deleted = state.questions.where((q) => q.isDeleted).toList();
    final updated = [...live, ...deleted];
    state = state.copyWith(questions: updated, error: null, clearMsg: true);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true, error: null, clearMsg: true);
    try {
      final dio = buildGenerationDio();
      final qs  = state.questions;

      // 1. Delete
      for (final q in qs.where((q) => q.isDeleted && q.id != null)) {
        await dio.delete(
            '/api/hr/question-generation-jobs/$sessionId/questions/${q.id}');
      }

      // 2. POST new questions and collect their new IDs
      final newIds = <String?>[];
      for (final q in qs.where((q) => q.isNew && !q.isDeleted)) {
        try {
          final res = await dio.post(
            '/api/hr/question-generation-jobs/$sessionId/questions',
            data: q.data,
          );
          final body = res.data;
          final newId = (body is Map
                  ? (body['data']?['id'] ?? body['id'])
                  : null)
              ?.toString();
          newIds.add(newId);
        } catch (_) {
          newIds.add(null);
        }
      }

      // 3. PUT edited questions
      for (final q in qs.where((q) => q.isDirty && !q.isDeleted && q.id != null)) {
        await dio.put(
          '/api/hr/question-generation-jobs/$sessionId/questions/${q.id}',
          data: q.data,
        );
      }

      // 4. Reorder surviving questions
      final survivingIds = qs
          .where((q) => !q.isDeleted)
          .map((q) => q.id)
          .whereType<String>()
          .toList();
      if (survivingIds.length > 1) {
        await dio.put(
          '/api/hr/question-generation-jobs/$sessionId/questions/reorder',
          data: survivingIds
              .asMap()
              .entries
              .map((e) => {'id': e.value, 'order': e.key})
              .toList(),
        );
      }

      // 5. Save draft
      await dio.post(
          '/api/hr/question-generation-jobs/$sessionId/save-draft');

      if (mounted) {
        // Reset dirty flags and reload
        await _load();
        state = state.copyWith(
            isSaving: false, successMsg: 'Đã lưu thành công');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSaving: false, error: _err(e));
      }
    }
  }

  Future<void> exportFile(String format) async {
    final qSetId = state.session?.questionSetId ?? sessionId;
    state = state.copyWith(isExporting: true, error: null, clearMsg: true);
    try {
      final dio = buildGenerationDio();
      final res = await dio.get(
        '/api/plans/$qSetId/export',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data as List<int>;
      final ext   = format == 'excel' ? 'xlsx' : 'pdf';
      final tmp   = Directory.systemTemp;
      final file  = File('${tmp.path}/hiregen_export_$sessionId.$ext');
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        state = state.copyWith(
          isExporting: false,
          successMsg:
              'Đã xuất file: ${file.path}',
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isExporting: false, error: _err(e));
      }
    }
  }

  void clearMessages() => state = state.copyWith(error: null, clearMsg: true);

  Future<void> publish() async {
    final qSetId = state.session?.questionSetId;
    if (qSetId == null || state.isPublishing) return;
    state = state.copyWith(isPublishing: true, error: null);
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$qSetId/publish');
      if (mounted) {
        state = state.copyWith(
          isPublishing: false,
          isPublished:  true,
          successMsg:   'Đã publish bộ câu hỏi lên marketplace!',
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isPublishing: false, error: _err(e));
      }
    }
  }

  Future<void> unpublish() async {
    final qSetId = state.session?.questionSetId;
    if (qSetId == null || state.isPublishing) return;
    state = state.copyWith(isPublishing: true, error: null);
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$qSetId/unpublish');
      if (mounted) {
        state = state.copyWith(
          isPublishing: false,
          isPublished:  false,
          successMsg:   'Đã gỡ bộ câu hỏi khỏi marketplace.',
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isPublishing: false, error: _err(e));
      }
    }
  }

  static String _err(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String) return msg;
      return 'Network error (${e.response?.statusCode ?? 'no response'})';
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
    final session  = dState.session;

    // Show toasts
    ref.listen(detailProvider(sessionId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
        ));
        notifier.clearMessages();
      } else if (next.successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.successMsg!),
          backgroundColor: const Color(0xFF10B981),
        ));
        notifier.clearMessages();
      }
    });

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
          session?.jobTitle ?? 'Chi tiết phiên',
          style: TextStyle(
              color:      isDark ? Colors.white : const Color(0xFF111827),
              fontSize:   17,
              fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (dState.isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width:  20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF6C47FF)),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: isDark ? Colors.white : const Color(0xFF111827)),
              color: isDark ? const Color(0xFF1A1F35) : Colors.white,
              onSelected: (v) async {
                if (v == 'pdf' || v == 'excel') {
                  notifier.exportFile(v);
                } else if (v == 'ai') {
                  _openAiPanel(context, sessionId, isDark);
                }
              },
              itemBuilder: (_) => [
                if (session?.questionSetId != null || true) ...[
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(children: const [
                      Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 8),
                      Text('Xuất PDF'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    child: Row(children: const [
                      Icon(Icons.table_chart_rounded,
                          color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 8),
                      Text('Xuất Excel'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                ],
                PopupMenuItem(
                  value: 'ai',
                  child: Row(children: const [
                    Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF6C47FF), size: 18),
                    SizedBox(width: 8),
                    Text('AI Hỏi đáp'),
                  ]),
                ),
              ],
            ),
          // ── Publish / Unpublish button ──────────────────────────────
          if (session?.questionSetId != null) ...[
            if (dState.isPublishing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: SizedBox(
                  width:  20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF7C3AED)),
                ),
              )
            else if (dState.isPublished)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmUnpublish(context, notifier, isDark),
                  icon:  const Icon(Icons.cloud_off_rounded, size: 14),
                  label: const Text('Unpublish',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side:            const BorderSide(color: Color(0xFF9CA3AF)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else if (dState.questions.where((q) => !q.isDeleted).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.icon(
                  onPressed: notifier.publish,
                  icon:  const Icon(Icons.cloud_upload_rounded, size: 14),
                  label: const Text('Publish',
                      style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
          if (dState.hasUnsaved)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: dState.isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: SizedBox(
                        width:  20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6C47FF)),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: notifier.save,
                      icon:  const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Lưu'),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (session != null) ...[
                        _StatusBanner(session: session, isDark: isDark),
                        const SizedBox(height: 14),

                        if (session.planDraft != null) ...[
                          _PlanCard(plan: session.planDraft!, isDark: isDark),
                          const SizedBox(height: 14),
                        ],

                        // Question list header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Câu hỏi (${dState.questions.where((q) => !q.isDeleted).length})',
                              style: TextStyle(
                                  color:      isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontSize:   16,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _openAddForm(context, notifier, isDark),
                              icon:  const Icon(Icons.add_rounded, size: 16,
                                  color: Color(0xFF6C47FF)),
                              label: const Text('Thêm câu hỏi',
                                  style: TextStyle(
                                      color:    Color(0xFF6C47FF),
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Reorderable question list
                        if (dState.questions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('Chưa có câu hỏi nào',
                                  style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF9CA3AF))),
                            ),
                          )
                        else
                          _QuestionList(
                            questions: dState.questions,
                            isDark:    isDark,
                            notifier:  notifier,
                            sessionId: sessionId,
                          ),
                      ],
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmUnpublish(
      BuildContext context, DetailNotifier notifier, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
        title: Text('Gỡ khỏi marketplace?',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827))),
        content: Text(
          'Bộ câu hỏi sẽ không hiển thị cho ứng viên sau khi Unpublish.',
          style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.unpublish();
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B7280)),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
  }

  void _openAddForm(
      BuildContext context, DetailNotifier notifier, bool isDark) {
    showModalBottomSheet(
      context:      context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddQuestionSheet(isDark: isDark, onAdd: (data) {
        notifier.addQuestion(data);
        Navigator.of(context).pop();
      }),
    );
  }

  void _openAiPanel(BuildContext context, String sId, bool isDark) {
    showModalBottomSheet(
      context:      context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0B1020) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AiPanel(sessionId: sId, isDark: isDark),
    );
  }
}

// ── Question list with reorder ────────────────────────────────────────────────

class _QuestionList extends StatelessWidget {
  final List<EditableQuestion> questions;
  final bool isDark;
  final DetailNotifier notifier;
  final String sessionId;

  const _QuestionList({
    required this.questions,
    required this.isDark,
    required this.notifier,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final live = questions.asMap().entries.where((e) => !e.value.isDeleted).toList();
    final deleted = questions.asMap().entries.where((e) => e.value.isDeleted).toList();

    return Column(children: [
      ReorderableListView.builder(
        shrinkWrap: true,
        physics:    const NeverScrollableScrollPhysics(),
        itemCount:  live.length,
        onReorder:  (oldIdx, newIdx) {
          if (newIdx > oldIdx) newIdx--;
          notifier.reorder(oldIdx, newIdx);
        },
        itemBuilder: (_, liveIdx) {
          final entry = live[liveIdx];
          return _QuestionCard(
            key:       ValueKey(entry.key),
            index:     entry.key,
            question:  entry.value,
            liveNum:   liveIdx + 1,
            isDark:    isDark,
            notifier:  notifier,
            sessionId: sessionId,
          );
        },
      ),

      if (deleted.isNotEmpty) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Sẽ bị xóa (${deleted.length})',
            style: const TextStyle(
                color:    Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        ...deleted.map((e) => _DeletedTile(
              index:    e.key,
              question: e.value,
              isDark:   isDark,
              notifier: notifier,
            )),
      ],
    ]);
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final int index;
  final EditableQuestion question;
  final int liveNum;
  final bool isDark;
  final DetailNotifier notifier;
  final String sessionId;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.liveNum,
    required this.isDark,
    required this.notifier,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final q       = question.data;
    final diff    = q['difficulty']?.toString() ?? '';
    final type    = q['questionType']?.toString() ?? '';
    final hasDirty = question.isDirty || question.isNew;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDirty
              ? const Color(0xFF6C47FF).withValues(alpha: 0.5)
              : isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: question.editing
          ? _EditForm(
              index:    index,
              data:     q,
              isDark:   isDark,
              notifier: notifier,
            )
          : Column(children: [
              // Header row
              InkWell(
                onTap: () => notifier.toggleExpand(index),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                    bottom: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width:  26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C47FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('$liveNum',
                                style: const TextStyle(
                                    color: Color(0xFF6C47FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (diff.isNotEmpty)
                          _SmallBadge(label: diff, color: _diffColor(diff)),
                        const SizedBox(width: 4),
                        if (type.isNotEmpty)
                          _SmallBadge(
                              label: _typeLabel(type),
                              color: const Color(0xFF3B82F6)),
                        if (hasDirty) ...[
                          const SizedBox(width: 4),
                          _SmallBadge(
                              label: question.isNew ? 'Mới' : 'Đã sửa',
                              color: const Color(0xFF6C47FF)),
                        ],
                        const Spacer(),
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          iconSize: 17,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                          onPressed: () => notifier.startEdit(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 10),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 17,
                          color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                          onPressed: () => _confirmDelete(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        // Drag handle
                        ReorderableDragStartListener(
                          index: liveNum - 1,
                          child: Icon(Icons.drag_handle_rounded,
                              color: isDark
                                  ? const Color(0xFF4A5578)
                                  : const Color(0xFF9CA3AF),
                              size: 20),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        q['question']?.toString() ?? '',
                        style: TextStyle(
                            color:    isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            fontSize: 13,
                            height:   1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Lịch sử AI Chat pill ─────────────────────────────────
              if (question.id != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                    onTap: () => showAskAiSheet(
                      context,
                      readOnly: true,
                      question: GeneratedQuestion(
                        id:           question.id!,
                        question:     q['question']?.toString() ?? '',
                        questionType: HrQuestionType.fromString(
                            q['questionType']?.toString() ?? 'technical'),
                        difficulty:   HrDifficultyLevel.fromString(
                            q['difficulty']?.toString() ?? 'medium'),
                        rationale:    q['rationale']?.toString(),
                        sampleAnswer: q['sampleAnswer']?.toString(),
                        orderIndex:   ((q['orderIndex'] ?? 0) as num).toInt(),
                      ),
                      jobId: sessionId,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                          begin:  Alignment.topLeft,
                          end:    Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Lịch sử AI',
                              style: TextStyle(
                                  color:      Colors.white,
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),

              // ── Expanded details ──────────────────────────────────────────
              if (question.expanded) ...[
                Divider(
                  height: 1,
                  color:  isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
                ),
                if (q['rationale'] != null)
                  _DetailSection(
                    title:  'Lý do hỏi',
                    text:   q['rationale'].toString(),
                    isDark: isDark,
                  ),
                if (q['sampleAnswer'] != null)
                  _DetailSection(
                    title:  'Câu trả lời mẫu',
                    text:   q['sampleAnswer'].toString(),
                    isDark: isDark,
                  ),
              ],
            ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
        title: Text('Xóa câu hỏi?',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827))),
        content: Text(
          'Câu hỏi sẽ được đánh dấu xóa. Nhấn Lưu để xác nhận.',
          style: TextStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.markDelete(index);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa'),
          ),
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
      case 'technical':       return 'Technical';
      case 'behavioral':      return 'Behavioral';
      case 'situational':     return 'Situational';
      case 'system_design':
      case 'system-design':   return 'System Design';
      case 'problem_solving':
      case 'problem-solving': return 'Problem Solving';
      default:                return t;
    }
  }
}

// ── Inline edit form ──────────────────────────────────────────────────────────

class _EditForm extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isDark;
  final DetailNotifier notifier;

  const _EditForm({
    required this.index,
    required this.data,
    required this.isDark,
    required this.notifier,
  });

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _qCtrl;
  late final TextEditingController _rationaleCtrl;
  late final TextEditingController _sampleCtrl;
  late String _difficulty;
  late String _type;

  static const _difficulties = ['easy', 'medium', 'hard'];
  static const _types = [
    'technical',
    'behavioral',
    'situational',
    'system_design',
    'problem_solving',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _qCtrl        = TextEditingController(text: d['question']?.toString() ?? '');
    _rationaleCtrl= TextEditingController(text: d['rationale']?.toString() ?? '');
    _sampleCtrl   = TextEditingController(text: d['sampleAnswer']?.toString() ?? '');
    _difficulty   = d['difficulty']?.toString() ?? 'medium';
    _type         = d['questionType']?.toString() ?? 'technical';
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _rationaleCtrl.dispose();
    _sampleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);
    final textColor =
        widget.isDark ? Colors.white : const Color(0xFF111827);
    final subColor = widget.isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final bgColor =
        widget.isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          TextField(
            controller:   _qCtrl,
            maxLines:     4,
            style:        TextStyle(color: textColor, fontSize: 13),
            decoration:   InputDecoration(
              hintText:    'Nội dung câu hỏi...',
              hintStyle:   TextStyle(color: subColor),
              filled:      true,
              fillColor:   bgColor,
              border:      OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6C47FF))),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),

          // Difficulty + Type row
          Row(children: [
            Expanded(
              child: _DropField(
                label:    'Độ khó',
                value:    _difficulty,
                items:    _difficulties,
                isDark:   widget.isDark,
                onChanged: (v) => setState(() => _difficulty = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DropField(
                label:    'Loại câu hỏi',
                value:    _type,
                items:    _types,
                isDark:   widget.isDark,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Rationale
          TextField(
            controller: _rationaleCtrl,
            maxLines:   2,
            style:      TextStyle(color: textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText:    'Lý do hỏi (tuỳ chọn)...',
              hintStyle:   TextStyle(color: subColor, fontSize: 12),
              filled:      true,
              fillColor:   bgColor,
              border:      OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6C47FF))),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),

          // Sample answer
          TextField(
            controller: _sampleCtrl,
            maxLines:   3,
            style:      TextStyle(color: textColor, fontSize: 12),
            decoration: InputDecoration(
              hintText:    'Câu trả lời mẫu (tuỳ chọn)...',
              hintStyle:   TextStyle(color: subColor, fontSize: 12),
              filled:      true,
              fillColor:   bgColor,
              border:      OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6C47FF))),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          Row(children: [
            const Spacer(),
            TextButton(
              onPressed: () => widget.notifier.cancelEdit(widget.index),
              child: Text('Hủy', style: TextStyle(color: subColor)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10)),
              child: const Text('Xong',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  void _submit() {
    if (_qCtrl.text.trim().isEmpty) return;
    final newData = Map<String, dynamic>.from(widget.data)
      ..['question']      = _qCtrl.text.trim()
      ..['difficulty']    = _difficulty
      ..['questionType']  = _type
      ..['rationale']     = _rationaleCtrl.text.trim()
      ..['sampleAnswer']  = _sampleCtrl.text.trim();
    widget.notifier.saveEdit(widget.index, newData);
  }
}

// ── Deleted tile ──────────────────────────────────────────────────────────────

class _DeletedTile extends StatelessWidget {
  final int index;
  final EditableQuestion question;
  final bool isDark;
  final DetailNotifier notifier;

  const _DeletedTile({
    required this.index,
    required this.question,
    required this.isDark,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              question.data['question']?.toString() ?? '',
              style: const TextStyle(
                  color:     Color(0xFFEF4444),
                  fontSize:  12,
                  decoration: TextDecoration.lineThrough),
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => notifier.undoDelete(index),
            child: const Text('Hoàn tác',
                style: TextStyle(color: Color(0xFF6C47FF), fontSize: 12)),
          ),
        ]),
      );
}

// ── Add question sheet ────────────────────────────────────────────────────────

class _AddQuestionSheet extends StatefulWidget {
  final bool isDark;
  final void Function(Map<String, dynamic>) onAdd;
  const _AddQuestionSheet({required this.isDark, required this.onAdd});

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _qCtrl        = TextEditingController();
  final _rationaleCtrl= TextEditingController();
  final _sampleCtrl   = TextEditingController();
  String _difficulty  = 'medium';
  String _type        = 'technical';

  static const _difficulties = ['easy', 'medium', 'hard'];
  static const _types = [
    'technical', 'behavioral', 'situational', 'system_design', 'problem_solving',
  ];

  @override
  void dispose() {
    _qCtrl.dispose();
    _rationaleCtrl.dispose();
    _sampleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final bgColor   = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final border    = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    InputDecoration field(String hint, {int? maxLines}) => InputDecoration(
      hintText:    hint,
      hintStyle:   TextStyle(color: subColor, fontSize: 12),
      filled:      true,
      fillColor:   bgColor,
      border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C47FF))),
      contentPadding: const EdgeInsets.all(10),
    );

    return DraggableScrollableSheet(
      expand:       false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (_, ctrl) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width:  40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:        border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Thêm câu hỏi mới',
                  style: TextStyle(
                      color:      textColor,
                      fontSize:   16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              TextField(
                controller: _qCtrl,
                maxLines:   4,
                style:      TextStyle(color: textColor, fontSize: 13),
                decoration: field('Nội dung câu hỏi *'),
              ),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: _DropField(
                    label:     'Độ khó',
                    value:     _difficulty,
                    items:     _difficulties,
                    isDark:    isDark,
                    onChanged: (v) => setState(() => _difficulty = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropField(
                    label:     'Loại câu hỏi',
                    value:     _type,
                    items:     _types,
                    isDark:    isDark,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              TextField(
                controller: _rationaleCtrl,
                maxLines:   2,
                style:      TextStyle(color: textColor, fontSize: 12),
                decoration: field('Lý do hỏi (tuỳ chọn)'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _sampleCtrl,
                maxLines:   3,
                style:      TextStyle(color: textColor, fontSize: 12),
                decoration: field('Câu trả lời mẫu (tuỳ chọn)'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_qCtrl.text.trim().isEmpty) return;
                    widget.onAdd({
                      'question':     _qCtrl.text.trim(),
                      'difficulty':   _difficulty,
                      'questionType': _type,
                      'rationale':    _rationaleCtrl.text.trim(),
                      'sampleAnswer': _sampleCtrl.text.trim(),
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Thêm câu hỏi',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Chat Panel ─────────────────────────────────────────────────────────────

class _AiPanel extends StatefulWidget {
  final String sessionId;
  final bool isDark;
  const _AiPanel({required this.sessionId, required this.isDark});

  @override
  State<_AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<_AiPanel> {
  final _ctrl      = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages  = <Map<String, dynamic>>[];
  bool  _loading   = false;

  static const _kRagBase = 'https://iqgsrag.cloud';

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _loading = true;
    });
    _scrollToBottom();

    try {
      final dio = Dio(BaseOptions(
        baseUrl:        _kRagBase,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ));

      final history = _messages
          .where((m) => m['role'] != 'user' || m['content'] != msg)
          .map((m) => {'role': m['role'], 'content': m['content']})
          .toList();

      final res = await dio.post(
        '/api/v1/rag/interview-plans/messages',
        data: {
          'planId':              widget.sessionId,
          'message':             msg,
          'conversationHistory': history,
        },
      );

      final body  = res.data;
      final reply = (body is Map
              ? (body['data']?['reply'] ??
                  body['reply'] ??
                  body['data']?['message'] ??
                  body['message'] ??
                  body['content'] ??
                  body['data']?.toString())
              : null)
          ?.toString() ??
          'Không có phản hồi.';

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role':    'assistant',
            'content': 'Lỗi kết nối. Vui lòng thử lại.',
          });
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor  = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final inputBg   = isDark ? const Color(0xFF1A1F35) : const Color(0xFFF9FAFB);
    final borderCol = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    return DraggableScrollableSheet(
      expand:           false,
      initialChildSize: 0.8,
      minChildSize:     0.5,
      builder: (_, sc) => Column(children: [
        // Handle + title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: borderCol, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF6C47FF), size: 18),
              const SizedBox(width: 8),
              Text('AI Hỏi đáp',
                  style: TextStyle(
                      color:      textColor,
                      fontSize:   16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ]),
        ),
        Divider(color: borderCol, height: 1),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: subColor, size: 48),
                      const SizedBox(height: 12),
                      Text('Hỏi AI về kế hoạch phỏng vấn này',
                          style: TextStyle(color: subColor, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_loading && i == _messages.length) {
                      return _BubbleShimmer(isDark: isDark);
                    }
                    final m     = _messages[i];
                    final isMe  = m['role'] == 'user';
                    return _ChatBubble(
                      text:    m['content'] as String,
                      isMe:    isMe,
                      isDark:  isDark,
                    );
                  },
                ),
        ),

        // Input
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
          decoration: BoxDecoration(
            color:  isDark ? const Color(0xFF0B1020) : Colors.white,
            border: Border(top: BorderSide(color: borderCol)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style:      TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText:  'Hỏi về kế hoạch phỏng vấn...',
                  hintStyle: TextStyle(color: subColor, fontSize: 13),
                  filled:    true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                maxLines:        null,
                textInputAction: TextInputAction.send,
                onSubmitted:     (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: _loading
                    ? const Color(0xFF6C47FF).withValues(alpha: 0.4)
                    : const Color(0xFF6C47FF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _loading ? null : _send,
                icon: Icon(
                  _loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size:  18,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isDark;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Container(
                width:  28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFF6C47FF), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF6C47FF)
                      : isDark
                          ? const Color(0xFF1A1F35)
                          : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(16),
                    topRight:    const Radius.circular(16),
                    bottomLeft:  Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                    fontSize: 13,
                    height:   1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _BubbleShimmer extends StatelessWidget {
  final bool isDark;
  const _BubbleShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width:  28,
            height: 28,
            decoration: const BoxDecoration(
                color: Color(0xFF6C47FF), shape: BoxShape.circle),
            child: const Center(
              child: SizedBox(
                width:  14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 36,
            width:  120,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1F35)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ]),
      );
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _DropField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final bool isDark;
  final void Function(String) onChanged;

  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border    = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);
    final bgColor   = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: subColor, fontSize: 10,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:        bgColor,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: border),
          ),
          child: DropdownButton<String>(
            value:         value,
            isExpanded:    true,
            underline:     const SizedBox(),
            dropdownColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
            style:         TextStyle(color: textColor, fontSize: 12),
            items:         items
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v,
                          style: TextStyle(color: textColor, fontSize: 12)),
                    ))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DetailSession session;
  final bool isDark;
  const _StatusBanner({required this.session, required this.isDark});

  Color get _color {
    switch (session.status.toUpperCase()) {
      case 'COMPLETED':
      case 'DRAFT_SAVED':    return const Color(0xFF10B981);
      case 'PLAN_PROPOSED':
      case 'WAITINGAPPROVAL':return const Color(0xFF3B82F6);
      case 'FAILED':         return const Color(0xFFEF4444);
      default:               return const Color(0xFFF59E0B);
    }
  }

  String get _label {
    switch (session.status.toUpperCase()) {
      case 'COMPLETED':      return 'Hoàn thành';
      case 'DRAFT_SAVED':    return 'Đã lưu Draft';
      case 'PLAN_PROPOSED':  return 'Plan chờ duyệt';
      case 'FAILED':         return 'Tạo thất bại';
      default:               return session.status;
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
        child: Row(children: [
          Icon(
            session.status.toUpperCase() == 'FAILED'
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
                if (session.failureMessage != null &&
                    session.status.toUpperCase() == 'FAILED') ...[
                  const SizedBox(height: 2),
                  Text(session.failureMessage!,
                      style: TextStyle(
                          color:    _color.withValues(alpha: 0.8),
                          fontSize: 11)),
                ],
              ],
            ),
          ),
        ]),
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
            Text('Kế hoạch phỏng vấn',
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
                    label:  plan['roleTitle'] ?? plan['role'],
                    icon:   Icons.work_outline_rounded,
                    isDark: isDark,
                  ),
                if (plan['experienceLevel'] != null || plan['level'] != null)
                  _PlanChip(
                    label:  plan['experienceLevel'] ?? plan['level'],
                    icon:   Icons.signal_cellular_alt_rounded,
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
                    label: '${plan['totalQuestions'] ?? plan['questionCount']} câu hỏi',
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
  const _PlanChip({required this.label, required this.icon, required this.isDark});

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

class _DetailSection extends StatelessWidget {
  final String title;
  final String text;
  final bool isDark;
  const _DetailSection(
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
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
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
