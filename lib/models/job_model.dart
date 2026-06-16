enum JobStatus { active, draft, closed }
enum ExperienceLevel { junior, middle, senior, lead }

class JobModel {
  final String id;
  final String title;
  final String department;
  final String location;
  final bool isRemote;
  final ExperienceLevel level;
  final String description;
  final List<String> skills;
  final JobStatus status;
  final int candidateCount;
  final String? salaryRange;
  final DateTime createdAt;
  final String? interviewKitId;

  const JobModel({
    required this.id,
    required this.title,
    required this.department,
    required this.location,
    this.isRemote = false,
    required this.level,
    required this.description,
    required this.skills,
    required this.status,
    this.candidateCount = 0,
    this.salaryRange,
    required this.createdAt,
    this.interviewKitId,
  });
}
