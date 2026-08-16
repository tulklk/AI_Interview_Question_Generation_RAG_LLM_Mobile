// lib/core/widgets/app_skeleton.dart
//
// Reusable skeleton-loading primitives for HireGen.
// Uses flutter_animate's built-in .shimmer() effect — no extra packages needed.
//
// Usage:
//   SkeletonLine(height: 16, isDark: isDark)
//   SkeletonBox(width: 64, height: 22, borderRadius: 8, isDark: isDark)
//   SkeletonCircle(size: 44, isDark: isDark)
//
// Each primitive already carries its own repeating shimmer animation.
// Stagger the delay for a wave effect:
//   SkeletonLine(...).animate(delay: (i * 80).ms)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Palette ───────────────────────────────────────────────────────────────────

Color _base(bool isDark) =>
    isDark ? const Color(0xFF1E2340) : const Color(0xFFEEEFF2);

Color _highlight(bool isDark) =>
    isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.85);

// ── Core skeleton box ─────────────────────────────────────────────────────────

/// A shimmer-animated rectangle.  All other skeleton primitives build on this.
class SkeletonBox extends StatelessWidget {
  final double  width;
  final double  height;
  final double  borderRadius;
  final bool    isDark;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color:        _base(isDark),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration:    1300.ms,
          color:       _highlight(isDark),
          angle:       0.0, // left → right
          blendMode:   BlendMode.srcATop,
        );
  }
}

// ── Convenience wrappers ──────────────────────────────────────────────────────

/// A full-width (or fixed-width) thin text-line skeleton.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double  height;
  final double  borderRadius;
  final bool    isDark;

  const SkeletonLine({
    super.key,
    this.width,
    this.height       = 14.0,
    this.borderRadius = 6.0,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    if (w == null) {
      return SizedBox(
        width: double.infinity,
        child: SkeletonBox(
          width:        double.infinity,
          height:       height,
          borderRadius: borderRadius,
          isDark:       isDark,
        ),
      );
    }
    return SkeletonBox(
      width:        w,
      height:       height,
      borderRadius: borderRadius,
      isDark:       isDark,
    );
  }
}

/// A circular skeleton (avatar, icon placeholder, status dot…).
class SkeletonCircle extends StatelessWidget {
  final double size;
  final bool   isDark;

  const SkeletonCircle({
    super.key,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => SkeletonBox(
        width:        size,
        height:       size,
        borderRadius: size / 2,
        isDark:       isDark,
      );
}

// ── Ready-made skeleton cards ──────────────────────────────────────────────────
//
// Concrete skeleton widgets that mirror the real card layouts used throughout
// the app.  Import this file and drop these directly into the loading branch
// of each screen.

// ── HR / History session card skeleton ────────────────────────────────────────

/// Drop-in shimmer placeholder for `_SessionCard` in history_list_screen.dart.
class HistorySessionSkeleton extends StatelessWidget {
  final bool isDark;

  const HistorySessionSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1225) : Colors.white;
    final border = isDark
        ? const Color(0xFF1E2340)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status dot
          SkeletonCircle(size: 9, isDark: isDark),
          const SizedBox(width: 10),

          // Title + badge row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 15, isDark: isDark),
                const SizedBox(height: 8),
                Row(children: [
                  SkeletonBox(width: 66, height: 22, borderRadius: 6, isDark: isDark),
                  const SizedBox(width: 6),
                  SkeletonBox(width: 50, height: 22, borderRadius: 6, isDark: isDark),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Date + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLine(width: 54, height: 11, isDark: isDark),
              const SizedBox(height: 8),
              SkeletonCircle(size: 26, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

/// Staggered list of [count] session skeletons.
class HistorySkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;

  const HistorySkeletonList({
    super.key,
    required this.isDark,
    this.count = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HistorySessionSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 200.ms),
      )),
    );
  }
}

// ── Knowledge document card skeleton ─────────────────────────────────────────

/// Drop-in shimmer placeholder for `_DocCard` in knowledge_screen.dart.
class KnowledgeDocSkeleton extends StatelessWidget {
  final bool isDark;

