import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/skill_icon.dart';
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
  int _currentPage = 0;
  static const _pageSize = 5;

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
    final apiState = ref.watch(marketplaceApiProvider);
    final filterNotifier = ref.read(marketplaceFilterProvider.notifier);

    // Trigger server-side refetch whenever filter changes.
    // Pill filters (difficulty/category) fire immediately; search is debounced.
    ref.listen<MarketplaceFilterState>(marketplaceFilterProvider,
        (prev, next) {
      if (prev == next) return;
      // Reset to first page whenever filter/search changes
      if (mounted) setState(() => _currentPage = 0);
      final isSearch = prev?.searchQuery != next.searchQuery;
      ref
          .read(marketplaceApiProvider.notifier)
          .scheduleRefresh(immediate: !isSearch);
    });

    Widget resultsHeader;
    if (apiState.isLoading) {
      resultsHeader = Text(
        'Đang tải...',
        style: AppTextStyles.labelBold.copyWith(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.45)
              : AppColors.gray400,
          fontSize: 13,
        ),
      );
    } else if (apiState.error != null) {
      resultsHeader = const SizedBox.shrink();
    } else {
      resultsHeader = Text(
        filteredSets.isEmpty
            ? l10n.noSetsFound
            : l10n.setsFound(filteredSets.length),
        style: AppTextStyles.labelBold.copyWith(
          color: AppColors.textPrimary(isDark),
          fontSize: 13,
        ),
      );
    }

    // Pagination
    final totalPages = filteredSets.isEmpty
        ? 1
        : ((filteredSets.length + _pageSize - 1) ~/ _pageSize);
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final pageStart = safePage * _pageSize;
    final pageEnd = (pageStart + _pageSize).clamp(0, filteredSets.length);
    final pagedSets = filteredSets.isEmpty ? <QuestionSet>[] : filteredSets.sublist(pageStart, pageEnd);

    Widget gridSliver;
    if (apiState.isLoading) {
      gridSliver = _SkeletonGrid(isDark: isDark);
    } else if (apiState.error != null) {
      gridSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          isDark: isDark,
          message: apiState.error!,
          onRetry: () => ref.read(marketplaceApiProvider.notifier).refresh(),
        ),
      );
    } else if (filteredSets.isEmpty) {
      gridSliver = SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(isDark: isDark),
      );
    } else {
      gridSliver = _SetsGrid(sets: pagedSets, isDark: isDark);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.brandPurple,
        onRefresh: () => ref.read(marketplaceApiProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero section ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroSection(isDark: isDark, l10n: l10n)
                  .animate()
                  .fadeIn(duration: 500.ms),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SearchBar(
                  controller: _searchCtrl,
                  isDark: isDark,
                  hint: l10n.searchSetsHint,
                  onChanged: filterNotifier.setSearch,
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
            ),

            // ── Compact filter bar ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _CompactFilterBar(
                  categories: _categories,
                  difficulties: _difficulties,
                  selectedCategory: filter.categoryFilter,
                  selectedDifficulty: filter.difficultyFilter,
                  isDark: isDark,
                  l10n: l10n,
                  onCategoryChanged: filterNotifier.setCategory,
                  onDifficultyChanged: filterNotifier.setDifficulty,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),

            // ── Results header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: resultsHeader,
              ).animate().fadeIn(delay: 260.ms),
            ),

            // ── Cards grid / skeleton / empty / error ────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: gridSliver,
            ),

            // ── Pagination controls ───────────────────────────────────────────
            if (!apiState.isLoading && apiState.error == null && totalPages > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  child: _PaginationBar(
                    currentPage: safePage,
                    totalPages:  totalPages,
                    isDark:      isDark,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                  ),
                ),
              ),

            if (apiState.isLoading || apiState.error != null || totalPages <= 1)
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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
        color: AppColors.cardBg(isDark),
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
                color: AppColors.textPrimary(isDark),
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
// Compact filter bar  (two dropdown-style buttons: category + difficulty)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactFilterBar extends StatelessWidget {
  final List<String> categories;
  final List<String> difficulties;
  final String selectedCategory;
  final String selectedDifficulty;
  final bool isDark;
  final AppLocalizations l10n;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onDifficultyChanged;

  const _CompactFilterBar({
    required this.categories,
    required this.difficulties,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.isDark,
    required this.l10n,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  });

  static const _catTints = {
    'All': AppColors.brandPurple,
    'Frontend': Color(0xFF3B82F6),
    'Full Stack': Color(0xFF8B5CF6),
    'Backend': Color(0xFF10B981),
    'Product': Color(0xFFF59E0B),
    'Data': Color(0xFFEC4899),
    'DevOps': Color(0xFF06B6D4),
  };

  static Color _diffColor(String d) {
    switch (d) {
      case 'Easy':   return const Color(0xFF10B981);
      case 'Medium': return const Color(0xFFF59E0B);
      case 'Hard':   return const Color(0xFFEF4444);
      default:       return AppColors.brandPurple;
    }
  }

  String _diffLabel(String d) {
    if (!l10n.isVi) return d;
    switch (d) {
      case 'Easy':   return 'Dễ';
      case 'Medium': return 'Trung bình';
      case 'Hard':   return 'Khó';
      default:       return l10n.isVi ? 'Tất cả' : 'All';
    }
  }

  void _showOptions({
    required BuildContext ctx,
    required String title,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
    String Function(String)? labelBuilder,
    Map<String, Color>? tints,
    Color Function(String)? colorBuilder,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _FilterOptionSheet(
        title: title,
        items: items,
        selected: selected,
        isDark: isDark,
        labelBuilder: labelBuilder,
        tints: tints,
        colorBuilder: colorBuilder,
        onSelect: (v) {
          onSelect(v);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catActive   = selectedCategory != 'All';
    final diffActive  = selectedDifficulty != 'All';
    final catColor    = _catTints[selectedCategory] ?? AppColors.brandPurple;
    final diffColor   = _diffColor(selectedDifficulty);

    return Row(
      children: [
        // ── Category ────────────────────────────────────────────────────────
        Expanded(
          child: _FilterDropBtn(
            icon: PhosphorIconsRegular.funnelSimple,
            label: catActive
                ? selectedCategory
                : (l10n.isVi ? 'Danh mục' : 'Category'),
            isActive: catActive,
            activeColor: catColor,
            isDark: isDark,
            onTap: () => _showOptions(
              ctx: context,
              title: l10n.isVi ? 'Chọn danh mục' : 'Select Category',
              items: categories,
              selected: selectedCategory,
              tints: _catTints,
              onSelect: onCategoryChanged,
            ),
            onClear: catActive ? () => onCategoryChanged('All') : null,
          ),
        ),
        const SizedBox(width: 10),
        // ── Difficulty ──────────────────────────────────────────────────────
        Expanded(
          child: _FilterDropBtn(
            icon: PhosphorIconsRegular.chartBar,
            label: diffActive
                ? _diffLabel(selectedDifficulty)
                : (l10n.isVi ? 'Cấp độ' : 'Level'),
            isActive: diffActive,
            activeColor: diffColor,
            isDark: isDark,
            onTap: () => _showOptions(
              ctx: context,
              title: l10n.isVi ? 'Chọn cấp độ' : 'Select Level',
              items: difficulties,
              selected: selectedDifficulty,
              colorBuilder: _diffColor,
              labelBuilder: _diffLabel,
              onSelect: onDifficultyChanged,
            ),
            onClear: diffActive ? () => onDifficultyChanged('All') : null,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single filter dropdown button
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterDropBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveIcon  = isDark
        ? AppColors.white.withValues(alpha: 0.40)
        : AppColors.gray400;
    final inactiveText  = isDark
        ? AppColors.white.withValues(alpha: 0.58)
        : AppColors.gray500;
    final borderColor   = isActive
        ? activeColor.withValues(alpha: isDark ? 0.55 : 0.45)
        : (AppColors.borderColor(isDark));
    final bgColor = isActive
        ? activeColor.withValues(alpha: isDark ? 0.15 : 0.09)
        : (AppColors.cardBg(isDark));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.12), blurRadius: 8)]
              : (isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : inactiveIcon,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  fontSize: 12.5,
                  color: isActive ? activeColor : inactiveText,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            // Show × when active, ▾ when inactive
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.close_rounded, size: 14, color: activeColor),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: inactiveIcon,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter option bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterOptionSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final String Function(String)? labelBuilder;
  final Map<String, Color>? tints;
  final Color Function(String)? colorBuilder;

  const _FilterOptionSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    this.labelBuilder,
    this.tints,
    this.colorBuilder,
  });

  Color _colorFor(String item) {
    if (tints != null) return tints![item] ?? AppColors.brandPurple;
    if (colorBuilder != null) return colorBuilder!(item);
    return AppColors.brandPurple;
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xFF131929) : Colors.white;
    final handleC = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 14, 20, MediaQuery.of(context).padding.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: handleC,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          // Options
          ...items.map((item) {
            final isSelected = item == selected;
            final color = _colorFor(item);
            final displayLabel = labelBuilder != null ? labelBuilder!(item) : item;

            return GestureDetector(
              onTap: () => onSelect(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: isDark ? 0.18 : 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.45 : 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    // Color dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayLabel,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : const Color(0xFF374151)),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, size: 18, color: color),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loading grid
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  final bool isDark;
  const _SkeletonGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _SkeletonCard(isDark: isDark),
        ),
        childCount: 4,
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = isDark ? AppColors.darkCard : AppColors.gray200;
        final highlight = isDark ? const Color(0xFF252B47) : AppColors.gray100;
        final shimmer = Color.lerp(base, highlight, _anim.value)!;
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor(isDark),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: shimmer,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: double.infinity,
                        decoration: BoxDecoration(color: shimmer,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 120,
                        decoration: BoxDecoration(color: shimmer,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                )),
                const SizedBox(width: 8),
                Container(width: 50, height: 22,
                    decoration: BoxDecoration(color: shimmer,
                        borderRadius: BorderRadius.circular(100))),
              ]),
              const SizedBox(height: 14),
              Container(height: 10, width: double.infinity,
                  decoration: BoxDecoration(color: shimmer,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(height: 10, width: 200,
                  decoration: BoxDecoration(color: shimmer,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 14),
              Row(children: [
                Container(width: 60, height: 22,
                    decoration: BoxDecoration(color: shimmer,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 8),
                Container(width: 60, height: 22,
                    decoration: BoxDecoration(color: shimmer,
                        borderRadius: BorderRadius.circular(6))),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 52,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.25)
                  : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bộ câu hỏi',
              style: AppTextStyles.labelBold.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.45)
                    : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.wifiX,
              size: 52,
              color: const Color(0xFFEF4444).withValues(alpha: 0.70),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: AppTextStyles.labelBold.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.45)
                    : AppColors.gray400,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise,
                  size: 15),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandPurple,
                side: const BorderSide(color: AppColors.brandPurple),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive grid
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.isDark,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Build page number buttons — show at most 5 page numbers with ellipsis
    final pages = <int?>[];
    if (totalPages <= 7) {
      for (var i = 0; i < totalPages; i++) pages.add(i);
    } else {
      pages.add(0);
      if (currentPage > 2) pages.add(null); // ellipsis
      final start = (currentPage - 1).clamp(1, totalPages - 2);
      final end   = (currentPage + 1).clamp(1, totalPages - 2);
      for (var i = start; i <= end; i++) pages.add(i);
      if (currentPage < totalPages - 3) pages.add(null); // ellipsis
      pages.add(totalPages - 1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 0,
          isDark: isDark,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),

        // Page numbers
        ...pages.map((p) {
          if (p == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('…',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black26,
                      fontSize: 14)),
            );
          }
          final isActive = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: isActive ? null : () => onPageChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6C47FF)
                      : (isDark
                          ? AppColors.darkCard
                          : AppColors.gray100),
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? null
                      : Border.all(
                          color: AppColors.borderColor(isDark)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${p + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF374151)),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 4),
        // Next
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages - 1,
          isDark: isDark,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.borderColor(isDark)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? (isDark ? Colors.white : const Color(0xFF374151))
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sets grid
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

    return GestureDetector(
      onTap: () => context.go('/jobseeker/sets/${s.id}'),
      child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -3.0, 0.0))
            : Matrix4.identity(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1D2E).withValues(alpha: 0.72)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hovered
                      ? AppColors.brandPurple.withValues(alpha: 0.28)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFF6C47FF).withValues(alpha: 0.09)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hovered ? 0.18 : 0.08),
                    blurRadius: _hovered ? 28 : 14,
                    offset: Offset(0, _hovered ? 12 : 5),
                  ),
                  if (_hovered)
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.14),
                      blurRadius: 22,
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
                  // Company avatar — logo image if available, else initials
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: s.companyLogo != null
                        ? Image.network(
                            s.companyLogo!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _CompanyInitialsAvatar(
                              initials: s.companyInitials,
                              color: s.companyColor,
                            ),
                          )
                        : _CompanyInitialsAvatar(
                            initials: s.companyInitials,
                            color: s.companyColor,
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
                            color: AppColors.textPrimary(isDark),
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

              // ── Description — skip internal metadata strings ─────────────
              if (_isValidDescription(s.description)) ...[
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
              ],

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

              // ── CTA button ──────────────────────────────────────────────
              const SizedBox(height: 12),
              AppGradientButton(
                label: 'Start Practice →',
                height: 42,
                onTap: () => context.go('/jobseeker/sets/${s.id}'),
              ),
            ],
          ),   // Column
        ),     // Padding
      ),       // inner AnimatedContainer (decoration)
    ),         // BackdropFilter
  ),           // ClipRRect
),             // outer AnimatedContainer (transform)
      ),       // MouseRegion
    );         // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Company initials avatar (fallback when no logo URL)
// ─────────────────────────────────────────────────────────────────────────────

class _CompanyInitialsAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _CompanyInitialsAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: color,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
    return buildSkillTag(label: label, isDark: isDark, accentColor: color);
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

// Returns false for internal metadata strings that should never be shown to users
// (e.g. "STUDIO_SAVE;\nproject=...").
bool _isValidDescription(String desc) {
  if (desc.trim().isEmpty) return false;
  final upper = desc.trimLeft().toUpperCase();
  if (upper.startsWith('STUDIO_')) return false;
  if (desc.contains('project=')) return false;
  return true;
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
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.3;
    final empty = (5 - full - (hasHalf ? 1 : 0)).clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(full, (_) => const Icon(PhosphorIconsBold.star, size: 14, color: Color(0xFFF59E0B))),
        if (hasHalf) const Icon(PhosphorIconsBold.starHalf, size: 14, color: Color(0xFFF59E0B)),
        ...List.generate(empty, (_) => const Icon(PhosphorIconsRegular.star, size: 14, color: Color(0xFFF59E0B))),
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
