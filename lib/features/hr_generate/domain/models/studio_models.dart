// ── Studio V2 — Dart models (spec §10.1–10.6) ─────────────────────────────
// All fromJson mappers are defensive: both camelCase and PascalCase keys are
// accepted. Missing fields fall back to safe defaults (empty string, 0, false).

import 'dart:convert';

// ── Helper ────────────────────────────────────────────────────────────────────

dynamic _v(Map<String, dynamic> j, String camel, [String? pascal]) =>
    j[camel] ?? (pascal != null ? j[pascal] : null);

List<T> _list<T>(dynamic raw, T Function(dynamic) f) {
  if (raw is! List) return [];
  return raw.map((e) => f(e)).whereType<T>().toList();
}

/// Same as [_list] but allows the mapper to return null (filtered out).
List<T> _listOf<T>(dynamic raw, T? Function(dynamic) f) {
  if (raw is! List) return [];
  return raw.map((e) => f(e)).whereType<T>().toList();
}

// ── 10.1 Enums ────────────────────────────────────────────────────────────────

enum StudioProjectStatus {
  draft, refining, awaitingApproval, approved, generated, archived;

  static StudioProjectStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      case 'refining':          return StudioProjectStatus.refining;
      case 'awaitingapproval':  return StudioProjectStatus.awaitingApproval;
      case 'approved':          return StudioProjectStatus.approved;
      case 'generated':         return StudioProjectStatus.generated;
      case 'archived':          return StudioProjectStatus.archived;
      default:                  return StudioProjectStatus.draft;
    }
  }

  String toApiString() {
    switch (this) {
      case StudioProjectStatus.draft:            return 'Draft';
      case StudioProjectStatus.refining:         return 'Refining';
      case StudioProjectStatus.awaitingApproval: return 'AwaitingApproval';
      case StudioProjectStatus.approved:         return 'Approved';
      case StudioProjectStatus.generated:        return 'Generated';
      case StudioProjectStatus.archived:         return 'Archived';
    }
  }
}

enum StudioQuestionDifficulty {
  easy, medium, hard;

  static StudioQuestionDifficulty fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'easy': return StudioQuestionDifficulty.easy;
      case 'hard': return StudioQuestionDifficulty.hard;
      default:     return StudioQuestionDifficulty.medium;
    }
  }

  String toApiString() {
    switch (this) {
      case StudioQuestionDifficulty.easy:   return 'Easy';
      case StudioQuestionDifficulty.medium: return 'Medium';
      case StudioQuestionDifficulty.hard:   return 'Hard';
    }
  }

  String get displayName {
    switch (this) {
      case StudioQuestionDifficulty.easy:   return 'Dễ';
      case StudioQuestionDifficulty.medium: return 'Trung bình';
      case StudioQuestionDifficulty.hard:   return 'Khó';
    }
  }
}

enum StudioQuestionType {
  technical, behavioral, systemDesign, problemSolving, situational, followUp;

  static StudioQuestionType fromString(String? s) {
    final k = (s ?? '').toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    switch (k) {
      case 'technical':      return StudioQuestionType.technical;
      case 'behavioral':     return StudioQuestionType.behavioral;
      case 'systemdesign':   return StudioQuestionType.systemDesign;
      case 'problemsolving': return StudioQuestionType.problemSolving;
      case 'situational':    return StudioQuestionType.situational;
      case 'followup':       return StudioQuestionType.followUp;
      default:               return StudioQuestionType.technical;
    }
  }

  String toApiString() {
    switch (this) {
      case StudioQuestionType.technical:      return 'Technical';
      case StudioQuestionType.behavioral:     return 'Behavioral';
      case StudioQuestionType.systemDesign:   return 'SystemDesign';
      case StudioQuestionType.problemSolving: return 'ProblemSolving';
      case StudioQuestionType.situational:    return 'Situational';
      case StudioQuestionType.followUp:       return 'FollowUp';
    }
  }

  String get displayName {
    switch (this) {
      case StudioQuestionType.technical:      return 'Kỹ thuật';
      case StudioQuestionType.behavioral:     return 'Hành vi';
      case StudioQuestionType.systemDesign:   return 'System Design';
      case StudioQuestionType.problemSolving: return 'Giải quyết vấn đề';
      case StudioQuestionType.situational:    return 'Tình huống';
      case StudioQuestionType.followUp:       return 'Follow-up';
    }
  }
}

