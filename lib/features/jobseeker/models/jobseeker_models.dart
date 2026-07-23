import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum QuestionDifficulty { Easy, Medium, Hard }

enum QuestionCategory { Technical, Behavioral, Situational }

// ── PracticeQuestion ──────────────────────────────────────────────────────────

class PracticeQuestion {
  final String id;
  final String text;
  final QuestionCategory category;
  final QuestionDifficulty difficulty;
  final int? timeLimit;

  const PracticeQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.difficulty,
    this.timeLimit,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> j) {
    final catStr = (j['category'] ?? j['questionCategory'] ?? 'Technical')
        .toString()
        .toLowerCase();
    final cat = catStr == 'behavioral'
        ? QuestionCategory.Behavioral
        : catStr == 'situational'
            ? QuestionCategory.Situational
            : QuestionCategory.Technical;

    final diffStr = (j['difficulty'] ?? j['level'] ?? 'Medium')
        .toString()
        .toLowerCase();
    final diff = diffStr == 'easy'
        ? QuestionDifficulty.Easy
        : diffStr == 'hard'
            ? QuestionDifficulty.Hard
            : QuestionDifficulty.Medium;

    return PracticeQuestion(
      id: (j['id'] ?? j['questionId'] ?? '').toString(),
      text: (j['text'] ?? j['question'] ?? j['content'] ??
              j['questionText'] ?? '')
          .toString(),
      category: cat,
      difficulty: diff,
      timeLimit: (j['timeLimit'] as num?)?.toInt(),
    );
  }
}

// ── QuestionSet ───────────────────────────────────────────────────────────────

class QuestionSet {
  final String id;
  final String title;
  final String company;
  final String companyInitials;
  final Color companyColor;
  final String? companyLogo;
  final QuestionDifficulty difficulty;
  final List<String> skills;
  final int totalQuestions;
  final String estimatedTime;
  final String category;
  final String description;
  final double? rating;
  final int? attempts;
  final List<PracticeQuestion> questions;
  final String? companyId;

  const QuestionSet({
    required this.id,
    required this.title,
    required this.company,
    required this.companyInitials,
    required this.companyColor,
    this.companyLogo,
    required this.difficulty,
    required this.skills,
    required this.totalQuestions,
    required this.estimatedTime,
    required this.category,
    required this.description,
    this.rating,
    this.attempts,
    this.companyId,
    required this.questions,
  });

