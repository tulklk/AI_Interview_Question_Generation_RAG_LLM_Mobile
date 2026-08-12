import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/jobseeker_models.dart';
import '../../../providers/jobseeker_providers.dart';

// ── Public grid ───────────────────────────────────────────────────────────────

class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(gamificationProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = AppColors.cardBg(isDark);
    final borderC = AppColors.borderColor(isDark);

    if (state.isLoading && state.achievements.isEmpty) {
      return _Skeleton(isDark: isDark, cardBg: cardBg, borderC: borderC);
    }

    final achievements = state.achievements;
    final earned       = state.earnedCount;
    final total        = achievements.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                  'Thành tích',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$earned/$total đạt',
                  style: const TextStyle(
                    color: AppColors.brandPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Grid ────────────────────────────────────────────────────────
          if (achievements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có thành tích',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: achievements.asMap().entries.map((e) {
                final idx = e.key;
                final ach = e.value;
                return _AchievementTile(
                  achievement: ach,
                  isDark: isDark,
                )
                    .animate(delay: (idx * 50).ms)
                    .fadeIn(duration: 360.ms)
                    .scaleXY(begin: 0.75, curve: Curves.easeOutBack);
              }).toList(),
            ),

          // ── Footer hint ─────────────────────────────────────────────────
          if (achievements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Nhấn vào thành tích để xem chi tiết',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 450.ms).slideY(begin: 0.05);
  }
}

// ── Achievement tile (tappable) ───────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  final GamificationAchievement achievement;
  final bool isDark;

  const _AchievementTile({
    required this.achievement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ach      = achievement;
    final unlocked = ach.unlocked;

    return GestureDetector(
      onTap: () => _showDetail(context, ach, isDark),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandPurple
                        .withValues(alpha: isDark ? 0.28 : 0.12),
                    AppColors.brandPurple
                        .withValues(alpha: isDark ? 0.14 : 0.04),
                  ],
                )
              : null,
          color: unlocked
              ? null
              : (isDark
                  ? const Color(0xFF0D1117)
                  : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked
                ? AppColors.brandPurple
                    .withValues(alpha: isDark ? 0.50 : 0.30)
                : (isDark
                    ? AppColors.darkChip
                    : AppColors.gray200),
            width: unlocked ? 1.5 : 1.0,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Must fill + center — Stack children default to top-left
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: unlocked ? 1.0 : 0.30,
                        child: Text(
                          ach.icon,
                          style: const TextStyle(fontSize: 26, height: 1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ach.name,
                        style: TextStyle(
                          color: unlocked
                              ? (AppColors.textPrimary(isDark))
                              : (isDark
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFD1D5DB)),
                          fontSize: 10,
                          fontWeight:
                              unlocked ? FontWeight.w600 : FontWeight.w500,
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 4, right: 4,
              child: unlocked
                  ? Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 9, color: Colors.white),
                    )
                  : Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkChip
                            : AppColors.gray200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          size: 8, color: Color(0xFF9CA3AF)),
                    ),
            ),

            if (ach.isNew)
              Positioned(
                top: 4, left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, GamificationAchievement ach, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AchievementDetailSheet(
        achievement: ach,
        isDark: isDark,
      ),
    );
  }
}

// ── Achievement detail bottom sheet ──────────────────────────────────────────

class _AchievementDetailSheet extends StatelessWidget {
  final GamificationAchievement achievement;
  final bool isDark;

