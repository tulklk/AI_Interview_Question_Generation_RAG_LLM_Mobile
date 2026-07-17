class QuestionSuggestion {
  final String question;
  final String? rationale;
  final String? sampleAnswer;
  final String? difficulty;
  final String? questionType;

  const QuestionSuggestion({
    required this.question,
    this.rationale,
    this.sampleAnswer,
    this.difficulty,
    this.questionType,
  });

  factory QuestionSuggestion.fromJson(Map<String, dynamic> j) =>
      QuestionSuggestion(
        question:     (j['question'] ?? '').toString(),
        rationale:    j['rationale']?.toString(),
        sampleAnswer: j['sampleAnswer']?.toString(),
        difficulty:   j['difficulty']?.toString(),
        questionType: j['questionType']?.toString(),
      );
}
