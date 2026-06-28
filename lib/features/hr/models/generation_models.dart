// Models for the HR Interview Question Generation flow.

enum QuestionType {
  technical,
  behavioral,
  situational,
  systemDesign,
  problemSolving;

  static QuestionType fromString(String s) {
    final k = s.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    switch (k) {
      case 'technical':      return QuestionType.technical;
      case 'behavioral':     return QuestionType.behavioral;
      case 'situational':    return QuestionType.situational;
      case 'systemdesign':   return QuestionType.systemDesign;
      case 'problemsolving': return QuestionType.problemSolving;
      default:               return QuestionType.technical;
    }
  }

  String toApiString() {
    switch (this) {
      case QuestionType.technical:      return 'technical';
      case QuestionType.behavioral:     return 'behavioral';
      case QuestionType.situational:    return 'situational';
      case QuestionType.systemDesign:   return 'system-design';
      case QuestionType.problemSolving: return 'problem-solving';
    }
  }

  String get displayName {
    switch (this) {
      case QuestionType.technical:      return 'Technical';
      case QuestionType.behavioral:     return 'Behavioral';
      case QuestionType.situational:    return 'Situational';
      case QuestionType.systemDesign:   return 'System Design';
      case QuestionType.problemSolving: return 'Problem Solving';
    }
  }
}

enum DifficultyLevel {
  easy, medium, hard;

  static DifficultyLevel fromString(String s) {
    switch (s.toLowerCase().trim()) {
      case 'easy':   return DifficultyLevel.easy;
      case 'hard':   return DifficultyLevel.hard;
      default:       return DifficultyLevel.medium;
    }
  }

  String get displayName =>
      '${name[0].toUpperCase()}${name.substring(1)}';

  String toApiString() => name.toLowerCase();
}

enum ExperienceLevel {
  intern, junior, midLevel, senior, lead, manager;

  static ExperienceLevel fromString(String s) {
    final k = s.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    switch (k) {
      case 'intern':          return ExperienceLevel.intern;
      case 'junior':          return ExperienceLevel.junior;
      case 'mid':
      case 'midlevel':
      case 'medium':
      case 'middle':          return ExperienceLevel.midLevel;
      case 'senior':          return ExperienceLevel.senior;
      case 'lead':            return ExperienceLevel.lead;
      case 'manager':         return ExperienceLevel.manager;
      default:                return ExperienceLevel.junior;
    }
  }

  String get displayName {
    switch (this) {
      case ExperienceLevel.intern:   return 'Intern';
      case ExperienceLevel.junior:   return 'Junior';
      case ExperienceLevel.midLevel: return 'Mid-level';
      case ExperienceLevel.senior:   return 'Senior';
      case ExperienceLevel.lead:     return 'Lead';
      case ExperienceLevel.manager:  return 'Manager';
    }
  }

  // Sent to BE lowercase, no dash ("mid-level" → "mid")
  String toApiString() {
    if (this == ExperienceLevel.midLevel) return 'mid';
    return name.toLowerCase();
  }
}

enum GenerationFlowState {
  form,
  pollingPlan,
  planReview,
  pollingQuestions,
  questionReview,
  failed,
}

// ─── Plan draft ───────────────────────────────────────────────────────────────

class PlanDraft {
  final String role;
  final ExperienceLevel experienceLevel;
  final DifficultyLevel difficulty;
  final int questionCount;
  final List<QuestionType> questionTypes;
  final List<String> topics;
  final String? constraints;
  final String? summary;

  const PlanDraft({
    required this.role,
    required this.experienceLevel,
    required this.difficulty,
    required this.questionCount,
    required this.questionTypes,
    this.topics = const [],
    this.constraints,
    this.summary,
  });