// ── 10.2 Project ──────────────────────────────────────────────────────────────

class StudioProject {
  final String id;
  final String name;
  final String? description;
  final StudioProjectStatus status;
  final bool isPublished;
  final String? questionSetId;

  const StudioProject({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.isPublished = false,
    this.questionSetId,
  });

  factory StudioProject.fromJson(Map<String, dynamic> j) => StudioProject(
        id:            (_v(j, 'id',            'Id')          ?? '').toString(),
        name:          (_v(j, 'name',          'Name')        ?? '').toString(),
        description:   _v(j, 'description',   'Description')?.toString(),
        status:        StudioProjectStatus.fromString(
                           (_v(j, 'status', 'Status') ?? '').toString()),
        isPublished:   _v(j, 'isPublished',   'IsPublished')  as bool? ?? false,
        questionSetId: _v(j, 'questionSetId', 'QuestionSetId')?.toString(),
      );
}

class StudioProjectDetail extends StudioProject {
  final String ownerId;
  final int latestPlanRevision;
  final String? questionSetStatus;

  const StudioProjectDetail({
    required super.id,
    required super.name,
    super.description,
    required super.status,
    super.isPublished,
    super.questionSetId,
    required this.ownerId,
    required this.latestPlanRevision,
    this.questionSetStatus,
  });

  factory StudioProjectDetail.fromJson(Map<String, dynamic> j) =>
      StudioProjectDetail(
        id:                  (_v(j, 'id',            'Id')          ?? '').toString(),
        name:                (_v(j, 'name',          'Name')        ?? '').toString(),
        description:         _v(j, 'description',   'Description')?.toString(),
        status:              StudioProjectStatus.fromString(
                                 (_v(j, 'status', 'Status') ?? '').toString()),
        isPublished:         _v(j, 'isPublished',   'IsPublished')  as bool? ?? false,
        questionSetId:       _v(j, 'questionSetId', 'QuestionSetId')?.toString(),
        ownerId:             (_v(j, 'ownerId',       'OwnerId')      ?? '').toString(),
        latestPlanRevision:  ((_v(j, 'latestPlanRevision', 'LatestPlanRevision') ?? 0) as num).toInt(),
        questionSetStatus:   _v(j, 'questionSetStatus', 'QuestionSetStatus')?.toString(),
      );
}

// ── 10.2 Job Description ──────────────────────────────────────────────────────

class JdAnalyzeResult {
  final String? detectedRole;
  final String? detectedSeniority;
  final String? detectedLanguage;
  final List<String> skills;

  const JdAnalyzeResult({
    this.detectedRole,
    this.detectedSeniority,
    this.detectedLanguage,
    this.skills = const [],
  });

  factory JdAnalyzeResult.fromJson(Map<String, dynamic> j) => JdAnalyzeResult(
        detectedRole:      _v(j, 'detectedRole',      'DetectedRole')?.toString(),
        detectedSeniority: _v(j, 'detectedSeniority', 'DetectedSeniority')?.toString(),
        detectedLanguage:  _v(j, 'detectedLanguage',  'DetectedLanguage')?.toString(),
        skills: _list(_v(j, 'skills', 'Skills'), (e) => e?.toString() ?? ''),
      );
}

class StudioJobDescription {
  final String content;
  final String sourceType;
  final String? originalFileName;
  final JdAnalyzeResult? summary;

  const StudioJobDescription({
    required this.content,
    this.sourceType = 'PastedText',
    this.originalFileName,
    this.summary,
  });

  factory StudioJobDescription.fromJson(Map<String, dynamic> j) {
    final rawSummary = _v(j, 'summary', 'Summary');
    return StudioJobDescription(
      content:          (_v(j, 'content',          'Content')          ?? '').toString(),
      sourceType:       (_v(j, 'sourceType',       'SourceType')       ?? 'PastedText').toString(),
      originalFileName: _v(j, 'originalFileName',  'OriginalFileName')?.toString(),
      summary: rawSummary is Map<String, dynamic>
          ? JdAnalyzeResult.fromJson(rawSummary)
          : null,
    );
  }
}

