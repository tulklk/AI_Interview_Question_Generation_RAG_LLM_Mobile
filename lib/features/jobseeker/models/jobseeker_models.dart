import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum QuestionDifficulty { Easy, Medium, Hard }

enum QuestionCategory { Technical, Behavioral, Situational }

// ── Code-question constants ───────────────────────────────────────────────────

/// Template types that require a code-style answer field.
/// SYSTEM_DESIGN is intentionally excluded — it is answered in prose.
const kCodeAnswerTemplateTypes = {
  'CODE_COMPLETION',
  'BUG_DETECTION',
  'REFACTORING',
  'TEST_CASE_DESIGN',
  'PERFORMANCE_ANALYSIS',
};

/// Min length for any answer (text or code).
const kMinAnswerChars = 20;

/// Min word count for *text* answers only (skipped for code).
const kMinAnswerWords = 3;

// ── PracticeQuestion ──────────────────────────────────────────────────────────

class PracticeQuestion {
  final String id;
  final String text;
  final QuestionCategory category;
  final QuestionDifficulty difficulty;
  final int? timeLimit;

  // ── Code-question fields (nullable → backward-compatible) ─────────────────
  /// Server-supplied template category, e.g. "CODE_COMPLETION".
  final String? codeTemplateType;
  /// Starter / reference code snippet from the back-end.
  final String? codeSnippet;
  /// Optional attached image (diagram, etc.).
  final String? attachedImageUrl;
  /// Explicit answer method override from the back-end, e.g. "code" | "text".
  final String? answerMethod;
  /// Free-tier lock — when true, hide snippet + answer field and show upsell.
  final bool isLocked;

  const PracticeQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.difficulty,
    this.timeLimit,
    this.codeTemplateType,
    this.codeSnippet,
    this.attachedImageUrl,
    this.answerMethod,
    this.isLocked = false,
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

    final lockedRaw = j['isLocked'] ?? j['IsLocked'] ?? false;

    return PracticeQuestion(
      id: (j['id'] ?? j['questionId'] ?? '').toString(),
      text: (j['text'] ?? j['question'] ?? j['content'] ??
              j['questionText'] ?? '')
          .toString(),
      category: cat,
      difficulty: diff,
      timeLimit: (j['timeLimit'] as num?)?.toInt(),
      codeTemplateType: (j['codeTemplateType'] ?? j['CodeTemplateType'])?.toString(),
      codeSnippet:      (j['codeSnippet'] ?? j['CodeSnippet'])?.toString(),
      attachedImageUrl: (j['attachedImageUrl'] ?? j['AttachedImageUrl'])?.toString(),
      answerMethod:     (j['answerMethod'] ?? j['AnswerMethod'])?.toString(),
      isLocked:         lockedRaw is bool ? lockedRaw : false,
    );
  }

  /// Returns true when this question expects a code-style answer.
  /// Priority: 1) explicit answerMethod  2) codeSnippet present  3) templateType ∈ set
  bool get needsCodeAnswer {
    // 1. Explicit override from server
    final method = answerMethod?.toLowerCase();
    if (method == 'code') return true;
    if (method == 'text') return false;

    // 2. Has a starter snippet → implies code answer
    if (codeSnippet != null && codeSnippet!.trim().isNotEmpty) return true;

    // 3. Template type membership
    final tpl = codeTemplateType?.toUpperCase() ?? '';
    return kCodeAnswerTemplateTypes.contains(tpl);
  }
}

// ── Code-snippet helpers ──────────────────────────────────────────────────────

/// Converts literal escape sequences sent as plain strings by the BE
/// (e.g. `"\\n"` → actual newline, `"\\t"` → actual tab).
String normalizeCodeEscapes(String raw) {
  return raw
      .replaceAll(r'\r\n', '\n')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\t', '\t');
}

