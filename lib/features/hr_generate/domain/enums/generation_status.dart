enum GenerationStatus {
  draft,
  planQueued,
  planProposed,
  confirmed,
  queued,
  questionQueued,
  questionProcessing,
  processing,
  completed,
  failed;

  static GenerationStatus fromPhase(String? raw) {
    if (raw == null || raw.isEmpty) return GenerationStatus.draft;
    final p = raw.toUpperCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    switch (p) {
      case 'COMPLETED':            return GenerationStatus.completed;
      case 'FAILED':               return GenerationStatus.failed;
      case 'PLAN_QUEUED':          return GenerationStatus.planQueued;
      case 'PLAN_PROCESSING':
      case 'WAITING_HR_APPROVAL':  return GenerationStatus.planProposed;
      case 'QUESTION_QUEUED':      return GenerationStatus.questionQueued;
      case 'QUESTION_PROCESSING':  return GenerationStatus.questionProcessing;
      case 'PROCESSING':           return GenerationStatus.processing;
      case 'QUEUED':               return GenerationStatus.queued;
      case 'CONFIRMED':            return GenerationStatus.confirmed;
      default:
        if (p.contains('PLAN'))    return GenerationStatus.planProposed;
        return GenerationStatus.draft;
    }
  }

  bool get isPlanPhase => const {
    GenerationStatus.planQueued,
    GenerationStatus.planProposed,
    GenerationStatus.queued,
  }.contains(this);

  bool get isQuestionPhase => const {
    GenerationStatus.confirmed,
    GenerationStatus.questionQueued,
    GenerationStatus.questionProcessing,
    GenerationStatus.processing,
  }.contains(this);

  bool get isTerminal =>
      this == GenerationStatus.completed || this == GenerationStatus.failed;
}
