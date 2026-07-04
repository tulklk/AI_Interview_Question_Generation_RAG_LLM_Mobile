import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_localizations.dart';
import '../../data/providers/app_providers.dart';
import '../../features/hr_generate/domain/models/generation_session.dart';
import 'providers/hr_dashboard_provider.dart';

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
    final statsAsync = ref.watch(hrDashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(hrDashboardProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Welcome ─────────────────────────────────────────────────
                _WelcomeSection(
                  greeting:  greeting,
                  firstName: firstName,
                  isDark:    isDark,
                ),
                const SizedBox(height: 20),

                // ── Stats grid ───────────────────────────────────────────────
                statsAsync.when(
                  loading: () => _StatsShimmer(isDark: isDark),
                  error:   (_, __) => _StatsGrid(
                    total:     0,
                    questions: 0,
                    month:     0,
                    isDark:    isDark,
                  ),
                  data: (stats) => _StatsGrid(
                    total:     stats.totalSessions,
                    questions: stats.totalQuestions,
                    month:     stats.thisMonth,
                    isDark:    isDark,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Weekly bar chart ─────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title:    'Hoạt động tuần này',
                        subtitle: 'Số phiên tạo câu hỏi theo ngày',
                        isDark:   isDark,
                      ),
                      const SizedBox(height: 16),
                      statsAsync.when(
                        loading: () => const SizedBox(
                          height: 140,
                          child:  Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox(height: 140),
                        data: (stats) => _WeeklyBarChart(
                          values: stats.weeklyActivity,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Level donut chart ────────────────────────────────────────
                statsAsync.maybeWhen(
                  data: (stats) => stats.levelBreakdown.isNotEmpty
                      ? Column(
                          children: [
                            _SectionCard(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    title:    'Phân loại cấp độ',
                                    subtitle: 'Phân bổ phiên theo kinh nghiệm',
                                    isDark:   isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  _LevelDonutChart(
                                    data:   stats.levelBreakdown,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),

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
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tạo câu hỏi phỏng vấn AI',
                              style: TextStyle(
                                  color:      Colors.white,
                                  fontSize:   16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text(
                            'Phân tích JD và tạo bộ câu hỏi phù hợp trong vài phút.',
                            style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 12,
                                height: 1.5),
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
                            child: const Text('Bắt đầu ngay',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 48),
                  ]),
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
                          _SectionHeader(title: 'Phiên gần đây', isDark: isDark),
                          TextButton(
                            onPressed: () => context.go('/hr/history'),
                            child: const Text('Xem tất cả',
                                style: TextStyle(
                                    color: Color(0xFF6C47FF), fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      statsAsync.when(
                        loading: () => Column(
                          children: List.generate(
                            3,
                            (_) => _SessionTileShimmer(isDark: isDark),
                          ),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text('Không thể tải dữ liệu',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 13)),
                          ),
                        ),
                        data: (stats) {
                          final recent = stats.sessions.take(5).toList();
                          if (recent.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Chưa có phiên nào',
                                    style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF9CA3AF),
                                        fontSize: 13)),
                              ),
                            );
                          }
                          return Column(
                            children: recent
                                .map((s) => _SessionTile(
                                      session: s,
                                      isDark:  isDark,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
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
            'Hôm nay bạn muốn tạo bộ câu hỏi nào?',
            style: TextStyle(
                color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 13,
                height:   1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.go('/hr/generate'),
            icon:  const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Tạo câu hỏi'),
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

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int total;
  final int questions;
  final int month;
  final bool isDark;

  const _StatsGrid({
    required this.total,
    required this.questions,
    required this.month,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Tổng phiên',
              value: '$total',
              icon:  Icons.description_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Câu hỏi đã tạo',
              value: '$questions',
              icon:  Icons.bolt_rounded,
              color: const Color(0xFF7C3AED),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Tháng này',
              value: '$month',
              icon:  Icons.calendar_month_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ],
      );
}

class _StatsShimmer extends StatelessWidget {
  final bool isDark;
  const _StatsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(3, (i) {
          if (i > 0) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _shimmerBox(isDark),
              ),
            );
          }
          return Expanded(child: _shimmerBox(isDark));
        }),
      );

  Widget _shimmerBox(bool isDark) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
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
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    fontSize: 10),
                maxLines:  1,
                overflow:  TextOverflow.ellipsis),
          ],
        ),
      );
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values; // Mon(0) … Sun(6)
  final bool isDark;

  static const _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  const _WeeklyBarChart({required this.values, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gridLine  = isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB);
    final labelColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return RepaintBoundary(
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
          gridData: FlGridData(
            show:             true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridLine, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 24,
                interval:     maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(color: labelColor, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _days.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_days[i],
                        style: TextStyle(color: labelColor, fontSize: 9)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          maxY: maxY,
          barGroups: List.generate(
            7,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY:    values[i].toDouble(),
                  width:  22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                    begin:  Alignment.bottomCenter,
                    end:    Alignment.topCenter,
                  ),
                ),
              ],
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1A1F35) : Colors.white,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()} phiên',
                TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        swapAnimationDuration: Duration.zero,
      ),
    ),
    );
  }
}