// ── 10.4 Plan ────────────────────────────────────────────────────────────────

class StudioPlanSection {
  final String id;
  final String name;
  final String? description;
  final int orderIndex;
  final int numberOfQuestions;
  final StudioQuestionDifficulty difficulty;
  final int estimatedMinutes;

  const StudioPlanSection({
    required this.id,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.numberOfQuestions,
    required this.difficulty,
    required this.estimatedMinutes,
  });

  factory StudioPlanSection.fromJson(Map<String, dynamic> j) => StudioPlanSection(
        id:                  (_v(j, 'id',                'Id')                ?? '').toString(),
        name:                (_v(j, 'name',              'Name')              ?? '').toString(),
        description:         _v(j, 'description',        'Description')?.toString(),
        orderIndex:          ((_v(j, 'orderIndex',        'OrderIndex')        ?? 0) as num).toInt(),
        numberOfQuestions:   ((_v(j, 'numberOfQuestions', 'NumberOfQuestions') ?? 0) as num).toInt(),
        difficulty:          StudioQuestionDifficulty.fromString(
                                 (_v(j, 'difficulty', 'Difficulty') ?? '').toString()),
        estimatedMinutes:    ((_v(j, 'estimatedMinutes', 'EstimatedMinutes') ?? 0) as num).toInt(),
      );
}

class StudioFocusArea {
  final String name;
  final double weight;
  final int orderIndex;
  final List<String> sourceFiles;

  const StudioFocusArea({
    required this.name,
    required this.weight,
    required this.orderIndex,
    this.sourceFiles = const [],
  });

  factory StudioFocusArea.fromJson(Map<String, dynamic> j) => StudioFocusArea(
        name:        (_v(j, 'name',       'Name')       ?? '').toString(),
        weight:      ((_v(j, 'weight',     'Weight')     ?? 0) as num).toDouble(),
        orderIndex:  ((_v(j, 'orderIndex', 'OrderIndex') ?? 0) as num).toInt(),
        sourceFiles: _list(_v(j, 'sourceFiles', 'SourceFiles'), (e) => e?.toString() ?? ''),
      );
}

class StudioDifficultyMix {
  final double easy;
  final double medium;
  final double hard;
  const StudioDifficultyMix({required this.easy, required this.medium, required this.hard});
  factory StudioDifficultyMix.fromJson(Map<String, dynamic> j) => StudioDifficultyMix(
        easy:   ((_v(j, 'easy',   'Easy')   ?? 0) as num).toDouble(),
        medium: ((_v(j, 'medium', 'Medium') ?? 0) as num).toDouble(),
        hard:   ((_v(j, 'hard',   'Hard')   ?? 0) as num).toDouble(),
      );
}

class StudioPlanDetail {
  final String id;
  final String projectId;
  final int revision;
  final String title;
  final String status;
  final int totalQuestions;
  final int interviewLengthMinutes;
  final StudioQuestionDifficulty difficulty;
  final StudioDifficultyMix? difficultyMix;
  final List<StudioFocusArea> focusAreas;
  final List<String> sourcesUsed;
  final List<StudioPlanSection> sections;
  final String concurrencyVersion;

  bool get isApproved => status == 'Approved';
  bool get isDraft     => status == 'Draft' || status == 'Refining';

  const StudioPlanDetail({
    required this.id,
    required this.projectId,
    required this.revision,
    required this.title,
    required this.status,
    required this.totalQuestions,
    required this.interviewLengthMinutes,
    required this.difficulty,
    this.difficultyMix,
    this.focusAreas = const [],
    this.sourcesUsed = const [],
    this.sections = const [],
    required this.concurrencyVersion,
  });

