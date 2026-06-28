import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';
import '../../domain/models/plan_draft.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class PlanReviewView extends ConsumerStatefulWidget {
  const PlanReviewView({super.key});

  @override
  ConsumerState<PlanReviewView> createState() => _PlanReviewViewState();
}

class _PlanReviewViewState extends ConsumerState<PlanReviewView> {
  final _roleCtrl   = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  late final _countCtrl = TextEditingController();

  late HrDifficultyLevel   _difficulty;
  String?                  _expLevel;
  late Set<HrQuestionType> _types;
  bool _initialized = false;

  static const _expOptions = [
    'Intern', 'Fresher', 'Junior', 'Mid-level', 'Senior', 'Lead', 'Manager',
  ];

  @override
  void dispose() {
    _roleCtrl.dispose();
    _skillsCtrl.dispose();
    _notesCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  void _initFromPlan(PlanDraft plan) {
    if (_initialized) return;
    _initialized   = true;
    _roleCtrl.text   = plan.role;
    _skillsCtrl.text = plan.topics.join(', ');
    _notesCtrl.text  = plan.constraints ?? '';
    _countCtrl.text  = plan.questionCount.toString();
    _difficulty = HrDifficultyLevel.fromString(plan.difficulty);
    _expLevel   = plan.level;
    _types = plan.questionTypes.isNotEmpty
        ? plan.questionTypes.toSet()
        : {HrQuestionType.technical, HrQuestionType.behavioral};
  }

  PlanDraft _buildDraft() {
    final count = int.tryParse(_countCtrl.text) ?? 10;
    return PlanDraft(
      role:          _roleCtrl.text.trim(),
      questionCount: count.clamp(1, 50),
      difficulty:    _difficulty.displayName,
      level:         _expLevel ?? 'Junior',
      questionTypes: _types.toList(),
      topics: _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      constraints: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );
  }

  Future<void> _approve() async {
    final draft = _buildDraft();
    ref.read(generationProvider.notifier).updateLocalPlan(draft);
    await ref.read(generationProvider.notifier).approvePlan(draft);
  }

  Future<void> _retryPlan() async {
    await ref.read(generationProvider.notifier).retryPlan();
  }

  void _goBack() =>
      ref.read(generationProvider.notifier).goBackToForm();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generationProvider);
    final plan  = state.effectivePlan;
    final c     = GenColors.of(context);

    if (plan == null) {
      return const Center(
          child: CircularProgressIndicator(color: GenColors.primary));
    }
    _initFromPlan(plan);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AI summary card ──────────────────────────────────────
                if (plan.summary != null && plan.summary!.isNotEmpty)
                  _AiSummaryCard(summary: plan.summary!),

                // ── Vị trí ──────────────────────────────────────────────
                _FieldLabel(label: 'Vị trí', required: true),
                const SizedBox(height: 6),
                _DarkTextField(
                  controller: _roleCtrl,
                  hint:       'VD: Product Manager',
                ),
                const SizedBox(height: 14),

