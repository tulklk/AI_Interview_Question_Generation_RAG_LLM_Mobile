import 'dart:io';
import 'package:dio/dio.dart';
import 'storage_service.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum GenerationJobStatus {
  pending,
  planning,
  clarifying,
  planProposed,
  generatingQuestions,
  completed,
  failed,
  unknown;

  static GenerationJobStatus fromString(String s) {
    final key = s.toLowerCase().replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');
    switch (key) {
      case 'pending':
      case 'queued':
      case 'submitted':                       return GenerationJobStatus.pending;
      case 'planning':                        return GenerationJobStatus.planning;
      case 'clarifying':                      return GenerationJobStatus.clarifying;
      case 'planned':
      case 'planproposed':
      case 'awaitingapproval':
      case 'approved':                        return GenerationJobStatus.planProposed;
      case 'generatingquestions':
      case 'generating':
      case 'processing':                      return GenerationJobStatus.generatingQuestions;
      case 'completed':
      case 'done':
      case 'success':                         return GenerationJobStatus.completed;
      case 'failed':
      case 'error':                           return GenerationJobStatus.failed;
      default:                                return GenerationJobStatus.unknown;
    }
  }

  bool get isTerminal   => this == completed || this == failed;
  bool get isProcessing => this == pending || this == planning || this == generatingQuestions;
  bool get needsClarify => this == clarifying;
  bool get hasPlan      => this == planProposed;
}

// ─── Chat message ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String role;    // 'assistant' | 'user'
  final String content;
  final DateTime? timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
  });

  bool get isAI => role == 'assistant' || role == 'ai' || role == 'system';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role:      (json['role'] ?? json['sender'] ?? 'assistant').toString(),
        content:   (json['content'] ?? json['message'] ?? json['text'] ?? '').toString(),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString())
            : null,
      );
}

// ─── Plan draft model ─────────────────────────────────────────────────────────

class GenerationPlanModel {
  final String? summary;
  final String? role;
  final String? level;
  final int totalQuestions;
  final List<String> questionTypes;
  final List<String> topics;
  final List<String> skills;
  final String? constraints;

  const GenerationPlanModel({
    this.summary,
    this.role,
    this.level,
    this.totalQuestions = 0,
    this.questionTypes = const [],
    this.topics = const [],
    this.skills = const [],
    this.constraints,
  });

  factory GenerationPlanModel.fromJson(Map<String, dynamic> json) =>
      GenerationPlanModel(
        summary:        json['summary'] as String?,
        role:           json['role'] as String?,
        level:          json['level'] as String?,
        totalQuestions: (json['totalQuestions'] ?? json['questionCount'] ?? json['numberOfQuestions'] ?? 0) as int,
        questionTypes:  _toList(json['questionTypes'] ?? json['question_types'] ?? []),
        topics:         _toList(json['topics'] ?? json['suggestedTopics'] ?? []),
        skills:         _toList(json['skills'] ?? json['extractedSkills'] ?? []),
        constraints:    json['constraints'] as String?,
      );

  static List<String> _toList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }
}

// ─── Generated question ───────────────────────────────────────────────────────

class GeneratedQuestionItem {
  final String       id;
  final String       question;
  final String?      sampleAnswer;
  final String?      rationale;
  final List<String> citations;
  final String?      type;
  final String?      difficulty;
  final String?      skill;

  const GeneratedQuestionItem({
    required this.id,
    required this.question,
    this.sampleAnswer,
    this.rationale,
    this.citations = const [],
    this.type,
    this.difficulty,
    this.skill,
  });

  factory GeneratedQuestionItem.fromJson(Map<String, dynamic> json) {
    final rawCitations = json['citations'] ?? json['sources'] ?? [];
    return GeneratedQuestionItem(
      id:           (json['id'] ?? '').toString(),
      question:     (json['question'] ?? json['content'] ?? '').toString(),
      sampleAnswer: (json['sampleAnswer'] ?? json['expectedAnswer'] ?? json['sample_answer']) as String?,
      rationale:    (json['rationale'] ?? json['reasoning']) as String?,
      citations:    rawCitations is List
                        ? rawCitations.map((e) => e.toString()).toList()
                        : <String>[],
      type:         (json['type'] ?? json['questionType'] ?? json['question_type'] ?? '').toString(),
      difficulty:   (json['difficulty'] ?? '').toString(),
      skill:        (json['skill'] ?? json['skillTested'] ?? '').toString(),
    );
  }
}

// ─── Job model ────────────────────────────────────────────────────────────────

class GenerationJobModel {
  final String                    id;
  final GenerationJobStatus       status;
  final String?                   currentQuestion;    // AI clarify question
  final List<ChatMessage>         chatHistory;
  final GenerationPlanModel?      plan;
  final List<GeneratedQuestionItem> questions;
  final String?                   errorMessage;

  const GenerationJobModel({
    required this.id,
    required this.status,
    this.currentQuestion,
    this.chatHistory = const [],
    this.plan,
    this.questions = const [],
    this.errorMessage,
  });