  factory StudioPlanDetail.fromJson(Map<String, dynamic> j) {
    final rawMix = _v(j, 'difficultyMix', 'DifficultyMix');
    final rawSections = _v(j, 'sections', 'Sections') ??
        _v(j, 'estimatedSections', 'EstimatedSections');
    return StudioPlanDetail(
      id:                    (_v(j, 'id',          'Id')          ?? '').toString(),
      projectId:             (_v(j, 'projectId',   'ProjectId')   ?? '').toString(),
      revision:              ((_v(j, 'revision',   'Revision')    ?? 0) as num).toInt(),
      title:                 (_v(j, 'title',       'Title')       ?? '').toString(),
      status:                (_v(j, 'status',      'Status')      ?? 'Draft').toString(),
      totalQuestions:        ((_v(j, 'totalQuestions',       'TotalQuestions')       ?? 0) as num).toInt(),
      interviewLengthMinutes:((_v(j, 'interviewLengthMinutes','InterviewLengthMinutes') ?? 60) as num).toInt(),
      difficulty:            StudioQuestionDifficulty.fromString(
                                 (_v(j, 'difficulty', 'Difficulty') ?? '').toString()),
      difficultyMix: rawMix is Map<String, dynamic>
          ? StudioDifficultyMix.fromJson(rawMix)
          : null,
      focusAreas:   _listOf<StudioFocusArea>(_v(j, 'focusAreas', 'FocusAreas'),
          (e) => e is Map<String, dynamic> ? StudioFocusArea.fromJson(e) : null),
      sourcesUsed:  _list(_v(j, 'sourcesUsed', 'SourcesUsed'), (e) => e?.toString() ?? ''),
      sections:     _listOf<StudioPlanSection>(rawSections,
          (e) => e is Map<String, dynamic> ? StudioPlanSection.fromJson(e) : null),
      concurrencyVersion: (_v(j, 'concurrencyVersion', 'ConcurrencyVersion') ?? '').toString(),
    );
  }
}

// ── 10.5 Settings ─────────────────────────────────────────────────────────────

class StudioReadiness {
  final bool hasJobDescription;
  final bool hasSelectedDocument;
  final bool hasAwaitingApprovalPlan;
  final bool hasApprovedPlan;
  final bool canGenerateQuestions;

  const StudioReadiness({
    this.hasJobDescription        = false,
    this.hasSelectedDocument      = false,
    this.hasAwaitingApprovalPlan  = false,
    this.hasApprovedPlan          = false,
    this.canGenerateQuestions     = false,
  });

  factory StudioReadiness.fromJson(Map<String, dynamic> j) => StudioReadiness(
        hasJobDescription:       _v(j, 'hasJobDescription',       'HasJobDescription')       as bool? ?? false,
        hasSelectedDocument:     _v(j, 'hasSelectedDocument',     'HasSelectedDocument')     as bool? ?? false,
        hasAwaitingApprovalPlan: _v(j, 'hasAwaitingApprovalPlan', 'HasAwaitingApprovalPlan') as bool? ?? false,
        hasApprovedPlan:         _v(j, 'hasApprovedPlan',         'HasApprovedPlan')         as bool? ?? false,
        canGenerateQuestions:    _v(j, 'canGenerateQuestions',    'CanGenerateQuestions')    as bool? ?? false,
      );
}

/// Normalise `language` / `outputLanguage` → "Vietnamese" | "English"
String _normaliseOutputLanguage(String? raw) {
  if (raw == null || raw.isEmpty) return 'Vietnamese';
  final lower = raw.toLowerCase();
  if (lower.contains('viet')) return 'Vietnamese';
  if (RegExp(r'en(glish)?').hasMatch(lower)) return 'English';
  return 'Vietnamese';
}

class StudioSettings {
  final String projectId;
  final String? appliedPlanId;
  final int interviewLengthMinutes;
  final int numberOfQuestions;
  final StudioQuestionDifficulty difficulty;
  final String questionTone;
  final bool includeSampleAnswers;
  final bool includeScoringRubric;
  final String outputFormat;
  final String outputLanguage;
  final List<String> questionTypes;
  final String contentMode;
  final List<String> enabledCodeTemplates;
  final StudioReadiness readiness;

  const StudioSettings({
    required this.projectId,
    this.appliedPlanId,
    required this.interviewLengthMinutes,
    required this.numberOfQuestions,
    required this.difficulty,
    required this.questionTone,
    required this.includeSampleAnswers,
    required this.includeScoringRubric,
    required this.outputFormat,
    required this.outputLanguage,
    required this.questionTypes,
    required this.contentMode,
    required this.enabledCodeTemplates,
    required this.readiness,
  });

