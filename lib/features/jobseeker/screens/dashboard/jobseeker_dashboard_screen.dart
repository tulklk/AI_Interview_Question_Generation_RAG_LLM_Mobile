import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/providers/app_providers.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';
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
            // ── Welcome header ────────────────────────────────────────────
            _WelcomeHeader(greeting: l10n.greetingFor(hour), name: name, l10n: l10n, isDark: isDark)
                .animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 20),

            // ── Stat cards (2×2 grid) ─────────────────────────────────────
            _StatCards(l10n: l10n, isDark: isDark)
                .animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            // ── Performance Analytics ─────────────────────────────────────
            _SectionTitle(title: l10n.performanceAnalytics, isDark: isDark)
                .animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 12),
            _RadarCard(isDark: isDark)
                .animate().fadeIn(delay: 160.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // ── Recent Practice + Skill Bars ──────────────────────────────
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
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  _SkillBarsSection(l10n: l10n, isDark: isDark)
                      .animate().fadeIn(delay: 240.ms),
                ],
              ),

            const SizedBox(height: 24),

            // ── AI Recommendation ─────────────────────────────────────────
            _AIRecommendationCard(l10n: l10n)
                .animate().fadeIn(delay: 260.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            // ── Recommended for You ───────────────────────────────────────
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
            _RecommendedSets(isDark: isDark)
                .animate().fadeIn(delay: 300.ms),
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

// ── Stat Cards ────────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _StatCards({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
          icon: Icons.menu_book_rounded,
          iconColor: Colors.blue,
          value: '24',
          label: l10n.practiceSessions,
          trend: l10n.thisWeekStat),
      _StatData(
          icon: Icons.gps_fixed_rounded,
          iconColor: const Color(0xFF6C47FF),
          value: '78%',
          label: l10n.averageScore,
          trend: l10n.vsLastWeek),
      _StatData(
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
          value: l10n.sevenDays,
          label: l10n.practiceStreak,
          trend: l10n.personalBest),
      _StatData(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF10B981),
          value: l10n.highReadiness,
          label: l10n.interviewReadiness,
          trend: l10n.aiAssessed),
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

// ── Radar Chart ───────────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final bool isDark;

  const _RadarCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF4A5578)
                      : const Color(0xFFD1D5DB),
                  fontSize: 9,
                ),
                radarBorderData: BorderSide(
                  color: isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E2640)
                      : const Color(0xFFF3F4F6),
                  width: 1,
                ),
                titleTextStyle: TextStyle(
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF6C47FF).withValues(alpha: 0.12),
                    borderColor: const Color(0xFF6C47FF),
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: skillRadarData
                        .map((s) => RadarEntry(value: s.score.toDouble()))
                        .toList(),
                  ),
                ],
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: skillRadarData[index].skill,
                    angle: angle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: skillRadarData.map((s) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C47FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${s.skill}: ${s.score}',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Recent Practice ───────────────────────────────────────────────────────────

class _RecentPracticeSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _RecentPracticeSection({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sessions = practiceSessions.take(3).toList();

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
        ...sessions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionTile(session: s, isDark: isDark),
            )),
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
    final scoreC = scoreColor(session.score);

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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: session.companyColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  session.companyInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.setTitle,
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
                      Text(
                        '${session.date} · ${session.duration}',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4A5578)
                              : const Color(0xFF9CA3AF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Score pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreC.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scoreC.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${session.score}%',
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

// ── Skill Bars ────────────────────────────────────────────────────────────────

class _SkillBarsSection extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _SkillBarsSection({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.strongestSkills, isDark: isDark),
        const SizedBox(height: 10),
        _AnimatedBar(label: 'React', pct: 0.90, color: const Color(0xFF10B981), isDark: isDark),
        const SizedBox(height: 8),
        _AnimatedBar(label: 'TypeScript', pct: 0.84, color: const Color(0xFF10B981), isDark: isDark),
        const SizedBox(height: 8),
        _AnimatedBar(label: 'Communication', pct: 0.78, color: const Color(0xFF10B981), isDark: isDark),
        const SizedBox(height: 20),
        _SectionTitle(title: l10n.areasToImprove, isDark: isDark),
        const SizedBox(height: 10),
        _AnimatedBar(label: 'Situational', pct: 0.55, color: const Color(0xFFF59E0B), isDark: isDark),
        const SizedBox(height: 8),
        _AnimatedBar(label: 'System Design', pct: 0.47, color: const Color(0xFFF59E0B), isDark: isDark),
        const SizedBox(height: 8),
        _AnimatedBar(label: 'SQL', pct: 0.39, color: const Color(0xFFF59E0B), isDark: isDark),
      ],
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
              color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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

// ── AI Recommendation ─────────────────────────────────────────────────────────

class _AIRecommendationCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _AIRecommendationCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
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
            l10n.aiRecommendationBody,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            child: ElevatedButton(
              onPressed: () => context.go('/jobseeker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                l10n.startPractice,
                style: const TextStyle(
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

// ── Recommended Sets ──────────────────────────────────────────────────────────

class _RecommendedSets extends StatelessWidget {
  final bool isDark;

  const _RecommendedSets({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sets = questionSets.take(3).toList();
    final isWide = MediaQuery.of(context).size.width > 840;

    if (isWide) {
      return Row(
        children: sets
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: e.key < sets.length - 1 ? 12 : 0),
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

// ── Section title ─────────────────────────────────────────────────────────────

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