  factory PlanDraft.fromJson(Map<String, dynamic> j) {
    final role = (j['roleTitle'] ?? j['role'] ?? '').toString();

    final rawExp = (j['experienceLevel'] ?? j['experience_level'] ?? 'junior').toString();
    final experienceLevel = ExperienceLevel.fromString(rawExp);

    // difficulty field; distinguish from experience-level strings
    final rawDiff = (j['difficulty'] ?? 'medium').toString();
    final difficulty = DifficultyLevel.fromString(rawDiff);

    final questionCount =
        ((j['totalQuestions'] ?? j['numberOfQuestions'] ?? j['questionCount'] ?? 10) as num)
            .toInt();

    final rawTypes = j['questionTypes'] ?? j['question_types'] ?? <dynamic>[];
    final questionTypes = (rawTypes is List)
        ? rawTypes.map((e) => QuestionType.fromString(e.toString())).toList()
        : <QuestionType>[];

    final rawTopics = j['skills'] ?? j['topics'] ?? j['suggestedTopics'] ?? <dynamic>[];
    final topics = (rawTopics is List)
        ? rawTopics.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final constraints = j['constraints']?.toString() ?? j['notes']?.toString();
    final summary = j['summary']?.toString() ?? j['aiInsight']?.toString();

    return PlanDraft(
      role:            role,
      experienceLevel: experienceLevel,
      difficulty:      difficulty,
      questionCount:   questionCount,
      questionTypes:   questionTypes.isEmpty
          ? [QuestionType.technical, QuestionType.behavioral]
          : questionTypes,
      topics:          topics,
      constraints:     constraints,
      summary:         summary,
    );
  }

  PlanDraft copyWith({
    String? role,
    ExperienceLevel? experienceLevel,
    DifficultyLevel? difficulty,
    int? questionCount,
    List<QuestionType>? questionTypes,
    List<String>? topics,
    String? constraints,
    String? summary,
  }) =>
      PlanDraft(
        role:            role ?? this.role,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        difficulty:      difficulty ?? this.difficulty,
        questionCount:   questionCount ?? this.questionCount,
        questionTypes:   questionTypes ?? this.questionTypes,
        topics:          topics ?? this.topics,
        constraints:     constraints ?? this.constraints,
        summary:         summary ?? this.summary,
      );

  Map<String, dynamic> toPutJson() => {
        'roleTitle':       role,
        'totalQuestions':  questionCount,
        'questionTypes':   questionTypes.map((t) => t.toApiString()).toList(),
        'skills':          topics,
        'notes':           constraints ?? '',
        'level':           difficulty.toApiString(),
        'experienceLevel': experienceLevel.toApiString(),
      };
}

// ─── Generated question ───────────────────────────────────────────────────────

class GeneratedQuestion {
  final String id;
  final String question;
  final QuestionType questionType;
  final DifficultyLevel difficulty;
  final String? rationale;
  final String? sampleAnswer;
  final List<String> citations;
  final int orderIndex;

  const GeneratedQuestion({
    required this.id,
    required this.question,
    required this.questionType,
    required this.difficulty,
    this.rationale,
    this.sampleAnswer,
    this.citations = const [],
    this.orderIndex = 0,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> j) {
    final rawCitations = j['citations'] ?? j['sources'] ?? <dynamic>[];
    final citations = (rawCitations is List)
        ? rawCitations.map((e) => e.toString()).toList()
        : <String>[];

    return GeneratedQuestion(
      id:           (j['id'] ?? '').toString(),
      question:     (j['question'] ?? j['content'] ?? '').toString(),
      questionType: QuestionType.fromString(
          (j['questionType'] ?? j['type'] ?? 'technical').toString()),
      difficulty:   DifficultyLevel.fromString(
          (j['difficulty'] ?? j['level'] ?? 'medium').toString()),
      rationale:    j['rationale']?.toString() ?? j['reasoning']?.toString(),
      sampleAnswer: j['sampleAnswer']?.toString() ??
          j['expectedAnswer']?.toString() ??
          j['sample_answer']?.toString(),
      citations:    citations,
      orderIndex:   ((j['orderIndex'] ?? j['order'] ?? 0) as num).toInt(),
    );
  }
}

// ─── Generation job ───────────────────────────────────────────────────────────

class GenerationJob {
  final String id;
  final String rawStatus;
  final PlanDraft? planDraft;
  final List<GeneratedQuestion> questions;
  final bool isPolling;
  final String? suggestedAction;
  final String? statusLabel;
  final String? failureMessage;
  final bool canRetryPlan;
  final bool canRetryQuestions;
  final bool canEditInput;

