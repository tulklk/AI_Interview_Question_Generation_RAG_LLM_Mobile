import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/studio_generation_provider.dart';
import '../../domain/models/studio_models.dart';

class StudioQuestionReviewView extends ConsumerStatefulWidget {
  const StudioQuestionReviewView({super.key});

  @override
  ConsumerState<StudioQuestionReviewView> createState() =>
      _StudioQuestionReviewViewState();
}

class _StudioQuestionReviewViewState
    extends ConsumerState<StudioQuestionReviewView> {
  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(studioGenerationProvider);
    final notifier  = ref.read(studioGenerationProvider.notifier);
    final questions = state.questions;
    final c         = GenColors.of(context);

    return Column(
      children: [
        // ── Stats bar ────────────────────────────────────────────────────
        _StatsBar(questions: questions, c: c),

        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    '${questions.length} câu hỏi được tạo',
                    style: TextStyle(
                        color:      c.text,
                        fontSize:   16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // ── List ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final q = questions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StudioQuestionCard(
                          question:  q,
                          index:     i + 1,
                          onUpdate:  (updated) => notifier.updateQuestion(updated),
                          onDelete:  () => notifier.deleteQuestion(q.id),
                          onRegen:   () => notifier.regenerateQuestion(q.id),
                          c: c,
                        ),
                      );
                    },
                    childCount: questions.length,
                  ),
                ),
              ),

              // ── Error ───────────────────────────────────────────────────
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding:    const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  ),
                ),

              // ── Save draft / Publish ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      // Save draft button — 3 states per spec §7.9
                      _SaveDraftBtn(c: c),
                      const SizedBox(height: 8),
                      SizedBox(
                        width:  double.infinity,
                        height: 46,
                        child:  OutlinedButton.icon(
                          onPressed: state.isLoading ? null : notifier.publishProject,
                          icon: const Icon(Icons.publish_rounded, size: 18),
                          label: const Text('Đăng bộ câu hỏi',
                              style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(
                                color: Color(0xFF10B981), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Save draft button (spec §7.9) ─────────────────────────────────────────────

class _SaveDraftBtn extends ConsumerWidget {
  final GenColors c;
  const _SaveDraftBtn({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(
        studioGenerationProvider.select((s) => s.isSavingDraft));
    final isDone   = ref.watch(
        studioGenerationProvider.select((s) => s.isDraftSaved));

    final IconData icon;
    final String label;
    final Color bg;

    if (isSaving) {
      icon  = Icons.hourglass_top_rounded;
      label = 'Đang lưu…';
      bg    = GenColors.primary.withValues(alpha: 0.6);
    } else if (isDone) {
      icon  = Icons.check_circle_rounded;
      label = 'Đã lưu';
      bg    = const Color(0xFF10B981);
    } else {
      icon  = Icons.save_rounded;
      label = 'Lưu bộ câu hỏi';
      bg    = GenColors.primary;
    }

    return SizedBox(
      width:  double.infinity,
      height: 50,
      child:  ElevatedButton.icon(
        onPressed: (isSaving || isDone)
            ? null
            : () => ref.read(studioGenerationProvider.notifier).saveDraft(),
        icon: isSaving
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor:         bg,
          disabledBackgroundColor: bg,
          foregroundColor:         Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<StudioQuestion> questions;
  final GenColors c;
  const _StatsBar({required this.questions, required this.c});

  @override
  Widget build(BuildContext context) {
    final easy   = questions.where((q) =>
        q.difficulty == StudioQuestionDifficulty.easy).length;
    final hard   = questions.where((q) =>
        q.difficulty == StudioQuestionDifficulty.hard).length;
    final edited = questions.where((q) => q.isEdited).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          color:  c.card,
          border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Tổng',   value: '${questions.length}', color: c.text),
          _StatItem(label: 'Dễ',     value: '$easy',               color: const Color(0xFF10B981)),
          _StatItem(label: 'Khó',    value: '$hard',               color: const Color(0xFFEF4444)),
          _StatItem(label: 'Đã sửa', value: '$edited',             color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color:      color,
                  fontSize:   18,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 11)),
        ],
      );
}

// ── Question card ─────────────────────────────────────────────────────────────

class _StudioQuestionCard extends StatefulWidget {
  final StudioQuestion question;
  final int index;
  final void Function(StudioQuestion) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onRegen;
  final GenColors c;

  const _StudioQuestionCard({
    required this.question,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
    required this.onRegen,
    required this.c,
  });

  @override
  State<_StudioQuestionCard> createState() => _StudioQuestionCardState();
}

class _StudioQuestionCardState extends State<_StudioQuestionCard> {
  bool _expanded = false;
  bool _editing  = false;
  late final _ctrl = TextEditingController(text: widget.question.content);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _save() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onUpdate(widget.question.copyWith(
        content: _ctrl.text.trim(), isEdited: true));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final c = widget.c;

    return Container(
      decoration: BoxDecoration(
          color:        c.card,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(
              color: q.isEdited
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                  : c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 26, height: 26,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text('${widget.index}',
                        style: const TextStyle(
                            color:      Color(0xFF7C3AED),
                            fontSize:   11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),

                // Badges
                Expanded(
                  child: Wrap(
                    spacing: 5, runSpacing: 4,
                    children: [
                      _badge(q.difficulty.displayName,
                          _diffColor(q.difficulty)),
                      _badge(q.type.displayName,
                          const Color(0xFF3B82F6)),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:     const Icon(Icons.refresh_rounded, size: 18),
                      color:    c.textSub,
                      onPressed: widget.onRegen,
                      tooltip:  'Tạo lại',
                      padding:  EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon:     const Icon(Icons.edit_rounded, size: 18),
                      color:    c.textSub,
                      onPressed: () => setState(() {
                        _editing   = !_editing;
                        _expanded  = true;
                        if (!_editing) _ctrl.text = q.content;
                      }),
                      tooltip:  'Sửa',
                      padding:  EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon:     const Icon(Icons.delete_rounded, size: 18),
                      color:    const Color(0xFFEF4444),
                      onPressed: widget.onDelete,
                      tooltip:  'Xóa',
                      padding:  EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _editing
                ? TextField(
                    controller: _ctrl,
                    maxLines:   null,
                    autofocus:  true,
                    style:      TextStyle(color: c.text, fontSize: 14),
                    decoration: InputDecoration(
                      border:      InputBorder.none,
                      hintText:    'Nội dung câu hỏi...',
                      hintStyle:   TextStyle(color: c.textSub),
                      filled:      true,
                      fillColor:   c.bg.withValues(alpha: 0.5),
                    ),
                  )
                : GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(q.content,
                        maxLines:  _expanded ? null : 3,
                        overflow:  _expanded ? null : TextOverflow.ellipsis,
                        style:     TextStyle(color: c.text, fontSize: 14, height: 1.5)),
                  ),
          ),

          // ── Edit action bar ───────────────────────────────────────────
          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _editing  = false;
                      _ctrl.text = q.content;
                    }),
                    child: Text('Huỷ', style: TextStyle(color: c.textSub)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GenColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10)),
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 12),

          // ── Expected answer (collapsible) ─────────────────────────────
          if (_expanded && q.expectedAnswer != null &&
              q.expectedAnswer!.isNotEmpty) ...[
            Divider(color: c.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đáp án mẫu',
                      style: TextStyle(
                          color:      c.textSub,
                          fontSize:   11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(q.expectedAnswer!,
                      style: TextStyle(
                          color: c.text, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label,
            style: TextStyle(
                color:      color,
                fontSize:   10,
                fontWeight: FontWeight.w700)),
      );

  Color _diffColor(StudioQuestionDifficulty d) => switch (d) {
    StudioQuestionDifficulty.easy   => const Color(0xFF10B981),
    StudioQuestionDifficulty.medium => const Color(0xFFF59E0B),
    StudioQuestionDifficulty.hard   => const Color(0xFFEF4444),
  };
}
