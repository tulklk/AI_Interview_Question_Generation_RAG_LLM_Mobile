import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';

class SetDetailScreen extends StatelessWidget {
  final String setId;
  const SetDetailScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context) {
    final set = findSetById(setId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    if (set == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF6B7280)),
              const SizedBox(height: 12),
              Text(
                'Question set not found',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/jobseeker'),
                child: Text(l10n.backToSets),
              ),
            ],
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 840;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back link
            GestureDetector(
              onTap: () => context.go('/jobseeker'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 16, color: const Color(0xFF6C47FF)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.backToSets,
                    style: const TextStyle(
                      color: Color(0xFF6C47FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),

            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 55,
                    child: _LeftColumn(set: set, isDark: isDark, l10n: l10n),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 280,
                    child: _OverviewCard(set: set, isDark: isDark, l10n: l10n),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms)
            else
              Column(
                children: [
                  _LeftColumn(set: set, isDark: isDark, l10n: l10n)
                      .animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  _OverviewCard(set: set, isDark: isDark, l10n: l10n)
                      .animate().fadeIn(delay: 100.ms),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Left Column ───────────────────────────────────────────────────────────────

class _LeftColumn extends StatelessWidget {
  final QuestionSet set;
  final bool isDark;
  final AppLocalizations l10n;

  const _LeftColumn({required this.set, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scoreC = difficultyColor(set.difficulty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company + title
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: set.companyColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  set.companyInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.by} ${set.company}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DifficultyPill(difficulty: set.difficulty),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          set.description,
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 14,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 14),

        // Meta row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _MetaChip(
              icon: Icons.quiz_rounded,
              label: '${set.totalQuestions} questions',
              isDark: isDark,
            ),
            _MetaChip(
              icon: Icons.access_time_rounded,
              label: set.estimatedTime,
              isDark: isDark,
            ),
            if (set.attempts != null)
              _MetaChip(
                icon: Icons.people_rounded,
                label: '${set.attempts} attempts',
                isDark: isDark,
              ),
            if (set.rating != null)
              _MetaChip(
                icon: Icons.star_rounded,
                label: '${set.rating!.toStringAsFixed(1)} ★',
                isDark: isDark,
                iconColor: const Color(0xFFF59E0B),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Skills covered
        Text(
          l10n.skillsCovered,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: set.skills
              .map((s) => _SkillTag(label: s, isDark: isDark))
              .toList(),
        ),

        const SizedBox(height: 24),

        // Question Preview accordion
        Text(
          l10n.questionPreview,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _QuestionPreviewAccordion(set: set, isDark: isDark, l10n: l10n),
      ],
    );
  }
}

// ── Question Preview Accordion ────────────────────────────────────────────────

class _QuestionPreviewAccordion extends StatefulWidget {
  final QuestionSet set;
  final bool isDark;
  final AppLocalizations l10n;

  const _QuestionPreviewAccordion({
    required this.set,
    required this.isDark,
    required this.l10n,
  });

  @override
  State<_QuestionPreviewAccordion> createState() =>
      _QuestionPreviewAccordionState();
}

class _QuestionPreviewAccordionState extends State<_QuestionPreviewAccordion> {
  // Track expanded categories
  final Set<QuestionCategory> _expanded = {QuestionCategory.Technical};

  @override
  Widget build(BuildContext context) {
    // Group by category in fixed order
    final order = [
      QuestionCategory.Technical,
      QuestionCategory.Behavioral,
      QuestionCategory.Situational
    ];

    return Column(
      children: order.map((cat) {
        final questions =
            widget.set.questions.where((q) => q.category == cat).toList();
        if (questions.isEmpty) return const SizedBox.shrink();

        final isOpen = _expanded.contains(cat);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF1A1F35)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF2D3562)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                // Header
                GestureDetector(
                  onTap: () => setState(() {
                    if (isOpen) {
                      _expanded.remove(cat);
                    } else {
                      _expanded.add(cat);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.l10n.nQuestionsInCategory(
                                categoryLabel(cat), questions.length),
                            style: TextStyle(
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          isOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: widget.isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOpen) ...[
                  Divider(
                    height: 1,
                    color: widget.isDark
                        ? const Color(0xFF2D3562)
                        : const Color(0xFFE5E7EB),
                  ),
                  ...questions.asMap().entries.map((e) {
                    final q = e.value;
                    final idx = e.key;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C47FF)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF6C47FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q.text,
                                  style: TextStyle(
                                    color: widget.isDark
                                        ? const Color(0xFFE5E7EB)
                                        : const Color(0xFF374151),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _DifficultyPill(difficulty: q.difficulty),
                            ],
                          ),
                        ),
                        if (idx < questions.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: widget.isDark
                                ? const Color(0xFF2D3562)
                                : const Color(0xFFF3F4F6),
                          ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Overview Card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final QuestionSet set;
  final bool isDark;
  final AppLocalizations l10n;

  const _OverviewCard({required this.set, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sessionOverview,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _OverviewRow(
            label: l10n.totalQuestions,
            value: '${set.totalQuestions}',
            isDark: isDark,
          ),
          _OverviewRow(
            label: l10n.estimatedTime,
            value: set.estimatedTime,
            isDark: isDark,
          ),
          _OverviewRow(
            label: l10n.difficulty,
            value: null,
            isDark: isDark,
            chip: _DifficultyPill(difficulty: set.difficulty),
          ),
          _OverviewRow(
            label: l10n.targetScore,
            value: '≥ 75 / 100',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.skills,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: set.skills
                .map((s) => _SkillTag(label: s, isDark: isDark))
                .toList(),
          ),
          const SizedBox(height: 16),
          // CTA
          SizedBox(
            width: double.infinity,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/jobseeker/practice/${set.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  l10n.startPractice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final Widget? chip;

  const _OverviewRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
          chip ??
              Text(
                value ?? '',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

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
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SkillTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6C47FF).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFF6C47FF).withValues(alpha: isDark ? 0.35 : 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark
              ? const Color(0xFFA78BFA)
              : const Color(0xFF6C47FF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? iconColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ??
        (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