  // Spec §7.3 — normalise + clamp every field
  factory StudioSettings.fromJson(Map<String, dynamic> j) {
    int len = (_v(j, 'interviewLengthMinutes', 'InterviewLengthMinutes') as num? ?? 60).toInt();
    if (len < 15 || len > 180) len = 60;
    int nq  = (_v(j, 'numberOfQuestions', 'NumberOfQuestions') as num? ?? 15).toInt();
    if (nq < 5 || nq > 50) nq = 15;

    final rawLang = _v(j, 'outputLanguage', 'OutputLanguage')?.toString()
                 ?? _v(j, 'language',       'Language')?.toString();

    List<String> qt = _list(
      _v(j, 'questionTypes', 'QuestionTypes'),
      (e) => e?.toString() ?? '',
    ).where((s) => s.isNotEmpty).toList();
    if (qt.isEmpty) qt = ['technical', 'system_design', 'problem_solving', 'behavioral'];

    List<String> ct = _list(
      _v(j, 'enabledCodeTemplates', 'EnabledCodeTemplates'),
      (e) => e?.toString() ?? '',
    ).where((s) => s.isNotEmpty).toList();
    if (ct.isEmpty) ct = ['BUG_DETECTION', 'CODE_COMPLETION', 'REFACTORING', 'PERFORMANCE_ANALYSIS'];

    final rawReadiness = _v(j, 'readiness', 'Readiness');
    return StudioSettings(
      projectId:             (_v(j, 'projectId', 'ProjectId') ?? '').toString(),
      appliedPlanId:         _v(j, 'appliedPlanId', 'AppliedPlanId')?.toString(),
      interviewLengthMinutes: len,
      numberOfQuestions:     nq,
      difficulty:            StudioQuestionDifficulty.fromString(
                                 (_v(j, 'difficulty', 'Difficulty') ?? 'Medium').toString()),
      questionTone:          (_v(j, 'questionTone', 'QuestionTone') ?? 'Professional').toString(),
      includeSampleAnswers:  _v(j, 'includeSampleAnswers', 'IncludeSampleAnswers') as bool? ?? true,
      includeScoringRubric:  _v(j, 'includeScoringRubric', 'IncludeScoringRubric') as bool? ?? true,
      outputFormat:          (_v(j, 'outputFormat', 'OutputFormat') ?? 'StructuredInterviewKit').toString(),
      outputLanguage:        _normaliseOutputLanguage(rawLang),
      questionTypes:         qt,
      contentMode:           (_v(j, 'contentMode', 'ContentMode') ?? 'Mixed').toString(),
      enabledCodeTemplates:  ct,
      readiness: rawReadiness is Map<String, dynamic>
          ? StudioReadiness.fromJson(rawReadiness)
          : const StudioReadiness(),
    );
  }
}

// ── 10.6 Question ─────────────────────────────────────────────────────────────

class StudioQuestion {
  final String id;
  final String content;  // NOTE: "content", not "question"
  final StudioQuestionDifficulty difficulty;
  final StudioQuestionType type;
  final int orderIndex;
  final String? expectedAnswer;
  final String? scoringRubric;
  final String? codeTemplateType;
  final String? codeSnippet;
  final String? imageHint;
  final String? attachedImageUrl;
  final String? answerMethod;
  bool isEdited;

  StudioQuestion({
    required this.id,
    required this.content,
    required this.difficulty,
    required this.type,
    required this.orderIndex,
    this.expectedAnswer,
    this.scoringRubric,
    this.codeTemplateType,
    this.codeSnippet,
    this.imageHint,
    this.attachedImageUrl,
    this.answerMethod,
    this.isEdited = false,
  });