  const KnowledgeDocSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1225) : Colors.white;
    final border = isDark
        ? const Color(0xFF1E2340)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: border),
      ),
      child: Row(
        children: [
          // File icon placeholder
          SkeletonBox(width: 40, height: 40, borderRadius: 10, isDark: isDark),
          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 14, isDark: isDark),
                const SizedBox(height: 6),
                SkeletonLine(width: 90, height: 11, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status chip
          SkeletonBox(width: 76, height: 26, borderRadius: 8, isDark: isDark),
        ],
      ),
    );
  }
}

/// Staggered list of [count] document skeletons.
class KnowledgeSkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;

  const KnowledgeSkeletonList({
    super.key,
    required this.isDark,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: KnowledgeDocSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 200.ms),
      )),
    );
  }
}

// ── Jobseeker practice-session card skeleton ──────────────────────────────────

/// Drop-in shimmer placeholder for `_SessionCard` in jobseeker_history_screen.dart.
class PracticeSessionSkeleton extends StatelessWidget {
  final bool isDark;

  const PracticeSessionSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1225) : Colors.white;
    final border = isDark
        ? const Color(0xFF1E2340)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company avatar (44×44, rounded 11)
          SkeletonBox(width: 44, height: 44, borderRadius: 11, isDark: isDark),
          const SizedBox(width: 12),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: SkeletonLine(height: 15, isDark: isDark)),
                    const SizedBox(width: 12),
                    SkeletonBox(width: 44, height: 28, borderRadius: 8, isDark: isDark),
                  ],
                ),
                const SizedBox(height: 6),
                SkeletonLine(width: 110, height: 12, isDark: isDark),
                const SizedBox(height: 8),
                Row(children: [
                  SkeletonBox(width: 68, height: 22, borderRadius: 6, isDark: isDark),
                  const SizedBox(width: 6),
                  SkeletonBox(width: 52, height: 22, borderRadius: 6, isDark: isDark),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered list of [count] practice-session skeletons.
class PracticeSkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;

  const PracticeSkeletonList({
    super.key,
    required this.isDark,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PracticeSessionSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 200.ms),
      )),
    );
  }
}

// ── KPI grid skeleton (4-cell) ─────────────────────────────────────────────────

/// Animated replacement for the static `_KpiShimmer` in hr_dashboard_screen.dart.
class KpiSkeletonGrid extends StatelessWidget {
  final bool isDark;

  const KpiSkeletonGrid({super.key, required this.isDark});

  Widget _cell(int i) => SkeletonBox(
        width:        double.infinity,
        height:       110,
        borderRadius: 14,
        isDark:       isDark,
      )
          .animate(delay: Duration(milliseconds: i * 80))
          .fadeIn(duration: 200.ms);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            Expanded(child: _cell(0)),
            const SizedBox(width: 12),
            Expanded(child: _cell(1)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _cell(2)),
            const SizedBox(width: 12),
            Expanded(child: _cell(3)),
          ]),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// New composite skeletons
// ─────────────────────────────────────────────────────────────────────────────
//
// Shared palette helpers (internal to this file)
Color _card(bool isDark)   => isDark ? const Color(0xFF0F1225) : Colors.white;
Color _border(bool isDark) => isDark ? const Color(0xFF1E2340) : const Color(0xFFE5E7EB);

// ── Saved-set card skeleton (saved_screen.dart) ───────────────────────────────

/// Drop-in shimmer placeholder for a saved question-set card.
class SavedSetCardSkeleton extends StatelessWidget {
  final bool isDark;
  const SavedSetCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        height: 90,
        padding:    const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        _card(isDark),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _border(isDark)),
        ),
        child: Row(children: [
          SkeletonBox(width: 40, height: 40, borderRadius: 10, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                SkeletonLine(width: 180, height: 14, isDark: isDark),
                const SizedBox(height: 6),
                SkeletonLine(width: 100, height: 11, isDark: isDark),
                const SizedBox(height: 6),
                SkeletonLine(width: 140, height: 10, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SkeletonBox(width: 36, height: 36, borderRadius: 18, isDark: isDark),
        ]),
      );
}

