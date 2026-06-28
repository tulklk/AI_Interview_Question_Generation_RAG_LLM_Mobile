import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';
import '../../domain/models/generated_question.dart';
import '../gen_colors.dart';

class QuestionCard extends StatefulWidget {
  final GeneratedQuestion question;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<GeneratedQuestion> onUpdated;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onUpdated,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  bool _expanded = false;
  bool _editing  = false;
  bool _copied   = false;

  late final _qCtrl = TextEditingController();
  late final _rCtrl = TextEditingController();
  late final _sCtrl = TextEditingController();
  late HrQuestionType   _editType;
  late HrDifficultyLevel _editDiff;

  @override
  void initState() {
    super.initState();
    _resetEdits();
  }

  void _resetEdits() {
    _qCtrl.text = widget.question.question;
    _rCtrl.text = widget.question.rationale ?? '';
    _sCtrl.text = widget.question.sampleAnswer ?? '';
    _editType   = widget.question.questionType;
    _editDiff   = widget.question.difficulty;
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _rCtrl.dispose();
    _sCtrl.dispose();
    super.dispose();
  }

  Color get _diffColor => widget.question.difficulty.badgeColor;

  void _startEdit() {
    _resetEdits();
    setState(() => _editing = true);
  }

  void _saveEdit() {
    final updated = widget.question.copyWith(
      question:     _qCtrl.text.trim(),
      questionType: _editType,
      difficulty:   _editDiff,
      rationale:    _rCtrl.text.trim().isEmpty ? null : _rCtrl.text.trim(),
      sampleAnswer: _sCtrl.text.trim().isEmpty ? null : _sCtrl.text.trim(),
      isEdited:     true,
    );
    widget.onUpdated(updated);
    setState(() => _editing = false);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.question.question));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.question.isEdited
              ? GenColors.primary.withValues(alpha: 0.5)
              : c.border,
        ),
      ),
      child: _editing ? _buildEditBody() : _buildViewBody(),
    );
  }

  Widget _buildViewBody() {
    final c = GenColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexBadge(index: widget.index),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.question.question,
                    style: TextStyle(
                        color:      c.text,
                        fontSize:   14,
                        height:     1.5,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 10, 10),
          child: Row(
            children: [
              _TypeBadge(type: widget.question.questionType),
              const SizedBox(width: 6),
              _DiffBadge(difficulty: widget.question.difficulty),
              if (widget.question.isEdited) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        GenColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Edited',
                      style: TextStyle(color: GenColors.primary, fontSize: 9)),
                ),
              ],
              const Spacer(),
              if (widget.canMoveUp)
                _IconBtn(icon: Icons.arrow_upward_rounded,   color: c.muted, onTap: widget.onMoveUp),
              if (widget.canMoveDown)
                _IconBtn(icon: Icons.arrow_downward_rounded, color: c.muted, onTap: widget.onMoveDown),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _copy,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _copied ? Icons.check_rounded : PhosphorIconsBold.copy,
                    key:   ValueKey(_copied),
                    color: _copied ? const Color(0xFF10B981) : c.muted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _IconBtn(
                  icon:  PhosphorIconsBold.pencil,
                  color: GenColors.primary.withValues(alpha: 0.8),
                  onTap: _startEdit),
              _IconBtn(
                  icon:  PhosphorIconsBold.trash,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                  onTap: () => _confirmDelete(context)),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedRotation(
                  turns:    _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: c.muted, size: 22),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild:     const SizedBox.shrink(),
          secondChild:    _ExpandedDetail(q: widget.question),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildEditBody() {
    final c = GenColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Chỉnh sửa câu hỏi',
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() { _editing = false; }),
              child: Icon(Icons.close_rounded, color: c.muted, size: 20),
            ),
          ]),
          const SizedBox(height: 12),
          _DarkField(controller: _qCtrl, hint: 'Câu hỏi', maxLines: 3),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _InlineDropdown<HrQuestionType>(
                value:     _editType,
                items:     HrQuestionType.values,
                label:     (v) => v.displayName,
                onChanged: (v) => setState(() => _editType = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineDropdown<HrDifficultyLevel>(
                value:     _editDiff,
                items:     HrDifficultyLevel.values,
                label:     (v) => v.displayName,
                onChanged: (v) => setState(() => _editDiff = v),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _DarkField(controller: _rCtrl, hint: 'Rationale (tùy chọn)', maxLines: 2),
          const SizedBox(height: 8),
          _DarkField(controller: _sCtrl, hint: 'Sample answer (tùy chọn)', maxLines: 3),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSub,
                  side:  BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saveEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Lưu'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final c  = GenColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title:   Text('Xóa câu hỏi?',
            style: TextStyle(color: c.text)),
        content: Text('Hành động này không thể hoàn tác.',
            style: TextStyle(color: c.textSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444)),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) widget.onDelete();
  }
}

class _ExpandedDetail extends StatelessWidget {
  final GeneratedQuestion q;
  const _ExpandedDetail({required this.q});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      margin:     const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding:    const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        c.bg,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.sampleAnswer != null && q.sampleAnswer!.isNotEmpty) ...[
            _Section(icon: PhosphorIconsBold.lightbulb,
                title: 'Gợi ý trả lời',
                content: q.sampleAnswer!,
                color: const Color(0xFF3B82F6)),
            const SizedBox(height: 10),
          ],
          if (q.rationale != null && q.rationale!.isNotEmpty)
            _Section(icon: PhosphorIconsBold.question,
                title: 'Lý do',
                content: q.rationale!,
                color: GenColors.primary),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   content;
  final Color    color;
  const _Section({required this.icon, required this.title,
      required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 5),
        Text(content,
            style: TextStyle(color: c.textSub, fontSize: 12, height: 1.5)),
      ],
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  const _IndexBadge({required this.index});
  @override
  Widget build(BuildContext context) => Container(
        width:  24, height: 24,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('$index',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   10,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  final HrQuestionType type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) => Container(
        padding:    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color:        const Color(0xFF7C3AED).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border:       Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
        ),
        child: Text(type.displayName,
            style: const TextStyle(
                color:      Color(0xFF7C3AED),
                fontSize:   10,
                fontWeight: FontWeight.w600)),
      );
}

class _DiffBadge extends StatelessWidget {
  final HrDifficultyLevel difficulty;
  const _DiffBadge({required this.difficulty});
  @override
  Widget build(BuildContext context) {
    final c = difficulty.badgeColor;
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border:       Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(difficulty.displayName,
          style: TextStyle(
              color:      c, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child:   Icon(icon, color: color, size: 17),
        ),
      );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int    maxLines;
  const _DarkField(
      {required this.controller, required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color:        c.bg,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: TextField(
        controller: controller,
        maxLines:   maxLines,
        style: TextStyle(color: c.text, fontSize: 13),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText:  hint,
          hintStyle: TextStyle(color: c.muted, fontSize: 12),
          border:    InputBorder.none,
        ),
      ),
    );
  }
}

class _InlineDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _InlineDropdown({
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
