import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

// ── Exported card so the dashboard can import it ──────────────────────────────
export 'marketplace_screen.dart' show QuestionSetCard;

// ─────────────────────────────────────────────────────────────────────────────
// MarketplaceScreen
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();

  static const _categories = [
    'All',
    'Frontend',
    'Full Stack',
    'Backend',
    'Product',
    'Data',
    'DevOps',
  ];

  static const _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final filter = ref.watch(marketplaceFilterProvider);
    final filteredSets = ref.watch(filteredSetsProvider);
    final notifier = ref.read(marketplaceFilterProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Hero section ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(isDark: isDark, l10n: l10n)
                .animate()
                .fadeIn(duration: 500.ms),
          ),

          // ── Search bar ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _SearchBar(
                controller: _searchCtrl,
                isDark: isDark,
                hint: l10n.searchSetsHint,
                onChanged: notifier.setSearch,
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
          ),

          // ── Category pills ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
              child: _CategoryPills(
                categories: _categories,
                selected: filter.categoryFilter,
                isDark: isDark,
                onSelect: notifier.setCategory,
                l10n: l10n,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

          // ── Difficulty pills ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: _DifficultyPills(
                difficulties: _difficulties,
                selected: filter.difficultyFilter,
                isDark: isDark,
                onSelect: notifier.setDifficulty,
              ),
            ).animate().fadeIn(delay: 230.ms),
          ),

          // ── Results header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                filteredSets.isEmpty
                    ? l10n.noSetsFound
                    : l10n.setsFound(filteredSets.length),
                style: AppTextStyles.labelBold.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                  fontSize: 13,
                ),
              ),
            ).animate().fadeIn(delay: 260.ms),
          ),

          // ── Cards grid ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: _SetsGrid(sets: filteredSets, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;

  const _HeroSection({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 32,
        24,
        40,
      ),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A0C3E), Color(0xFF0B1020)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFF3B1FA8), Color(0xFF6C47FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsBold.sparkle,
                    size: 12, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  l10n.aiPoweredBadge,
                  style: AppTextStyles.overline.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 20),

          // Title line 1
          Text(
            l10n.marketplaceTitle1,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1, end: 0),

          // Title line 2 — gradient text via ShaderMask
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              l10n.marketplaceTitle2,
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 14),

          // Subtitle
          Text(
            l10n.marketplaceSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 14,
              height: 1.55,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // CTA button
          _GradientHeroButton(label: l10n.startPracticingFree)
              .animate()
              .fadeIn(delay: 240.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 10),

          Text(
            l10n.noCreditCard,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ).animate().fadeIn(delay: 280.ms),
        ],
      ),
    );
  }
}

class _GradientHeroButton extends StatefulWidget {
  final String label;
  const _GradientHeroButton({required this.label});

  @override
  State<_GradientHeroButton> createState() => _GradientHeroButtonState();
}