  factory QuestionSet.fromJson(Map<String, dynamic> j) {
    final company = (j['company'] ?? j['organizationName'] ??
        j['hrCompany'] ?? j['companyName'] ?? '').toString();
    final companyColor = _colorFromString(company);
    final companyInitials = _initials(company);

    final diffStr = (j['difficulty'] ?? j['level'] ?? 'Medium')
        .toString().toLowerCase();
    final difficulty = diffStr == 'easy'
        ? QuestionDifficulty.Easy
        : diffStr == 'hard'
            ? QuestionDifficulty.Hard
            : QuestionDifficulty.Medium;

    final rawSkills = j['skills'] ?? j['techStack'] ?? j['tags'];
    List<String> skills;
    if (rawSkills is List) {
      skills = rawSkills.map((s) {
        if (s is Map) return (s['name'] ?? s['skill'] ?? '').toString();
        return s.toString();
      }).where((s) => s.isNotEmpty).toList();
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      skills = rawSkills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else {
      skills = const [];
    }

    final rawQ = j['totalQuestions'] ?? j['questionCount'] ??
        j['totalQ'] ?? j['numQuestions'];
    final totalQuestions = rawQ is num
        ? rawQ.toInt()
        : (j['questions'] is List ? (j['questions'] as List).length : 0);

    final rawTime = j['estimatedTime'] ?? j['estimatedTimeMinutes'] ??
        j['duration'] ?? j['estimatedDuration'];
    final estimatedTime = rawTime is num
        ? '~${rawTime.toInt()} min'
        : (rawTime?.toString() ?? '~30 min');

    final rawQList = j['questions'] ?? j['questionList'] ?? const [];
    final questions = rawQList is List
        ? rawQList
            .whereType<Map<String, dynamic>>()
            .map(PracticeQuestion.fromJson)
            .toList()
        : <PracticeQuestion>[];

    return QuestionSet(
      id:               (j['id'] ?? j['questionSetId'] ?? j['setId'] ?? '').toString(),
      title:            (j['title'] ?? j['name'] ?? j['setTitle'] ?? '').toString(),
      company:          company.isEmpty ? 'Unknown' : company,
      companyInitials:  companyInitials,
      companyColor:     companyColor,
      companyLogo:      _extractLogoUrl(j),
      difficulty:       difficulty,
      skills:           skills,
      totalQuestions:   totalQuestions,
      estimatedTime:    estimatedTime,
      category:         (j['category'] ?? j['type'] ?? 'Technical').toString(),
      description:      (j['description'] ?? j['summary'] ?? '').toString(),
      rating:           (j['rating'] as num?)?.toDouble(),
      attempts:         (j['attempts'] ?? j['practiceCount'] as num?)?.toInt(),
      questions:        questions,
      companyId:        (j['companyId'] ?? j['organizationId'] ?? j['hrCompanyId'])?.toString(),
    );
  }

  static Color _colorFromString(String s) {
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
      Color(0xFFEC4899),
    ];
    if (s.isEmpty) return palette[0];
    var hash = 0;
    for (final c in s.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || name.isEmpty) return '?';
    if (words.length == 1) {
      return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

// ── AnswerRecord ──────────────────────────────────────────────────────────────

class AnswerRecord {
  final String questionId;
  final String questionText;
  final QuestionCategory category;
  final QuestionDifficulty difficulty;
  final String answer;
  final int aiScore;
  final List<String> strengths;
  final List<String> improvements;
  final String suggestion;

  const AnswerRecord({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.difficulty,
    required this.answer,
    required this.aiScore,
    required this.strengths,
    required this.improvements,
    required this.suggestion,
  });
}

// ── PracticeSession ───────────────────────────────────────────────────────────

class PracticeSession {
  final String id;
  final String setId;
  final String setTitle;
  final String company;
  final String companyInitials;
  final Color companyColor;
  final String? companyLogo;
  final String date;
  final int score;
  final String duration;
  final List<String> skills;
  final int totalQuestions;
  final List<AnswerRecord> answers;

  const PracticeSession({
    required this.id,
    required this.setId,
    required this.setTitle,
    required this.company,
    required this.companyInitials,
    required this.companyColor,
    this.companyLogo,
    required this.date,
    required this.score,
    required this.duration,
    required this.skills,
    required this.totalQuestions,
    required this.answers,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> j) {
    final company = (j['company'] ?? j['organizationName'] ??
            j['companyName'] ?? '')
        .toString();

    // Parse completion / creation date to display string
    String date = '';
    final rawDate =
        j['completedAt'] ?? j['startedAt'] ?? j['createdAt'] ?? j['updatedAt'];
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        date = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      } catch (_) {
        date = rawDate.toString();
      }
    }

    final score =
        ((j['overallScore'] ?? j['score'] ?? j['totalScore'] ?? 0) as num)
            .toInt();

    final questionsRaw = j['questions'] ?? j['questionList'] ?? const [];
    final totalQuestions = j['totalQuestions'] is num
        ? (j['totalQuestions'] as num).toInt()
        : questionsRaw is List
            ? questionsRaw.length
            : 0;

    final rawSkills = j['skills'] ?? j['techStack'] ?? const [];
    final skills = rawSkills is List
        ? rawSkills.map((s) => s.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return PracticeSession(
      id:              (j['id'] ?? j['sessionId'] ?? '').toString(),
      setId:           (j['questionSetId'] ?? j['setId'] ?? '').toString(),
      setTitle:        (j['questionSetTitle'] ?? j['setTitle'] ??
                        j['title'] ?? '').toString(),
      company:         company.isEmpty ? 'Unknown' : company,
      companyInitials: QuestionSet._initials(company),
      companyColor:    QuestionSet._colorFromString(company),
      companyLogo:     _extractLogoUrl(j),
      date:            date,
      score:           score,
      duration:        totalQuestions > 0 ? '~${totalQuestions * 3} min' : '—',
      skills:          skills,
      totalQuestions:  totalQuestions,
      answers:         const [],
    );
  }
}

// ── PracticeStats ─────────────────────────────────────────────────────────────

class PracticeStats {
  final int totalSessions;
  final int bestScore;
  final int avgScore;

  const PracticeStats({
    required this.totalSessions,
    required this.bestScore,
    required this.avgScore,
  });

  factory PracticeStats.fromJson(Map<String, dynamic> j) {
    final raw =
        j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;
    return PracticeStats(
      totalSessions: ((raw['totalSessions'] ?? raw['completedCount'] ??
                       raw['total'] ?? 0) as num).toInt(),
      bestScore:     ((raw['bestScore'] ?? raw['highestScore'] ??
                       raw['maxScore'] ?? 0) as num).toInt(),
      avgScore:      ((raw['avgScore'] ?? raw['averageScore'] ??
                       raw['meanScore'] ?? 0) as num).toInt(),
    );
  }
}

// ── SkillStat ─────────────────────────────────────────────────────────────────

class SkillStat {
  final String skill;
  final int score;
  final int fullMark;

  const SkillStat({
    required this.skill,
    required this.score,
    this.fullMark = 100,
  });
}

// ── Achievement ───────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool earned;
  final String? earnedDate;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earned,
    this.earnedDate,
  });
}

