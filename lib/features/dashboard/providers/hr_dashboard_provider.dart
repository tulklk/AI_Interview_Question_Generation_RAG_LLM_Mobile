import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../hr_generate/data/generation_api.dart';
import '../../hr_generate/domain/models/generation_session.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class DashboardStats {
  final List<GenerationSession> sessions;
  final int totalSessions;
  final int totalQuestions;
  final int thisMonth;
  /// 7 values: Mon(0)…Sun(6) — job count in the last 7 rolling days
  final List<int> weeklyActivity;
  /// level → count (from planDraft.level)
  final Map<String, int> levelBreakdown;

  const DashboardStats({
    required this.sessions,
    required this.totalSessions,
    required this.totalQuestions,
    required this.thisMonth,
    required this.weeklyActivity,
    required this.levelBreakdown,
  });

  static const empty = DashboardStats(
    sessions:        [],
    totalSessions:   0,
    totalQuestions:  0,
    thisMonth:       0,
    weeklyActivity:  [0, 0, 0, 0, 0, 0, 0],
    levelBreakdown:  {},
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final hrDashboardProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final dio = buildGenerationDio();
  final res = await dio.get('/api/hr/question-generation-jobs');

  final rawList = _extractList(res.data);
  final sessions = rawList
      .whereType<Map<String, dynamic>>()
      .map((j) => GenerationSession.fromJson(j))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final now            = DateTime.now();
  final monthStart     = DateTime(now.year, now.month, 1);
  final weeklyActivity = List<int>.filled(7, 0);
  final levelBreakdown = <String, int>{};
  int totalQuestions   = 0;
  int thisMonth        = 0;

  for (final s in sessions) {
    totalQuestions += s.generatedQuestions.length;

    final createdAt = DateTime.tryParse(s.createdAt);
    if (createdAt != null) {
      if (!createdAt.isBefore(monthStart)) thisMonth++;

      final diff = now.difference(createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        final dow = createdAt.weekday - 1; // 0=Mon … 6=Sun
        weeklyActivity[dow]++;
      }
    }

    final level = s.planDraft?.level ?? 'Unknown';
    levelBreakdown[level] = (levelBreakdown[level] ?? 0) + 1;
  }

  return DashboardStats(
    sessions:       sessions,
    totalSessions:  sessions.length,
    totalQuestions: totalQuestions,
    thisMonth:      thisMonth,
    weeklyActivity: weeklyActivity,
    levelBreakdown: levelBreakdown,
  );
});

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['data'];
    if (inner is List)  return inner;
    if (inner is Map) {
      final items = inner['items'] ?? inner['jobs'] ?? inner['data'];
      if (items is List) return items;
    }
    final top = data['items'] ?? data['jobs'];
    if (top is List) return top;
  }
  return [];
}
