import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/providers/app_providers.dart';
import '../../features/hr_generate/domain/models/generation_session.dart';
import '../../features/hr_generate/domain/enums/generation_status.dart';
import 'providers/hr_dashboard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class HRDashboardScreen extends ConsumerWidget {
  const HRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user   = ref.watch(authProvider).user;
    final name   = user?.name ?? 'HR';
    final stats  = ref.watch(hrDashboardProvider);

    return RefreshIndicator(
      color: const Color(0xFF6C47FF),
      onRefresh: () => ref.refresh(hrSessionsRawProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 1. Header ─────────────────────────────────────────────
                _DashboardHeader(
                  name:  name,
                  stats: stats.valueOrNull,
                  isDark: isDark,
                ).animate().fadeIn(duration: 280.ms),

                const SizedBox(height: 16),

                // ── 2. Time filter ────────────────────────────────────────
                _TimeFilterBar(isDark: isDark),

                const SizedBox(height: 20),

                // ── 3. KPI grid ───────────────────────────────────────────
                stats.when(
                  loading: () => _KpiShimmer(isDark: isDark),
                  error:   (_, __) => _KpiError(isDark: isDark, onRetry: () => ref.refresh(hrSessionsRawProvider.future)),
                  data:    (s) => _KpiGrid(stats: s, isDark: isDark),
                ).animate().fadeIn(duration: 320.ms, delay: 40.ms),

                const SizedBox(height: 16),

                // ── 4. Attention / insight panel ──────────────────────────
                stats.maybeWhen(
                  data: (s) {
                    final hasAttention =
                        s.failedSessions > 0 || s.processingSessions > 0;
                    if (!hasAttention) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AttentionPanel(stats: s, isDark: isDark),
                    ).animate().fadeIn(duration: 300.ms, delay: 60.ms);
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // ── 5. Activity chart ─────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        title: 'Hoạt động 7 ngày',
                        subtitle: 'Số phiên tạo câu hỏi theo ngày trong tuần',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      stats.when(
                        loading: () => _chartPlaceholder(isDark),
                        error:   (_, __) => _ChartError(isDark: isDark),
                        data:    (s) => s.weeklyActivity.every((v) => v == 0)
                            ? _ChartEmpty(
                                message:
                                    'Chưa có phiên nào trong 7 ngày qua',
                                isDark: isDark)
                            : _WeeklyBarChart(
                                values: s.weeklyActivity, isDark: isDark),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms, delay: 80.ms),

                const SizedBox(height: 16),

                // ── 6. Status distribution ────────────────────────────────
                stats.maybeWhen(
                  data: (s) => s.totalSessions == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StatusDistributionCard(
                              stats: s, isDark: isDark),
                        ).animate().fadeIn(duration: 320.ms, delay: 100.ms),
                  orElse: () => const SizedBox.shrink(),
                ),

                // ── 7. Level distribution ─────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  child: _LevelSection(stats: stats, isDark: isDark),
                ).animate().fadeIn(duration: 320.ms, delay: 120.ms),

                const SizedBox(height: 16),

                // ── 8. Question type breakdown ────────────────────────────
                stats.maybeWhen(
                  data: (s) => s.questionTypeBreakdown.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SectionCard(
                            isDark: isDark,
                            child: _QuestionTypeSection(
                                stats: s, isDark: isDark),
                          ),
                        ).animate().fadeIn(duration: 320.ms, delay: 140.ms)
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),

                // ── 9. Top skills ──────────────────────────────────────────
                stats.maybeWhen(
                  data: (s) => s.topSkills.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SectionCard(
                            isDark: isDark,
                            child: _TopSkillsSection(
                                stats: s, isDark: isDark),
                          ),
                        ).animate().fadeIn(duration: 320.ms, delay: 160.ms)
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),

                // ── 10. Recent sessions ───────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Phiên gần đây', isDark: isDark),
                          TextButton(
                            onPressed: () => context.go('/hr/history'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Xem tất cả',
                                style: TextStyle(
                                    color: Color(0xFF6C47FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      stats.when(
                        loading: () => Column(
                          children: List.generate(
                              3, (_) => _SessionShimmer(isDark: isDark)),
                        ),
                        error: (_, __) => _inlineError(isDark, 'Không thể tải phiên'),
                        data: (s) {
                          final recent =
                              s.allSessions.take(5).toList();
                          if (recent.isEmpty) {
                            return _ChartEmpty(
                              message: 'Chưa có phiên nào. Hãy tạo bộ câu hỏi đầu tiên!',
                              isDark: isDark,
                              cta: 'Tạo ngay',
                              onCta: () => context.go('/hr/generate'),
                            );
                          }
                          return Column(
                            children: recent
                                .map((s) => _SessionTile(
                                      session: s,
                                      isDark: isDark,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms, delay: 180.ms),

                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartPlaceholder(bool isDark) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2640)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _inlineError(bool isDark, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(msg,
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 13)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Dashboard header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String name;
  final DashboardStats? stats;
  final bool isDark;

  const _DashboardHeader({
    required this.name,
    required this.stats,
    required this.isDark,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5)  return 'Xin chào';
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String get _firstName =>
      name.trim().split(RegExp(r'\s+')).last;

  String _insight(DashboardStats s) {
    if (s.totalSessions == 0) return 'Chưa có phiên nào trong kỳ này.';
    final q = s.totalQuestions;
    final sess = s.totalSessions;
    return 'Kỳ này: $sess phiên tạo, $q câu hỏi được tạo bởi AI.';
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $_firstName',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            stats != null
                ? _insight(stats!)
                : 'Đang tải dữ liệu tuyển dụng...',
            style: TextStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/hr/generate'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: const Text('Tạo bộ câu hỏi'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/hr/history'),
                icon: Icon(Icons.history_rounded,
                    size: 15,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                label: Text('Lịch sử',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280))),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2D3562)
                          : const Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Time filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _TimeFilterBar extends ConsumerWidget {
  final bool isDark;
  const _TimeFilterBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(dashboardTimeRangeProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DashboardTimeRange.values.map((range) {
          final active = range == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(dashboardTimeRangeProvider.notifier)
                  .state = range,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF6C47FF)
                      : isDark
                          ? const Color(0xFF1A1F35)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF6C47FF)
                        : isDark
                            ? const Color(0xFF2D3562)
                            : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  range.label,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. KPI grid
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _KpiGrid({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final successPct = stats.successRate < 0
        ? '—'
        : '${(stats.successRate * 100).round()}%';

    return Column(
      children: [
        Row(children: [
          Expanded(child: _kpi(
            icon: Icons.description_rounded,
            color: const Color(0xFF3B82F6),
            label: 'Tổng phiên tạo',
            value: '${stats.totalSessions}',
            sub: '${stats.completedSessions} hoàn thành',
          )),
          const SizedBox(width: 12),
          Expanded(child: _kpi(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF6C47FF),
            label: 'Câu hỏi đã tạo',
            value: '${stats.totalQuestions}',
            sub: stats.avgQuestionsPerSession > 0
                ? 'TB ${stats.avgQuestionsPerSession.toStringAsFixed(1)}/phiên'
                : 'chưa có dữ liệu',
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _kpi(
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            label: 'Tỷ lệ thành công',
            value: successPct,
            sub: stats.successRate < 0
                ? 'chưa có phiên kết thúc'
                : '${stats.failedSessions} thất bại',
          )),
          const SizedBox(width: 12),
          Expanded(child: _kpi(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B),
            label: 'Đang xử lý',
            value: '${stats.processingSessions}',
            sub: stats.failedSessions > 0
                ? '${stats.failedSessions} thất bại'
                : 'không có lỗi',
            alertColor: stats.failedSessions > 0
                ? const Color(0xFFEF4444)
                : null,
          )),
        ]),
      ],
    );
  }

  Widget _kpi({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String sub,
    Color? alertColor,
  }) =>
      Container(
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
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    color: alertColor ??
                        (isDark
                            ? const Color(0xFF4A5578)
                            : const Color(0xFF9CA3AF)),
                    fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _KpiShimmer extends StatelessWidget {
  final bool isDark;
  const _KpiShimmer({required this.isDark});

  Widget _box() => Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(14),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            Expanded(child: _box()),
            const SizedBox(width: 12),
            Expanded(child: _box()),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _box()),
            const SizedBox(width: 12),
            Expanded(child: _box()),
          ]),
        ],
      );
}

class _KpiError extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  const _KpiError({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Không thể tải dữ liệu dashboard',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Attention panel
// ─────────────────────────────────────────────────────────────────────────────

class _AttentionPanel extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _AttentionPanel({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = <_InsightItem>[];

    if (stats.failedSessions > 0) {
      items.add(_InsightItem(
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEF4444),
        text: '${stats.failedSessions} phiên tạo câu hỏi thất bại trong kỳ này.',
        cta: 'Xem lịch sử',
        route: '/hr/history',
      ));
    }
    if (stats.processingSessions > 0) {
      items.add(_InsightItem(
        icon: Icons.schedule_rounded,
        color: const Color(0xFFF59E0B),
        text: '${stats.processingSessions} phiên đang trong quá trình xử lý.',
        cta: 'Theo dõi',
        route: '/hr/history',
      ));
    }

    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded,
                  size: 15, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text('Cần chú ý',
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          ...items.map((item) => _AttentionRow(
              item: item, isDark: isDark, last: item == items.last)),
        ],
      ),
    );
  }
}

class _InsightItem {
  final IconData icon;
  final Color color;
  final String text;
  final String cta;
  final String route;
  const _InsightItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.cta,
    required this.route,
  });
}

class _AttentionRow extends StatelessWidget {
  final _InsightItem item;
  final bool isDark;
  final bool last;
  const _AttentionRow(
      {required this.item, required this.isDark, required this.last});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF1E2640)
                  : const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(children: [
              Icon(item.icon, color: item.color, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.text,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.4)),
              ),
              TextButton(
                onPressed: () => context.go(item.route),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(item.cta,
                    style: TextStyle(
                        color: item.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Weekly bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values;
  final bool isDark;
  static const _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  const _WeeklyBarChart({required this.values, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gridLine = isDark
        ? const Color(0xFF1E2640)
        : const Color(0xFFE5E7EB);
    final labelColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final maxRaw = values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxRaw < 4 ? 4 : maxRaw + 1).toDouble();
    final interval = (maxY / 4).ceilToDouble();

    return Semantics(
      label: 'Biểu đồ hoạt động tuần: '
          '${_days.asMap().entries.map((e) => "${e.value}: ${values[e.key]} phiên").join(", ")}',
      child: RepaintBoundary(
        child: SizedBox(
          height: 148,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridLine, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: interval,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style:
                            TextStyle(color: labelColor, fontSize: 9)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= _days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_days[i],
                            style: TextStyle(
                                color: labelColor, fontSize: 9)),
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
                      toY: values[i].toDouble(),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      gradient: LinearGradient(
                        colors: values[i] == 0
                            ? [
                                (isDark
                                    ? const Color(0xFF2D3562)
                                    : const Color(0xFFE5E7EB)),
                                (isDark
                                    ? const Color(0xFF2D3562)
                                    : const Color(0xFFE5E7EB)),
                              ]
                            : const [
                                Color(0xFF6C47FF),
                                Color(0xFF8B65FF),
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => isDark
                      ? const Color(0xFF111827)
                      : Colors.white,
                  tooltipBorder: BorderSide(
                    color: isDark
                        ? const Color(0xFF2D3562)
                        : const Color(0xFFE5E7EB),
                  ),
                  getTooltipItem: (group, _, rod, __) =>
                      rod.toY == 0
                          ? null
                          : BarTooltipItem(
                              '${rod.toY.toInt()} phiên',
                              TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                ),
              ),
            ),
            swapAnimationDuration: Duration.zero,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Status distribution
// ─────────────────────────────────────────────────────────────────────────────

class _StatusDistributionCard extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _StatusDistributionCard(
      {required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Hoàn thành', stats.completedSessions,
          const Color(0xFF10B981)),
      ('Đang xử lý', stats.processingSessions,
          const Color(0xFF6C47FF)),
      ('Thất bại', stats.failedSessions, const Color(0xFFEF4444)),
      ('Bản nháp', stats.pendingSessions, const Color(0xFF9CA3AF)),
    ].where((e) => e.$2 > 0).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final total = stats.totalSessions;

    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Phân bổ trạng thái',
            subtitle: '$total phiên trong kỳ',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: items.map((item) {
                final pct = total > 0 ? item.$2 / total : 0.0;
                return Flexible(
                  flex: (pct * 1000).round(),
                  child: Container(height: 8, color: item.$3),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: items.map((item) {
              final pct = total > 0
                  ? '${(item.$2 / total * 100).round()}%'
                  : '0%';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: item.$3, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text('${item.$1} ${item.$2} ($pct)',
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Level distribution
// ─────────────────────────────────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final AsyncValue<DashboardStats> stats;
  final bool isDark;
  const _LevelSection({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Phân loại cấp độ',
          subtitle: 'Phân bổ phiên theo kinh nghiệm',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        stats.when(
          loading: () => _shimmerBars(isDark),
          error: (_, __) => _ChartError(isDark: isDark),
          data: (s) {
            // Unknown-dominant case
            if (!s.hasUsefulLevelData) {
              return _DataQualityState(
                message:
                    '${s.totalSessions > 0 ? s.totalSessions : 0} phiên chưa có thông tin cấp độ kinh nghiệm.',
                hint: 'Cấp độ được xác định từ plan khi tạo bộ câu hỏi.',
                isDark: isDark,
                cta: s.totalSessions > 0 ? 'Xem phiên' : null,
                onCta: s.totalSessions > 0
                    ? () => context.go('/hr/history')
                    : null,
              );
            }
            final total = s.levelBreakdown.values.fold(0, (a, b) => a + b);
            final sorted = s.levelBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            const colors = [
              Color(0xFF6C47FF),
              Color(0xFF3B82F6),
              Color(0xFF10B981),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
              Color(0xFF8B5CF6),
            ];
            return Column(
              children: sorted.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final color = colors[idx % colors.length];
                final pct = total > 0 ? e.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(e.key,
                              style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                  fontSize: 12)),
                        ),
                        Text(
                          '${e.value}  ${(pct * 100).round()}%',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? const Color(0xFF1E2640)
                              : const Color(0xFFE5E7EB),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _shimmerBars(bool isDark) => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2640)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Question type breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionTypeSection extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _QuestionTypeSection(
      {required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = stats.questionTypeBreakdown.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    const colors = [
      Color(0xFF6C47FF),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Phân loại câu hỏi',
          subtitle: 'Theo loại trong các phiên tạo',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        ...entries.asMap().entries.map((me) {
          final idx = me.key;
          final e = me.value;
          final color = colors[idx % colors.length];
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 88,
                child: Text(e.key,
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${(pct * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Top skills
// ─────────────────────────────────────────────────────────────────────────────

class _TopSkillsSection extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _TopSkillsSection({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = stats.topSkills.entries.toList();
    final maxCount =
        entries.isEmpty ? 1 : entries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Kỹ năng phổ biến',
          subtitle: 'Từ topics trong các bộ câu hỏi đã tạo',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.map((e) {
            final opacity =
                maxCount > 0 ? 0.4 + 0.6 * (e.value / maxCount) : 1.0;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C47FF)
                    .withValues(alpha: opacity * 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6C47FF)
                      .withValues(alpha: opacity * 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.key,
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFFB39DFF)
                              : const Color(0xFF5535DD),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 5),
                  Text('${e.value}',
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF8B65FF)
                              : const Color(0xFF6C47FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. Recent session tile
// ─────────────────────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final GenerationSession session;
  final bool isDark;
  const _SessionTile({required this.session, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusInfo(session.status);
    final d = DateTime.tryParse(session.createdAt);
    final dateStr =
        d != null ? DateFormat('dd/MM/yy HH:mm').format(d) : '';
    final qCount = session.generatedQuestions.length;

    return Semantics(
      button: true,
      label: '${session.jobTitle.isEmpty ? "Phiên phỏng vấn" : session.jobTitle}, $label, $qCount câu hỏi',
      child: InkWell(
        onTap: () => context.push('/hr/history/${session.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(_statusIcon(session.status),
                  color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.jobTitle.isEmpty
                        ? 'Phiên phỏng vấn'
                        : session.jobTitle,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    _StatusChip(label: label, color: color),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10)),
                    ],
                  ]),
                ],
              ),
            ),
            if (qCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$qCount câu',
                    style: const TextStyle(
                        color: Color(0xFF6C47FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? const Color(0xFF4A5578)
                    : const Color(0xFF9CA3AF),
                size: 18),
          ]),
        ),
      ),
    );
  }

  static (Color, String) _statusInfo(GenerationStatus s) => switch (s) {
        GenerationStatus.completed    => (const Color(0xFF10B981), 'Hoàn thành'),
        GenerationStatus.failed       => (const Color(0xFFEF4444), 'Thất bại'),
        GenerationStatus.planProposed => (const Color(0xFF3B82F6), 'Chờ duyệt plan'),
        GenerationStatus.draft        => (const Color(0xFFF59E0B), 'Bản nháp'),
        _                             => (const Color(0xFF6C47FF), 'Đang xử lý'),
      };

  static IconData _statusIcon(GenerationStatus s) => switch (s) {
        GenerationStatus.completed    => Icons.check_circle_outline_rounded,
        GenerationStatus.failed       => Icons.error_outline_rounded,
        GenerationStatus.planProposed => Icons.rate_review_rounded,
        GenerationStatus.draft        => Icons.edit_note_rounded,
        _                             => Icons.sync_rounded,
      };
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}

class _SessionShimmer extends StatelessWidget {
  final bool isDark;
  const _SessionShimmer({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
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
                  height: 11,
                  width: 140,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 9,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared state widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChartEmpty extends StatelessWidget {
  final String message;
  final bool isDark;
  final String? cta;
  final VoidCallback? onCta;
  const _ChartEmpty(
      {required this.message,
      required this.isDark,
      this.cta,
      this.onCta});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 32,
                color: isDark
                    ? const Color(0xFF4A5578)
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.4)),
            if (cta != null && onCta != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onCta,
                child: Text(cta!,
                    style: const TextStyle(
                        color: Color(0xFF6C47FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
}

class _ChartError extends StatelessWidget {
  final bool isDark;
  const _ChartError({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 6),
            Text('Không thể tải dữ liệu',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12)),
          ],
        ),
      );
}

class _DataQualityState extends StatelessWidget {
  final String message;
  final String hint;
  final bool isDark;
  final String? cta;
  final VoidCallback? onCta;
  const _DataQualityState({
    required this.message,
    required this.hint,
    required this.isDark,
    this.cta,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2640)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2D3562)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF9CA3AF), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(hint,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11)),
                  if (cta != null && onCta != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onCta,
                      child: Text(cta!,
                          style: const TextStyle(
                              color: Color(0xFF6C47FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout helpers
// ─────────────────────────────────────────────────────────────────────────────

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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  const _SectionTitle(
      {required this.title, this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color:
                      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 11)),
          ],
        ],
      );
}