  const _AchievementDetailSheet({
    required this.achievement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ach      = achievement;
    final unlocked = ach.unlocked;
    final tips     = _howToEarn(ach.code);
    final bg       = AppColors.cardBg(isDark);
    final borderC  = AppColors.borderColor(isDark);
    final txtColor = AppColors.textPrimary(isDark);
    final subColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final hasProgress =
        ach.currentValue != null && ach.targetValue != null && ach.targetValue! > 0;
    final pct = hasProgress
        ? (ach.currentValue! / ach.targetValue!).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderC)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 24),

          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: unlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandPurple.withValues(alpha: 0.20),
                        AppColors.brandPurple.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: unlocked
                  ? null
                  : (isDark
                      ? const Color(0xFF0D1117)
                      : AppColors.gray100),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? AppColors.brandPurple.withValues(alpha: 0.35)
                    : (isDark
                        ? AppColors.darkChip
                        : AppColors.gray200),
                width: unlocked ? 2 : 1.5,
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: unlocked ? 1.0 : 0.35,
                child: Text(
                  ach.icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            ach.name,
            style: TextStyle(
              color: txtColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : (AppColors.chipBg(isDark)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unlocked
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  size: 13,
                  color: unlocked
                      ? const Color(0xFF10B981)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 5),
                Text(
                  unlocked
                      ? (ach.unlockedAt != null
                          ? 'Đã đạt · ${_formatDate(ach.unlockedAt!)}'
                          : 'Đã đạt được')
                      : 'Chưa đạt được',
                  style: TextStyle(
                    color: unlocked
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
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
            child: Text(
              ach.description,
              style: TextStyle(
                color: subColor,
                fontSize: 13,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (hasProgress) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ',
                  style: TextStyle(
                    color: txtColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${ach.currentValue}/${ach.targetValue}',
                  style: const TextStyle(
                    color: AppColors.brandPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.darkChip
                    : AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  unlocked
                      ? const Color(0xFF10B981)
                      : AppColors.brandPurple,
                ),
              ),
            ),
          ],

          if (ach.xpReward != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                          style: TextStyle(fontSize: 13, height: 1)),
                      const SizedBox(width: 5),
                      Text(
                        '+${ach.xpReward} XP thưởng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          if (!unlocked && tips.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Divider(label: 'Cách đạt được', isDark: isDark),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (unlocked) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Xuất sắc! Bạn đã đạt được thành tích này.\nHãy tiếp tục duy trì phong độ nhé!',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
      'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

List<String> _howToEarn(String code) {
  switch (code) {
    case 'FIRST_STEP':
      return [
        'Chọn một bộ câu hỏi bất kỳ từ Thị trường',
        'Hoàn thành toàn bộ phiên luyện tập',
        'Xem kết quả và phản hồi từ AI',
      ];
    case 'ON_FIRE':
      return [
        'Luyện tập ít nhất 1 phiên mỗi ngày',
        'Duy trì chuỗi không nghỉ trong 7 ngày liên tiếp',
        'Mỗi ngày đạt ít nhất mục tiêu XP tối thiểu',
      ];
    case 'EXCELLENT_ANSWER':
      return [
        'Trả lời đầy đủ, có cấu trúc rõ ràng (STAR method)',
        'Đưa ra ví dụ cụ thể từ kinh nghiệm thực tế',
        'Đạt điểm AI 90 trở lên trong một phiên bất kỳ',
      ];
    case 'DEDICATED':
      return [
        'Luyện tập đều đặn mỗi ngày',
        'Thử thách bản thân với các bộ câu hỏi khác nhau',
        'Hoàn thành tổng cộng 10 phiên luyện tập',
      ];
    case 'TECHNICAL_MIND':
      return [
        'Tìm các bộ câu hỏi có nhãn "Technical"',
        'Hoàn thành ít nhất 5 bộ câu hỏi kỹ thuật',
        'Tập trung vào các câu hỏi về thuật toán, hệ thống',
      ];
    case 'SYSTEM_THINKER':
      return [
        'Luyện tập câu hỏi Kỹ thuật (Technical)',
        'Luyện tập câu hỏi Hành vi (Behavioral)',
        'Luyện tập câu hỏi Tình huống (Situational)',
      ];
    case 'CONSISTENCY':
      return [
        'Đặt mục tiêu XP hàng ngày phù hợp với lịch của bạn',
        'Đạt mục tiêu XP đó mỗi ngày trong 30 ngày',
        'Dùng nhắc nhở để không bỏ lỡ ngày nào',
      ];
    case 'INTERVIEW_VETERAN':
      return [
        'Luyện tập đều đặn theo từng tuần',
        'Thử nghiệm với nhiều công ty và vị trí khác nhau',
        'Hoàn thành tổng cộng 50 phiên luyện tập',
      ];
    default:
      return ['Hoàn thành các yêu cầu của thành tích này'];
  }
}

class _Divider extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Divider({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lineC = isDark ? AppColors.darkChip : AppColors.gray200;
    return Row(
      children: [
        Expanded(child: Divider(color: lineC, height: 1)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: lineC, height: 1)),
      ],
    );
  }
}

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
          Row(children: [
            box(90, 14, r: 6),
            const Spacer(),
            box(60, 22, r: 11),
          ]),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: List.generate(8, (_) =>
              box(double.infinity, double.infinity, r: 14),
            ),
          ),
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