/// Staggered list of [count] saved-set skeletons — fills a scrollable area.
class SavedSetSkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;
  const SavedSetSkeletonList({super.key, required this.isDark, this.count = 5});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding:          const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount:        count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => SavedSetCardSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 200.ms),
      );
}

// ── Invitation card skeleton (invitations_screen.dart) ───────────────────────

/// Drop-in shimmer placeholder for an invitation card.
class InvitationCardSkeleton extends StatelessWidget {
  final bool isDark;
  const InvitationCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding:    const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        _card(isDark),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _border(isDark)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SkeletonBox(width: 40, height: 40, borderRadius: 10, isDark: isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SkeletonLine(width: 120, height: 14, isDark: isDark),
                const SizedBox(height: 5),
                SkeletonLine(width: 80,  height: 11, isDark: isDark),
              ]),
            ),
            SkeletonBox(width: 70, height: 22, borderRadius: 6, isDark: isDark),
          ]),
          const SizedBox(height: 12),
          SkeletonLine(height: 12, isDark: isDark),
          const SizedBox(height: 6),
          SkeletonLine(width: 200, height: 12, isDark: isDark),
        ]),
      );
}

/// Staggered list of [count] invitation skeletons.
class InvitationSkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;
  const InvitationSkeletonList({super.key, required this.isDark, this.count = 4});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding:          const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount:        count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => InvitationCardSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 200.ms),
      );
}

// ── Recommendation card skeleton (recommendation_list_screen.dart) ────────────

/// Drop-in shimmer placeholder for a `_RecommendationCard`.
class RecommendationCardSkeleton extends StatelessWidget {
  final bool isDark;
  const RecommendationCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        _card(isDark),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonCircle(size: 48, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: SkeletonLine(height: 15, isDark: isDark)),
                const SizedBox(width: 12),
                SkeletonBox(width: 46, height: 22, borderRadius: 11, isDark: isDark),
              ]),
              const SizedBox(height: 6),
              SkeletonLine(width: 130, height: 12, isDark: isDark),
              const SizedBox(height: 8),
              Row(children: [
                SkeletonBox(width: 68, height: 22, borderRadius: 6, isDark: isDark),
                const SizedBox(width: 6),
                SkeletonBox(width: 52, height: 22, borderRadius: 6, isDark: isDark),
              ]),
              const SizedBox(height: 8),
              SkeletonLine(height: 6, borderRadius: 3, isDark: isDark),
            ]),
          ),
        ]),
      );
}

/// Scrollable list of [count] recommendation skeletons.
class RecommendationSkeletonList extends StatelessWidget {
  final bool isDark;
  final int  count;
  const RecommendationSkeletonList({super.key, required this.isDark, this.count = 5});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding:   const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: count,
        itemBuilder: (_, i) => RecommendationCardSkeleton(isDark: isDark)
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 200.ms),
      );
}

// ── Candidate profile skeleton (jobseeker_profile_screen.dart) ────────────────

/// Full-page shimmer placeholder that mirrors the candidate profile layout:
/// hero card → menu sections.
class CandidateProfileSkeleton extends StatelessWidget {
  final bool isDark;
  const CandidateProfileSkeleton({super.key, required this.isDark});