/// Validates an answer string according to the spec:
/// - Always: minimum [kMinAnswerChars] characters.
/// - Text questions only: minimum [kMinAnswerWords] words.
/// Returns null if valid, or a i18n-key string if invalid.
String? validateAnswerText(String text, {required bool isCode}) {
  final trimmed = text.trim();
  if (trimmed.length < kMinAnswerChars) return 'validationTooShort';
  if (!isCode) {
    final wordCount = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < kMinAnswerWords) return 'validationTooFewWords';
  }
  return null;
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

// ── Invitation ────────────────────────────────────────────────────────────────

enum InvitationStatus { pending, accepted, rejected }

class Invitation {
  final String id;
  final String questionSetId;
  final String questionSetTitle;
  final String company;
  final Color companyColor;
  final String companyInitials;
  final String? companyLogo;
  final InvitationStatus status;
  final String? hrNote;
  final String? responseMessage;
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final int totalQuestions;
  final List<String> skills;

  const Invitation({
    required this.id,
    required this.questionSetId,
    required this.questionSetTitle,
    required this.company,
    required this.companyColor,
    required this.companyInitials,
    this.companyLogo,
    required this.status,
    this.hrNote,
    this.responseMessage,
    required this.invitedAt,
    this.respondedAt,
    this.totalQuestions = 0,
    this.skills = const [],
  });

  factory Invitation.fromJson(Map<String, dynamic> j) {
    final qs = j['questionSet'] as Map<String, dynamic>?;
    final company = (qs?['companyName'] ?? qs?['company'] ??
        j['companyName'] ?? j['company'] ?? j['organizationName'] ?? '').toString();

    InvitationStatus parseStatus(String s) {
      switch (s.toUpperCase()) {
        case 'ACCEPTED': return InvitationStatus.accepted;
        case 'REJECTED': return InvitationStatus.rejected;
        default:         return InvitationStatus.pending;
      }
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try { return DateTime.parse(v.toString()).toLocal(); } catch (_) { return DateTime.now(); }
    }

    List<String> parseSkills(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      return const [];
    }

    final logoUrl = _extractLogoUrl(qs ?? j);

    return Invitation(
      id:                 (j['id'] ?? j['invitationId'] ?? '').toString(),
      questionSetId:      (qs?['id'] ?? j['questionSetId'] ?? j['setId'] ?? '').toString(),
      questionSetTitle:   (qs?['title'] ?? qs?['name'] ?? j['questionSetTitle'] ??
                          j['setTitle'] ?? j['title'] ?? '').toString(),
      company:            company.isEmpty ? 'Unknown' : company,
      companyColor:       QuestionSet._colorFromString(company),
      companyInitials:    QuestionSet._initials(company),
      companyLogo:        logoUrl,
      status:             parseStatus((j['status'] ?? 'PENDING').toString()),
      hrNote:             (j['hrNote'] ?? j['message'] ?? j['note'])?.toString(),
      responseMessage:    (j['responseMessage'] ?? j['candidateMessage'])?.toString(),
      invitedAt:          parseDate(j['invitedAt'] ?? j['createdAt'] ?? j['sentAt']),
      respondedAt:        j['respondedAt'] != null ? parseDate(j['respondedAt']) : null,
      totalQuestions:     ((qs?['totalQuestions'] ?? qs?['questionCount'] ??
                           j['totalQuestions'] ?? 0) as num).toInt(),
      skills:             parseSkills(qs?['skills'] ?? qs?['techStack'] ?? j['skills'] ?? []),
    );
  }

  Invitation copyWith({InvitationStatus? status, String? responseMessage}) => Invitation(
    id: id, questionSetId: questionSetId, questionSetTitle: questionSetTitle,
    company: company, companyColor: companyColor, companyInitials: companyInitials,
    companyLogo: companyLogo, hrNote: hrNote, invitedAt: invitedAt, respondedAt: respondedAt,
    totalQuestions: totalQuestions, skills: skills,
    status: status ?? this.status,
    responseMessage: responseMessage ?? this.responseMessage,
  );
}

