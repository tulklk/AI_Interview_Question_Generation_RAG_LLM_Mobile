import 'dart:io';
import 'package:dio/dio.dart';
import '../domain/models/studio_models.dart';
import 'generation_api.dart';

// ignore_for_file: avoid_print

/// Studio V2 — all calls to /api/studio/projects/*
/// Dio client is the same auth-interceptor client used by GenerationRepository.
class StudioRepository {
  StudioRepository() : _dio = buildGenerationDio();

  final Dio _dio;

  // ── helpers ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _unwrap(dynamic raw) =>
      unwrapObject(raw) ?? (raw is Map<String, dynamic> ? raw : {});

  // ── 9.4 Project ──────────────────────────────────────────────────────────────

  /// Create a new project and return its detail.
  Future<StudioProjectDetail> createProject({
    required String name,
    String? description,
  }) async {
    final res = await _dio.post(
      '/api/studio/projects',
      data: {'name': name, if (description != null) 'description': description},
    );
    return StudioProjectDetail.fromJson(_unwrap(res.data));
  }

  /// List projects (returns summary list).
  Future<List<StudioProject>> listProjects() async {
    final res = await _dio.get('/api/studio/projects');
    return unwrapList(res.data)
        .map((j) => StudioProject.fromJson(j))
        .toList();
  }

  /// Get a single project.
  Future<StudioProjectDetail> getProject(String projectId) async {
    final res = await _dio.get('/api/studio/projects/$projectId');
    return StudioProjectDetail.fromJson(_unwrap(res.data));
  }

  /// Update project name/description.
  Future<StudioProjectDetail> updateProject(
      String projectId, {required String name, String? description}) async {
    final res = await _dio.put(
      '/api/studio/projects/$projectId',
      data: {'name': name, if (description != null) 'description': description},
    );
    return StudioProjectDetail.fromJson(_unwrap(res.data));
  }

  /// Save draft (snapshot).
  Future<void> saveProject(String projectId) async {
    await _dio.post('/api/studio/projects/$projectId/save');
  }

  /// Publish project → question set becomes PUBLISHED.
  Future<void> publishProject(String projectId) async {
    await _dio.post('/api/studio/projects/$projectId/publish');
  }

  /// Unpublish project.
  Future<void> unpublishProject(String projectId) async {
    await _dio.post('/api/studio/projects/$projectId/unpublish');
  }

  // ── 9.5 Job Description ───────────────────────────────────────────────────────