// ── CandidateProfileData ──────────────────────────────────────────────────────

class CandidateProfileData {
  final String fullName;
  final String email;
  final String? targetRole;
  final String? seniorityLevel;
  final List<String> techStack;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? bio;

  const CandidateProfileData({
    required this.fullName,
    required this.email,
    this.targetRole,
    this.seniorityLevel,
    List<String>? techStack,
    this.phoneNumber,
    this.avatarUrl,
    this.linkedInUrl,
    this.githubUrl,
    this.bio,
  }) : techStack = techStack ?? const [];

  CandidateProfileData copyWith({
    String? fullName,
    String? email,
    String? targetRole,
    String? seniorityLevel,
    List<String>? techStack,
    String? phoneNumber,
    String? avatarUrl,
    String? linkedInUrl,
    String? githubUrl,
    String? bio,
  }) {
    return CandidateProfileData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      targetRole: targetRole ?? this.targetRole,
      seniorityLevel: seniorityLevel ?? this.seniorityLevel,
      techStack: techStack ?? this.techStack,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      bio: bio ?? this.bio,
    );
  }

  factory CandidateProfileData.fromMap(Map<String, dynamic> m, String email) {
    final profile = m['candidateProfile'] as Map<String, dynamic>?;
    final p = profile ?? m;
    List<String> parseStack(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return CandidateProfileData(
      fullName: (p['fullName'] ?? p['FullName'] ?? m['fullName'] ?? '').toString(),
      email: email,
      targetRole: (p['targetRole'] ?? p['TargetRole'])?.toString(),
      seniorityLevel: (p['seniorityLevel'] ?? p['SeniorityLevel'] ??
              p['experienceLevel'] ?? p['ExperienceLevel'])
          ?.toString(),
      techStack: parseStack(p['techStack'] ?? p['TechStack']),
      phoneNumber: (p['phoneNumber'] ?? p['phone'])?.toString(),
      avatarUrl: (p['avatarUrl'] ?? p['avatar'])?.toString(),
      linkedInUrl: (p['linkedInUrl'] ?? p['linkedin'])?.toString(),
      githubUrl: (p['githubUrl'] ?? p['github'])?.toString(),
      bio: p['bio']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateMap() {
    final m = <String, dynamic>{'fullName': fullName.trim()};
    if (targetRole != null && targetRole!.isNotEmpty) m['targetRole'] = targetRole;
    if (seniorityLevel != null && seniorityLevel!.isNotEmpty) m['seniorityLevel'] = seniorityLevel;
    m['techStack'] = techStack;
    if (bio != null && bio!.isNotEmpty) m['bio'] = bio;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) m['phoneNumber'] = phoneNumber;
    if (linkedInUrl != null && linkedInUrl!.isNotEmpty) m['linkedInUrl'] = linkedInUrl;
    if (githubUrl != null && githubUrl!.isNotEmpty) m['githubUrl'] = githubUrl;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) m['avatarUrl'] = avatarUrl;
    return m;
  }
}

