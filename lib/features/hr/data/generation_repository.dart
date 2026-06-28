import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/generation_models.dart';

const _baseUrl = 'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';

class GenerationRepository {
  late final Dio _dio;

  GenerationRepository() {
    _dio = Dio(BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ))
      ..interceptors.add(_AuthInterceptor())
      ..interceptors.add(LogInterceptor(
        requestBody:    true,
        responseBody:   true,
        requestHeader:  false,
        responseHeader: false,
      ));
  }

  // ── Step 1: Create job ─────────────────────────────────────────────────────

  Future<String> createJob(GenerationFormInput input) async {
    final res = await _dio.post(
      '/api/hr/question-generation-jobs/plan',
      data: input.toJson(),
    );
    return _extractJobId(res.data);
  }

  // ── Step 2/4: Poll job ─────────────────────────────────────────────────────

  Future<GenerationJob> getJob(String jobId) async {
    final res = await _dio.get('/api/hr/question-generation-jobs/$jobId');
    return GenerationJob.fromJson(res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : {});
  }

  // ── Step 3a: Update plan ───────────────────────────────────────────────────

  Future<void> updatePlan(String jobId, PlanDraft plan) async {
    await _dio.put(
      '/api/hr/question-generation-jobs/$jobId/plan',
      data: plan.toPutJson(),
    );
  }

  // ── Step 3b: Approve plan ──────────────────────────────────────────────────

  Future<void> approvePlan(String jobId) async {
    await _dio.post('/api/hr/question-generation-jobs/$jobId/approve-plan');
  }

  // ── Step 4: Get questions ──────────────────────────────────────────────────

  Future<List<GeneratedQuestion>> getQuestions(String jobId) async {
    final res = await _dio.get('/api/hr/question-generation-jobs/$jobId/questions');
    return _parseQuestions(res.data);
  }

  // ── Step 5: Save draft ─────────────────────────────────────────────────────

  Future<String?> saveDraft(String jobId) async {
    final res = await _dio.post('/api/hr/question-generation-jobs/$jobId/save-draft');
    final data = _unwrap(res.data);
    return (data['questionSetId'] ?? data['id'])?.toString();
  }

  // ── Recovery ───────────────────────────────────────────────────────────────

  Future<void> retryPlan(String jobId) async {
    await _dio.post('/api/hr/question-generation-jobs/$jobId/retry-plan');
  }

  Future<void> retryQuestions(String jobId) async {
    await _dio.post('/api/hr/question-generation-jobs/$jobId/retry-questions');
  }

  Future<void> editInput(String jobId, GenerationFormInput input) async {
    await _dio.put(
      '/api/hr/question-generation-jobs/$jobId/input',
      data: input.toJson(),
    );
  }

  // ── Question management ────────────────────────────────────────────────────

  Future<void> deleteQuestion(String jobId, String questionId) async {
    await _dio.delete(
      '/api/hr/question-generation-jobs/$jobId/questions/$questionId',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _extractJobId(dynamic raw) {
    final data = _unwrap(raw);
    return (data['jobId'] ?? data['id'] ?? data['job_id'] ?? '').toString();
  }

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      if (raw['result'] is Map<String, dynamic>) return raw['result'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  static List<GeneratedQuestion> _parseQuestions(dynamic raw) {
    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['questions'] as List? ?? data['items'] as List?;
      }
      list ??= raw['questions'] as List? ?? raw['items'] as List?;
    }
    if (list == null) return [];
    final questions = list
        .whereType<Map<String, dynamic>>()
        .map(GeneratedQuestion.fromJson)
        .toList();
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return questions;
  }
}

// ─── Auth interceptor with auto-refresh ───────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('auth_refresh_token') ?? '';
        if (refreshToken.isEmpty) return handler.next(err);

        final refreshDio = Dio(BaseOptions(
          baseUrl:        _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          headers:        {'Content-Type': 'application/json'},
        ));

        final res = await refreshDio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final payload = res.data is Map && res.data['data'] is Map
            ? res.data['data'] as Map<String, dynamic>
            : (res.data is Map ? res.data as Map<String, dynamic> : {});

        final newToken =
            (payload['accessToken'] ?? payload['access_token'] ?? '').toString();
        if (newToken.isEmpty) return handler.next(err);

        await prefs.setString('auth_access_token', newToken);

        // Retry original request with new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';

        final retryDio = Dio(BaseOptions(baseUrl: _baseUrl));
        final retry = await retryDio.fetch(opts);
        return handler.resolve(retry);
      } catch (_) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}
