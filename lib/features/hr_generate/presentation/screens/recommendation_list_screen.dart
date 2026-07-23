import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/candidate_recommendation.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/recommendation_shared_widgets.dart';

class RecommendationListScreen extends ConsumerStatefulWidget {
  const RecommendationListScreen({super.key});

  @override
  ConsumerState<RecommendationListScreen> createState() =>
      _RecommendationListScreenState();
}

class _RecommendationListScreenState
    extends ConsumerState<RecommendationListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadInitial() {
    final filter = ref.read(recommendationFilterProvider);
    ref.read(recommendationListProvider.notifier).load(filter);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(recommendationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(recommendationListProvider);
    final filter = ref.watch(recommendationFilterProvider);

    ref.listen(recommendationFilterProvider, (prev, next) {
      if (prev != next) {
        ref.read(recommendationListProvider.notifier).load(next);
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF4F5FB),
      body: Column(
        children: [
          _FilterBar(isDark: isDark),
          if (state.totalElements > 0)
            _CountBar(count: state.totalElements, isDark: isDark),
          Expanded(child: _buildBody(state, isDark, filter)),
        ],
      ),
    );
  }

  Widget _buildBody(
      RecommendationListState state, bool isDark, RecommendationFilter filter) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF6C47FF), strokeWidth: 2),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
          message: state.error!, onRetry: _loadInitial, isDark: isDark);
    }
    if (state.items.isEmpty) {
      return _EmptyView(isDark: isDark, hasFilter: !filter.isEmpty);
    }

    return RefreshIndicator(
      color: const Color(0xFF6C47FF),
      onRefresh: () async => _loadInitial(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF6C47FF), strokeWidth: 2),
              ),
            );
          }
          final item = state.items[i];
          return _RecommendationCard(
            item: item,
            isDark: isDark,
            onTap: () {
              ref.read(selectedRecommendationProvider.notifier).state = item;
              context.push('/hr/recommendations/${item.id}');
            },
          ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(
                begin: 0.05,
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

// ── Count bar ──────────────────────────────────────────────────────────────────

class _CountBar extends StatelessWidget {
  final int count;
  final bool isDark;
  const _CountBar({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        color: isDark ? const Color(0xFF0B1020) : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Text(
              '$count ứng viên được đề xuất',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

// ── Filter Bar ─────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerStatefulWidget {
  final bool isDark;
  const _FilterBar({required this.isDark});

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  bool _showScoreSlider = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filter = ref.watch(recommendationFilterProvider);
    final notifier = ref.read(recommendationFilterProvider.notifier);
    final sep = isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB);

    return Container(
      color: isDark ? const Color(0xFF0B1020) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + score filter row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Tất cả',
                        active: filter.status == null,
                        isDark: isDark,
                        color: const Color(0xFF6C47FF),
                        onTap: () => notifier.setStatus(null),
                      ),
                      const SizedBox(width: 6),
                      ...RecommendationStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _Chip(
                            label: s.label,
                            active: filter.status == s,
                            isDark: isDark,
                            color: s.color,
                            onTap: () => notifier
                                .setStatus(filter.status == s ? null : s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Score filter icon button
              GestureDetector(
                onTap: () =>
                    setState(() => _showScoreSlider = !_showScoreSlider),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: filter.minScore != null
                        ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                        : isDark
                            ? const Color(0xFF1A2035)
                            : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: filter.minScore != null
                        ? Border.all(
                            color:
                                const Color(0xFF6C47FF).withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 15,
                        color: filter.minScore != null
                            ? const Color(0xFF6C47FF)
                            : isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                      ),
                      if (filter.minScore != null) ...[
                        const SizedBox(width: 3),
                        Text(
                          '≥${filter.minScore}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C47FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showScoreSlider) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(filter.minScore ?? 0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6C47FF),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: const Color(0xFF6C47FF),
                      activeTrackColor: const Color(0xFF6C47FF),
                      inactiveTrackColor: isDark
                          ? const Color(0xFF2A3350)
                          : const Color(0xFFE5E7EB),
                      overlayColor:
                          const Color(0xFF6C47FF).withValues(alpha: 0.15),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      trackHeight: 3,
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      value: (filter.minScore ?? 0).toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (v) => notifier.setMinScore(
                          v == 0 ? null : v.toInt()),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    notifier.setMinScore(null);
                    setState(() => _showScoreSlider = false);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: sep),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.5)
                  : isDark
                      ? const Color(0xFF2A3350)
                      : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? color
                  : isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
}

// ── Recommendation Card ────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final CandidateRecommendation item;
  final bool isDark;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CandidateAvatarWidget(item: item, size: 48),
              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + score
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.candidateName,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ScorePill(
                            score: item.overallScore,
                            color: item.scoreColor),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Email
                    if (item.candidateEmail != null)
                      Text(
                        item.candidateEmail!,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 6),

                    // Status + question set
                    Row(
                      children: [
                        _StatusDot(status: item.status),
                        if (item.questionSetTitle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF4A5578)
                                  : const Color(0xFFD1D5DB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.questionSetTitle,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Skills
                    if (item.skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SkillsRow(skills: item.skills, isDark: isDark),
                    ],
                  ],
                ),
              ),

              // Arrow
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color:
                    isDark ? const Color(0xFF4A5578) : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double score;
  final Color color;
  const _ScorePill({required this.score, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${score.round()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _StatusDot extends StatelessWidget {
  final RecommendationStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _SkillsRow extends StatelessWidget {
  final List<String> skills;
  final bool isDark;
  const _SkillsRow({required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const max = 3;
    final visible = skills.take(max).toList();
    final extra = skills.length - max;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visible.map((s) => _SkillTag(label: s, isDark: isDark)),
        if (extra > 0)
          _SkillTag(
            label: '+$extra',
            isDark: isDark,
            accent: true,
          ),
      ],
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool accent;
  const _SkillTag(
      {required this.label, required this.isDark, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: accent
              ? const Color(0xFF6C47FF).withValues(alpha: 0.08)
              : isDark
                  ? const Color(0xFF1A2035)
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: accent
              ? Border.all(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.25))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: accent ? FontWeight.w700 : FontWeight.w400,
            color: accent
                ? const Color(0xFF6C47FF)
                : isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
          ),
        ),
      );
}

// ── Empty / Error ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool isDark;
  final bool hasFilter;
  const _EmptyView({required this.isDark, required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFilter
                      ? Icons.manage_search_rounded
                      : Icons.people_outline_rounded,
                  size: 36,
                  color: const Color(0xFF6C47FF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasFilter
                    ? 'Không có kết quả'
                    : 'Chưa có ứng viên nào',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasFilter
                    ? 'Thử bỏ bộ lọc để xem thêm kết quả.'
                    : 'Ứng viên hoàn thành bài phỏng vấn sẽ xuất hiện tại đây.',
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.92, 0.92),
                curve: Curves.easeOutBack,
              ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorView(
      {required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 36, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
}