                // ── Cấp độ + Kinh nghiệm ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'Cấp độ'),
                          const SizedBox(height: 6),
                          _DarkDropdown<HrDifficultyLevel>(
                            value:   _difficulty,
                            items:   HrDifficultyLevel.values,
                            label:   (v) => v.displayName,
                            onChanged: (v) => setState(() => _difficulty = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'Kinh nghiệm'),
                          const SizedBox(height: 6),
                          _DarkDropdown<String>(
                            value:   _expLevel,
                            items:   _expOptions,
                            label:   (v) => v,
                            hint:    'Chọn cấp độ',
                            onChanged: (v) => setState(() => _expLevel = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Số câu hỏi ──────────────────────────────────────────
                Row(
                  children: [
                    _FieldLabel(label: 'Số câu hỏi'),
                    Text(' (1 - 50)',
                        style: TextStyle(color: c.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller:   _countCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _RangeFormatter(1, 50),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color:      c.text,
                        fontSize:   15,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled:    true,
                      fillColor: c.card,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide(color: c.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide(color: c.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   const BorderSide(
                              color: GenColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Loại câu hỏi ────────────────────────────────────────
                _FieldLabel(label: 'Loại câu hỏi'),
                const SizedBox(height: 8),
                _QuestionTypeChips(
                  selected: _types,
                  onToggle: (t) => setState(() {
                    if (_types.contains(t)) {
                      if (_types.length > 1) _types.remove(t);
                    } else {
                      _types.add(t);
                    }
                  }),
                ),
                const SizedBox(height: 14),

                // ── Kĩ năng ─────────────────────────────────────────────
                _FieldLabel(label: 'Kĩ năng',
                    suffix: '(ngăn cách bằng dấu phẩy)'),
                const SizedBox(height: 6),
                _DarkTextField(
                  controller: _skillsCtrl,
                  hint:       'VD: Python, Docker, REST API, Microservices...',
                  maxLines:   3,
                ),
                const SizedBox(height: 14),

                // ── Ghi chú / Ràng buộc ─────────────────────────────────
                _FieldLabel(label: 'Ghi chú / Ràng buộc',
                    suffix: '(tùy chọn)'),
                const SizedBox(height: 6),
                _DarkTextField(
                  controller: _notesCtrl,
                  hint:       'Yêu cầu đặc biệt, ngôn ngữ phỏng vấn, v.v.',
                  maxLines:   3,
                ),
                const SizedBox(height: 8),

                // ── Error ────────────────────────────────────────────────
                if (state.error != null)
                  Container(
                    margin:     const EdgeInsets.only(top: 8),
                    padding:    const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Text(state.error!,
                        style: const TextStyle(
                            color: Color(0xFFEF4444), fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),

        // ── Bottom action bar ────────────────────────────────────────────
        _ActionBar(
          isLoading: state.isLoading,
          onBack:    _goBack,
          onRetry:   _retryPlan,
          onApprove: _approve,
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  final String summary;
  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      margin:     const EdgeInsets.only(bottom: 16),
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: GenColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded,
                color: GenColors.primary, size: 14),
            SizedBox(width: 6),
            Text('Nhận xét từ AI',
                style: TextStyle(
                    color:      GenColors.primary,
                    fontSize:   12,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(summary,
              style: TextStyle(color: c.textSub, fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String  label;
  final String? suffix;
  final bool    required;
  const _FieldLabel({
    required this.label,
    this.suffix,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Row(children: [
      Text(label,
          style: TextStyle(
              color:      c.text,
              fontSize:   13,
              fontWeight: FontWeight.w500)),
      if (required)
        const Text(' *',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
      if (suffix != null) ...[
        const SizedBox(width: 5),
        Text(suffix!,
            style: TextStyle(color: c.muted, fontSize: 12)),
      ],
    ]);
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int    maxLines;
  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return TextField(
        controller: controller,
        maxLines:   maxLines,
        style: TextStyle(color: c.text, fontSize: 13, height: 1.5),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: TextStyle(color: c.hint, fontSize: 12),
          filled:    true,
          fillColor: c.card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   const BorderSide(
                  color: GenColors.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      );
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) label;
  final String? hint;
  final ValueChanged<T> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.label,
    this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value:         value,
          isExpanded:    true,
          dropdownColor: c.card,
          hint: hint != null
              ? Text(hint!, style: TextStyle(color: c.hint, fontSize: 13))
              : null,
          style: TextStyle(color: c.text, fontSize: 13),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(label(i))))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _QuestionTypeChips extends StatelessWidget {
  final Set<HrQuestionType> selected;
  final ValueChanged<HrQuestionType> onToggle;
  const _QuestionTypeChips({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Wrap(
      spacing:    8,
      runSpacing: 8,
      children: HrQuestionType.values.map((t) {
        final sel = selected.contains(t);
        return GestureDetector(
          onTap: () => onToggle(t),
          child: AnimatedContainer(
            duration:   const Duration(milliseconds: 180),
            padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:        sel ? GenColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: sel ? GenColors.primary : c.border,
                width: 1.5,
              ),
            ),
            child: Text(t.displayName,
                style: TextStyle(
                    color:      sel ? Colors.white : c.muted,
                    fontSize:   13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onApprove;

  const _ActionBar({
    required this.isLoading,
    required this.onBack,
    required this.onRetry,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color:  c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onBack,
            icon:  const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Quay lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textSub,
              side:    BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onRetry,
            icon: isLoading
                ? SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.textSub))
                : const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tạo lại Plan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textSub,
              side:    BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onApprove,
              icon: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Approve Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor:        GenColors.primary,
                disabledBackgroundColor: GenColors.primary.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape:   RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Range input formatter ─────────────────────────────────────────────────────

class _RangeFormatter extends TextInputFormatter {
  final int min;
  final int max;
  _RangeFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;
    final n = int.tryParse(newVal.text);
    if (n == null) return old;
    if (n > max) {
      final s = max.toString();
      return newVal.copyWith(
          text:      s,
          selection: TextSelection.collapsed(offset: s.length));
    }
    return newVal;
  }
}