// ── InProgressSummary ─────────────────────────────────────────────────────────

class InProgressSummary {
  final String sessionId;
  final String setId;
  final String setTitle;
  final String company;
  final Color companyColor;
  final String companyInitials;
  final String? companyLogo;
  final int answeredCount;
  final int totalQuestions;

  const InProgressSummary({
    required this.sessionId,
    required this.setId,
    required this.setTitle,
    required this.company,
    required this.companyColor,
    required this.companyInitials,
    this.companyLogo,
    required this.answeredCount,
    required this.totalQuestions,
  });

  factory InProgressSummary.fromJson(Map<String, dynamic> j) {
    final company = (j['company'] ?? j['organizationName'] ??
            j['companyName'] ?? '')
        .toString();
    final answersRaw = j['answers'] ?? j['submittedAnswers'] ?? const [];
    final answeredCount = answersRaw is List ? answersRaw.length : 0;
    final questionsRaw = j['questions'] ?? j['questionList'] ?? const [];
    final totalQuestions = j['totalQuestions'] is num
        ? (j['totalQuestions'] as num).toInt()
        : questionsRaw is List
            ? questionsRaw.length
            : 0;

    return InProgressSummary(
      sessionId:       (j['id'] ?? j['sessionId'] ?? '').toString(),
      setId:           (j['questionSetId'] ?? j['setId'] ?? '').toString(),
      setTitle:        (j['questionSetTitle'] ?? j['setTitle'] ??
                        j['title'] ?? '').toString(),
      company:         company.isEmpty ? 'Unknown' : company,
      companyColor:    QuestionSet._colorFromString(company),
      companyInitials: QuestionSet._initials(company),
      companyLogo:     _extractLogoUrl(j),
      answeredCount:   answeredCount,
      totalQuestions:  totalQuestions,
    );
  }
}

// ── Logo extraction helper ────────────────────────────────────────────────────

/// Extracts a company logo URL from a JSON map, handling multiple response shapes:
/// - Flat: `companyLogo`, `logoUrl`, `logo`
/// - Nested in `questionSet`: `questionSet.companyLogo`
/// - Nested in `company`/`companyInfo`: `companyInfo.logoUrl`
String? _extractLogoUrl(Map<String, dynamic> j) {
  // 1. Direct root-level fields
  for (final key in ['companyLogo', 'logoUrl', 'logo', 'companyLogoUrl', 'organizationLogo']) {
    final v = j[key];
    if (v is String && v.startsWith('http')) return v;
  }
  // 2. Nested in questionSet object
  for (final setKey in ['questionSet', 'questionSetData', 'questionSetInfo', 'set']) {
    final qs = j[setKey];
    if (qs is Map) {
      for (final key in ['companyLogo', 'logoUrl', 'logo', 'companyLogoUrl']) {
        final v = qs[key];
        if (v is String && v.startsWith('http')) return v;
      }
    }
  }
  // 3. Nested in company/companyInfo object
  for (final compKey in ['companyInfo', 'companyDetail', 'company', 'organization']) {
    final comp = j[compKey];
    if (comp is Map) {
      for (final key in ['logoUrl', 'logo', 'companyLogo', 'imageUrl']) {
        final v = comp[key];
        if (v is String && v.startsWith('http')) return v;
      }
    }
  }
  return null;
}