// ── UserProgress (Gamification) ───────────────────────────────────────────────

class UserProgress {
  final int totalXp;
  final int level;
  final int currentLevelXp;
  final int xpRequiredForNextLevel;
  final int progressPercentage;
  final int currentStreak;
  final int longestStreak;
  final int dailyGoalXp;
  final int todayXp;
  final bool dailyGoalCompleted;
  final int totalPracticeSessions;
  final int? nextLevel;

  const UserProgress({
    required this.totalXp,
    required this.level,
    required this.currentLevelXp,
    required this.xpRequiredForNextLevel,
    required this.progressPercentage,
    required this.currentStreak,
    required this.longestStreak,
    required this.dailyGoalXp,
    required this.todayXp,
    required this.dailyGoalCompleted,
    required this.totalPracticeSessions,
    this.nextLevel,
  });

  factory UserProgress.fromJson(Map<String, dynamic> j) {
    // /progress wraps in {data: ...}; we unwrap one level if present
    final raw = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    return UserProgress(
      totalXp:               ((raw['totalXp'] ?? raw['xp'] ?? 0) as num).toInt(),
      level:                 ((raw['level'] ?? raw['currentLevel'] ?? 1) as num).toInt(),
      currentLevelXp:        ((raw['currentLevelXp'] ?? raw['levelXp'] ?? 0) as num).toInt(),
      xpRequiredForNextLevel:((raw['xpRequiredForNextLevel'] ?? raw['nextLevelXp'] ?? 100) as num).toInt(),
      progressPercentage:    ((raw['progressPercentage'] ?? raw['progress'] ?? 0) as num).toInt(),
      currentStreak:         ((raw['currentStreak'] ?? raw['streak'] ?? 0) as num).toInt(),
      longestStreak:         ((raw['longestStreak'] ?? raw['bestStreak'] ?? 0) as num).toInt(),
      dailyGoalXp:           ((raw['dailyGoalXp'] ?? raw['dailyGoal'] ?? 50) as num).toInt(),
      todayXp:               ((raw['todayXp'] ?? raw['dailyXp'] ?? 0) as num).toInt(),
      dailyGoalCompleted:    (raw['dailyGoalCompleted'] ?? raw['goalCompleted'] ?? false) as bool,
      totalPracticeSessions: ((raw['totalPracticeSessions'] ?? raw['sessions'] ?? 0) as num).toInt(),
      nextLevel:             (raw['nextLevel'] as num?)?.toInt(),
    );
  }

  double get progressFraction {
    if (xpRequiredForNextLevel <= 0) return 1.0;
    return (currentLevelXp / xpRequiredForNextLevel).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => (xpRequiredForNextLevel - currentLevelXp).clamp(0, xpRequiredForNextLevel);
}

// ── GamificationAchievement ───────────────────────────────────────────────────

class GamificationAchievement {
  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int? currentValue;
  final int? targetValue;
  final int? xpReward;

  const GamificationAchievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
    this.currentValue,
    this.targetValue,
    this.xpReward,
  });

  factory GamificationAchievement.fromJson(Map<String, dynamic> j) {
    final code = (j['code'] ?? j['achievementCode'] ?? '').toString().toUpperCase();
    final meta = _achievementMeta(code);

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { return DateTime.parse(v.toString()).toLocal(); } catch (_) { return null; }
    }

    return GamificationAchievement(
      id:           (j['id'] ?? j['achievementId'] ?? code).toString(),
      code:         code,
      name:         (j['name'] ?? j['title'] ?? meta.name).toString(),
      description:  (j['description'] ?? j['desc'] ?? meta.description).toString(),
      icon:         meta.icon,
      unlocked:     (j['unlocked'] ?? j['earned'] ?? j['isUnlocked'] ?? false) as bool,
      unlockedAt:   parseDate(j['unlockedAt'] ?? j['earnedAt']),
      currentValue: (j['currentValue'] ?? j['progress'] as num?)?.toInt(),
      targetValue:  (j['targetValue'] ?? j['target'] as num?)?.toInt(),
      xpReward:     (j['xpReward'] ?? j['reward'] as num?)?.toInt(),
    );
  }

  /// True if unlocked within the last 7 days (shows "Mới" badge)
  bool get isNew {
    if (!unlocked || unlockedAt == null) return false;
    return DateTime.now().difference(unlockedAt!).inDays < 7;
  }
}

