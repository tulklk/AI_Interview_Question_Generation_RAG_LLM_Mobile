import 'package:dio/dio.dart';
import '../domain/models/generated_question.dart';
import '../domain/models/generation_session.dart';
import '../domain/models/plan_draft.dart';
import 'generation_api.dart';

class GenerationRepository {
  final Dio _dio = buildGenerationDio();

  static const _base = '/api/hr/question-generation-jobs';

  // ── 1. Create job ──────────────────────────────────────────────────────────

  Future<String> createJob({
    required String jobDescription,
    String? hrNote,
    int numberOfQuestions = 10,
    String difficulty = 'medium',
    List<String> questionTypes = const ['technical', 'behavioral'],
    String? knowledgeDocumentId,
  }) async {
    final res = await _dio.post('$_base/plan', data: {
      'jobDescription':    jobDescription,
      if (hrNote != null && hrNote.isNotEmpty) 'hrNote': hrNote,
      'numberOfQuestions': numberOfQuestions,
      'difficulty':        difficulty,
      'questionTypes':     questionTypes,
      if (knowledgeDocumentId != null) 'knowledgeDocumentId': knowledgeDocumentId,
    });
    return _extractJobId(res.data);
  }

  // ── 2. Get session (polling) ───────────────────────────────────────────────

  Future<GenerationSession> getSession(String jobId) async {
    final res = await _dio.get('$_base/$jobId');
    return GenerationSession.fromJson(
        res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {});
  }

  // ── 3. Update plan ─────────────────────────────────────────────────────────

  Future<void> updatePlan(String jobId, PlanDraft plan) async {
    await _dio.put('$_base/$jobId/plan', data: plan.toJson());
  }

  // ── 4. Approve plan ────────────────────────────────────────────────────────

  Future<void> approvePlan(String jobId) async {
    await _dio.post('$_base/$jobId/approve-plan', data: <String, dynamic>{});
  }

  // ── 5. Retry plan ──────────────────────────────────────────────────────────

  Future<void> retryPlan(String jobId) async {
    await _dio.post('$_base/$jobId/retry-plan', data: <String, dynamic>{});
  }

  // ── 6. Retry questions ─────────────────────────────────────────────────────

  Future<void> retryQuestions(String jobId) async {
    await _dio.post('$_base/$jobId/retry-questions', data: <String, dynamic>{});
  }

  // ── 7. Update job input ────────────────────────────────────────────────────

  Future<void> updateInput(String jobId,
      {String? jobDescription, String? hrNote}) async {
    await _dio.put('$_base/$jobId/input', data: {
      if (jobDescription != null) 'jobDescription': jobDescription,
      if (hrNote != null) 'hrNote': hrNote,
    });
  }

  // ── 8. Get questions ───────────────────────────────────────────────────────

  Future<List<GeneratedQuestion>> getQuestions(String jobId) async {
    final res = await _dio.get('$_base/$jobId/questions');
    return _parseQuestions(res.data);
  }

  // ── 9. Update single question ──────────────────────────────────────────────

  Future<GeneratedQuestion> updateQuestion(
      String jobId, GeneratedQuestion q) async {
    final res = await _dio.put(
      '$_base/$jobId/questions/${q.id}',
      data: q.toUpdateJson(),
    );
    final data = _unwrap(res.data);
    return GeneratedQuestion.fromJson(
        data.isNotEmpty ? data : q.toUpdateJson()..['id'] = q.id);
  }

  // ── 10. Delete question ────────────────────────────────────────────────────

  Future<void> deleteQuestion(String jobId, String questionId) async {
    await _dio.delete('$_base/$jobId/questions/$questionId');
  }

  // ── 11. Add question ───────────────────────────────────────────────────────

  Future<GeneratedQuestion> addQuestion(String jobId,
      GeneratedQuestion q, int order) async {
    final res = await _dio.post('$_base/$jobId/questions', data: {
      ...q.toUpdateJson(),
      'order': order,
    });
    final data = _unwrap(res.data);
    return GeneratedQuestion.fromJson(data.isNotEmpty ? data : {'id': ''});
  }

  // ── 12. Save draft ─────────────────────────────────────────────────────────

  Future<String?> saveDraft(String jobId) async {
    try {
      final res = await _dio.post('$_base/$jobId/save-draft',
          data: <String, dynamic>{});
      final data = _unwrap(res.data);
      return (data['questionSetId'] ?? data['id'])?.toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return null; // already saved — OK
      rethrow;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _extractJobId(dynamic raw) {
    final d = _unwrap(raw);
    return (d['jobId'] ?? d['id'] ?? d['job_id'] ?? '').toString();
  }

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is! Map<String, dynamic>) return {};
    var m = raw;
    for (var i = 0; i < 4; i++) {
      if (m['data'] is Map<String, dynamic>) {
        m = m['data'] as Map<String, dynamic>;
        continue;
      }
      if (m['result'] is Map<String, dynamic>) {
        m = m['result'] as Map<String, dynamic>;
        continue;
      }
      break;
    }
    return m;
  }

  static List<GeneratedQuestion> _parseQuestions(dynamic raw) {
    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final d = raw['data'];
      if (d is List) {
        list = d;
      } else if (d is Map) {
        list = d['questions'] as List? ?? d['items'] as List?;
      }
      list ??= raw['questions'] as List? ?? raw['items'] as List?;
    }
    if (list == null) return [];
    final qs = list
        .whereType<Map<String, dynamic>>()
        .map(GeneratedQuestion.fromJson)
        .toList();
    qs.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return qs;
  }

  static String friendlyError(Object e) {
    if (e is DioException) {
      final body = e.response?.data;
      if (body is Map) {
        return (body['message'] ?? body['error'] ?? body['title'] ??
                'Lỗi từ máy chủ')
            .toString();
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