  factory GenerationJobModel.fromJson(Map<String, dynamic> json) {
    // Parse chat history
    final rawChat = json['chatHistory'] ?? json['chat_history'] ?? json['messages'] ?? [];
    final chatHistory = rawChat is List
        ? rawChat.whereType<Map<String, dynamic>>().map(ChatMessage.fromJson).toList()
        : <ChatMessage>[];

    // Parse plan
    final rawPlan = json['plan'] ?? json['planDraft'] ?? json['plan_draft'];
    GenerationPlanModel? plan;
    if (rawPlan is Map<String, dynamic>) {
      plan = GenerationPlanModel.fromJson(rawPlan);
    }

    // Parse questions
    final rawQs = json['questions'];
    final questions = rawQs is List
        ? rawQs.whereType<Map<String, dynamic>>().map(GeneratedQuestionItem.fromJson).toList()
        : <GeneratedQuestionItem>[];

    // Current clarify question from AI
    final currentQuestion =
        json['currentQuestion'] ?? json['clarifyQuestion'] ?? json['question'];

    return GenerationJobModel(
      id:              (json['id'] ?? json['jobId'] ?? json['job_id'] ??
                        json['generationJobId'] ?? json['sessionId'] ?? json['questionGenerationJobId'] ?? '').toString(),
      status:          GenerationJobStatus.fromString((json['status'] ?? json['phase'] ?? '').toString()),
      currentQuestion: currentQuestion?.toString(),
      chatHistory:     chatHistory,
      plan:            plan,
      questions:       questions,
      errorMessage:    json['errorMessage'] as String?,
    );
  }
}

// ─── Config ───────────────────────────────────────────────────────────────────

class GenerationConfig {
  final int            numberOfQuestions;
  final List<String>   questionTypes;
  final List<String>   skills;
  final String         difficulty;
  final String?        hrNote;

  const GenerationConfig({
    this.numberOfQuestions = 10,
    this.questionTypes     = const ['technical', 'behavioral'],
    this.skills            = const [],
    this.difficulty        = 'medium',
    this.hrNote,
  });

  Map<String, dynamic> toJson() => {
        'numberOfQuestions': numberOfQuestions,
        'questionTypes':     questionTypes,
        'skills':            skills,
        'difficulty':        difficulty,
        if (hrNote != null && hrNote!.isNotEmpty) 'hrNote': hrNote,
      };

  // Multipart upload endpoint — PascalCase field names
  Map<String, String> toFormFields() => {
        'NumberOfQuestions': numberOfQuestions.toString(),
        'QuestionTypes':     questionTypes.join(','),
        'Skills':            skills.join(','),
        'Difficulty':        difficulty,
        if (hrNote != null && hrNote!.isNotEmpty) 'HrNote': hrNote!,
      };
}

// ─── Service ──────────────────────────────────────────────────────────────────

class QuestionGenerationService {
  static const _baseUrl =
      'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';

  static final _dio = Dio(BaseOptions(
    baseUrl:        _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ))
    ..interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
    ));

  static Future<Options> _auth() async {
    final token = await StorageService.getAccessToken();
    return Options(
      headers: (token?.isNotEmpty == true)
          ? {'Authorization': 'Bearer $token'}
          : {},
    );
  }

  // Unwrap common .NET API response wrappers: {"data":{...}} or {"result":{...}}
  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      if (raw.containsKey('result') && raw['result'] is Map<String, dynamic>) {
        return raw['result'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {'id': raw.toString()};
  }

  // ── Create job (text JD) ────────────────────────────────────────────────────

  static Future<GenerationJobModel> createJobFromText({
    required String          jobDescription,
    required GenerationConfig config,
  }) async {
    final res = await _dio.post(
      '/api/hr/question-generation-jobs/plan',
      data:    {'jobDescription': jobDescription, ...config.toJson()},
      options: await _auth(),
    );
    final data = res.data;
    return GenerationJobModel.fromJson(_unwrap(data));
  }

  // ── Create job (file upload) ────────────────────────────────────────────────

  static Future<GenerationJobModel> createJobFromFile({
    required File            file,
    required String          fileName,
    required GenerationConfig config,
  }) async {
    final authOpts = await _auth();
    final form = FormData.fromMap({
      'File': await MultipartFile.fromFile(file.path, filename: fileName),
      ...config.toFormFields(),
    });
    final res = await _dio.post(
      '/api/hr/question-generation-jobs/plan/upload',
      data:    form,
      options: Options(headers: {...?authOpts.headers}),
    );
    final data = res.data;
    return GenerationJobModel.fromJson(_unwrap(data));
  }

  // ── Get job status ──────────────────────────────────────────────────────────

  static Future<GenerationJobModel> getJob(String jobId) async {
    final res = await _dio.get(
      '/api/hr/question-generation-jobs/$jobId',
      options: await _auth(),
    );
    return GenerationJobModel.fromJson(_unwrap(res.data));
  }

  // ── Send clarify answer → PUT /{jobId}/plan ─────────────────────────────────

  static Future<GenerationJobModel> sendClarifyAnswer({
    required String jobId,
    required String answer,
  }) async {
    final res = await _dio.put(
      '/api/hr/question-generation-jobs/$jobId/plan',
      data:    {'hrNote': answer},
      options: await _auth(),
    );
    return GenerationJobModel.fromJson(_unwrap(res.data));
  }

  // ── Approve plan ────────────────────────────────────────────────────────────

  static Future<void> approvePlan(String jobId) async {
    await _dio.post(
      '/api/hr/question-generation-jobs/$jobId/approve-plan',
      options: await _auth(),
    );
  }

  // ── Get questions ───────────────────────────────────────────────────────────

  static Future<List<GeneratedQuestionItem>> getQuestions(String jobId) async {
    final res = await _dio.get(
      '/api/hr/question-generation-jobs/$jobId/questions',
      options: await _auth(),
    );
    if (res.data is List) {
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(GeneratedQuestionItem.fromJson)
          .toList();
    }
    return [];
  }

  // ── Retry plan ──────────────────────────────────────────────────────────────

  static Future<void> retryPlan(String jobId) async {
    await _dio.post(
      '/api/hr/question-generation-jobs/$jobId/retry-plan',
      options: await _auth(),
    );
  }

  // ── Retry questions ─────────────────────────────────────────────────────────

  static Future<void> retryQuestions(String jobId) async {
    await _dio.post(
      '/api/hr/question-generation-jobs/$jobId/retry-questions',
      options: await _auth(),
    );
  }
}