  factory StudioQuestion.fromJson(Map<String, dynamic> j) => StudioQuestion(
        id:             (_v(j, 'id',      'Id')      ?? '').toString(),
        content:        (_v(j, 'content', 'Content') ??
                         _v(j, 'question', 'Question') ?? '').toString(),
        difficulty:     StudioQuestionDifficulty.fromString(
                            (_v(j, 'difficulty', 'Difficulty') ?? '').toString()),
        type:           StudioQuestionType.fromString(
                            (_v(j, 'type', 'Type') ?? '').toString()),
        orderIndex:     ((_v(j, 'orderIndex', 'OrderIndex') ?? 0) as num).toInt(),
        expectedAnswer: _v(j, 'expectedAnswer', 'ExpectedAnswer')?.toString(),
        scoringRubric:  _v(j, 'scoringRubric',  'ScoringRubric')?.toString(),
        codeTemplateType: (_v(j, 'codeTemplateType', 'CodeTemplateType') ??
                           _v(j, 'code_template_type'))?.toString(),
        codeSnippet:    (_v(j, 'codeSnippet', 'CodeSnippet') ??
                         _v(j, 'code_snippet'))?.toString(),
        imageHint:      (_v(j, 'imageHint', 'ImageHint') ??
                         _v(j, 'image_hint'))?.toString(),
        attachedImageUrl: (_v(j, 'attachedImageUrl', 'AttachedImageUrl') ??
                           _v(j, 'attached_image_url'))?.toString(),
        answerMethod:   _v(j, 'answerMethod', 'AnswerMethod')?.toString(),
      );

  Map<String, dynamic> toUpdateJson() => {
        'content':           content,
        'difficulty':        difficulty.toApiString(),
        'type':              type.toApiString(),
        'estimatedMinutes':  5, // hardcoded per spec §7.10
        if (expectedAnswer != null) 'expectedAnswer':  expectedAnswer,
        if (scoringRubric  != null) 'scoringRubric':   scoringRubric,
      };

  StudioQuestion copyWith({
    String? content,
    StudioQuestionDifficulty? difficulty,
    StudioQuestionType? type,
    int? orderIndex,
    String? expectedAnswer,
    String? scoringRubric,
    bool? isEdited,
  }) => StudioQuestion(
        id:              id,
        content:         content ?? this.content,
        difficulty:      difficulty ?? this.difficulty,
        type:            type ?? this.type,
        orderIndex:      orderIndex ?? this.orderIndex,
        expectedAnswer:  expectedAnswer ?? this.expectedAnswer,
        scoringRubric:   scoringRubric  ?? this.scoringRubric,
        codeTemplateType: codeTemplateType,
        codeSnippet:     codeSnippet,
        imageHint:       imageHint,
        attachedImageUrl: attachedImageUrl,
        answerMethod:    answerMethod,
        isEdited:        isEdited ?? this.isEdited,
      );
}

// ── 10.6 Generation Run ───────────────────────────────────────────────────────

enum GenerationRunStatus {
  pending, generating, completed, failed, cancelled;

  static GenerationRunStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'generating': return GenerationRunStatus.generating;
      case 'completed':  return GenerationRunStatus.completed;
      case 'failed':     return GenerationRunStatus.failed;
      case 'cancelled':  return GenerationRunStatus.cancelled;
      default:           return GenerationRunStatus.pending;
    }
  }

  bool get isTerminal =>
      this == completed || this == failed || this == cancelled;
  bool get isRunning  =>
      this == pending   || this == generating;
}

class StudioGenerationRun {
  final String id;
  final String planId;
  final GenerationRunStatus status;
  final int requestedQuestionCount;
  final int generatedQuestionCount;
  final String startedAt;
  final String? completedAt;
  final String? errorCode;
  final String? errorMessage;

  const StudioGenerationRun({
    required this.id,
    required this.planId,
    required this.status,
    required this.requestedQuestionCount,
    required this.generatedQuestionCount,
    required this.startedAt,
    this.completedAt,
    this.errorCode,
    this.errorMessage,
  });

  factory StudioGenerationRun.fromJson(Map<String, dynamic> j) =>
      StudioGenerationRun(
        id:                     (_v(j, 'id',          'Id')          ?? '').toString(),
        planId:                 (_v(j, 'planId',      'PlanId')      ?? '').toString(),
        status:                 GenerationRunStatus.fromString(
                                    (_v(j, 'status', 'Status') ?? '').toString()),
        requestedQuestionCount: ((_v(j, 'requestedQuestionCount', 'RequestedQuestionCount') ?? 0) as num).toInt(),
        generatedQuestionCount: ((_v(j, 'generatedQuestionCount', 'GeneratedQuestionCount') ?? 0) as num).toInt(),
        startedAt:              (_v(j, 'startedAt',   'StartedAt')   ?? '').toString(),
        completedAt:            _v(j, 'completedAt',  'CompletedAt')?.toString(),
        errorCode:              _v(j, 'errorCode',    'ErrorCode')?.toString(),
        errorMessage:           _v(j, 'errorMessage', 'ErrorMessage')?.toString(),
      );
}

