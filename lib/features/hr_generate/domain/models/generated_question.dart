import '../enums/difficulty_level.dart';
import '../enums/question_type.dart';

class GeneratedQuestion {
  final String id;
  final String question;
  final HrQuestionType questionType;
  final HrDifficultyLevel difficulty;
  final String? rationale;
  final String? sampleAnswer;
  final int orderIndex;
  bool isEdited;

  GeneratedQuestion({
    required this.id,
    required this.question,
    required this.questionType,
    required this.difficulty,
    this.rationale,
    this.sampleAnswer,
    this.orderIndex = 0,
    this.isEdited = false,
  });

  factory GeneratedQuestion.fromJson(Map<String, dynamic> j) =>
      GeneratedQuestion(
        id:           (j['id'] ?? '').toString(),
        question:     (j['question'] ?? j['content'] ?? '').toString(),
        questionType: HrQuestionType.fromString(
            (j['questionType'] ?? j['type'] ?? 'technical').toString()),
        difficulty:   HrDifficultyLevel.fromString(
            (j['difficulty'] ?? j['level'] ?? 'medium').toString()),
        rationale:    j['rationale']?.toString() ?? j['reasoning']?.toString(),
        sampleAnswer: j['sampleAnswer']?.toString() ??
            j['expectedAnswer']?.toString() ??
            j['sample_answer']?.toString(),
        orderIndex: ((j['orderIndex'] ?? j['order'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toUpdateJson() => {
        'question':     question,
        'questionType': questionType.toApiString(),
        'difficulty':   difficulty.toApiString(),
        if (rationale != null) 'rationale':    rationale,
        if (sampleAnswer != null) 'sampleAnswer': sampleAnswer,
      };

  GeneratedQuestion copyWith({
    String? question,
    HrQuestionType? questionType,
    HrDifficultyLevel? difficulty,
    String? rationale,
    String? sampleAnswer,
    int? orderIndex,
    bool? isEdited,
  }) =>
      GeneratedQuestion(
        id:           id,
        question:     question ?? this.question,
        questionType: questionType ?? this.questionType,
        difficulty:   difficulty ?? this.difficulty,
        rationale:    rationale ?? this.rationale,
        sampleAnswer: sampleAnswer ?? this.sampleAnswer,
        orderIndex:   orderIndex ?? this.orderIndex,
        isEdited:     isEdited ?? this.isEdited,
      );
}
