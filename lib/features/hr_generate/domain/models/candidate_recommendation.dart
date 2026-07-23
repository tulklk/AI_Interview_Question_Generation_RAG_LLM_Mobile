import 'package:flutter/material.dart';

// ── Status enum ────────────────────────────────────────────────────────────────

enum RecommendationStatus {
  // NEW = chưa HR xem; SHORTLISTED/DISMISSED/INVITED = HR đã tác động
  newStatus,
  shortlisted,
  invited,
  dismissed;

  static RecommendationStatus fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'SHORTLISTED': return shortlisted;
      case 'INVITED':     return invited;
      case 'DISMISSED':   return dismissed;
      case 'NEW':
      case 'VIEWED':
      default:            return newStatus;
    }
  }

  String get toApiString => switch (this) {
        newStatus   => 'NEW',
        shortlisted => 'SHORTLISTED',
        invited     => 'INVITED',
        dismissed   => 'DISMISSED',
      };

  String get label => switch (this) {
        newStatus   => 'Mới',
        shortlisted => 'Quan tâm',
        invited     => 'Đã mời',
        dismissed   => 'Bỏ qua',
      };

  Color get color => switch (this) {
        newStatus   => const Color(0xFF3B82F6),
        shortlisted => const Color(0xFF6C47FF),
        invited     => const Color(0xFF10B981),
        dismissed   => const Color(0xFFEF4444),
      };

  IconData get icon => switch (this) {
        newStatus   => Icons.fiber_new_rounded,
        shortlisted => Icons.bookmark_rounded,
        invited     => Icons.mail_rounded,
        dismissed   => Icons.close_rounded,
      };

  /// Actions HR can take from this status
  List<RecommendationAction> get availableActions => switch (this) {
        newStatus   => [RecommendationAction.shortlist, RecommendationAction.dismiss],
        shortlisted => [RecommendationAction.invite, RecommendationAction.dismiss],
        invited     => [],
        dismissed   => [RecommendationAction.shortlist],
      };
}

enum RecommendationAction {
  shortlist,
  invite,
  dismiss;

  String get label => switch (this) {
        shortlist => 'Quan tâm',
        invite    => 'Gửi lời mời',
        dismiss   => 'Bỏ qua',
      };

  IconData get icon => switch (this) {
        shortlist => Icons.bookmark_add_rounded,
        invite    => Icons.send_rounded,
        dismiss   => Icons.close_rounded,
      };

  Color get color => switch (this) {
        shortlist => const Color(0xFF6C47FF),
        invite    => const Color(0xFF10B981),
        dismiss   => const Color(0xFFEF4444),
      };
}

// ── QuestionScore ─────────────────────────────────────────────────────────────

class QuestionScore {
  final String questionId;
  final String questionText;
  final String category;
  final String difficulty;
  final double score;
  final String? answerText;
  final String? feedback;
  final List<String> strengths;
  final List<String> improvements;

  const QuestionScore({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.difficulty,
    required this.score,
    this.answerText,
    this.feedback,
    this.strengths = const [],
    this.improvements = const [],
  });

  factory QuestionScore.fromJson(Map<String, dynamic> j) {
    List<String> parseList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return QuestionScore(
      questionId:   (j['questionId']   ?? j['id']       ?? '').toString(),
      questionText: (j['questionText'] ?? j['question'] ?? j['text'] ?? '').toString(),
      category:     (j['category']     ?? j['questionCategory'] ?? 'Technical').toString(),
      difficulty:   (j['difficulty']   ?? j['level']    ?? 'Medium').toString(),
      score:        ((j['score'] ?? j['aiScore'] ?? j['questionScore'] ?? 0) as num).toDouble(),
      answerText:   (j['answerText']   ?? j['answer'])?.toString(),
      feedback:     (j['feedback']     ?? j['suggestion'] ?? j['aiSuggestion'])?.toString(),
      strengths:    parseList(j['strengths']),
      improvements: parseList(j['improvements'] ?? j['areasToImprove']),
    );
  }

  Color get categoryColor => switch (category.toLowerCase()) {
        'behavioral'  => const Color(0xFF8B5CF6),
        'situational' => const Color(0xFFF59E0B),
        _             => const Color(0xFF3B82F6),
      };

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF6C47FF);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── CandidateRecommendation ───────────────────────────────────────────────────

class CandidateRecommendation {
  final String id;
  final String candidateId;
  final String candidateName;
  final String? candidateEmail;
  final String? candidateAvatarUrl;
  final String questionSetId;
  final String questionSetTitle;
  final double overallScore;
  final int totalQuestions;
  final int answeredQuestions;
  final DateTime? completedAt;
  RecommendationStatus status;
  final String? recommendationReason;
  final List<String> skills;
  final List<QuestionScore> questionScores;

  CandidateRecommendation({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    this.candidateEmail,
    this.candidateAvatarUrl,
    required this.questionSetId,
    required this.questionSetTitle,
    required this.overallScore,
    required this.totalQuestions,
    required this.answeredQuestions,
    this.completedAt,
    required this.status,
    this.recommendationReason,
    this.skills = const [],
    this.questionScores = const [],
  });

