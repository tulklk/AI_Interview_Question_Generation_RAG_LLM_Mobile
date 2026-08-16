import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

const _kPrimary = Color(0xFF6C47FF);

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state  = ref.watch(savedSetsProvider);
    final sets   = state.displayed;

    final bg      = AppColors.surfaceBg(isDark);
    final cardBg  = isDark ? AppColors.darkSurface : AppColors.white;
    final border  = isDark ? AppColors.darkChip : AppColors.gray200;
    final textPri = AppColors.textPrimary(isDark);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.savedSets,
                          style: TextStyle(
                            color: textPri,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sets.length} bộ câu hỏi đã lưu',
                          style: TextStyle(color: textSub, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (state.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: textSub),
                      onPressed: () => ref.read(savedSetsProvider.notifier).load(),
                      tooltip: 'Làm mới',
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────────────
            Expanded(
              child: _Body(
                state:   state,
                sets:    sets,
                isDark:  isDark,
                cardBg:  cardBg,
                border:  border,
                textPri: textPri,
                textSub: textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final SavedSetsState state;
  final List<QuestionSet> sets;
  final bool isDark;
  final Color cardBg, border, textPri, textSub;

  const _Body({
    required this.state,
    required this.sets,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && sets.isEmpty) {
      return SavedSetSkeletonList(isDark: isDark);
    }

    if (state.error != null && sets.isEmpty) {
      return _ErrorState(
        message: state.error!,
        isDark:  isDark,
        textPri: textPri,
        textSub: textSub,
        onRetry: () => ref.read(savedSetsProvider.notifier).load(),
      );
    }

    if (sets.isEmpty) {
      return _EmptyState(
        isDark:  isDark,
        textPri: textPri,
        textSub: textSub,
      );
    }

    return RefreshIndicator(
      color:         _kPrimary,
      backgroundColor: cardBg,
      onRefresh: () => ref.read(savedSetsProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount: sets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final set = sets[i];
          return _SavedSetTile(
            key:    ValueKey(set.id),
            set:    set,
            index:  i,
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            textPri: textPri,
            textSub: textSub,
            onRemove: () async {
              final ok = await ref.read(savedSetsProvider.notifier).removeBookmark(set.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Không thể bỏ lưu. Vui lòng thử lại.'),
                    backgroundColor: isDark ? AppColors.darkChip : const Color(0xFF374151),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// ── Tile with swipe-to-remove ─────────────────────────────────────────────────

class _SavedSetTile extends StatelessWidget {
  final QuestionSet set;
  final int index;
  final bool isDark;
  final Color cardBg, border, textPri, textSub;
  final VoidCallback onRemove;

  const _SavedSetTile({
    super.key,
    required this.set,
    required this.index,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSub,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_remove_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(height: 4),
            Text(
              'Bỏ lưu',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onRemove();
        return false; // We handle removal ourselves via optimistic update
      },
      child: GestureDetector(
        onTap: () => context.push('/jobseeker/sets/${set.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Company logo / initials
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: set.companyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: set.companyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    set.companyInitials,
                    style: TextStyle(
                      color: set.companyColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      style: TextStyle(
                        color: textPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      set.company,
                      style: TextStyle(color: textSub, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(
                          icon: Icons.help_outline_rounded,
                          label: '${set.totalQuestions} câu',
                          isDark: isDark,
                        ),
                        _MetaChip(
                          icon: Icons.access_time_rounded,
                          label: set.estimatedTime,
                          isDark: isDark,
                        ),
                        _DifficultyBadge(difficulty: set.difficulty),
                      ],
                    ),
                    if (set.skills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: set.skills
                            .take(3)
                            .map((s) => _SkillChip(skill: s, isDark: isDark))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Actions column
              Column(
                children: [
                  // Remove bookmark button
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bookmark_remove_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? const Color(0xFF4A5578)
                        : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _MetaChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final QuestionDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        difficultyLabel(difficulty),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;
  final bool isDark;
  const _SkillChip({required this.skill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: isDark ? const Color(0xFFA78BFA) : _kPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color textPri, textSub;
  const _EmptyState({required this.isDark, required this.textPri, required this.textSub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: _kPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa lưu bộ câu hỏi nào',
              style: TextStyle(
                color: textPri,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu bộ câu hỏi yêu thích để luyện tập sau\nmà không cần tìm kiếm lại.',
              style: TextStyle(color: textSub, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/jobseeker'),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Khám phá bộ câu hỏi'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  final Color textPri, textSub;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.message,
    required this.isDark,
    required this.textPri,
    required this.textSub,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tải được',
              style: TextStyle(
                color: textPri,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: textSub, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