// ── Response unwrap helper (spec §9.11 §3) ────────────────────────────────────

List<Map<String, dynamic>> unwrapList(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().toList();
  }
  if (raw is Map<String, dynamic>) {
    // Direct items field: { page, pageSize, total, items: [...] }
    final directItems = raw['items'] ?? raw['Items'];
    if (directItems is List) {
      return directItems.whereType<Map<String, dynamic>>().toList();
    }
    // Wrapped in data: { data: [...] } or { data: { items: [...] } }
    final inner = raw['data'] ?? raw['Data'];
    if (inner is List) return inner.whereType<Map<String, dynamic>>().toList();
    if (inner is Map<String, dynamic>) {
      final items = inner['items'] ?? inner['Items'];
      if (items is List) return items.whereType<Map<String, dynamic>>().toList();
    }
  }
  return [];
}

Map<String, dynamic>? unwrapObject(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    final data = raw['data'] ?? raw['Data'];
    if (data is Map<String, dynamic>) return data;
    // No data wrapper — return the object itself (backend returns flat object)
    return raw;
  }
  return null;
}

// ── 10.3 Studio Document (spec §10.3) ─────────────────────────────────────────

/// Status values for studio documents — distinct from KnowledgeDocument status.
enum StudioDocumentStatus {
  pending, processing, completed, failed;

  static StudioDocumentStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'processing': return StudioDocumentStatus.processing;
      case 'completed':  return StudioDocumentStatus.completed;
      case 'failed':     return StudioDocumentStatus.failed;
      default:           return StudioDocumentStatus.pending;
    }
  }

  String get displayLabel {
    switch (this) {
      case StudioDocumentStatus.pending:    return 'Đang chờ';
      case StudioDocumentStatus.processing: return 'Đang xử lý';
      case StudioDocumentStatus.completed:  return 'Hoàn thành';
      case StudioDocumentStatus.failed:     return 'Thất bại';
    }
  }

  bool get isProcessing => this == pending || this == processing;
}

class StudioDocument {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final bool isSelected;
  final StudioDocumentStatus status;
  final String? previewText;
  final String? knowledgeDocumentId;
  final String? ragStatus;
  final int? chunkCount;
  final String? processingError;
  final bool isLibraryLink;

  const StudioDocument({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.isSelected,
    required this.status,
    this.previewText,
    this.knowledgeDocumentId,
    this.ragStatus,
    this.chunkCount,
    this.processingError,
    this.isLibraryLink = false,
  });

  factory StudioDocument.fromJson(Map<String, dynamic> j) => StudioDocument(
        id:                  (_v(j, 'id',                  'Id')                  ?? '').toString(),
        fileName:            (_v(j, 'fileName',            'FileName')            ?? '').toString(),
        fileType:            (_v(j, 'fileType',            'FileType')            ?? '').toString(),
        fileSize:            ((_v(j, 'fileSize',           'FileSize')            ?? 0) as num).toInt(),
        isSelected:          _v(j, 'isSelected',           'IsSelected')           as bool? ?? false,
        status:              StudioDocumentStatus.fromString(
                                 (_v(j, 'status', 'Status') ?? '').toString()),
        previewText:         _v(j, 'previewText',          'PreviewText')?.toString(),
        knowledgeDocumentId: _v(j, 'knowledgeDocumentId',  'KnowledgeDocumentId')?.toString(),
        ragStatus:           _v(j, 'ragStatus',            'RagStatus')?.toString(),
        chunkCount:          (_v(j, 'chunkCount',          'ChunkCount') as num?)?.toInt(),
        processingError:     _v(j, 'processingError',      'ProcessingError')?.toString(),
        isLibraryLink:       _v(j, 'isLibraryLink',        'IsLibraryLink')        as bool? ?? false,
      );