  const GenerationJob({
    required this.id,
    required this.rawStatus,
    this.planDraft,
    this.questions = const [],
    this.isPolling = false,
    this.suggestedAction,
    this.statusLabel,
    this.failureMessage,
    this.canRetryPlan = false,
    this.canRetryQuestions = false,
    this.canEditInput = false,
  });

  bool get isPlanPhase {
    final s = rawStatus.toUpperCase();
    return s.contains('PLAN') || s == 'QUEUED' || s == 'SUBMITTED' || s == 'PENDING';
  }

  factory GenerationJob.fromJson(Map<String, dynamic> raw) {
    final j = _unwrap(raw);

    final id = (j['jobId'] ?? j['id'] ?? j['job_id'] ??
            j['generationJobId'] ?? j['sessionId'] ?? '')
        .toString();

    final rawStatus = (j['phase'] ?? j['status'] ?? '').toString();

    final ui = j['ui'] as Map<String, dynamic>?;
    final isPolling      = ui?['isPolling'] as bool? ?? false;
    final suggestedAction = ui?['suggestedAction']?.toString();
    final statusLabel    = ui?['statusLabel']?.toString();

    final failure = j['failure'] as Map<String, dynamic>?;
    final failureMessage = failure != null
        ? (failure['reason'] ?? failure['detail'] ?? failure['message'])?.toString()
        : (j['failureMessage'] ?? j['errorMessage'])?.toString();

    PlanDraft? planDraft;
    final rawPlan = j['plan'] ?? j['planDraft'] ?? j['plan_draft'];
    if (rawPlan is Map<String, dynamic>) {
      final merged = <String, dynamic>{...rawPlan};
      final summary = j['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        if (!merged.containsKey('roleTitle') && summary.containsKey('role')) {
          merged['roleTitle'] = summary['role'];
        }
        merged['summary'] = summary['insight'] ?? summary['text'] ?? summary['content'];
      }
      planDraft = PlanDraft.fromJson(merged);
    }

    final rawQs = j['questions'];
    final questions = rawQs is List
        ? rawQs
            .whereType<Map<String, dynamic>>()
            .map(GeneratedQuestion.fromJson)
            .toList()
        : <GeneratedQuestion>[];

    final caps = j['capabilities'] as Map<String, dynamic>?;

    return GenerationJob(
      id:                id,
      rawStatus:         rawStatus,
      planDraft:         planDraft,
      questions:         questions,
      isPolling:         isPolling,
      suggestedAction:   suggestedAction,
      statusLabel:       statusLabel,
      failureMessage:    failureMessage,
      canRetryPlan:      caps?['canRetryPlan'] as bool? ?? false,
      canRetryQuestions: caps?['canRetryQuestions'] as bool? ?? false,
      canEditInput:      caps?['canEditInput'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      if (raw['result'] is Map<String, dynamic>) return raw['result'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }
}

// ─── Form input ───────────────────────────────────────────────────────────────

class GenerationFormInput {
  final String jobDescription;
  final String? hrNote;
  final int numberOfQuestions;
  final DifficultyLevel difficulty;
  final List<QuestionType> questionTypes;
  final List<String> skills;

  const GenerationFormInput({
    required this.jobDescription,
    this.hrNote,
    this.numberOfQuestions = 10,
    this.difficulty = DifficultyLevel.medium,
    this.questionTypes = const [
      QuestionType.technical,
      QuestionType.behavioral
    ],
    this.skills = const [],
  });

  Map<String, dynamic> toJson() => {
        'jobDescription':    jobDescription,
        if (hrNote != null && hrNote!.isNotEmpty) 'hrNote': hrNote,
        'numberOfQuestions': numberOfQuestions,
        'difficulty':        difficulty.toApiString(),
        'questionTypes':     questionTypes.map((t) => t.toApiString()).toList(),
        if (skills.isNotEmpty) 'skills': skills,
      };
}
