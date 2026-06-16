enum CandidateStage { applied, screening, interview, offer, rejected }

class CandidateModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String appliedRole;
  final String jobId;
  final int matchScore; // 0-100
  final List<String> skills;
  final String? summary;
  final CandidateStage stage;
  final DateTime appliedAt;
  final String? linkedIn;
  final String? github;
  final int yearsOfExperience;

  const CandidateModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.appliedRole,
    required this.jobId,
    required this.matchScore,
    required this.skills,
    this.summary,
    required this.stage,
    required this.appliedAt,
    this.linkedIn,
    this.github,
    this.yearsOfExperience = 0,
  });
}