// ── Achievement code → display meta ──────────────────────────────────────────

class _AchievementMeta {
  final String icon;
  final String name;
  final String description;
  const _AchievementMeta(this.icon, this.name, this.description);
}

_AchievementMeta _achievementMeta(String code) {
  const map = <String, _AchievementMeta>{
    'FIRST_STEP':       _AchievementMeta('🚀', 'Bước đầu tiên',          'Hoàn thành phiên luyện tập đầu tiên'),
    'ON_FIRE':          _AchievementMeta('🔥', 'Bùng cháy',              'Duy trì chuỗi 7 ngày liên tiếp'),
    'EXCELLENT_ANSWER': _AchievementMeta('⭐', 'Câu trả lời xuất sắc',   'Đạt điểm 90+ trong một phiên'),
    'DEDICATED':        _AchievementMeta('🎯', 'Người luyện tập chăm chỉ','Hoàn thành 10 phiên luyện tập'),
    'TECHNICAL_MIND':   _AchievementMeta('⚡', 'Tư duy kỹ thuật',        'Hoàn thành 5 bộ câu hỏi kỹ thuật'),
    'SYSTEM_THINKER':   _AchievementMeta('🌐', 'Tư duy hệ thống',        'Thực hành 3 danh mục khác nhau'),
    'CONSISTENCY':      _AchievementMeta('📅', 'Bền bỉ mỗi ngày',       'Đạt mục tiêu XP hàng ngày 30 ngày'),
    'INTERVIEW_VETERAN':_AchievementMeta('🏆', 'Cựu binh phỏng vấn',    'Hoàn thành 50 phiên luyện tập'),
  };
  return map[code] ?? _AchievementMeta('🏅', code, '');
}

/// Map code → human-readable display (used by widgets)
String achievementIcon(String code)        => _achievementMeta(code).icon;
String achievementName(String code)        => _achievementMeta(code).name;
String achievementDescription(String code) => _achievementMeta(code).description;

/// Level label per spec §9.5
String levelLabel(int level) {
  if (level <= 2)  return 'Newcomer';
  if (level <= 5)  return 'Practitioner';
  if (level <= 9)  return 'Achiever';
  if (level <= 14) return 'Trailblazer';
  if (level <= 19) return 'Specialist';
  if (level <= 29) return 'Mentor';
  return 'Legend';
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

// ── XpReward ──────────────────────────────────────────────────────────────────

class XpReward {
  final int totalEarned;
  final bool levelUp;
  final int newLevel;
  final int oldLevel;
  final int currentXp;

  const XpReward({
    required this.totalEarned,
    required this.levelUp,
    required this.newLevel,
    required this.oldLevel,
    required this.currentXp,
  });

  factory XpReward.fromJson(Map<String, dynamic> j) {
    final raw = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    return XpReward(
      totalEarned: ((raw['totalEarned'] ?? raw['xpEarned'] ?? raw['xp'] ?? 0) as num).toInt(),
      levelUp:     raw['levelUp'] as bool? ?? false,
      newLevel:    ((raw['newLevel'] ?? raw['level'] ?? 1) as num).toInt(),
      oldLevel:    ((raw['oldLevel'] ?? raw['previousLevel'] ?? 1) as num).toInt(),
      currentXp:   ((raw['currentXp'] ?? raw['totalXp'] ?? 0) as num).toInt(),
    );
  }
}

// ── AI Feedback access / gating types ─────────────────────────────────────────

/// ONLY "Full" === premium; every other value defaults to FreeTeaser (safe).
enum PracticeFeedbackAccessLevel { freeTeaser, full }

class SessionAiInsight {
  final String vi;
  final String en;
  final List<String> skillsToImproveVi;
  final List<String> skillsToImproveEn;

  const SessionAiInsight({
    required this.vi,
    required this.en,
    required this.skillsToImproveVi,
    required this.skillsToImproveEn,
  });

  factory SessionAiInsight.fromJson(Map<String, dynamic> j) {
    List<String> _parseList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];
    return SessionAiInsight(
      vi:                (j['vi'] ?? j['Vi'] ?? j['content'] ?? '').toString(),
      en:                (j['en'] ?? j['En'] ?? '').toString(),
      skillsToImproveVi: _parseList(j['skillsToImproveVi'] ?? j['skillsToImprove']),
      skillsToImproveEn: _parseList(j['skillsToImproveEn']),
    );
  }
}

