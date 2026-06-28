import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_localizations.dart';
import '../../data/providers/app_providers.dart';

class HRDashboardScreen extends ConsumerWidget {
  const HRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final l10n      = context.l10n;
    final user      = ref.watch(authProvider).user;
    final name      = user?.name ?? 'HR Manager';
    final firstName = name.trim().split(' ').first;
    final greeting  = l10n.greetingFor(DateTime.now().hour);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Welcome ──────────────────────────────────────────────────
              _WelcomeSection(
                greeting:  greeting,
                firstName: firstName,
                isDark:    isDark,
              ),
              const SizedBox(height: 20),

              // ── Stats grid ───────────────────────────────────────────────
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StatCard(
                        label: l10n.totalJDs,
                        value: '24',
                        trend: l10n.trendThisMonth12,
                        icon:  Icons.description_rounded,
                        color: const Color(0xFF3B82F6),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: l10n.questionsGenerated,
                        value: '186',
                        trend: l10n.trendThisMonth28,
                        icon:  Icons.bolt_rounded,
                        color: const Color(0xFF7C3AED),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _StatCard(
                        label: l10n.thisWeek,
                        value: '12',
                        trend: l10n.trendLastWeek4,
                        icon:  Icons.trending_up_rounded,
                        color: const Color(0xFF10B981),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        label: l10n.avgQuestionsPerJD,
                        value: '7.75',
                        trend: l10n.trendImprovement,
                        icon:  Icons.bar_chart_rounded,
                        color: const Color(0xFFF59E0B),
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Weekly chart ─────────────────────────────────────────────
              _SectionCard(
                isDark: isDark,
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title:    l10n.weeklyActivity,
                      subtitle: l10n.questionsThisWeek,
                      isDark:   isDark,
                    ),
                    const SizedBox(height: 12),
                    _WeeklyLineChart(isDark: isDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LegendDot(color: const Color(0xFF6C47FF), label: l10n.questions),
                        const SizedBox(width: 16),
                        _LegendDot(color: const Color(0xFF34D399), label: l10n.jds),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Category bar chart ───────────────────────────────────────
              _SectionCard(
                isDark: isDark,
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title:    l10n.byCategory,
                      subtitle: l10n.questionTypeBreakdown,
                      isDark:   isDark,
                    ),
                    const SizedBox(height: 12),
                    _CategoryBarChart(isDark: isDark),
                    const SizedBox(height: 12),
                    _CategoryBars(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick generate promo ─────────────────────────────────────
              Container(
                padding:    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient:     const LinearGradient(
                    colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.generateQuestionsBtn,
                              style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            l10n.quickCreateDesc,
                            style: const TextStyle(
                                color:   Color(0xCCFFFFFF),
                                fontSize: 12,
                                height:  1.5),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () => context.go('/hr/generate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white60),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(l10n.startNow,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Recent sessions ──────────────────────────────────────────
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeader(
                          title:  l10n.recentActivity,
                          isDark: isDark,
                        ),
                        TextButton(
                          onPressed: () => context.go('/hr/history'),
                          child: Text(l10n.viewAll,
                              style: const TextStyle(
                                  color: Color(0xFF6C47FF), fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._mockSessions.map((s) => _SessionTile(
                          session: s,
                          isDark:  isDark,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  static const _mockSessions = [
    _SessionData(
        role: 'Senior Frontend Developer',
        category: 'Frontend',
        categoryColor: Color(0xFF3B82F6),
        count: 15,
        ago: '3 hours ago'),
    _SessionData(
        role: 'Product Manager',
        category: 'Product',
        categoryColor: Color(0xFF7C3AED),
        count: 12,
        ago: '1 day ago'),
    _SessionData(
        role: 'Data Scientist',
        category: 'Data',
        categoryColor: Color(0xFFF59E0B),
        count: 18,
        ago: '2 days ago'),
    _SessionData(
        role: 'Backend Developer',
        category: 'Backend',
        categoryColor: Color(0xFF10B981),
        count: 14,
        ago: '3 days ago'),
  ];
}

// ── Welcome section ───────────────────────────────────────────────────────────

class _WelcomeSection extends StatelessWidget {
  final String greeting;
  final String firstName;
  final bool isDark;

  const _WelcomeSection({
    required this.greeting,
    required this.firstName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $firstName 👋',
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening with your recruitment toolkit today.",
            style: TextStyle(
                color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 13,
                height:   1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.go('/hr/generate'),
            icon:  const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate Questions'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C47FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1F35)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? const Color(0xFF2D3562)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  32,
            height: 32,
            decoration: BoxDecoration(
              color:  color.withValues(alpha: 0.15),
              shape:  BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                color:    isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: const TextStyle(
                color:      Color(0xFF10B981),
                fontSize:   10,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Weekly line chart ─────────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final bool isDark;
  const _WeeklyLineChart({required this.isDark});

  static const _questions = [20.0, 25.0, 22.0, 38.0, 45.0, 30.0, 25.0];
  static const _jds       = [5.0,  8.0,  6.0,  9.0,  12.0, 8.0,  7.0];
  static const _days      = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  Widget build(BuildContext context) {
    final gridLine = isDark
        ? const Color(0xFF1E2640)
        : const Color(0xFFE5E7EB);
    final labelColor = isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show:                true,
            drawVerticalLine:    false,
            horizontalInterval:  20,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridLine, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:    true,
                interval:      20,
                reservedSize:  28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(color: labelColor, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                interval:     1,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _days.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _days[i],
                      style: TextStyle(color: labelColor, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 60,
          lineBarsData: [
            // Questions line
            LineChartBarData(
              spots: List.generate(
                  7, (i) => FlSpot(i.toDouble(), _questions[i])),
              isCurved:      true,
              color:         const Color(0xFF6C47FF),
              barWidth:      2.5,
              dotData:       const FlDotData(show: false),
              belowBarData:  BarAreaData(
                show:         true,
                gradient:     LinearGradient(
                  colors: [
                    const Color(0xFF6C47FF).withValues(alpha: 0.25),
                    const Color(0xFF6C47FF).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
            // JDs line
            LineChartBarData(
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), _jds[i])),
              isCurved:     true,
              color:        const Color(0xFF34D399),
              barWidth:     2.5,
              dotData:      const FlDotData(show: false),
              belowBarData: BarAreaData(
                show:         true,
                gradient:     LinearGradient(
                  colors: [
                    const Color(0xFF34D399).withValues(alpha: 0.15),
                    const Color(0xFF34D399).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark
                  ? const Color(0xFF1A1F35)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category bar chart ────────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  final bool isDark;
  const _CategoryBarChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gridLine = isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB);
    final label    = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final data     = [68.0, 42.0, 35.0, 18.0];
    final xLabels  = ['Tech', 'Behav.', 'Situ.', 'Cultural'];

    return SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show:                true,
            drawVerticalLine:    false,
            horizontalInterval:  20,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridLine, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:    true,
                interval:      20,
                reservedSize:  28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(color: label, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:    true,
                reservedSize:  20,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= xLabels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(xLabels[i],
                        style: TextStyle(color: label, fontSize: 9)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          maxY: 80,
          barGroups: List.generate(
            4,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY:    data[i],
                  color:  const Color(0xFF6C47FF),
                  width:  28,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                    begin:  Alignment.bottomCenter,
                    end:    Alignment.topCenter,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final bool isDark;
  const _CategoryBars({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Technical',    68, 100, const Color(0xFF6C47FF)),
      ('Behavioral',   42, 100, const Color(0xFF3B82F6)),
      ('Situational',  35, 100, const Color(0xFF10B981)),
      ('Cultural Fit', 18, 100, const Color(0xFFF59E0B)),
    ];
    return Column(
      children: items.map((e) {
        final (label, val, max, color) = e;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(label,
                    style: TextStyle(
                        color:    isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 11)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           val / max,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    valueColor:      AlwaysStoppedAnimation<Color>(color),
                    minHeight:       6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$val',
                  style: TextStyle(
                      color:      isDark ? Colors.white : const Color(0xFF111827),
                      fontSize:   11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

class _SessionData {
  final String role;
  final String category;
  final Color categoryColor;
  final int count;
  final String ago;

  const _SessionData({
    required this.role,
    required this.category,
    required this.categoryColor,
    required this.count,
    required this.ago,
  });
}

class _SessionTile extends StatelessWidget {
  final _SessionData session;
  final bool isDark;

  const _SessionTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width:  38,
              height: 38,
              decoration: BoxDecoration(
                color:        session.categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: session.categoryColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.description_rounded,
                  color: session.categoryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.role,
                    style: TextStyle(
                        color:      isDark ? Colors.white : const Color(0xFF111827),
                        fontSize:   13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:        session.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(session.category,
                            style: TextStyle(
                                color:      session.categoryColor,
                                fontSize:   10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(session.ago,
                          style: const TextStyle(
                              color:    Color(0xFF6B7280),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${session.count} Qs',
                  style: const TextStyle(
                      color:      Color(0xFF6C47FF),
                      fontSize:   11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

// ── Common widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _SectionCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding:    const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   15,
                fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: TextStyle(
                    color:    isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 11)),
          ],
        ],
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 11)),
        ],
      );
}
