import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/question_model.dart';

class AIGeneratorScreen extends ConsumerStatefulWidget {
  const AIGeneratorScreen({super.key});

  @override
  ConsumerState<AIGeneratorScreen> createState() => _AIGeneratorScreenState();
}

class _AIGeneratorScreenState extends ConsumerState<AIGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final _jdCtrl = TextEditingController();
  late TabController _tabCtrl;
  QuestionType _type = QuestionType.mixed;
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;
  int _count = 5;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _jdCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    await ref.read(aiGeneratorProvider.notifier).generate(
      jobDescription: _jdCtrl.text,
      type: _type,
      difficulty: _difficulty,
      count: _count,
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGeneratorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              PhosphorIconsBold.arrowLeft,
              size: 18,
              color: isDark ? AppColors.white : AppColors.nearBlack,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(PhosphorIconsBold.sparkle,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Question Generator',
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Config panel ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Job Description',
                          hint:
                              'Paste the job description here to generate relevant interview questions...',
                          controller: _jdCtrl,
                          maxLines: 4,
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 20),
                        _ConfigRow(
                          isDark: isDark,
                          children: [
                            _ConfigItem(
                              label: 'Type',
                              child: _TypeSelector(
                                value: _type,
                                onChanged: (t) =>
                                    setState(() => _type = t),
                                isDark: isDark,
                              ),
                            ),
                            _ConfigItem(
                              label: 'Difficulty',
                              child: _DifficultySelector(
                                value: _difficulty,
                                onChanged: (d) =>
                                    setState(() => _difficulty = d),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 150.ms),
                        const SizedBox(height: 16),
                        _ConfigRow(
                          isDark: isDark,
                          children: [
                            _ConfigItem(
                              label: 'Questions: $_count',
                              child: SliderTheme(
                                data: SliderThemeData(
                                  thumbColor: AppColors.brandPurple,
                                  activeTrackColor: AppColors.brandPurple,
                                  inactiveTrackColor: AppColors.brandPurple
                                      .withValues(alpha: 0.15),
                                  overlayColor: AppColors.brandPurple
                                      .withValues(alpha: 0.12),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: _count.toDouble(),
                                  min: 3,
                                  max: 15,
                                  divisions: 12,
                                  onChanged: (v) =>
                                      setState(() => _count = v.round()),
                                ),
                              ),
                            ),
                            _ConfigItem(
                              label: 'Language',
                              child: Row(
                                children:
                                    ['English', 'Vietnamese'].map((l) {
                                  final isActive = _language == l;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _language = l),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9),
                                        decoration: BoxDecoration(
                                          gradient: isActive
                                              ? AppColors.primaryGradient
                                              : null,
                                          color: isActive
                                              ? null
                                              : (isDark
                                                  ? const Color(0xFF0D1222)
                                                  : AppColors.offWhite),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.transparent
                                                : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.07)
                                                    : AppColors.gray200),
                                          ),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.brandPurple
                                                        .withValues(alpha: 0.30),
                                                    blurRadius: 8,
                                                    spreadRadius: -2,
                                                    offset:
                                                        const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          l,
                                          textAlign: TextAlign.center,
                                          style:
                                              AppTextStyles.caption.copyWith(
                                            color: isActive
                                                ? Colors.white
                                                : (isDark
                                                    ? AppColors.white
                                                        .withValues(alpha: 0.45)
                                                    : AppColors.gray500),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 20),
                        AppGradientButton(
                          label: aiState.isGenerating
                              ? 'Generating...'
                              : 'Generate Questions',
                          isLoading: aiState.isGenerating,
                          onTap: aiState.isGenerating ? null : _generate,
                          height: 54,
                          icon: aiState.isGenerating
                              ? null
                              : const Icon(PhosphorIconsBold.robot,
                                  size: 18, color: Colors.white),
                        ).animate().fadeIn(delay: 250.ms),
                      ],
                    ),
                  ),
                ),

                // ── Results header ────────────────────────────────────────
                if (aiState.generatedQuestions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsBold.sparkle,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '${aiState.generatedQuestions.length} questions generated',
                                  style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          AppSecondaryButton(
                            label: 'Save Kit',
                            height: 36,
                            width: 90,
                            onTap: () {},
                            icon: const Icon(
                                PhosphorIconsBold.floppyDisk,
                                size: 14,
                                color: AppColors.brandPurple),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final q = aiState.generatedQuestions[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionCard(
                                    question: q,
                                    index: i + 1,
                                    isDark: isDark)
                                .animate()
                                .fadeIn(delay: (i * 80).ms)
                                .slideY(begin: 0.15, end: 0),
                          );
                        },
                        childCount:
                            aiState.generatedQuestions.length,
                      ),
                    ),
                  ),
                ],

                // ── Empty state ───────────────────────────────────────────
                if (!aiState.isGenerating &&
                    aiState.generatedQuestions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1D2440),
                                    const Color(0xFF131825)
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFF8F9FE)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.brandPurple
                                .withValues(alpha: isDark ? 0.14 : 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.brandPurple
                                          .withValues(alpha: 0.12),
                                      AppColors.brandPurple
                                          .withValues(alpha: 0.03),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIconsBold.robot,
                                  size: 28,
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'AI questions will appear here',
                                style: AppTextStyles.label.copyWith(
                                  color: isDark
                                      ? AppColors.white
                                          .withValues(alpha: 0.50)
                                      : AppColors.gray400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the job description above to start',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.white
                                          .withValues(alpha: 0.28)
                                      : AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final int index;
  final bool isDark;
  const _QuestionCard(
      {required this.question, required this.index, required this.isDark});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  String get _diffLabel {
    switch (widget.question.difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      padding: const EdgeInsets.all(16),
      accentColor: AppColors.brandPurple,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.question.question,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isDark
                        ? AppColors.white
                        : AppColors.nearBlack,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: _expanded ? null : 3,
                  overflow:
                      _expanded ? null : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppDifficultyBadge(level: _diffLabel),
              const SizedBox(width: 8),
              AppSkillChip(label: widget.question.skillTested),
              const Spacer(),
              Icon(
                _expanded
                    ? PhosphorIconsBold.caretUp
                    : PhosphorIconsBold.caretDown,
                size: 14,
                color: AppColors.gray400,
              ),
            ],
          ),
          if (_expanded &&
              widget.question.expectedAnswer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandPurple
                    .withValues(alpha: widget.isDark ? 0.10 : 0.05),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(
                      color: AppColors.brandPurple, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(PhosphorIconsBold.sparkle,
                        size: 12, color: AppColors.brandPurple),
                    const SizedBox(width: 6),
                    Text(
                      'Expected Answer',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.expectedAnswer,
                    style: AppTextStyles.caption.copyWith(
                      color: widget.isDark
                          ? AppColors.white.withValues(alpha: 0.75)
                          : AppColors.gray500,
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Config row (glass card) ───────────────────────────────────────────────────

class _ConfigRow extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _ConfigRow({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1D2440), const Color(0xFF131825)]
              : [Colors.white, const Color(0xFFF8F9FE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.gray200.withValues(alpha: 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color:
                AppColors.brandPurple.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Top accent stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2.5,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: children.expand((w) {
                  final isLast = w == children.last;
                  return isLast
                      ? [w]
                      : [
                          w,
                          Divider(
                            height: 20,
                            color: isDark
                                ? Colors.white
                                    .withValues(alpha: 0.06)
                                : AppColors.gray200
                                    .withValues(alpha: 0.60),
                          ),
                        ];
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Config item ───────────────────────────────────────────────────────────────

class _ConfigItem extends StatelessWidget {
  final String label;
  final Widget child;
  const _ConfigItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.50)
                : AppColors.gray500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final QuestionType value;
  final ValueChanged<QuestionType> onChanged;
  final bool isDark;
  const _TypeSelector(
      {required this.value,
      required this.onChanged,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    const types = {
      QuestionType.technical: 'Technical',
      QuestionType.behavioral: 'Behavioral',
      QuestionType.cultureFit: 'Culture',
      QuestionType.mixed: 'Mixed',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.entries.map((e) {
        final isActive = value == e.key;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive
                  ? null
                  : (isDark
                      ? const Color(0xFF0D1222)
                      : AppColors.offWhite),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.gray200),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.brandPurple
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              e.value,
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppColors.white.withValues(alpha: 0.50)
                        : AppColors.gray500),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Difficulty selector ───────────────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final QuestionDifficulty value;
  final ValueChanged<QuestionDifficulty> onChanged;
  final bool isDark;
  const _DifficultySelector(
      {required this.value,
      required this.onChanged,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final diffs = {
      QuestionDifficulty.easy: ('Easy', AppColors.success),
      QuestionDifficulty.medium: ('Medium', AppColors.amber),
      QuestionDifficulty.hard: ('Hard', AppColors.error),
    };
    return Row(
      children: diffs.entries.map((e) {
        final isActive = value == e.key;
        final color = e.value.$2;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin:
                  const EdgeInsets.symmetric(horizontal: 3),
              padding:
                  const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.14)
                    : (isDark
                        ? const Color(0xFF0D1222)
                        : AppColors.offWhite),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? color.withValues(alpha: 0.50)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : AppColors.gray200),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                e.value.$1,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: isActive
                      ? color
                      : (isDark
                          ? AppColors.white.withValues(alpha: 0.40)
                          : AppColors.gray400),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