/// Per-question evaluation returned inside feedback `items[]`.
class AnswerEvaluation {
  final double? score;
  final List<String> strengths;
  final List<String> improvements;
  final String? suggestion;
  final Map<String, double>? dimensionScores;
  final String evaluationStatus; // "Succeeded" | "Pending" | "Unknown" …
  final bool isLocked;
  final bool isTeaser;
  final String? questionText;
  final String? answerText;
  final String questionType;

  const AnswerEvaluation({
    this.score,
    required this.strengths,
    required this.improvements,
    this.suggestion,
    this.dimensionScores,
    required this.evaluationStatus,
    required this.isLocked,
    required this.isTeaser,
    this.questionText,
    this.answerText,
    required this.questionType,
  });

  factory AnswerEvaluation.fromJson(Map<String, dynamic> j) {
    List<String> _parseList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    Map<String, double>? _parseDims(dynamic v) {
      if (v is! Map) return null;
      final m = <String, double>{};
      v.forEach((k, val) {
        if (val is num) m[k.toString()] = val.toDouble();
      });
      return m.isEmpty ? null : m;
    }

    final lockedRaw = j['isLocked'] ?? j['IsLocked'] ?? false;
    final teaserRaw = j['isTeaser'] ?? j['IsTeaser'] ?? false;
    final scoreRaw  = j['score'] ?? j['aiScore'];

    return AnswerEvaluation(
      score:            scoreRaw is num ? scoreRaw.toDouble() : null,
      strengths:        _parseList(j['strengths']),
      improvements:     _parseList(j['improvements'] ?? j['areasToImprove']),
      suggestion:       (j['suggestion'] ?? j['aiSuggestion'])?.toString(),
      dimensionScores:  _parseDims(j['dimensionScores']),
      evaluationStatus: (j['evaluationStatus'] ?? j['EvaluationStatus'] ?? 'Unknown').toString(),
      isLocked:         lockedRaw is bool ? lockedRaw : false,
      isTeaser:         teaserRaw is bool ? teaserRaw : false,
      questionText:     (j['question'] ?? j['questionText'] ?? j['text'])?.toString(),
      answerText:       (j['answerText'] ?? j['answer'])?.toString(),
      questionType:     (j['questionType'] ?? j['category'] ?? 'Technical').toString(),
    );
  }
}

/// Full feedback payload for a completed session.
class SessionFeedback {
  final double? overallScore;
  final PracticeFeedbackAccessLevel accessLevel;
  final SessionAiInsight? aiInsight;
  /// Map from questionId → evaluation (sourced from `items[]`).
  final Map<String, AnswerEvaluation> evaluations;

  const SessionFeedback({
    this.overallScore,
    required this.accessLevel,
    this.aiInsight,
    required this.evaluations,
  });

