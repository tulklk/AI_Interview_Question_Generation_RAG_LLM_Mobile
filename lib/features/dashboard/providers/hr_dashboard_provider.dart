import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../hr_generate/data/studio_repository.dart';
import '../../hr_generate/domain/models/generation_session.dart';
import '../../hr_generate/domain/models/studio_models.dart';
import '../../hr_generate/domain/enums/generation_status.dart';

// ── Time range ────────────────────────────────────────────────────────────────

enum DashboardTimeRange {
  today,
  days7,
  days30,
  month;

  String get label => switch (this) {
        today  => 'Hôm nay',
        days7  => '7 ngày',
        days30 => '30 ngày',
        month  => 'Tháng này',
      };

  DateTime get startDate {
    final now = DateTime.now();
    return switch (this) {
      today  => DateTime(now.year, now.month, now.day),
      days7  => now.subtract(const Duration(days: 7)),
      days30 => now.subtract(const Duration(days: 30)),
      month  => DateTime(now.year, now.month, 1),
    };
  }
}

final dashboardTimeRangeProvider =
    StateProvider<DashboardTimeRange>((_) => DashboardTimeRange.days7);

// ── DashboardStats ────────────────────────────────────────────────────────────

class DashboardStats {
  final List<GenerationSession> allSessions;
  final List<GenerationSession> filteredSessions;
  final DashboardTimeRange range;

  final int totalSessions;
  final int totalQuestions;
  final int completedSessions;
  final int failedSessions;
  final int processingSessions;
  final int pendingSessions;

  /// 0.0–1.0 — only from completed + failed; -1 = no terminal sessions yet
  final double successRate;
  final double avgQuestionsPerSession;

  /// 7 slots Mon(0)…Sun(6) rolling last-7-days count
  final List<int> weeklyActivity;

  /// level label → count  (excludes Unknown)
  final Map<String, int> levelBreakdown;
  final int unknownLevelCount;
  final bool hasUsefulLevelData;

  /// Vietnamese type label → count
  final Map<String, int> questionTypeBreakdown;

  /// skill/topic → count, top 8 sorted desc
  final Map<String, int> topSkills;

  /// jobTitle → count, top 5 sorted desc
  final Map<String, int> topRoles;

  const DashboardStats({
    required this.allSessions,
    required this.filteredSessions,
    required this.range,
    required this.totalSessions,
    required this.totalQuestions,
    required this.completedSessions,
    required this.failedSessions,
    required this.processingSessions,
    required this.pendingSessions,
    required this.successRate,
    required this.avgQuestionsPerSession,
    required this.weeklyActivity,
    required this.levelBreakdown,
    required this.unknownLevelCount,
    required this.hasUsefulLevelData,
    required this.questionTypeBreakdown,
    required this.topSkills,
    required this.topRoles,
  });