  // Shared mini helpers
  Widget _menuCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color:        _card(isDark),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _border(isDark)),
        ),
        child: Column(children: rows),
      );

  Widget _menuRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          SkeletonBox(width: 38, height: 38, borderRadius: 10, isDark: isDark),
          const SizedBox(width: 12),
          Expanded(child: SkeletonLine(height: 14, isDark: isDark)),
          const SizedBox(width: 12),
          SkeletonBox(width: 18, height: 18, borderRadius: 9, isDark: isDark),
        ]),
      );

  Widget _divider() => Divider(
        height: 1, indent: 64,
        color: _border(isDark),
      );

  Widget _sectionLabel() => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: SkeletonBox(width: 72, height: 10, borderRadius: 5, isDark: isDark),
      );

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // ── Hero ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color:   isDark ? const Color(0xFF0F1629) : const Color(0xFFF8F7FF),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 20, 24, 28),
              child: Column(children: [
                SkeletonCircle(size: 84, isDark: isDark),
                const SizedBox(height: 14),
                Center(child: SkeletonBox(
                    width: 140, height: 20, borderRadius: 10, isDark: isDark)),
                const SizedBox(height: 7),
                Center(child: SkeletonBox(
                    width: 100, height: 13, borderRadius: 6,  isDark: isDark)),
                const SizedBox(height: 7),
                Center(child: SkeletonBox(
                    width: 80,  height: 13, borderRadius: 6,  isDark: isDark)),
              ]),
            ).animate().fadeIn(duration: 280.ms),
          ),

          // ── Menu sections ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionLabel(),
                const SizedBox(height: 8),
                _menuCard([
                  _menuRow(), _divider(), _menuRow(), _divider(), _menuRow(),
                ]).animate(delay: 60.ms).fadeIn(duration: 200.ms),
                const SizedBox(height: 20),

                _sectionLabel(),
                const SizedBox(height: 8),
                _menuCard([_menuRow(), _divider(), _menuRow()])
                    .animate(delay: 100.ms).fadeIn(duration: 200.ms),
                const SizedBox(height: 20),

                _sectionLabel(),
                const SizedBox(height: 8),
                _menuCard([
                  _menuRow(), _divider(), _menuRow(), _divider(), _menuRow(),
                ]).animate(delay: 140.ms).fadeIn(duration: 200.ms),
                const SizedBox(height: 20),

                _sectionLabel(),
                const SizedBox(height: 8),
                _menuCard([_menuRow()])
                    .animate(delay: 180.ms).fadeIn(duration: 200.ms),
              ]),
            ),
          ),
        ],
      );
}

// ── Session detail skeleton (history_detail_screen.dart) ──────────────────────

/// Shimmer placeholder for the history-session detail body.
class SessionDetailSkeleton extends StatelessWidget {
  final bool isDark;
  const SessionDetailSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Widget questionRow(int i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding:    const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        _card(isDark),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: _border(isDark)),
            ),
            child: Row(children: [
              SkeletonCircle(size: 28, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SkeletonLine(height: 13, isDark: isDark),
                  const SizedBox(height: 6),
                  SkeletonLine(width: 180, height: 11, isDark: isDark),
                ]),
              ),
              const SizedBox(width: 12),
              SkeletonBox(width: 36, height: 24, borderRadius: 6, isDark: isDark),
            ]),
          )
              .animate(delay: Duration(milliseconds: 80 + i * 60))
              .fadeIn(duration: 200.ms),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        SkeletonBox(
            width:        double.infinity,
            height:       52,
            borderRadius: 12,
            isDark:       isDark)
            .animate().fadeIn(duration: 200.ms),
        const SizedBox(height: 14),
        // Plan / info card
        SkeletonBox(
            width:        double.infinity,
            height:       76,
            borderRadius: 12,
            isDark:       isDark)
            .animate(delay: 40.ms).fadeIn(duration: 200.ms),
        const SizedBox(height: 16),
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 160, height: 15, borderRadius: 7, isDark: isDark),
            SkeletonBox(width: 80,  height: 28, borderRadius: 8, isDark: isDark),
          ],
        ).animate(delay: 60.ms).fadeIn(duration: 200.ms),
        const SizedBox(height: 12),
        // Question rows
        ...List.generate(4, questionRow),
      ]),
    );
  }
}

// ── Feedback result skeleton (feedback_result_screen.dart) ────────────────────

/// Shimmer placeholder for the feedback-result screen body.
class FeedbackResultSkeleton extends StatelessWidget {
  final bool isDark;
  const FeedbackResultSkeleton({super.key, required this.isDark});