  String get initials {
    final parts = candidateName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return candidateName.isNotEmpty ? candidateName[0].toUpperCase() : 'C';
  }

  Color get scoreColor {
    if (overallScore >= 80) return const Color(0xFF10B981);
    if (overallScore >= 60) return const Color(0xFF6C47FF);
    if (overallScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get scoreLabel {
    if (overallScore >= 80) return 'Xuất sắc';
    if (overallScore >= 60) return 'Tốt';
    if (overallScore >= 40) return 'Khá';
    return 'Cần cải thiện';
  }

  String get formattedDate {
    if (completedAt == null) return '';
    final d = completedAt!;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is! Map<String, dynamic>) return {};
    var m = raw;
    for (var i = 0; i < 4; i++) {
      if (m['data'] is Map<String, dynamic>) { m = m['data'] as Map<String, dynamic>; continue; }
      if (m['result'] is Map<String, dynamic>) { m = m['result'] as Map<String, dynamic>; continue; }
      break;
    }
    return m;
  }

  factory CandidateRecommendation.fromJson(Map<String, dynamic> raw) {
    final j = _unwrap(raw);

    DateTime? completedAt;
    final rawDate = j['completedAt'] ?? j['finishedAt'] ?? j['createdAt'] ?? j['updatedAt'];
    if (rawDate != null) {
      try { completedAt = DateTime.parse(rawDate.toString()).toLocal(); } catch (_) {}
    }

    List<String> parseList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : <String>[];

    final rawQS = j['questionScores'] ?? j['scores'] ?? j['answers'] ??
        j['questionFeedbacks'] ?? j['feedbacks'] ?? const [];
    final questionScores = rawQS is List
        ? rawQS.whereType<Map<String, dynamic>>().map(QuestionScore.fromJson).toList()
        : <QuestionScore>[];

    return CandidateRecommendation(
      id:                  (j['id'] ?? j['recommendationId'] ?? '').toString(),
      candidateId:         (j['candidateId'] ?? j['userId'] ?? '').toString(),
      candidateName:       (j['candidateName'] ?? j['candidateFullName'] ??
                            j['fullName'] ?? j['name'] ?? 'Ứng viên').toString(),
      candidateEmail:      (j['candidateEmail'] ?? j['email'])?.toString(),
      candidateAvatarUrl:  (j['candidateAvatarUrl'] ?? j['avatarUrl'] ?? j['avatar'])?.toString(),
      questionSetId:       (j['questionSetId'] ?? j['setId'] ?? '').toString(),
      questionSetTitle:    (j['questionSetTitle'] ?? j['setTitle'] ?? j['title'] ?? '').toString(),
      overallScore:        ((j['overallScore'] ?? j['totalScore'] ?? j['score'] ?? 0) as num).toDouble(),
      totalQuestions:      ((j['totalQuestions'] ?? j['questionCount'] ?? 0) as num).toInt(),
      answeredQuestions:   ((j['answeredQuestions'] ?? j['answeredCount'] ?? 0) as num).toInt(),
      completedAt:         completedAt,
      status:              RecommendationStatus.fromString(
                               (j['status'] ?? j['recommendationStatus'])?.toString()),
      recommendationReason: (j['recommendationReason'] ?? j['aiReason'] ??
                              j['reason'] ?? j['summary'])?.toString(),
      skills:              parseList(j['skills'] ?? j['candidateSkills'] ?? j['techStack']),
      questionScores:      questionScores,
    );
  }
}

// ── Paginated list wrapper ─────────────────────────────────────────────────────

class RecommendationPage {
  final List<CandidateRecommendation> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const RecommendationPage({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });

  bool get hasMore => currentPage + 1 < totalPages;

  static RecommendationPage fromJson(dynamic raw) {
    Map<String, dynamic> envelope = {};
    List<dynamic> list = [];

    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw;
      if (inner is Map<String, dynamic>) {
        for (final key in ['content', 'items', 'data', 'result']) {
          if (inner[key] is List) { list = inner[key] as List; break; }
        }
        if (list.isEmpty && inner is Map) {
          for (final key in ['content', 'items']) {
            if (raw[key] is List) { list = raw[key] as List; break; }
          }
        }
        envelope = inner;
      } else if (inner is List) {
        list = inner;
      }
      if (list.isEmpty && raw['content'] is List) list = raw['content'] as List;
      if (list.isEmpty && raw['items'] is List) list = raw['items'] as List;
    } else if (raw is List) {
      list = raw;
    }

    return RecommendationPage(
      items: list.whereType<Map<String, dynamic>>()
          .map(CandidateRecommendation.fromJson).toList(),
      totalElements: ((envelope['totalElements'] ?? envelope['total'] ?? list.length) as num).toInt(),
      totalPages:    ((envelope['totalPages'] ?? envelope['pages'] ?? 1) as num).toInt(),
      currentPage:   ((envelope['number'] ?? envelope['page'] ?? 0) as num).toInt(),
    );
  }
}