class _GradientHeroButtonState extends State<_GradientHeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C47FF), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F35) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.gray200,
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
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            PhosphorIconsBold.magnifyingGlass,
            size: 17,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.35)
                : AppColors.gray400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.nearBlack,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.30)
                      : AppColors.gray400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category pills
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final AppLocalizations l10n;

  const _CategoryPills({
    required this.categories,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = cat == selected;
          final isAll = cat == 'All';

          Color activeColor;
          if (isAll) {
            activeColor = AppColors.brandPurple;
          } else {
            // Assign unique tints per category
            const tints = {
              'Frontend': Color(0xFF3B82F6),
              'Full Stack': Color(0xFF8B5CF6),
              'Backend': Color(0xFF10B981),
              'Product': Color(0xFFF59E0B),
              'Data': Color(0xFFEC4899),
              'DevOps': Color(0xFF06B6D4),
            };
            activeColor = tints[cat] ?? AppColors.brandPurple;
          }

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? (isAll ? AppColors.brandPurple : activeColor.withValues(alpha: 0.15))
                    : (isDark ? const Color(0xFF1A1F35) : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isActive
                      ? (isAll ? AppColors.brandPurple : activeColor)
                      : (isDark ? AppColors.darkCardBorder : AppColors.gray200),
                ),
              ),
              child: Text(
                cat,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isAll ? Colors.white : activeColor)
                      : (isDark
                          ? AppColors.white.withValues(alpha: 0.70)
                          : AppColors.gray500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty pills
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyPills extends StatelessWidget {
  final List<String> difficulties;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _DifficultyPills({
    required this.difficulties,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  Color _colorFor(String d) {
    switch (d) {
      case 'Easy':   return const Color(0xFF10B981);
      case 'Medium': return const Color(0xFFF59E0B);
      case 'Hard':   return const Color(0xFFEF4444);
      default:       return AppColors.brandPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: difficulties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final diff = difficulties[i];
          final isActive = diff == selected;
          final color = _colorFor(diff);

          return GestureDetector(
            onTap: () => onSelect(diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1A1F35) : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isActive
                      ? color
                      : (isDark ? AppColors.darkCardBorder : AppColors.gray200),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                diff,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? color
                      : (isDark
                          ? AppColors.white.withValues(alpha: 0.70)
                          : AppColors.gray500),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive grid
// ─────────────────────────────────────────────────────────────────────────────

class _SetsGrid extends StatelessWidget {
  final List<QuestionSet> sets;
  final bool isDark;

  const _SetsGrid({required this.sets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        int cols = 1;
        if (width >= 960) cols = 3;
        else if (width >= 600) cols = 2;

        if (cols == 1) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: QuestionSetCard(set: sets[i], isDark: isDark)
                    .animate()
                    .fadeIn(delay: (i * 60).ms)
                    .slideY(begin: 0.08, end: 0),
              ),
              childCount: sets.length,
            ),
          );
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => QuestionSetCard(set: sets[i], isDark: isDark)
                .animate()
                .fadeIn(delay: (i * 50).ms)
                .slideY(begin: 0.06, end: 0),
            childCount: sets.length,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuestionSetCard  (exported — reused by dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class QuestionSetCard extends StatefulWidget {
  final QuestionSet set;
  final bool isDark;

  const QuestionSetCard({
    super.key,
    required this.set,
    required this.isDark,
  });

  @override
  State<QuestionSetCard> createState() => _QuestionSetCardState();
}

class _QuestionSetCardState extends State<QuestionSetCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.set;
    final isDark = widget.isDark;

    const skillChipColors = [
      Color(0xFF0D9488),
      Color(0xFF3B82F6),
      Color(0xFF0891B2),
      Color(0xFF0284C7),
    ];

    final displaySkills = s.skills.take(4).toList();
    final overflowCount = s.skills.length > 4 ? s.skills.length - 4 : 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -3.0, 0.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.14 : 0.06),
              blurRadius: _hovered ? 28 : 12,
              spreadRadius: _hovered ? -2 : -4,
              offset: Offset(0, _hovered ? 12 : 4),
            ),
            if (_hovered)
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: s.companyColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        s.companyInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title + company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: AppTextStyles.labelBold.copyWith(
                            fontSize: 14,
                            color: isDark ? AppColors.white : AppColors.nearBlack,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.l10n.by} ${s.company}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.white.withValues(alpha: 0.45)
                                : AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Difficulty pill (right-aligned)
                  const SizedBox(width: 8),
                  _DifficultyPill(difficulty: s.difficulty),
                ],
              ),

              // ── Description ─────────────────────────────────────────────
              const SizedBox(height: 10),
              Text(
                s.description,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.55)
                      : AppColors.gray500,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Skill chips ─────────────────────────────────────────────
              if (s.skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...displaySkills.asMap().entries.map((e) {
                      final color = skillChipColors[e.key % skillChipColors.length];
                      return _SkillChip(
                        label: e.value,
                        color: color,
                        isDark: isDark,
                      );
                    }),
                    if (overflowCount > 0)
                      _SkillChip(
                        label: '+$overflowCount',
                        color: AppColors.gray400,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],

              // ── Meta row ────────────────────────────────────────────────
              const SizedBox(height: 10),
              _MetaRow(set: s, isDark: isDark),

              // ── Rating ──────────────────────────────────────────────────
              if (s.rating != null) ...[
                const SizedBox(height: 8),
                _RatingRow(rating: s.rating!, isDark: isDark),
              ],

              const Spacer(),

              // ── CTA button ──────────────────────────────────────────────
              const SizedBox(height: 12),
              AppGradientButton(
                label: 'Start Practice →',
                height: 42,
                onTap: () => context.go('/jobseeker/sets/${s.id}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty pill
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyPill extends StatelessWidget {
  final QuestionDifficulty difficulty;
  const _DifficultyPill({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficultyLabel(difficulty),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill chip
// ─────────────────────────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _SkillChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.withValues(alpha: 0.90) : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta row
// ─────────────────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final QuestionSet set;
  final bool isDark;

  const _MetaRow({required this.set, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? AppColors.white.withValues(alpha: 0.45)
        : AppColors.gray400;

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        _MetaItem(
          icon: PhosphorIconsRegular.list,
          label: '${set.totalQuestions} questions',
          color: color,
        ),
        _MetaItem(
          icon: PhosphorIconsRegular.clock,
          label: set.estimatedTime,
          color: color,
        ),
        if (set.attempts != null)
          _MetaItem(
            icon: PhosphorIconsRegular.users,
            label: '${set.attempts}${context.l10n.attemptsSuffix}',
            color: color,
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating row
// ─────────────────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final double rating;
  final bool isDark;

  const _RatingRow({required this.rating, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < filled ? PhosphorIconsBold.star : PhosphorIconsRegular.star,
            size: 14,
            color: const Color(0xFFF59E0B),
          );
        }),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.60)
                : AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