  static DashboardStats derive(
    List<GenerationSession> all,
    DashboardTimeRange range,
  ) {
    final start = range.startDate;
    final now   = DateTime.now();

    final filtered = all.where((s) {
      final d = DateTime.tryParse(s.createdAt);
      return d != null && !d.isBefore(start);
    }).toList();

    final weeklyActivity     = List<int>.filled(7, 0);
    final levelBreakdown     = <String, int>{};
    final qtBreakdown        = <String, int>{};
    final skillMap           = <String, int>{};
    final roleMap            = <String, int>{};
    int totalQuestions       = 0;
    int completedSessions    = 0;
    int failedSessions       = 0;
    int processingSessions   = 0;
    int pendingSessions      = 0;
    int unknownLevelCount    = 0;

    for (final s in filtered) {
      totalQuestions += s.generatedQuestions.length;

      switch (s.status) {
        case GenerationStatus.completed:
          completedSessions++;
        case GenerationStatus.failed:
          failedSessions++;
        case GenerationStatus.planQueued:
        case GenerationStatus.planProposed:
        case GenerationStatus.confirmed:
        case GenerationStatus.queued:
        case GenerationStatus.questionQueued:
        case GenerationStatus.questionProcessing:
        case GenerationStatus.processing:
          processingSessions++;
        case GenerationStatus.draft:
          pendingSessions++;
      }

      final d = DateTime.tryParse(s.createdAt);
      if (d != null) {
        final diff = now.difference(d).inDays;
        if (diff >= 0 && diff < 7) weeklyActivity[d.weekday - 1]++;
      }

      final rawLevel = s.planDraft?.level ?? '';
      if (rawLevel.isEmpty || rawLevel.toLowerCase() == 'unknown') {
        unknownLevelCount++;
      } else {
        levelBreakdown[rawLevel] = (levelBreakdown[rawLevel] ?? 0) + 1;
      }

      if (s.planDraft != null) {
        for (final qt in s.planDraft!.questionTypes) {
          final label = _qtLabel(qt.displayName);
          qtBreakdown[label] = (qtBreakdown[label] ?? 0) + 1;
        }
        for (final skill in s.planDraft!.topics) {
          if (skill.isNotEmpty) {
            skillMap[skill] = (skillMap[skill] ?? 0) + 1;
          }
        }
      }

      final title = s.jobTitle.trim();
      if (title.isNotEmpty) roleMap[title] = (roleMap[title] ?? 0) + 1;
    }

    final finished = completedSessions + failedSessions;
    final successRate =
        finished > 0 ? completedSessions / finished : -1.0;
    final avgQ = filtered.isEmpty ? 0.0 : totalQuestions / filtered.length;

    final knownLevelTotal =
        levelBreakdown.values.fold(0, (a, b) => a + b);
    final hasUsefulLevelData =
        levelBreakdown.isNotEmpty && knownLevelTotal > unknownLevelCount * 0.25;

    return DashboardStats(
      allSessions:         all,
      filteredSessions:    filtered,
      range:               range,
      totalSessions:       filtered.length,
      totalQuestions:      totalQuestions,
      completedSessions:   completedSessions,
      failedSessions:      failedSessions,
      processingSessions:  processingSessions,
      pendingSessions:     pendingSessions,
      successRate:         successRate,
      avgQuestionsPerSession: avgQ,
      weeklyActivity:      weeklyActivity,
      levelBreakdown:      levelBreakdown,
      unknownLevelCount:   unknownLevelCount,
      hasUsefulLevelData:  hasUsefulLevelData,
      questionTypeBreakdown: Map.fromEntries(
          (qtBreakdown.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(6)),
      topSkills: Map.fromEntries(
          (skillMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(8)),
      topRoles: Map.fromEntries(
          (roleMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)),
    );
  }

  static String _qtLabel(String displayName) => switch (displayName) {
        'Technical'      => 'Kỹ thuật',
        'Behavioral'     => 'Hành vi',
        'Situational'    => 'Tình huống',
        'System-design'  => 'Thiết kế HT',
        'Problem-solving' => 'Giải quyết VĐ',
        _                => displayName,
      };
}

// ── Map StudioProject → GenerationSession for dashboard stats ─────────────────

GenerationStatus _studioStatusToGen(StudioProjectStatus s) => switch (s) {
      StudioProjectStatus.generated ||
      StudioProjectStatus.archived   => GenerationStatus.completed,
      StudioProjectStatus.approved   => GenerationStatus.questionQueued,
      StudioProjectStatus.awaitingApproval ||
      StudioProjectStatus.refining   => GenerationStatus.planProposed,
      StudioProjectStatus.draft      => GenerationStatus.draft,
    };

GenerationSession _projectToSession(StudioProject p) => GenerationSession(
      id:        p.id,
      jobTitle:  p.name,
      status:    _studioStatusToGen(p.status),
      rawPhase:  p.status.toApiString(),
      createdAt: DateTime.now().toIso8601String(),
      questionSetId: p.questionSetId,
    );

// ── Raw sessions ──────────────────────────────────────────────────────────────

final hrSessionsRawProvider =
    FutureProvider.autoDispose<List<GenerationSession>>((ref) async {
  final repo = StudioRepository();
  final projects = await repo.listProjects();
  return projects.map(_projectToSession).toList();
});

// ── Derived stats (instant, no extra API call on filter change) ───────────────

final hrDashboardProvider =
    Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final range = ref.watch(dashboardTimeRangeProvider);
  return ref
      .watch(hrSessionsRawProvider)
      .whenData((s) => DashboardStats.derive(s, range));
});

