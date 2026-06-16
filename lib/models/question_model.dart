enum QuestionDifficulty { easy, medium, hard }
enum QuestionType { technical, behavioral, cultureFit, mixed }

class QuestionModel {
  final String id;
  final String question;
  final String expectedAnswer;
  final String skillTested;
  final QuestionDifficulty difficulty;
  final QuestionType type;
  final String? scoreRubric;
  final String? kitId;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.expectedAnswer,
    required this.skillTested,
    required this.difficulty,
    required this.type,
    this.scoreRubric,
    this.kitId,
  });
}

class InterviewKit {
  final String id;
  final String name;
  final String jobId;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final QuestionType type;

  const InterviewKit({
    required this.id,
    required this.name,
    required this.jobId,
    required this.questions,
    required this.createdAt,
    required this.type,
  });
}
