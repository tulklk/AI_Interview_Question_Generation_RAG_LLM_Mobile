enum InterviewStatus { scheduled, completed, cancelled, rescheduled }

class ScoreCategory {
  final String name;
  final double score; // 0-10
  final String? notes;
  const ScoreCategory({required this.name, required this.score, this.notes});
}

class InterviewModel {
  final String id;
  final String candidateId;
  final String candidateName;
  final String? candidateAvatar;
  final String jobId;
  final String jobTitle;
  final DateTime scheduledAt;
  final InterviewStatus status;
  final String? interviewKitId;
  final List<ScoreCategory> scores;
  final String? overallRecommendation;
  final String? notes;

  const InterviewModel({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    this.candidateAvatar,
    required this.jobId,
    required this.jobTitle,
    required this.scheduledAt,
    required this.status,
    this.interviewKitId,
    this.scores = const [],
    this.overallRecommendation,
    this.notes,
  });

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.score).reduce((a, b) => a + b) / scores.length;
  }
}
