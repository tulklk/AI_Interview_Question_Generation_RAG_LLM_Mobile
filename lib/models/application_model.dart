enum ApplicationStatus { applied, cvScreening, interview, offer, rejected }

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String userId;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? interviewDate;
  final String? notes;
  final String? cvUrl;
  final int matchScore;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.userId,
    required this.status,
    required this.appliedAt,
    this.interviewDate,
    this.notes,
    this.cvUrl,
    this.matchScore = 0,
  });
}
