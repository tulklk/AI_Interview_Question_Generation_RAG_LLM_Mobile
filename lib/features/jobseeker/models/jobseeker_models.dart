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
}

// ── QuestionSet ───────────────────────────────────────────────────────────────

class QuestionSet {
  final String id;
  final String title;
  final String company;
  final String companyInitials;
  final Color companyColor;
  final QuestionDifficulty difficulty;
  final List<String> skills;
  final int totalQuestions; // display count (may differ from questions.length)
  final String estimatedTime;
  final String category;
  final String description;
  final double? rating;
  final int? attempts;
  final List<PracticeQuestion> questions;

  const QuestionSet({
    required this.id,
    required this.title,
    required this.company,
    required this.companyInitials,
    required this.companyColor,
    required this.difficulty,
    required this.skills,
    required this.totalQuestions,
    required this.estimatedTime,
    required this.category,
    required this.description,
    this.rating,
    this.attempts,
    required this.questions,
  });
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
    required this.date,
    required this.score,
    required this.duration,
    required this.skills,
    required this.totalQuestions,
    required this.answers,
  });
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
