import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/jobseeker_models.dart';
import '../../../providers/jobseeker_providers.dart';

// ── Daily-goal presets ────────────────────────────────────────────────────────
const _dailyGoalPresets = [20, 50, 80, 120];

// ── Public card ───────────────────────────────────────────────────────────────

class GamificationProgressCard extends ConsumerWidget {
  const GamificationProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(gamificationProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = AppColors.cardBg(isDark);
    final borderC = AppColors.borderColor(isDark);

    if (state.isLoading && state.progress == null) {
      return _Skeleton(isDark: isDark, cardBg: cardBg, borderC: borderC);
    }

    final p = state.progress;
    if (p == null) {
      if (state.error != null) {
        return _ErrorCard(
          isDark: isDark,
          cardBg: cardBg,
          borderC: borderC,
          error: state.error!,
          onRetry: () => ref.read(gamificationProvider.notifier).refresh(),
        );
      }
      return const SizedBox.shrink();
    }

    return _ProgressCard(
      p:       p,
      isDark:  isDark,
      cardBg:  cardBg,
      borderC: borderC,
      onGoalChange: (xp) =>
          ref.read(gamificationProvider.notifier).updateDailyGoal(xp),
    );
  }
}

// ── Main card body ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final UserProgress p;
  final bool isDark;
  final Color cardBg;
  final Color borderC;
  final Future<bool> Function(int) onGoalChange;

  const _ProgressCard({
    required this.p,
    required this.isDark,
    required this.cardBg,
    required this.borderC,
    required this.onGoalChange,
  });

  @override
  Widget build(BuildContext context) {
    final label      = levelLabel(p.level);
    final textColor  = AppColors.textPrimary(isDark);
    final subColor   = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final goalPct    = p.dailyGoalXp > 0
        ? (p.todayXp / p.dailyGoalXp).clamp(0.0, 1.0)
        : 0.0;
    final remaining  = (p.dailyGoalXp - p.todayXp).clamp(0, p.dailyGoalXp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderC),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiến độ luyện tập',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _InfoButton(isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),

          // ── Level + total XP ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Level badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡',
                        style: TextStyle(fontSize: 11, height: 1)),
                    const SizedBox(width: 4),
                    Text(
                      'Cấp ${p.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: subColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Total XP
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${p.totalXp}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: ' XP',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── XP progress bar ──────────────────────────────────────────────
          _XpBar(p: p, isDark: isDark),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.currentLevelXp} / ${p.xpRequiredForNextLevel} XP',
                style: TextStyle(
                  color: subColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'XP lên cấp: ${p.xpToNextLevel}',
                style: TextStyle(
                  color: AppColors.brandPurple.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Stat chips ───────────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                  emoji: '🔥',
                  value: '${p.currentStreak}',
                  label: 'Chuỗi ngày',
                  isDark: isDark),
              const SizedBox(width: 6),
              _StatChip(
                  emoji: '⚡',
                  value: '${p.todayXp}',
                  label: 'XP hôm nay',
                  isDark: isDark),
              const SizedBox(width: 6),
              _StatChip(
                  emoji: '🎮',
                  value: '${p.totalPracticeSessions}',
                  label: 'Phiên',
                  isDark: isDark),
            ],
          ),
          const SizedBox(height: 14),

          // ── Daily goal bar ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D1117)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? AppColors.darkChip
                      : AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mục tiêu hôm nay',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showGoalPicker(context),
                      child: Text(
                        '${p.todayXp} / ${p.dailyGoalXp} XP',
                        style: const TextStyle(
                          color: AppColors.brandPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goalPct,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.darkChip
                        : AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      p.dailyGoalCompleted
                          ? const Color(0xFF10B981)
                          : AppColors.brandPurple,
                    ),
                  ),
                ),
                if (!p.dailyGoalCompleted) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Còn $remaining XP để đạt mục tiêu',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    '🎉 Đã đạt mục tiêu hôm nay!',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 60.ms, duration: 450.ms).slideY(begin: 0.05);
  }

  void _showGoalPicker(BuildContext context) {
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalPickerSheet(
        currentGoal: p.dailyGoalXp,
        onSelect: onGoalChange,
      ),
    );
  }
}

// ── XP bar ────────────────────────────────────────────────────────────────────

class _XpBar extends StatefulWidget {
  final UserProgress p;
  final bool isDark;
  const _XpBar({required this.p, required this.isDark});

