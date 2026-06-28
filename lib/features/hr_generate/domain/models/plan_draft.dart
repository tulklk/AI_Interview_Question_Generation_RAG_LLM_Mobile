import 'dart:convert';
import '../enums/question_type.dart';

class PlanDraft {
  final String role;
  final String level;       // display: Intern / Junior / Mid-level / Senior / Lead / Manager
  final String difficulty;  // display: Easy / Medium / Hard
  final int questionCount;
  final List<HrQuestionType> questionTypes;
  final List<String> topics;
  final String? constraints;
  final String? summary;

  const PlanDraft({
    required this.role,
    required this.level,
    required this.difficulty,
    required this.questionCount,
    required this.questionTypes,
    this.topics = const [],
    this.constraints,
    this.summary,
  });

  // ── Experience level helpers ───────────────────────────────────────────────

  static String experienceLevelDisplay(String? raw) {
    if (raw == null) return 'Junior';
    final k = raw.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    switch (k) {
      case 'intern':   return 'Intern';
      case 'junior':   return 'Junior';
      case 'mid':
      case 'medium':
      case 'midlevel': return 'Mid-level';
      case 'senior':   return 'Senior';
      case 'lead':     return 'Lead';
      case 'manager':  return 'Manager';
      default:         return 'Junior';
    }
  }

  // "Mid-level" → "mid", "Senior" → "senior"
  static String levelToApiString(String display) {
    final k = display.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    if (k == 'midlevel') return 'mid';
    return k;
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory PlanDraft.fromJson(Map<String, dynamic> j) {
    final role = (j['roleTitle'] ?? j['role'] ?? '').toString();
    final level = experienceLevelDisplay(
        (j['experienceLevel'] ?? j['level'] ?? j['experience_level'] ?? '').toString());
    final difficulty = _capitalise(
        (j['difficulty'] ?? j['level'] ?? 'medium').toString());
    final count = ((j['totalQuestions'] ?? j['numberOfQuestions'] ??
                j['questionCount'] ?? 10) as num)
        .toInt();

    final rawTypes = j['questionTypes'] ?? j['skills'] ?? <dynamic>[];
    final types = rawTypes is List
        ? rawTypes.map((e) => HrQuestionType.fromString(e.toString())).toList()
        : <HrQuestionType>[];

    final rawTopics = j['skills'] ?? j['topics'] ?? <dynamic>[];
    final topics = rawTopics is List
        ? rawTopics.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return PlanDraft(
      role:          role,
      level:         level,
      difficulty:    difficulty,
      questionCount: count,
      questionTypes: types.isEmpty
          ? [HrQuestionType.technical, HrQuestionType.behavioral]
          : types,
      topics:        topics,
      constraints:   j['notes']?.toString() ?? j['constraints']?.toString(),
      summary:       j['summary']?.toString(),
    );
  }

  static String _capitalise(String s) =>
      s.isEmpty ? 'Medium' : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Map<String, dynamic> toJson() => {
        'roleTitle':       role,
        'totalQuestions':  questionCount,
        'questionTypes':
            questionTypes.map((t) => t.toApiString()).toList(),
        'skills':          topics,
        'notes':           constraints ?? '',
        'level':           difficulty.toLowerCase(),
        'experienceLevel': levelToApiString(level),
      };

  String toStorageJson() => jsonEncode({
        'role':           role,
        'level':          level,
        'difficulty':     difficulty,
        'questionCount':  questionCount,
        'questionTypes':
            questionTypes.map((t) => t.toApiString()).toList(),
        'topics':         topics,
        'constraints':    constraints,
        'summary':        summary,
      });

  factory PlanDraft.fromStorageJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final rawTypes = j['questionTypes'] as List? ?? [];
    return PlanDraft(
      role:          j['role'] as String? ?? '',
      level:         j['level'] as String? ?? 'Junior',
      difficulty:    j['difficulty'] as String? ?? 'Medium',
      questionCount: j['questionCount'] as int? ?? 10,
      questionTypes: rawTypes
          .map((e) => HrQuestionType.fromString(e.toString()))
          .toList(),
      topics:        (j['topics'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      constraints:   j['constraints'] as String?,
      summary:       j['summary'] as String?,
    );
  }

  PlanDraft copyWith({
    String? role,
    String? level,
    String? difficulty,
    int? questionCount,
    List<HrQuestionType>? questionTypes,
    List<String>? topics,
    String? constraints,
    String? summary,
  }) =>
      PlanDraft(
        role:          role ?? this.role,
        level:         level ?? this.level,
        difficulty:    difficulty ?? this.difficulty,
        questionCount: questionCount ?? this.questionCount,
        questionTypes: questionTypes ?? this.questionTypes,
        topics:        topics ?? this.topics,
        constraints:   constraints ?? this.constraints,
        summary:       summary ?? this.summary,
      );

  // Merge: prefer non-empty local values over server values
  PlanDraft mergeWith(PlanDraft server) => PlanDraft(
        role:          role.isNotEmpty ? role : server.role,
        level:         level.isNotEmpty ? level : server.level,
        difficulty:    difficulty.isNotEmpty ? difficulty : server.difficulty,
        questionCount: questionCount > 0 ? questionCount : server.questionCount,
        questionTypes: questionTypes.isNotEmpty
            ? questionTypes : server.questionTypes,
        topics:        topics.isNotEmpty ? topics : server.topics,
        constraints:   (constraints != null && constraints!.isNotEmpty)
            ? constraints : server.constraints,
        summary:       server.summary ?? summary,
      );
}