  StudioDocument copyWith({bool? isSelected, StudioDocumentStatus? status}) =>
      StudioDocument(
        id:                  id,
        fileName:            fileName,
        fileType:            fileType,
        fileSize:            fileSize,
        isSelected:          isSelected ?? this.isSelected,
        status:              status     ?? this.status,
        previewText:         previewText,
        knowledgeDocumentId: knowledgeDocumentId,
        ragStatus:           ragStatus,
        chunkCount:          chunkCount,
        processingError:     processingError,
        isLibraryLink:       isLibraryLink,
      );
}

class StudioLibraryDocument {
  final String knowledgeDocumentId;
  final String fileName;
  final String status;
  final int? chunkCount;
  final String createdAt;
  final bool alreadyAttached;

  const StudioLibraryDocument({
    required this.knowledgeDocumentId,
    required this.fileName,
    required this.status,
    this.chunkCount,
    required this.createdAt,
    this.alreadyAttached = false,
  });

  factory StudioLibraryDocument.fromJson(Map<String, dynamic> j) =>
      StudioLibraryDocument(
        knowledgeDocumentId: (_v(j, 'knowledgeDocumentId', 'KnowledgeDocumentId') ?? '').toString(),
        fileName:            (_v(j, 'fileName',            'FileName')            ?? '').toString(),
        status:              (_v(j, 'status',              'Status')              ?? '').toString(),
        chunkCount:          (_v(j, 'chunkCount',          'ChunkCount') as num?)?.toInt(),
        createdAt:           (_v(j, 'createdAt',           'CreatedAt')           ?? '').toString(),
        alreadyAttached:     _v(j, 'alreadyAttached',      'AlreadyAttached')      as bool? ?? false,
      );
}

// ── 10.6 Chat Message (spec §10.6) ────────────────────────────────────────────

enum ChatMessageRole { user, assistant, system;
  static ChatMessageRole fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'assistant': return ChatMessageRole.assistant;
      case 'system':    return ChatMessageRole.system;
      default:          return ChatMessageRole.user;
    }
  }
}

enum ChatMessageStatus {
  pending, streaming, completed, failed, cancelled;
  static ChatMessageStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'streaming':  return ChatMessageStatus.streaming;
      case 'completed':  return ChatMessageStatus.completed;
      case 'failed':     return ChatMessageStatus.failed;
      case 'cancelled':  return ChatMessageStatus.cancelled;
      default:           return ChatMessageStatus.pending;
    }
  }
}

class StudioChatMessage {
  final String id;
  final String sessionId;
  final ChatMessageRole role;
  final String content;
  final ChatMessageStatus status;
  final String createdAt;

  const StudioChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory StudioChatMessage.fromJson(Map<String, dynamic> j) =>
      StudioChatMessage(
        id:        (_v(j, 'id',        'Id')        ?? '').toString(),
        sessionId: (_v(j, 'sessionId', 'SessionId') ?? '').toString(),
        role:      ChatMessageRole.fromString((_v(j, 'role', 'Role') ?? '').toString()),
        content:   (_v(j, 'content',   'Content')   ?? '').toString(),
        status:    ChatMessageStatus.fromString((_v(j, 'status', 'Status') ?? '').toString()),
        createdAt: (_v(j, 'createdAt', 'CreatedAt') ?? '').toString(),
      );

  bool get isStreaming => status == ChatMessageStatus.streaming || status == ChatMessageStatus.pending;
  bool get isUser      => role   == ChatMessageRole.user;

  /// Create a temporary streaming placeholder message (assistant)
  factory StudioChatMessage.streamingPlaceholder({required String text}) =>
      StudioChatMessage(
        id:        'tmp_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: '',
        role:      ChatMessageRole.assistant,
        content:   text,
        status:    ChatMessageStatus.streaming,
        createdAt: DateTime.now().toIso8601String(),
      );
}

// ── Storage key constants ─────────────────────────────────────────────────────

class StudioStorage {
  static const kActiveProjectId = 'studio_active_project_id';
  static const kActiveTask      = 'studio_active_task';
  static const kView            = 'studio_gen_view';
  static const kPollingPhase    = 'studio_gen_polling_phase';
  static const kProjectId       = 'studio_gen_project_id';
  static const kPlanId          = 'studio_gen_plan_id';
  static const kRunId           = 'studio_gen_run_id';

  static Map<String, dynamic>? decodeTask(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }
}