  @override
  State<_XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<_XpBar> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.p.progressFraction > 0.02) {
      _sweep.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _XpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = widget.p.progressFraction > 0.02;
    if (active && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!active && _sweep.isAnimating) {
      _sweep.stop();
      _sweep.value = 0;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final isDark = widget.isDark;

    return LayoutBuilder(
      builder: (_, constraints) {
        final totalW = constraints.maxWidth;
        final barW = (totalW * p.progressFraction).clamp(0.0, totalW);

        return Stack(
          children: [
            Container(
              height: 10,
              width: totalW,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkChip
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            AnimatedContainer(
              duration: 800.ms,
              curve: Curves.easeOut,
              height: 10,
              width: barW,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: barW < 8
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (_, __) {
                          final sweepW = barW * 0.35;
                          final x =
                              (_sweep.value * (barW + sweepW)) - sweepW;
                          return Stack(
                            children: [
                              Positioned(
                                left: x,
                                top: 0,
                                bottom: 0,
                                width: sweepW,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.45),
                                          const Color(0xFFE9D5FF)
                                              .withValues(alpha: 0.35),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                        stops: const [0, 0.35, 0.55, 1],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? AppColors.darkChip
                  : AppColors.gray200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16, height: 1.2)),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info button + bottom sheet ────────────────────────────────────────────────

class _InfoButton extends StatelessWidget {
  final bool isDark;
  const _InfoButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showXpGuide(context, isDark),
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: AppColors.brandPurple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline_rounded,
            size: 14, color: AppColors.brandPurple),
      ),
    );
  }

  void _showXpGuide(BuildContext context, bool isDark) {
    final bg     = AppColors.cardBg(isDark);
    final border = AppColors.borderColor(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hướng dẫn XP',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ..._xpRules(isDark),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _xpRules(bool isDark) {
    final items = [
      ('⚡', 'Hoàn thành câu hỏi',  '+5–15 XP'),
      ('🎯', 'Điểm cao (≥80)',       '+10 XP thưởng'),
      ('🔥', 'Hoàn thành bộ câu',   '+20 XP'),
      ('📈', 'Cải thiện điểm số',   '+5 XP thưởng'),
      ('⭐', 'Chuỗi streak',         '+2 XP / ngày'),
      ('🏆', 'Mở thành tích',       '+50 XP'),
    ];
    final txt = AppColors.textPrimary(isDark);
    return items.map((t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(t.$1, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.$2,
                style: TextStyle(
                    color: txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t.$3,
                style: const TextStyle(
                    color: AppColors.brandPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    )).toList();
  }
}

// ── Daily-goal picker ─────────────────────────────────────────────────────────

class _GoalPickerSheet extends StatefulWidget {
  final int currentGoal;
  final Future<bool> Function(int) onSelect;

  const _GoalPickerSheet(
      {required this.currentGoal, required this.onSelect});

  @override
  State<_GoalPickerSheet> createState() => _GoalPickerSheetState();
}

class _GoalPickerSheetState extends State<_GoalPickerSheet> {
  bool _saving = false;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = AppColors.cardBg(isDark);
    final border = AppColors.borderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mục tiêu XP hàng ngày',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn mục tiêu phù hợp với lịch trình của bạn',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ..._dailyGoalPresets.map((xp) => _GoalOption(
                xp: xp,
                selected: _selected == xp,
                isDark: isDark,
                onTap: () => setState(() => _selected = xp),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSelect(_selected);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu mục tiêu',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final int xp;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _GoalOption({
    required this.xp,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  String _label(int xp) {
    if (xp <= 20) return 'Nhẹ nhàng';
    if (xp <= 50) return 'Vừa phải';
    if (xp <= 80) return 'Nghiêm túc';
    return 'Chuyên sâu';
  }

  String _desc(int xp) {
    if (xp <= 20) return '≈ 1 câu hỏi / ngày';
    if (xp <= 50) return '≈ 2–3 câu hỏi / ngày';
    if (xp <= 80) return '≈ 4–5 câu hỏi / ngày';
    return '≈ 6–8 câu hỏi / ngày';
  }

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AppColors.brandPurple
        : (AppColors.borderColor(isDark));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPurple.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPurple
                    .withValues(alpha: selected ? 0.15 : 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$xp',
                  style: TextStyle(
                    color: AppColors.brandPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
                    '${_label(xp)} · $xp XP',
                    style: TextStyle(
                      color:
                          AppColors.textPrimary(isDark),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _desc(xp),
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
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.brandPurple, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color borderC;

  const _Skeleton(
      {required this.isDark, required this.cardBg, required this.borderC});

  @override
  Widget build(BuildContext context) {
    final shimmer =
        isDark ? const Color(0xFF252D4A) : const Color(0xFFEEF0F6);

    Widget box(double w, double h, {double r = 8}) => Container(
          width: w, height: h,
          decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(r)),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(140, 14, r: 6),
          const SizedBox(height: 16),
          Row(children: [
            box(60, 26, r: 10),
            const SizedBox(width: 8),
            box(70, 14, r: 6),
            const Spacer(),
            box(40, 20, r: 6),
          ]),
          const SizedBox(height: 12),
          box(double.infinity, 10, r: 8),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: box(double.infinity, 56, r: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          box(double.infinity, 80, r: 12),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
        );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color borderC;
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.isDark,
    required this.cardBg,
    required this.borderC,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderC),
      ),
      child: Column(
        children: [
          Text('⚠️',
              style: TextStyle(
                  fontSize: 28, color: Colors.orange.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại',
                style: TextStyle(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