// ── Score helpers ─────────────────────────────────────────────────────────────

Color scoreColor(int score) {
  if (score >= 80) return const Color(0xFF10B981);
  if (score >= 65) return const Color(0xFF6C47FF);
  return const Color(0xFFF59E0B);
}

String scoreLevel(int score) {
  if (score >= 80) return 'Excellent';
  if (score >= 65) return 'Good';
  if (score >= 50) return 'Fair';
  return 'Needs Work';
}

Color difficultyColor(QuestionDifficulty d) {
  switch (d) {
    case QuestionDifficulty.Easy:   return const Color(0xFF10B981);
    case QuestionDifficulty.Medium: return const Color(0xFFF59E0B);
    case QuestionDifficulty.Hard:   return const Color(0xFFEF4444);
  }
}

Color categoryColor(QuestionCategory c) {
  switch (c) {
    case QuestionCategory.Technical:   return const Color(0xFF3B82F6);
    case QuestionCategory.Behavioral:  return const Color(0xFF8B5CF6);
    case QuestionCategory.Situational: return const Color(0xFFF59E0B);
  }
}

String difficultyLabel(QuestionDifficulty d) => d.name;
String categoryLabel(QuestionCategory c) => c.name;

// ── CvData ───────────────────────────────────────────────────────────────────

class CvData {
  final String? cvFileName;
  final String? parsedAt;
  final List<String> skills;
  final String? summary;
  final List<String> techStack;
  final String? cvUrl;

  const CvData({
    this.cvFileName,
    this.parsedAt,
    this.skills = const [],
    this.summary,
    this.techStack = const [],
    this.cvUrl,
  });

  factory CvData.fromJson(Map<String, dynamic> j) {
    final data =
        j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : j;

    List<String> parseList(dynamic v) => v is List
        ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : [];

    return CvData(
      cvFileName: (data['cvFileName'] ?? data['fileName'] ?? data['name'])?.toString(),
      parsedAt:   (data['parsedAt'] ?? data['createdAt'] ?? data['updatedAt'])?.toString(),
      skills:     parseList(data['skills'] ?? data['cvSkills']),
      summary:    (data['summary'] ?? data['cvSummary'] ?? data['aiSummary'])?.toString(),
      techStack:  parseList(data['techStack'] ?? data['cvTechStack']),
      cvUrl:      (data['cvUrl'] ?? data['url'] ?? data['fileUrl'])?.toString(),
    );
  }
}

// ── CompanyInfo ───────────────────────────────────────────────────────────────

class CompanyInfo {
  final String id;
  final String name;
  final String? logoUrl;
  final String? industry;
  final String? size;
  final String? website;
  final String? description;
  final String? location;

  const CompanyInfo({
    required this.id,
    required this.name,
    this.logoUrl,
    this.industry,
    this.size,
    this.website,
    this.description,
    this.location,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> j) {
    final data = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    return CompanyInfo(
      id:          (data['id'] ?? data['companyId'] ?? '').toString(),
      name:        (data['name'] ?? data['companyName'] ?? '').toString(),
      logoUrl:     (data['logoUrl'] ?? data['logo'])?.toString(),
      industry:    data['industry']?.toString(),
      size:        (data['size'] ?? data['companySize'])?.toString(),
      website:     data['website']?.toString(),
      description: (data['description'] ?? data['about'])?.toString(),
      location:    (data['location'] ?? data['address'])?.toString(),
    );
  }
}

// ── QuestionFeedback ──────────────────────────────────────────────────────────

class QuestionFeedback {
  final String questionId;
  final String questionText;
  final QuestionCategory category;
  final String answerText;
  final int score;
  final List<String> strengths;
  final List<String> improvements;
  final String suggestion;

