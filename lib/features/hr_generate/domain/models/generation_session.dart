import '../enums/generation_status.dart';
import 'generated_question.dart';
import 'plan_draft.dart';

class GenerationSession {
  final String id;
  final String jobTitle;
  final String? jdContent;
  final GenerationStatus status;
  final PlanDraft? planDraft;
  final List<GeneratedQuestion> generatedQuestions;
  final String? failureMessage;
  final String createdAt;
  final String? updatedAt;
  // BE-driven UI guidance
  final String? suggestedAction;
  final bool isPolling;
  final String? statusLabel;
  final bool hasDraft;
  final String? questionSetId;
  final bool canRetryPlan;
  final bool canRetryQuestions;
  final bool canEditInput;
  final bool canApprovePlan;
  final bool canSaveDraft;

  const GenerationSession({
    required this.id,
    required this.jobTitle,
    this.jdContent,
    required this.status,
    this.planDraft,
    this.generatedQuestions = const [],
    this.failureMessage,
    required this.createdAt,
    this.updatedAt,
    this.suggestedAction,
    this.isPolling = false,
    this.statusLabel,
    this.hasDraft = false,
    this.questionSetId,
    this.canRetryPlan = false,
    this.canRetryQuestions = false,
    this.canEditInput = false,
    this.canApprovePlan = false,
    this.canSaveDraft = false,
  });

  factory GenerationSession.fromJson(Map<String, dynamic> raw) {
    final j = _unwrap(raw);

    final id = (j['jobId'] ?? j['id'] ?? j['job_id'] ?? '').toString();
    final jdContent = j['jobDescription']?.toString();

    // Status / phase
    final rawPhase = (j['phase'] ?? j['status'] ?? '').toString();
    final status   = GenerationStatus.fromPhase(rawPhase);

    // Plan
    PlanDraft? planDraft;
    final rawPlan = j['plan'] as Map<String, dynamic>?;
    if (rawPlan != null) {
      planDraft = PlanDraft.fromJson(rawPlan);
    }

    // Questions from body (may also come from separate endpoint)
    final rawQs = j['questions'] as List?;
    final questions = rawQs != null
        ? rawQs
            .whereType<Map<String, dynamic>>()
            .map(GeneratedQuestion.fromJson)
            .toList()
        : <GeneratedQuestion>[];
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // UI block
    final ui      = j['ui'] as Map<String, dynamic>?;
    final isPolling     = ui?['isPolling'] as bool? ?? false;
    final statusLabel   = ui?['statusLabel']?.toString();
    final suggestedAction = ui?['suggestedAction']?.toString();
    final actions = ui?['actions'] as Map<String, dynamic>?;

    // Meta block
    final meta    = j['meta'] as Map<String, dynamic>?;
    final hasDraft = meta?['hasDraft'] as bool? ?? false;
    final questionSetId = meta?['questionSetId']?.toString();

    // Failure
    final failure = j['failure'] as Map<String, dynamic>?;
    final failureMessage = failure != null
        ? (failure['reason'] ?? failure['detail'])?.toString()
        : j['failureMessage']?.toString();

    return GenerationSession(
      id:                id,
      jobTitle:          planDraft?.role ?? jdContent?.split('\n').first ?? '',
      jdContent:         jdContent,
      status:            status,
      planDraft:         planDraft,
      generatedQuestions: questions,
      failureMessage:    failureMessage,
      createdAt:         j['createdAt']?.toString() ?? '',
      updatedAt:         j['updatedAt']?.toString(),
      suggestedAction:   suggestedAction,
      isPolling:         isPolling,
      statusLabel:       statusLabel,
      hasDraft:          hasDraft,
      questionSetId:     questionSetId,
      canRetryPlan:      actions?['canRetryPlan'] as bool? ?? false,
      canRetryQuestions: actions?['canRetryQuestions'] as bool? ?? false,
      canEditInput:      actions?['canEditInput'] as bool? ?? false,
      canApprovePlan:    actions?['canApprovePlan'] as bool? ?? false,
      canSaveDraft:      actions?['canSaveDraft'] as bool? ?? false,
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
