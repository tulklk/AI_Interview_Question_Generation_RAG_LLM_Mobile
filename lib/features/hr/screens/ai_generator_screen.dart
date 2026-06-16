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
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(PhosphorIconsBold.arrowLeft, size: 18,
              color: isDark ? AppColors.white : AppColors.nearBlack),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(PhosphorIconsBold.sparkle, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text('AI Question Generator', style: AppTextStyles.h4.copyWith(
              color: isDark ? AppColors.white : AppColors.nearBlack)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Input panel
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Config panel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // JD Input
                        AppTextField(
                          label: 'Job Description',
                          hint: 'Paste the job description here to generate relevant interview questions...',
                          controller: _jdCtrl,
                          maxLines: 4,
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 20),
                        // Config row
                        _ConfigRow(isDark: isDark, children: [
                          _ConfigItem(
                            label: 'Type',
                            child: _TypeSelector(
                              value: _type,
                              onChanged: (t) => setState(() => _type = t),
                              isDark: isDark,
                            ),
                          ),
                          _ConfigItem(
                            label: 'Difficulty',
                            child: _DifficultySelector(
                              value: _difficulty,
                              onChanged: (d) => setState(() => _difficulty = d),
                              isDark: isDark,
                            ),
                          ),
                        ]).animate().fadeIn(delay: 150.ms),
                        const SizedBox(height: 16),
                        _ConfigRow(isDark: isDark, children: [
                          _ConfigItem(
                            label: 'Questions: $_count',
                            child: Slider(
                              value: _count.toDouble(),
                              min: 3,
                              max: 15,
                              divisions: 12,
                              activeColor: AppColors.brandPurple,
                              onChanged: (v) => setState(() => _count = v.round()),
                            ),
                          ),
                          _ConfigItem(
                            label: 'Language',
                            child: Row(
                              children: ['English', 'Vietnamese'].map((l) => Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _language = l),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: _language == l ? AppColors.primaryGradient : null,
                                      color: _language == l ? null : (isDark ? AppColors.darkBg : AppColors.offWhite),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(l, textAlign: TextAlign.center,
                                      style: AppTextStyles.caption.copyWith(
                                        color: _language == l ? Colors.white : AppColors.gray500,
                                        fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ]).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 20),
                        AppGradientButton(
                          label: aiState.isGenerating ? 'Generating...' : 'Generate Questions',
                          isLoading: aiState.isGenerating,
                          onTap: aiState.isGenerating ? null : _generate,
                          height: 54,
                          icon: aiState.isGenerating ? null :
                            const Icon(PhosphorIconsBold.robot, size: 18, color: Colors.white),
                        ).animate().fadeIn(delay: 250.ms),
                      ],
                    ),
                  ),
                ),

                // Generated questions
                if (aiState.generatedQuestions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${aiState.generatedQuestions.length} questions generated',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          AppSecondaryButton(
                            label: 'Save Kit',
                            height: 36,
                            width: 90,
                            onTap: () {},
                            icon: const Icon(PhosphorIconsBold.floppyDisk,
                              size: 14, color: AppColors.brandPurple),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final q = aiState.generatedQuestions[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionCard(question: q, index: i + 1, isDark: isDark)
                                .animate()
                                .fadeIn(delay: (i * 80).ms)
                                .slideY(begin: 0.15, end: 0),
                          );
                        },
                        childCount: aiState.generatedQuestions.length,
                      ),
                    ),
                  ),
                ],

                // Empty state for output
                if (!aiState.isGenerating && aiState.generatedQuestions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brandPurple.withOpacity(0.15),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsBold.robot,
                                size: 36, color: AppColors.brandPurple.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text('AI questions will appear here',
                                style: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.white.withOpacity(0.4) : AppColors.gray400,
                                  fontSize: 14)),
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

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final int index;
  final bool isDark;
  const _QuestionCard({required this.question, required this.index, required this.isDark});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  String get _diffLabel {
    switch (widget.question.difficulty) {
      case QuestionDifficulty.easy: return 'Easy';
      case QuestionDifficulty.medium: return 'Medium';
      case QuestionDifficulty.hard: return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppElevatedCard(
      padding: const EdgeInsets.all(16),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${widget.index}',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.question.question,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isDark ? AppColors.white : AppColors.nearBlack,
                    fontSize: 14, height: 1.5),
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
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
                _expanded ? PhosphorIconsBold.caretUp : PhosphorIconsBold.caretDown,
                size: 14, color: AppColors.gray400),
            ],
          ),
          if (_expanded && widget.question.expectedAnswer.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.brandPurple, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsBold.sparkle,
                        size: 12, color: AppColors.brandPurple),
                      const SizedBox(width: 6),
                      Text('Expected Answer', style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.question.expectedAnswer,
                    style: AppTextStyles.caption.copyWith(
                      color: widget.isDark ? AppColors.white.withOpacity(0.75) : AppColors.gray500,
                      height: 1.6, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _ConfigRow({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: children.expand((w) => [w, if (w != children.last) const Divider(height: 20)]).toList(),
      ),
    );
  }
}

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
        Text(label, style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.white.withOpacity(0.5) : AppColors.gray500,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final QuestionType value;
  final ValueChanged<QuestionType> onChanged;
  final bool isDark;
  const _TypeSelector({required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final types = {
      QuestionType.technical: 'Technical',
      QuestionType.behavioral: 'Behavioral',
      QuestionType.cultureFit: 'Culture',
      QuestionType.mixed: 'Mixed',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.entries.map((e) => GestureDetector(
        onTap: () => onChanged(e.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: value == e.key ? AppColors.primaryGradient : null,
            color: value == e.key ? null : (isDark ? AppColors.darkBg : AppColors.offWhite),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(e.value, style: AppTextStyles.caption.copyWith(
            color: value == e.key ? Colors.white : AppColors.gray500,
            fontWeight: FontWeight.w600)),
        ),
      )).toList(),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final QuestionDifficulty value;
  final ValueChanged<QuestionDifficulty> onChanged;
  final bool isDark;
  const _DifficultySelector({required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final diffs = {
      QuestionDifficulty.easy: ('Easy', AppColors.success),
      QuestionDifficulty.medium: ('Medium', AppColors.amber),
      QuestionDifficulty.hard: ('Hard', AppColors.error),
    };
    return Row(
      children: diffs.entries.map((e) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: value == e.key ? e.value.$2.withOpacity(0.12) : (isDark ? AppColors.darkBg : AppColors.offWhite),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value == e.key ? e.value.$2.withOpacity(0.4) : Colors.transparent),
            ),
            child: Text(e.value.$1, textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: value == e.key ? e.value.$2 : AppColors.gray500,
                fontWeight: FontWeight.w700)),
          ),
        ),
      )).toList(),
    );
  }
}
