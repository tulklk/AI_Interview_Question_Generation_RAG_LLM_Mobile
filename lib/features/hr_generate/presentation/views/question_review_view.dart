import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';
import '../../domain/models/generated_question.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';
import '../widgets/question_card.dart';

class QuestionReviewView extends ConsumerStatefulWidget {
  const QuestionReviewView({super.key});

  @override
  ConsumerState<QuestionReviewView> createState() =>
      _QuestionReviewViewState();
}

class _QuestionReviewViewState
    extends ConsumerState<QuestionReviewView> {
  bool _addingNew = false;

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(generationProvider);
    final notifier  = ref.read(generationProvider.notifier);
    final questions = state.questions;

    return Column(
      children: [
        // ── Stats bar ──
        _StatsBar(questions: questions),

        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child:   _ReviewHeader(count: questions.length),
                ),
              ),

              // ── Question list ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver:  SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final q = questions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:   QuestionCard(
                          question:    q,
                          index:       i + 1,
                          canMoveUp:   i > 0,
                          canMoveDown: i < questions.length - 1,
                          onUpdated:   (updated) =>
                              notifier.updateQuestion(updated),
                          onDelete:    () =>
                              notifier.deleteQuestion(q.id),
                          onMoveUp:    () => _moveQuestion(i, -1),
                          onMoveDown:  () => _moveQuestion(i, 1),
                        ),
                      );
                    },
                    childCount: questions.length,
                  ),
                ),
              ),

              // ── Add question ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child:   _addingNew
                      ? _AddQuestionForm(
                          onAdd:    (q) {
                            notifier.addQuestion(q);
                            setState(() => _addingNew = false);
                          },
                          onCancel: () =>
                              setState(() => _addingNew = false),
                        )
                      : OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _addingNew = true),
                          icon:  const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm câu hỏi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(
                                color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            minimumSize:
                                const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ),

              // ── Error ──
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child:   Container(
                      padding:    const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  ),
                ),

              // ── Save draft button ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child:   SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child:  ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => notifier.saveDraft(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_add_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Lưu bộ câu hỏi',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
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
    );
  }

  void _moveQuestion(int fromIdx, int direction) {
    final notifier  = ref.read(generationProvider.notifier);
    final state     = ref.read(generationProvider);
    final questions = List<GeneratedQuestion>.from(state.questions);
    final toIdx     = fromIdx + direction;
    if (toIdx < 0 || toIdx >= questions.length) return;
    final tmp           = questions[fromIdx];
    questions[fromIdx]  = questions[toIdx];
    questions[toIdx]    = tmp;
    // Persist reorder via update calls
    notifier.updateQuestion(
        questions[toIdx].copyWith(orderIndex: fromIdx + 1));
    notifier.updateQuestion(
        questions[fromIdx].copyWith(orderIndex: toIdx + 1));
  }
}

class _StatsBar extends StatelessWidget {
  final List<GeneratedQuestion> questions;
  const _StatsBar({required this.questions});

  @override
  Widget build(BuildContext context) {
    final c      = GenColors.of(context);
    final byDiff = <HrDifficultyLevel, int>{};
    final byType = <HrQuestionType, int>{};
    for (final q in questions) {
      byDiff[q.difficulty]   = (byDiff[q.difficulty] ?? 0) + 1;
      byType[q.questionType] = (byType[q.questionType] ?? 0) + 1;
    }

    return Container(
      color:   c.bg,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          _StatChip(
            label: '${questions.length} câu',
            color: GenColors.primary,
            icon:  PhosphorIconsBold.listBullets,
          ),
          const SizedBox(width: 8),
          ...byDiff.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child:   _StatChip(
                  label: '${e.value} ${e.key.displayName}',
                  color: e.key.badgeColor,
                ),
              )),
          const Spacer(),
          Text('${questions.where((q) => q.isEdited).length} đã sửa',
              style: TextStyle(color: c.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _StatChip({required this.label, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color:      color,
                    fontSize:   11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ReviewHeader extends StatelessWidget {
  final int count;
  const _ReviewHeader({required this.count});
  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Đã tạo $count câu hỏi! Xem xét, chỉnh sửa rồi lưu.',
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _AddQuestionForm extends StatefulWidget {
  final ValueChanged<GeneratedQuestion> onAdd;
  final VoidCallback onCancel;
  const _AddQuestionForm({required this.onAdd, required this.onCancel});

  @override
  State<_AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<_AddQuestionForm> {
  final _ctrl       = TextEditingController();
  HrQuestionType    _type   = HrQuestionType.technical;
  HrDifficultyLevel _diff   = HrDifficultyLevel.medium;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: GenColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thêm câu hỏi mới',
              style: TextStyle(
                  color: c.text, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLines:   3,
            style: TextStyle(color: c.text, fontSize: 13),
            decoration: InputDecoration(
              hintText:  'Nội dung câu hỏi...',
              hintStyle: TextStyle(color: c.muted, fontSize: 12),
              filled:    true,
              fillColor: c.bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   const BorderSide(color: GenColors.primary)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _DropDown<HrQuestionType>(
              value:     _type,
              items:     HrQuestionType.values,
              label:     (v) => v.displayName,
              onChanged: (v) => setState(() => _type = v),
            )),
            const SizedBox(width: 8),
            Expanded(child: _DropDown<HrDifficultyLevel>(
              value:     _diff,
              items:     HrDifficultyLevel.values,
              label:     (v) => v.displayName,
              onChanged: (v) => setState(() => _diff = v),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSub,
                  side:  BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  final txt = _ctrl.text.trim();
                  if (txt.isEmpty) return;
                  widget.onAdd(GeneratedQuestion(
                    id:           '',
                    question:     txt,
                    questionType: _type,
                    difficulty:   _diff,
                    orderIndex:   0,
                    isEdited:     false,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Thêm'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _DropDown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _DropDown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color:        c.bg,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: DropdownButton<T>(
        value:         value,
        isExpanded:    true,
        underline:     const SizedBox(),
        dropdownColor: c.card,
        style: TextStyle(color: c.text, fontSize: 12),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(label(i))))
            .toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
