import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../data/providers/app_providers.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';
import '../marketplace/marketplace_screen.dart';

class JobseekerDashboardScreen extends ConsumerWidget {
  const JobseekerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'User';
    final hour = DateTime.now().hour;
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 840;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeHeader(
              greeting: l10n.greetingFor(hour),
              name: name,
              l10n: l10n,
              isDark: isDark,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 16),

            _InProgressSection(isDark: isDark).animate().fadeIn(delay: 60.ms),

            _KpiSection(isDark: isDark)
                .animate()
                .fadeIn(delay: 80.ms, duration: 400.ms)
                .slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            _SectionTitle(title: l10n.performanceAnalytics, isDark: isDark)
                .animate()
                .fadeIn(delay: 120.ms),
            const SizedBox(height: 12),
            _TrendChartCard(isDark: isDark)
                .animate()
                .fadeIn(delay: 160.ms, duration: 400.ms),

            const SizedBox(height: 24),

            _ConsistencyCard(isDark: isDark)
                .animate()
                .fadeIn(delay: 180.ms, duration: 400.ms),

            const SizedBox(height: 24),

            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _RecentPracticeSection(l10n: l10n, isDark: isDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _SkillBarsSection(l10n: l10n, isDark: isDark),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms)
            else
              Column(
                children: [
                  _RecentPracticeSection(l10n: l10n, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  _SkillBarsSection(l10n: l10n, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 240.ms),
                ],
              ),

            const SizedBox(height: 24),

            _AICoachCard(l10n: l10n)
                .animate()
                .fadeIn(delay: 260.ms)
                .slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: l10n.recommendedForYou, isDark: isDark),
                GestureDetector(
                  onTap: () => context.go('/jobseeker'),
                  child: Text(
                    l10n.browseAll,
                    style: const TextStyle(
                      color: Color(0xFF6C47FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 4),
            Text(
              l10n.recommendedSubtitle,
              style: TextStyle(
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 12),
            _RecommendedSets(isDark: isDark, isWide: isWide)
                .animate()
                .fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ── Welcome Header ────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final AppLocalizations l10n;
  final bool isDark;

  const _WelcomeHeader({
    required this.greeting,
    required this.name,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name 👋',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dashboardGreetingSubtitle,
          style: TextStyle(
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── KPI Section (real data) ───────────────────────────────────────────────────

class _KpiSection extends ConsumerWidget {
  final bool isDark;
  const _KpiSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isVi = l10n.isVi;
    final stats = ref.watch(practiceStatsProvider).valueOrNull;
    final streak = ref.watch(practiceStreakProvider);

    String readiness;
    Color readinessColor;
    if (stats == null || stats.totalSessions == 0) {
      readiness = '—';
      readinessColor = const Color(0xFF6B7280);
    } else if (stats.avgScore >= 80) {
      readiness = isVi ? 'Cao' : 'High';
      readinessColor = const Color(0xFF10B981);
    } else if (stats.avgScore >= 65) {
      readiness = isVi ? 'Tốt' : 'Good';
      readinessColor = const Color(0xFF6C47FF);
    } else {
      readiness = isVi ? 'Khá' : 'Fair';
      readinessColor = const Color(0xFFF59E0B);
    }

    final streakTrend = streak >= 7
        ? l10n.personalBest
        : streak > 0
            ? (isVi ? 'Tiếp tục chuỗi!' : 'Keep it up!')
            : (isVi ? 'Bắt đầu hôm nay' : 'Start today');

    final cards = [
      _StatData(
        icon: Icons.menu_book_rounded,
        iconColor: Colors.blue,
        value: stats != null ? '${stats.totalSessions}' : '—',
        label: l10n.practiceSessions,
        trend: isVi ? 'Đã hoàn thành' : 'Completed',
      ),
      _StatData(
        icon: Icons.gps_fixed_rounded,
        iconColor: const Color(0xFF6C47FF),
        value: stats != null ? '${stats.avgScore}%' : '—',
        label: l10n.averageScore,
        trend: stats != null
            ? (isVi
                ? 'Tốt nhất: ${stats.bestScore}%'
                : 'Best: ${stats.bestScore}%')
            : '—',
      ),
      _StatData(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFF59E0B),
        value: streak > 0 ? '$streak${isVi ? ' ngày' : 'd'}' : '0',
        label: l10n.practiceStreak,
        trend: streakTrend,
      ),
      _StatData(
        icon: Icons.trending_up_rounded,
        iconColor: readinessColor,
        value: readiness,
        label: l10n.interviewReadiness,
        trend: l10n.aiAssessed,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[0], isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(data: cards[1], isDark: isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[2], isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(data: cards[3], isDark: isDark)),
          ],
        ),
      ],
    );
  }
}

class _StatData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String trend;

  const _StatData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.trend,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool isDark;

  const _StatCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.trend,
            style: TextStyle(
              color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Performance Trend Chart (real data) ───────────────────────────────────────

class _TrendChartCard extends ConsumerWidget {
  final bool isDark;
  const _TrendChartCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ref.watch(practiceHistoryProvider).when(
      loading: () => _skeleton(),
      error: (_, __) => _emptyState(l10n),
      data: (sessions) {
        if (sessions.isEmpty) return _emptyState(l10n);

        // Oldest → newest for left-to-right display
        final recent = sessions.take(7).toList().reversed.toList();
        final spots = recent
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
            .toList();

        final avgScore = sessions
                .map((s) => s.score)
                .reduce((a, b) => a + b) /
            sessions.length;

        final gridColor =
            isDark ? const Color(0xFF1E2640) : const Color(0xFFF3F4F6);
        final labelColor =
            isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: _cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.isVi
                        ? '${recent.length} phiên gần nhất'
                        : 'Last ${recent.length} sessions',
                    style: TextStyle(color: labelColor, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TB: ${avgScore.round()}%',
                      style: const TextStyle(
                        color: Color(0xFF6C47FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: spots.length > 2,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF6C47FF),
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 3.5,
                            color: const Color(0xFF6C47FF),
                            strokeWidth: 2,
                            strokeColor: isDark
                                ? const Color(0xFF1A1F35)
                                : Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C47FF).withValues(alpha: 0.15),
                              const Color(0xFF6C47FF).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                    clipData: const FlClipData.all(),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 50,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == 50 || value == 100) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  '${value.toInt()}',
                                  style:
                                      TextStyle(color: labelColor, fontSize: 9),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= recent.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${index + 1}',
                                style:
                                    TextStyle(color: labelColor, fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skeleton() {
    return _PulsingBox(height: 210, isDark: isDark);
  }

  Widget _emptyState(AppLocalizations l10n) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 28,
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.isVi
                  ? 'Hoàn thành phiên luyện tập để xem biểu đồ tiến độ'
                  : 'Complete practice sessions to see your progress chart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Practice (real data) ───────────────────────────────────────────────

class _RecentPracticeSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _RecentPracticeSection({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: l10n.recentPractice, isDark: isDark),
                Text(
                  l10n.latestSessions,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/jobseeker/history'),
              child: Text(
                l10n.viewAllHistory,
                style: const TextStyle(
                  color: Color(0xFF6C47FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ref.watch(practiceHistoryProvider).when(
          loading: () => Column(
            children: List.generate(
              3,
              (i) => Padding(
                key: ValueKey('rp_sk_$i'),
                padding: const EdgeInsets.only(bottom: 10),
                child: _PulsingBox(height: 72, isDark: isDark),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(isDark),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 28,
                        color: isDark
                            ? const Color(0xFF2D3562)
                            : const Color(0xFFE5E7EB),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.isVi
                            ? 'Chưa có phiên nào hoàn thành'
                            : 'No completed sessions yet',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: sessions
                  .take(3)
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SessionTile(session: s, isDark: isDark),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final PracticeSession session;
  final bool isDark;

  const _SessionTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scoreC = scoreColor(session.score > 0 ? session.score : 50);

    return GestureDetector(
      onTap: () => context.go('/jobseeker/practice/${session.setId}/result'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final logoUrl = session.companyLogo ??
                    ref
                        .watch(setDetailProvider(session.setId))
                        .maybeWhen(
                          data: (qs) => qs?.companyLogo,
                          orElse: () => null,
                        );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: logoUrl != null
                      ? Image.network(
                          logoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CompanyAvatar(
                            color: session.companyColor,
                            initials: session.companyInitials,
                            size: 40,
                            fontSize: 14,
                          ),
                        )
                      : _CompanyAvatar(
                          color: session.companyColor,
                          initials: session.companyInitials,
                          size: 40,
                          fontSize: 14,
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.setTitle.isNotEmpty
                        ? session.setTitle
                        : session.company,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF4A5578)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          session.date.isNotEmpty
                              ? '${session.date} · ${session.duration}'
                              : session.duration,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF4A5578)
                                : const Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreC.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scoreC.withValues(alpha: 0.3)),
              ),
              child: Text(
                session.score > 0 ? '${session.score}%' : '—',
                style: TextStyle(
                  color: scoreC,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skill Bars (derived from real history) ────────────────────────────────────

class _SkillBarData {
  final String label;
  final double pct;

  const _SkillBarData({required this.label, required this.pct});
}

class _SkillBarsSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _SkillBarsSection({required this.l10n, required this.isDark});

  List<_SkillBarData> _deriveSkills(List<PracticeSession> sessions) {
    final skillTotals = <String, List<int>>{};
    for (final s in sessions) {
      if (s.skills.isEmpty || s.score == 0) continue;
      for (final skill in s.skills) {
        if (skill.isEmpty) continue;
        skillTotals.putIfAbsent(skill, () => []).add(s.score);
      }
    }
    if (skillTotals.isEmpty) return [];

    return (skillTotals.entries.map((e) {
      final avg =
          e.value.reduce((a, b) => a + b) / e.value.length;
      return _SkillBarData(label: e.key, pct: avg / 100.0);
    }).toList()
      ..sort((a, b) => b.pct.compareTo(a.pct)));
  }

  Color _barColor(double pct) {
    if (pct >= 0.75) return const Color(0xFF10B981);
    if (pct >= 0.6) return const Color(0xFF6C47FF);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(practiceHistoryProvider).when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        final skills = _deriveSkills(sessions);

        if (skills.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: l10n.strongestSkills, isDark: isDark),
              const SizedBox(height: 10),
              Text(
                l10n.isVi
                    ? 'Hoàn thành thêm phiên để xem phân tích kỹ năng'
                    : 'Complete more sessions to see skill analysis',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          );
        }

        final midpoint = (skills.length / 2).ceil();
        final strong = skills.take(midpoint).toList();
        final weak = skills.length > 2
            ? skills.skip(midpoint).toList()
            : <_SkillBarData>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: l10n.strongestSkills, isDark: isDark),
            const SizedBox(height: 10),
            ...strong.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnimatedBar(
                    label: s.label,
                    pct: s.pct,
                    color: _barColor(s.pct),
                    isDark: isDark,
                  ),
                )),
            if (weak.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(title: l10n.areasToImprove, isDark: isDark),
              const SizedBox(height: 10),
              ...weak.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AnimatedBar(
                      label: s.label,
                      pct: s.pct,
                      color: _barColor(s.pct),
                      isDark: isDark,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final String label;
  final double pct;
  final Color color;
  final bool isDark;

  const _AnimatedBar({
    required this.label,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _anim.value * widget.pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${(widget.pct * 100).round()}%',
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── AI Coach Card (contextual) ────────────────────────────────────────────────

class _AICoachCard extends ConsumerWidget {
  final AppLocalizations l10n;

  const _AICoachCard({required this.l10n});

  String _buildInsight(PracticeStats? stats, int streak) {
    final isVi = l10n.isVi;

    if (stats == null || stats.totalSessions == 0) {
      return isVi
          ? 'Bắt đầu phiên luyện tập đầu tiên để nhận gợi ý AI cá nhân hóa dựa trên kết quả của bạn.'
          : 'Complete your first practice session to unlock personalized AI coaching based on your performance.';
    }

    if (stats.avgScore >= 80) {
      return isVi
          ? 'Xuất sắc! Điểm TB ${stats.avgScore}% rất ấn tượng. Thử thách bản thân với bộ câu hỏi khó hơn hoặc luyện System Design để tăng tính cạnh tranh.'
          : 'Outstanding! Avg ${stats.avgScore}% is top-tier. Push further with harder sets or System Design practice to stay competitive.';
    }

    if (stats.avgScore >= 65) {
      return isVi
          ? 'Tiến bộ tốt! Sau ${stats.totalSessions} phiên với điểm TB ${stats.avgScore}%, tập trung vào câu hỏi Tình huống và Hành vi để nâng điểm lên 80+.'
          : 'Good progress! After ${stats.totalSessions} sessions at avg ${stats.avgScore}%, focus on Situational and Behavioral questions to push your score above 80.';
    }

    return isVi
        ? 'Hãy tiếp tục! ${stats.totalSessions} phiên hoàn thành là khởi đầu tốt. Điểm TB ${stats.avgScore}% cho thấy tiềm năng lớn — luyện tập đều đặn mỗi ngày sẽ giúp bạn cải thiện nhanh chóng.'
        : 'Keep going! ${stats.totalSessions} sessions is a solid start. Avg ${stats.avgScore}% shows great potential — consistent daily practice accelerates improvement significantly.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(practiceStatsProvider).valueOrNull;
    final streak = ref.watch(practiceStreakProvider);
    final message = _buildInsight(stats, streak);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6C47FF), Color(0xFF1A47CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.aiRecommendation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.go('/jobseeker'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.startPractice,
                style: const TextStyle(
                  color: Color(0xFF6C47FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommended Sets (real marketplace data) ──────────────────────────────────

class _RecommendedSets extends ConsumerWidget {
  final bool isDark;
  final bool isWide;

  const _RecommendedSets({required this.isDark, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceApiProvider);

    if (state.isLoading) {
      return Column(
        children: List.generate(
          isWide ? 1 : 2,
          (i) => Padding(
            key: ValueKey('rs_sk_$i'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _PulsingBox(height: 120, isDark: isDark),
          ),
        ),
      );
    }

    final sets = state.sets.take(3).toList();

    if (sets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(isDark),
        child: Center(
          child: Text(
            context.l10n.isVi
                ? 'Không tìm thấy bộ câu hỏi'
                : 'No question sets available',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (isWide) {
      return Row(
        children: sets
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: e.key < sets.length - 1 ? 12 : 0),
                    child: QuestionSetCard(set: e.value, isDark: isDark)
                        .animate()
                        .fadeIn(delay: (e.key * 80).ms),
                  ),
                ))
            .toList(),
      );
    }

    return Column(
      children: sets
          .asMap()
          .entries
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuestionSetCard(set: e.value, isDark: isDark)
                    .animate()
                    .fadeIn(delay: (e.key * 80).ms),
              ))
          .toList(),
    );
  }
}

// ── In-Progress Section ───────────────────────────────────────────────────────

class _InProgressSection extends ConsumerWidget {
  final bool isDark;
  const _InProgressSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref
        .watch(allInProgressSessionsProvider)
        .maybeWhen(data: (list) => list, orElse: () => <InProgressSummary>[]);

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                size: 16, color: Color(0xFF6C47FF)),
            const SizedBox(width: 6),
            Text(
              'Phiên đang dở',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...sessions.map((s) => _InProgressCard(session: s, isDark: isDark)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InProgressCard extends StatelessWidget {
  final InProgressSummary session;
  final bool isDark;
  const _InProgressCard({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = session.totalQuestions;
    final done = session.answeredCount;
    final pct = total > 0 ? done / total : 0.0;

    return GestureDetector(
      onTap: () => context.go('/jobseeker/practice/${session.setId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6C47FF).withValues(alpha: 0.3),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6C47FF).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final logoUrl = session.companyLogo ??
                    ref
                        .watch(setDetailProvider(session.setId))
                        .maybeWhen(
                          data: (qs) => qs?.companyLogo,
                          orElse: () => null,
                        );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: logoUrl != null
                      ? Image.network(
                          logoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CompanyAvatar(
                            color: session.companyColor,
                            initials: session.companyInitials,
                            size: 40,
                            fontSize: 13,
                          ),
                        )
                      : _CompanyAvatar(
                          color: session.companyColor,
                          initials: session.companyInitials,
                          size: 40,
                          fontSize: 13,
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.setTitle.isNotEmpty
                        ? session.setTitle
                        : 'Phiên luyện tập',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total > 0
                        ? '$done/$total câu đã trả lời'
                        : 'Đang tiếp tục...',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: isDark
                          ? const Color(0xFF2D3562)
                          : const Color(0xFFE5E7EB),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF6C47FF)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _CompanyAvatar extends StatelessWidget {
  final Color color;
  final String initials;
  final double size;
  final double fontSize;

  const _CompanyAvatar({
    required this.color,
    required this.initials,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF111827),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
      color: isDark ? const Color(0xFF1A1F35) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
    );

// ── Pulsing skeleton box (replaces shimmer to avoid GlobalKey conflicts) ───────

class _PulsingBox extends StatefulWidget {
  final double height;
  final bool isDark;

  const _PulsingBox({
    required this.height,
    required this.isDark,
  });

  @override
  State<_PulsingBox> createState() => _PulsingBoxState();
}

class _PulsingBoxState extends State<_PulsingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity =
      Tween<double>(begin: 0.4, end: 0.85).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color:
              widget.isDark ? const Color(0xFF1A1F35) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark
                ? const Color(0xFF2D3562)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
    );
  }
}

// ── Practice Consistency Card (heatmap) ───────────────────────────────────────

class _ConsistencyCard extends ConsumerWidget {
  final bool isDark;
  const _ConsistencyCard({required this.isDark});

  static const _weeks = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isVi = l10n.isVi;
    final stats = ref.watch(practiceConsistencyProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6C47FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVi
                          ? 'Mức độ đều đặn luyện tập'
                          : 'Practice Consistency',
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isVi
                          ? 'Số phiên luyện tập mỗi ngày trong $_weeks tuần gần nhất'
                          : 'Practice sessions per day in the last $_weeks weeks',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _ConsistencyChip(
                value: '${stats.currentStreak}',
                label: isVi ? 'Chuỗi hiện tại' : 'Current streak',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ConsistencyChip(
                value: '${stats.longestStreak}',
                label: isVi ? 'Chuỗi dài nhất' : 'Longest streak',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ConsistencyChip(
                value: '${stats.activeDays}',
                label: isVi ? 'Ngày hoạt động' : 'Active days',
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Heatmap grid
          _HeatmapGrid(
            activityByDay: stats.activityByDay,
            isDark: isDark,
            weeks: _weeks,
          ),

          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVi ? 'Ít' : 'Less',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _heatmapCellColor(i, isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                isVi ? 'Nhiều' : 'More',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _heatmapCellColor(int count, bool isDark) {
  if (count <= 0) {
    return isDark ? const Color(0xFF1A2040) : const Color(0xFFEEF2FF);
  }
  if (count == 1) return const Color(0xFF8B5CF6).withValues(alpha: 0.45);
  if (count == 2) return const Color(0xFF7C3AED).withValues(alpha: 0.65);
  if (count == 3) return const Color(0xFF6D28D9).withValues(alpha: 0.85);
  return const Color(0xFF6C47FF);
}

class _ConsistencyChip extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _ConsistencyChip({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1729) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<DateTime, int> activityByDay;
  final bool isDark;
  final int weeks;

  const _HeatmapGrid({
    required this.activityByDay,
    required this.isDark,
    required this.weeks,
  });

  static const _cellSize = 10.0;
  static const _cellGap = 2.5;
  static const _cellStep = _cellSize + _cellGap;
  static const _labelWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Align start to Monday of the week (weeks-1) ago
    final daysFromMonday = (today.weekday - 1) % 7;
    final thisMonday = today.subtract(Duration(days: daysFromMonday));
    final startMonday =
        thisMonday.subtract(Duration(days: (weeks - 1) * 7));

    final weekStarts = List.generate(
      weeks,
      (i) => startMonday.add(Duration(days: i * 7)),
    );

    // Month label at first week of each new month
    final monthLabels = <int, String>{};
    int? prevMonth;
    for (int col = 0; col < weeks; col++) {
      final m = weekStarts[col].month;
      if (m != prevMonth) {
        monthLabels[col] = 'Th$m';
        prevMonth = m;
      }
    }

    // Row 0=Mon … 6=Sun; show labels for Mon(0), Wed(2), Sat(5)
    const dayLabelMap = {0: 'T2', 2: 'T4', 5: 'T7'};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _labelWidth + weeks * _cellStep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels row
            SizedBox(
              height: 14,
              child: Row(
                children: [
                  const SizedBox(width: _labelWidth),
                  ...List.generate(weeks, (col) {
                    final label = monthLabels[col];
                    return SizedBox(
                      width: _cellStep,
                      child: label != null
                          ? Text(
                              label,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF4A5578)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 8,
                              ),
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 3),

            // Day rows (Mon … Sun)
            ...List.generate(7, (row) {
              final label = dayLabelMap[row];
              return Padding(
                padding: EdgeInsets.only(bottom: row < 6 ? _cellGap : 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: label != null
                          ? Text(
                              label,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF4A5578)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 8,
                              ),
                            )
                          : null,
                    ),
                    ...List.generate(weeks, (col) {
                      final weekStart = weekStarts[col];
                      final dayDate = weekStart.add(Duration(days: row));
                      final normalized = DateTime(
                          dayDate.year, dayDate.month, dayDate.day);
                      final isFuture = normalized.isAfter(today);
                      final count = isFuture
                          ? -1
                          : (activityByDay[normalized] ?? 0);

                      return Padding(
                        padding: EdgeInsets.only(
                            right: col < weeks - 1 ? _cellGap : 0),
                        child: Container(
                          width: _cellSize,
                          height: _cellSize,
                          decoration: BoxDecoration(
                            color: isFuture
                                ? Colors.transparent
                                : _heatmapCellColor(count, isDark),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