  const QuestionFeedback({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.answerText,
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.suggestion,
  });

  factory QuestionFeedback.fromJson(Map<String, dynamic> j) {
    final catStr = (j['category'] ?? j['questionCategory'] ?? 'Technical')
        .toString()
        .toLowerCase();
    final cat = catStr == 'behavioral'
        ? QuestionCategory.Behavioral
        : catStr == 'situational'
            ? QuestionCategory.Situational
            : QuestionCategory.Technical;

    List<String> parseList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return QuestionFeedback(
      questionId:   (j['questionId'] ?? j['id'] ?? '').toString(),
      questionText: (j['questionText'] ?? j['question'] ?? j['text'] ?? '').toString(),
      category:     cat,
      answerText:   (j['answerText'] ?? j['answer'] ?? '').toString(),
      score:        ((j['score'] ?? j['aiScore'] ?? 0) as num).toInt(),
      strengths:    parseList(j['strengths']),
      improvements: parseList(j['improvements'] ?? j['areasToImprove']),
      suggestion:   (j['suggestion'] ?? j['aiSuggestion'] ?? j['feedback'] ?? '').toString(),
    );
  }
}

// ── FeedbackResult ────────────────────────────────────────────────────────────

class FeedbackResult {
  final String sessionId;
  final String setId;
  final String setTitle;
  final String company;
  final Color companyColor;
  final String companyInitials;
  final int overallScore;
  final List<SkillStat> skillStats;
  final List<QuestionFeedback> questionFeedbacks;

  const FeedbackResult({
    required this.sessionId,
    required this.setId,
    required this.setTitle,
    required this.company,
    required this.companyColor,
    required this.companyInitials,
    required this.overallScore,
    required this.skillStats,
    required this.questionFeedbacks,
  });

  factory FeedbackResult.fromJson(Map<String, dynamic> j) {
    final raw = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;

    final company = (raw['company'] ?? raw['organizationName'] ??
            raw['companyName'] ?? '')
        .toString();

    List<SkillStat> parseSkillStats(dynamic v) {
      if (v is! List) return [];
      return v.whereType<Map<String, dynamic>>().map((s) {
        return SkillStat(
          skill:    (s['skill'] ?? s['name'] ?? s['skillName'] ?? '').toString(),
          score:    ((s['score'] ?? s['value'] ?? 0) as num).toInt(),
          fullMark: ((s['fullMark'] ?? s['maxScore'] ?? 100) as num).toInt(),
        );
      }).toList();
    }

    List<QuestionFeedback> parseQF(dynamic v) {
      if (v is! List) return [];
      return v.whereType<Map<String, dynamic>>().map(QuestionFeedback.fromJson).toList();
    }

    return FeedbackResult(
      sessionId:         (raw['sessionId'] ?? raw['id'] ?? '').toString(),
      setId:             (raw['questionSetId'] ?? raw['setId'] ?? '').toString(),
      setTitle:          (raw['setTitle'] ?? raw['title'] ?? raw['questionSetTitle'] ?? '').toString(),
      company:           company.isEmpty ? 'Unknown' : company,
      companyColor:      QuestionSet._colorFromString(company),
      companyInitials:   QuestionSet._initials(company),
      overallScore:      ((raw['overallScore'] ?? raw['score'] ?? raw['totalScore'] ?? 0) as num).toInt(),
      skillStats:        parseSkillStats(raw['skillStats'] ?? raw['skills'] ?? raw['skillBreakdown']),
      questionFeedbacks: parseQF(raw['questionFeedbacks'] ?? raw['answers'] ?? raw['feedbacks']),
    );
  }
}