  factory SessionFeedback.fromJson(Map<String, dynamic> j) {
    final raw = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;

    // ONLY "Full" → premium; everything else → freeTeaser (safe default).
    final accessStr = (raw['accessLevel'] ?? '').toString();
    final accessLevel = accessStr == 'Full'
        ? PracticeFeedbackAccessLevel.full
        : PracticeFeedbackAccessLevel.freeTeaser;

    // Parse evaluations from items[] (canonical), fall back to legacy keys.
    final evals = <String, AnswerEvaluation>{};

    void _parseList(dynamic v) {
      if (v is! List) return;
      for (final item in v.whereType<Map<String, dynamic>>()) {
        final qId = (item['questionId'] ?? item['id'] ?? '').toString();
        if (qId.isNotEmpty) evals[qId] = AnswerEvaluation.fromJson(item);
      }
    }

    _parseList(raw['items']);
    if (evals.isEmpty) {
      _parseList(raw['questionFeedbacks']);
      _parseList(raw['feedbacks']);
      _parseList(raw['answers']);
    }

    // Also accept Map<questionId, eval> format
    final legacyMap = raw['evaluations'];
    if (legacyMap is Map) {
      legacyMap.forEach((k, v) {
        if (!evals.containsKey(k) && v is Map<String, dynamic>) {
          evals[k] = AnswerEvaluation.fromJson(v);
        }
      });
    }

    SessionAiInsight? insight;
    final aiRaw = raw['aiInsight'];
    if (aiRaw is Map<String, dynamic>) insight = SessionAiInsight.fromJson(aiRaw);

    return SessionFeedback(
      overallScore: (raw['overallScore'] as num?)?.toDouble(),
      accessLevel:  accessLevel,
      aiInsight:    insight,
      evaluations:  evals,
    );
  }
}

/// A single question within a session (returned by GET /practice-sessions/:id).
class PracticeSessionQuestion {
  final String id;
  final int order;
  final String question;
  final String questionType;
  final String difficulty;
  final String? skill;
  final String? answerText;

  const PracticeSessionQuestion({
    required this.id,
    required this.order,
    required this.question,
    required this.questionType,
    required this.difficulty,
    this.skill,
    this.answerText,
  });

  factory PracticeSessionQuestion.fromJson(Map<String, dynamic> j) {
    return PracticeSessionQuestion(
      id:           (j['id'] ?? j['questionId'] ?? '').toString(),
      order:        ((j['order'] ?? j['orderNumber'] ?? j['index'] ?? 1) as num).toInt(),
      question:     (j['question'] ?? j['text'] ?? j['questionText'] ?? j['content'] ?? '').toString(),
      questionType: (j['questionType'] ?? j['category'] ?? 'Technical').toString(),
      difficulty:   (j['difficulty'] ?? 'Medium').toString(),
      skill:        j['skill']?.toString(),
      answerText:   (j['answerText'] ?? j['answer'])?.toString(),
    );
  }
}

/// Lightweight session detail used by the result screen (GET /practice-sessions/:id).
class PracticeSessionDetail {
  final String id;
  final String questionSetId;
  final String status;
  final double? overallScore;
  final List<PracticeSessionQuestion> questions;

  const PracticeSessionDetail({
    required this.id,
    required this.questionSetId,
    required this.status,
    this.overallScore,
    required this.questions,
  });

  factory PracticeSessionDetail.fromJson(Map<String, dynamic> j) {
    final raw = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;

    final rawQ = raw['questions'] ?? raw['questionList'] ?? const [];
    final questions = (rawQ as List)
        .whereType<Map<String, dynamic>>()
        .map(PracticeSessionQuestion.fromJson)
        .toList();

    return PracticeSessionDetail(
      id:            (raw['id'] ?? raw['sessionId'] ?? '').toString(),
      questionSetId: (raw['questionSetId'] ?? raw['setId'] ?? '').toString(),
      status:        (raw['status'] ?? 'COMPLETED').toString(),
      overallScore:  (raw['overallScore'] as num?)?.toDouble(),
      questions:     questions,
    );
  }
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