  Widget _sectionCard(double height, int delay) => SkeletonBox(
        width:        double.infinity,
        height:       height,
        borderRadius: 16,
        isDark:       isDark,
      ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 200.ms);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Score header card
          Container(
            padding:    const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color:        _card(isDark),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: _border(isDark)),
            ),
            child: Column(children: [
              SkeletonCircle(size: 80, isDark: isDark),
              const SizedBox(height: 12),
              SkeletonBox(width: 70,  height: 18, borderRadius: 9, isDark: isDark),
              const SizedBox(height: 6),
              SkeletonBox(width: 130, height: 12, borderRadius: 6, isDark: isDark),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SkeletonBox(width: 78, height: 26, borderRadius: 8, isDark: isDark),
                const SizedBox(width: 8),
                SkeletonBox(width: 78, height: 26, borderRadius: 8, isDark: isDark),
              ]),
            ]),
          ).animate().fadeIn(duration: 200.ms),
          const SizedBox(height: 14),
          // Insight / upsell block
          _sectionCard(120, 60),
          const SizedBox(height: 14),
          // Q&A header
          SkeletonBox(width: 160, height: 14, borderRadius: 7, isDark: isDark)
              .animate(delay: 100.ms).fadeIn(duration: 200.ms),
          const SizedBox(height: 10),
          // Q&A cards
          _sectionCard(90, 120),
          const SizedBox(height: 10),
          _sectionCard(90, 160),
          const SizedBox(height: 10),
          _sectionCard(90, 200),
        ]),
      );
}

// ── Subscription skeleton (subscription_screen.dart) ─────────────────────────

/// Full-page skeleton for the subscription screen (replaces full-page CPI).
class SubscriptionSkeleton extends StatelessWidget {
  final bool isDark;
  const SubscriptionSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final planBg = isDark ? const Color(0xFF1A1F3A) : const Color(0xFFEEF2FF);

    Widget planCard(int i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding:    const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:        _card(isDark),
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: _border(isDark)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SkeletonCircle(size: 44, isDark: isDark),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 80,  height: 12, isDark: isDark),
                      const SizedBox(height: 6),
                      SkeletonLine(width: 120, height: 20, isDark: isDark),
                    ])),
                SkeletonBox(width: 62, height: 26, borderRadius: 13, isDark: isDark),
              ]),
              const SizedBox(height: 14),
              SkeletonLine(height: 12, isDark: isDark),
              const SizedBox(height: 6),
              SkeletonLine(height: 12, isDark: isDark),
              const SizedBox(height: 6),
              SkeletonLine(width: 220, height: 12, isDark: isDark),
            ]),
          )
              .animate(delay: Duration(milliseconds: 80 + i * 80))
              .fadeIn(duration: 200.ms),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
      children: [
        // Current plan card
        Container(
          padding:    const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:        planBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A3350)
                  : const Color(0xFFDDE1FF),
            ),
          ),
          child: Row(children: [
            SkeletonCircle(size: 50, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 80,  height: 11, isDark: isDark),
                  const SizedBox(height: 6),
                  SkeletonLine(width: 130, height: 20, isDark: isDark),
                ])),
            SkeletonBox(width: 70, height: 28, borderRadius: 14, isDark: isDark),
          ]),
        ).animate().fadeIn(duration: 200.ms),
        const SizedBox(height: 16),
        // Usage card
        Container(
          height:     76,
          padding:    const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        _card(isDark),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: _border(isDark)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonLine(width: 120, height: 12, isDark: isDark),
            const SizedBox(height: 10),
            SkeletonLine(height: 8, borderRadius: 4, isDark: isDark),
          ]),
        ).animate(delay: 60.ms).fadeIn(duration: 200.ms),
        const SizedBox(height: 28),
        SkeletonBox(width: 130, height: 16, borderRadius: 8, isDark: isDark)
            .animate(delay: 80.ms).fadeIn(duration: 200.ms),
        const SizedBox(height: 14),
        ...List.generate(3, planCard),
      ],
    );
  }
}

/// Inline placeholder for the plans section while `plansAsync` is loading.
class PlanLoadingSkeleton extends StatelessWidget {
  final bool isDark;
  const PlanLoadingSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonBox(
            width:        double.infinity,
            height:       80,
            borderRadius: 14,
            isDark:       isDark,
          ).animate(delay: Duration(milliseconds: i * 80)).fadeIn(duration: 200.ms),
        )),
      );
}