  /// Get current JD — returns null on 404 / error.
  Future<StudioJobDescription?> getJobDescription(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/job-description');
      final j = _unwrap(res.data);
      if (j.isEmpty) return null;
      return StudioJobDescription.fromJson(j);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Save JD text.
  Future<void> saveJobDescription(String projectId, {required String content}) async {
    await _dio.put(
      '/api/studio/projects/$projectId/job-description',
      data: {'content': content, 'sourceType': 'PastedText'},
    );
  }

  /// Analyze JD → returns detected role / seniority / skills (may return null on error).
  Future<JdAnalyzeResult?> analyzeJobDescription(String projectId) async {
    try {
      final res = await _dio.post(
          '/api/studio/projects/$projectId/job-description/analyze');
      final j = _unwrap(res.data);
      return j.isEmpty ? null : JdAnalyzeResult.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  /// Upload JD file (PDF / DOCX / TXT / image). Field name: lowercase `file`.
  Future<void> uploadJobDescriptionFile(String projectId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last.split('\\').last,
      ),
    });
    await _dio.post(
      '/api/studio/projects/$projectId/job-description/upload',
      data: form,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  // ── 9.7 Settings ──────────────────────────────────────────────────────────────

  /// Get project settings (includes readiness).
  Future<StudioSettings> getSettings(String projectId) async {
    final res = await _dio.get('/api/studio/projects/$projectId/settings');
    return StudioSettings.fromJson(_unwrap(res.data));
  }

  /// Update project settings (full object).
  Future<StudioSettings> updateSettings(
      String projectId, Map<String, dynamic> payload) async {
    final res = await _dio.put(
      '/api/studio/projects/$projectId/settings',
      data: payload,
    );
    return StudioSettings.fromJson(_unwrap(res.data));
  }

  // ── 9.7 Plan ──────────────────────────────────────────────────────────────────

  /// Trigger plan generation. timeout 180s.
  Future<void> generatePlan(String projectId) async {
    await _dio.post(
      '/api/studio/projects/$projectId/plans/generate',
      options: Options(receiveTimeout: const Duration(seconds: 180)),
    );
  }

  /// Get current plan — returns null when backend sends 204 or empty.
  Future<StudioPlanDetail?> getCurrentPlan(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/plans/current');
      if (res.statusCode == 204) return null;
      final j = _unwrap(res.data);
      if (j.isEmpty) return null;
      return StudioPlanDetail.fromJson(j);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  /// Get specific plan by id.
  Future<StudioPlanDetail> getPlan(String projectId, String planId) async {
    final res = await _dio.get(
        '/api/studio/projects/$projectId/plans/$planId');
    return StudioPlanDetail.fromJson(_unwrap(res.data));
  }

  /// Approve plan. Requires revision + concurrencyVersion from plan detail (spec §9.7).
  Future<void> approvePlan(
    String projectId,
    String planId, {
    required int revision,
    required String concurrencyVersion,
    String? notes,
  }) async {
    await _dio.post(
      '/api/studio/projects/$projectId/plans/$planId/approve',
      data: {
        'revision':           revision,
        'concurrencyVersion': concurrencyVersion,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// Submit plan for approval.
  Future<void> submitPlanForApproval(String projectId, String planId) async {
    await _dio.post(
        '/api/studio/projects/$projectId/plans/$planId/submit-for-approval');
  }

  /// Apply settings to plan.
  Future<void> applyPlanSettings(
      String projectId, String planId, Map<String, dynamic> payload) async {
    await _dio.post(
      '/api/studio/projects/$projectId/plans/$planId/apply-settings',
      data: payload,
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
  }

  // ── 9.8 Questions ─────────────────────────────────────────────────────────────

  /// Start question generation run. Returns the run id from response.
  Future<String> generateQuestions(
    String projectId, {
    required String planId,
    bool replaceExisting = true,
    bool includeSampleAnswers = true,
    bool includeScoringRubric = true,
  }) async {
    final res = await _dio.post(
      '/api/studio/projects/$projectId/questions/generate',
      data: {
        'planId':              planId,
        'replaceExisting':     replaceExisting,
        'includeSampleAnswers': includeSampleAnswers,
        'includeScoringRubric': includeScoringRubric,
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final j = _unwrap(res.data);
    return (j['id'] ?? j['Id'] ?? j['runId'] ?? j['RunId'] ?? '').toString();
  }

  /// Poll a specific generation run.
  Future<StudioGenerationRun> getGenerationRun(
      String projectId, String runId) async {
    final res = await _dio.get(
        '/api/studio/projects/$projectId/question-generation-runs/$runId');
    return StudioGenerationRun.fromJson(_unwrap(res.data));
  }

  /// Get the most recent run (first in array) — returns null when list empty.
  Future<StudioGenerationRun?> getLatestGenerationRun(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/question-generation-runs');
      final list = unwrapList(res.data);
      if (list.isEmpty) return null;
      return StudioGenerationRun.fromJson(list.first);
    } catch (_) {
      return null;
    }
  }

  /// List questions (camelCase query params per spec §9.11).
  Future<List<StudioQuestion>> listQuestions(
    String projectId, {
    String? planId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final res = await _dio.get(
      '/api/studio/projects/$projectId/questions',
      queryParameters: {
        if (planId != null) 'planId': planId,
        'page':     page,
        'pageSize': pageSize,
      },
    );
    return unwrapList(res.data)
        .map((j) => StudioQuestion.fromJson(j))
        .toList();
  }

  /// Update a single question.
  Future<StudioQuestion> updateQuestion(
      String projectId, String questionId, Map<String, dynamic> payload) async {
    final res = await _dio.put(
      '/api/studio/projects/$projectId/questions/$questionId',
      data: payload,
    );
    return StudioQuestion.fromJson(_unwrap(res.data));
  }

  /// Delete a question.
  Future<void> deleteQuestion(String projectId, String questionId) async {
    await _dio.delete(
        '/api/studio/projects/$projectId/questions/$questionId');
  }

  /// Regenerate a single question.
  Future<StudioQuestion?> regenerateQuestion(
    String projectId,
    String questionId, {
    bool includeSampleAnswers = true,
    bool includeScoringRubric = true,
  }) async {
    try {
      final res = await _dio.post(
        '/api/studio/projects/$projectId/questions/$questionId/regenerate',
        data: {
          'includeSampleAnswers': includeSampleAnswers,
          'includeScoringRubric': includeScoringRubric,
        },
      );
      final j = _unwrap(res.data);
      return j.isEmpty ? null : StudioQuestion.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  // ── 9.6 Knowledge Documents (RAG) ────────────────────────────────────────────

  /// List documents attached to the project.
  Future<List<StudioDocument>> listDocuments(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/knowledge-documents');
      return unwrapList(res.data)
          .map((j) => StudioDocument.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Upload a new document (RAG). Field name: `file`.
  Future<StudioDocument> uploadDocument(
      String projectId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last.split('\\').last,
      ),
    });
    final res = await _dio.post(
      '/api/studio/projects/$projectId/knowledge-documents',
      data: form,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return StudioDocument.fromJson(_unwrap(res.data));
  }

  /// Delete / detach a document from the project.
  Future<void> deleteDocument(String projectId, String documentId) async {
    await _dio.delete(
        '/api/studio/projects/$projectId/knowledge-documents/$documentId');
  }

  /// Reingest (re-index) a document.
  Future<void> reingestDocument(String projectId, String documentId) async {
    await _dio.post(
        '/api/studio/projects/$projectId/knowledge-documents/$documentId/reingest');
  }

  /// Toggle document selection for RAG context.
  Future<void> setDocumentSelection(
      String projectId, String documentId, {required bool isSelected}) async {
    await _dio.patch(
      '/api/studio/projects/$projectId/knowledge-documents/$documentId',
      data: {'isSelected': isSelected},
    );
  }

  /// List global library documents (KnowledgeDocument table).
  Future<List<StudioLibraryDocument>> listLibraryDocuments(
      String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/knowledge-documents/library');
      return unwrapList(res.data)
          .map((j) => StudioLibraryDocument.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Attach selected library documents to the project.
  Future<void> attachLibraryDocuments(
      String projectId, List<String> knowledgeDocumentIds) async {
    await _dio.post(
      '/api/studio/projects/$projectId/knowledge-documents/attach',
      data: {'knowledgeDocumentIds': knowledgeDocumentIds},
    );
  }

  // ── 9.9 Chat / Refine ─────────────────────────────────────────────────────────

  /// Get or create chat session for this project.
  Future<Map<String, dynamic>?> getChatSession(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/chat/session');
      return _unwrap(res.data);
    } catch (_) {
      return null;
    }
  }

  /// List chat messages for the project.
  Future<List<StudioChatMessage>> getChatMessages(String projectId) async {
    try {
      final res = await _dio.get(
          '/api/studio/projects/$projectId/chat/messages');
      return unwrapList(res.data)
          .map((j) => StudioChatMessage.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Send a refine-plan message and wait for the assistant reply.
  /// Returns the latest list of messages (including assistant response).
  Future<List<StudioChatMessage>> refinePlan(
      String projectId, String message) async {
    await _dio.post(
      '/api/studio/projects/$projectId/chat/refine',
      data: {'message': message},
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return getChatMessages(projectId);
  }

  /// Apply current settings to the plan (regenerates plan sections).
  Future<void> applySettingsToPlan(String projectId, String planId) async {
    await _dio.post(
      '/api/studio/projects/$projectId/plans/$planId/apply-settings',
      data: {},
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────────

  /// Create a share token with the given permission level.
  Future<String?> createShareLink(
      String projectId, {String permission = 'View'}) async {
    try {
      final res = await _dio.post(
        '/api/studio/projects/$projectId/share',
        data: {'permission': permission},
      );
      final j = _unwrap(res.data);
      return (j['token'] ?? j['Token'])?.toString();
    } catch (_) {
      return null;
    }
  }
}
