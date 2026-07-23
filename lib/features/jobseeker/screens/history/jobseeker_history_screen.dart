import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

class JobseekerHistoryScreen extends ConsumerWidget {
  const JobseekerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final filter = ref.watch(historyFilterProvider);
    final sessions = ref.watch(filteredSessionsProvider);
    final historyAsync = ref.watch(practiceHistoryProvider);
    final statsAsync = ref.watch(practiceStatsProvider);

    // Stats: prefer API endpoint, fallback to deriving from loaded sessions
    final allLoaded = historyAsync.maybeWhen(
      data: (list) => list, orElse: () => <PracticeSession>[]);
    final apiStats = statsAsync.maybeWhen(data: (s) => s, orElse: () => null);
    final total = apiStats?.totalSessions ?? allLoaded.length;
    final best = apiStats?.bestScore ??
        (allLoaded.isEmpty ? 0 : allLoaded.map((s) => s.score).reduce((a, b) => a > b ? a : b));
    final avgScore = apiStats?.avgScore ??
        (allLoaded.isEmpty
            ? 0
            : (allLoaded.map((s) => s.score).reduce((a, b) => a + b) / allLoaded.length).round());
    final isLoading = historyAsync.isLoading;
    final loadError = historyAsync.error;

    final bg = isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1A1F35) : Colors.white;
    final borderC = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              l10n.practiceHistory,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 4),
            Text(
              l10n.dashboardGreetingSubtitle,
              style: TextStyle(
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
            ).animate().fadeIn(delay: 60.ms),
            const SizedBox(height: 20),

            // Stat cards
            _StatCards(
              total: total,
              best: best,
              avgScore: avgScore,
              isDark: isDark,
              cardBg: cardBg,
              borderC: borderC,
              l10n: l10n,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Search + filters
            _SearchBar(isDark: isDark, cardBg: cardBg, borderC: borderC, l10n: l10n),
            const SizedBox(height: 12),
            _FilterRow(
              current: filter.timeFilter,
              isDark: isDark,
              borderC: borderC,
              l10n: l10n,
            ),
            const SizedBox(height: 16),

            // Sessions list
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C47FF), strokeWidth: 2.5),
                ),
              )
            else if (loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 40, color: Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      Text(
                        'Không thể tải lịch sử',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(practiceHistoryProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Thử lại'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C47FF),
                          side: const BorderSide(color: Color(0xFF6C47FF)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (sessions.isEmpty)
              _EmptyState(isDark: isDark, l10n: l10n).animate().fadeIn()
            else
              Column(
                children: sessions.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionCard(
                      session: e.value,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderC: borderC,
                      l10n: l10n,
                    ).animate().fadeIn(
                        delay: Duration(milliseconds: e.key * 60)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Cards ────────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final int total;
  final int best;
  final int avgScore;
  final bool isDark;
  final Color cardBg;
  final Color borderC;
  final AppLocalizations l10n;

  const _StatCards({
    required this.total,
    required this.best,
    required this.avgScore,
    required this.isDark,
    required this.cardBg,
    required this.borderC,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: l10n.totalSessions,
            value: '$total',
            icon: Icons.article_rounded,
            color: AppColors.brandPurple,
            isDark: isDark,
            cardBg: cardBg,
            borderC: borderC,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: l10n.bestScore,
            value: '$best',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            cardBg: cardBg,
            borderC: borderC,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: l10n.averageScore,
            value: '$avgScore',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            cardBg: cardBg,
            borderC: borderC,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color cardBg;
  final Color borderC;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cardBg,
    required this.borderC,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
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
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  final bool isDark;
  final Color cardBg;
  final Color borderC;
  final AppLocalizations l10n;

  const _SearchBar({
    required this.isDark,
    required this.cardBg,
    required this.borderC,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderC),
      ),
      child: TextField(
        onChanged: (v) =>
            ref.read(historyFilterProvider.notifier).setSearch(v),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111827),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchByCompany,
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  final String current;
  final bool isDark;
  final Color borderC;
  final AppLocalizations l10n;

  const _FilterRow({
    required this.current,
    required this.isDark,
    required this.borderC,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = [
      (key: 'all', label: l10n.allTime),
      (key: 'week', label: l10n.thisWeekFilter),
      (key: 'month', label: l10n.thisMonthFilter),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isActive = f.key == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(historyFilterProvider.notifier)
                  .setTimeFilter(f.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brandPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isActive ? AppColors.brandPurple : borderC,
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final PracticeSession session;
  final bool isDark;
  final Color cardBg;
  final Color borderC;
  final AppLocalizations l10n;

  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.cardBg,
    required this.borderC,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final sc = scoreColor(session.score);
    final dateStr = session.date;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderC),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company avatar
          Consumer(
            builder: (context, ref, _) {
              final logoUrl = session.companyLogo ??
                  ref.watch(setDetailProvider(session.setId)).maybeWhen(
                        data: (qs) => qs?.companyLogo,
                        orElse: () => null,
                      );
              return ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: logoUrl != null
                    ? Image.network(
                        logoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CompanyAvatar(
                          color: session.companyColor,
                          initials: session.companyInitials,
                          size: 44,
                          fontSize: 16,
                        ),
                      )
                    : _CompanyAvatar(
                        color: session.companyColor,
                        initials: session.companyInitials,
                        size: 44,
                        fontSize: 16,
                      ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.setTitle,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sc.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${session.score}/100',
                        style: TextStyle(
                          color: sc,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.company,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // Date + actions
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isDark
                          ? const Color(0xFF4A5578)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF4A5578)
                            : const Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),

                    // View session
                    GestureDetector(
                      onTap: () => context.go(
                          '/jobseeker/practice/${session.setId}/result'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.brandPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          l10n.viewSession,
                          style: const TextStyle(
                            color: AppColors.brandPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Retry
                    GestureDetector(
                      onTap: () =>
                          context.go('/jobseeker/practice/${session.setId}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1F35)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderC),
                        ),
                        child: Text(
                          l10n.retrySession,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Company Avatar ────────────────────────────────────────────────────────────

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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  const _EmptyState({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSessions,
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noSessionsAction,
              style: TextStyle(
                color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/jobseeker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(l10n.practiceNow),
            ),
          ],
        ),
      ),
    );
  }
}