// ── Level donut chart ─────────────────────────────────────────────────────────

class _LevelDonutChart extends StatefulWidget {
  final Map<String, int> data;
  final bool isDark;

  const _LevelDonutChart({required this.data, required this.isDark});

  @override
  State<_LevelDonutChart> createState() => _LevelDonutChartState();
}

class _LevelDonutChartState extends State<_LevelDonutChart> {
  int _touched = -1;

  static const _colors = [
    Color(0xFF6C47FF),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total   = entries.fold<int>(0, (s, e) => s + e.value);

    return RepaintBoundary(
      child: Row(
      children: [
        SizedBox(
          width:  140,
          height: 140,
          child:  PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              pieTouchData: PieTouchData(
                touchCallback: (event, resp) {
                  if (!event.isInterestedForInteractions ||
                      resp == null ||
                      resp.touchedSection == null) {
                    setState(() => _touched = -1);
                    return;
                  }
                  setState(() => _touched =
                      resp.touchedSection!.touchedSectionIndex);
                },
              ),
              sections: List.generate(entries.length, (i) {
                final entry   = entries[i];
                final color   = _colors[i % _colors.length];
                final isTouched = i == _touched;
                final pct = total > 0 ? entry.value / total * 100 : 0.0;
                return PieChartSectionData(
                  color:         color,
                  value:         entry.value.toDouble(),
                  title:         isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                  radius:        isTouched ? 38 : 30,
                  titleStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white),
                );
              }),
            ),
            swapAnimationDuration: Duration.zero,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(entries.length, (i) {
              final entry = entries[i];
              final color = _colors[i % _colors.length];
              final pct   = total > 0
                  ? (entry.value / total * 100).toStringAsFixed(0)
                  : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(entry.key,
                        style: TextStyle(
                            color: widget.isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${entry.value} ($pct%)',
                      style: TextStyle(
                          color:      widget.isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontSize:   11,
                          fontWeight: FontWeight.w600)),
                ]),
              );
            }),
          ),
        ),
      ],
    ),
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final GenerationSession session;
  final bool isDark;

  const _SessionTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusInfo(session.status.name);
    final createdAt = DateTime.tryParse(session.createdAt);
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
        : '';

    return InkWell(
      onTap: () => context.push('/hr/history/${session.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.description_rounded,
                color: Color(0xFF6C47FF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.jobTitle.isEmpty
                      ? 'Interview Session'
                      : session.jobTitle,
                  style: TextStyle(
                      color:      isDark ? Colors.white : const Color(0xFF111827),
                      fontSize:   13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(children: [
                  _StatusChip(label: label, color: color),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 10)),
                  ],
                ]),
              ],
            ),
          ),
          if (session.generatedQuestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${session.generatedQuestions.length} câu',
                style: const TextStyle(
                    color:      Color(0xFF6C47FF),
                    fontSize:   11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
              size: 18),
        ]),
      ),
    );
  }

  static (Color, String) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':             return (const Color(0xFF10B981), 'Hoàn thành');
      case 'failed':                return (const Color(0xFFEF4444), 'Thất bại');
      case 'planproposed':          return (const Color(0xFF3B82F6), 'Chờ duyệt plan');
      case 'processing':
      case 'queued':
      case 'questionprocessing':
      case 'planqueued':            return (const Color(0xFF6C47FF), 'Đang xử lý');
      case 'draft':                 return (const Color(0xFFF59E0B), 'Draft');
      default:                     return (const Color(0xFF9CA3AF), 'Pending');
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color:      color,
                fontSize:   10,
                fontWeight: FontWeight.w600)),
      );
}

class _SessionTileShimmer extends StatelessWidget {
  final bool isDark;
  const _SessionTileShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2640)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
}

// ── Common widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _SectionCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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
          Text(title,
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   15,
                  fontWeight: FontWeight.w700)),
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
