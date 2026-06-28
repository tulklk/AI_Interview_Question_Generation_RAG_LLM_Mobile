import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class Step1JdInputView extends ConsumerStatefulWidget {
  const Step1JdInputView({super.key});

  @override
  ConsumerState<Step1JdInputView> createState() => _Step1JdInputViewState();
}

class _Step1JdInputViewState extends ConsumerState<Step1JdInputView> {
  final _jdCtrl   = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool  _jdFocused   = false;
  bool  _noteFocused = false;

  int  get _wordCount => _jdCtrl.text.trim().isEmpty
      ? 0 : _jdCtrl.text.trim().split(RegExp(r'\s+')).length;
  int  get _charCount => _jdCtrl.text.length;
  bool get _isValid   => _charCount >= 50;

  @override
  void initState() {
    super.initState();
    _jdCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _jdCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = GenColors.of(context);
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(context.l10n.minCharsError),
          backgroundColor: c.card,
        ),
      );
      return;
    }
    await ref.read(generationProvider.notifier).submitJob(
      jd:     _jdCtrl.text.trim(),
      hrNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(generationProvider.select((s) => s.isLoading));
    final error     = ref.watch(generationProvider.select((s) => s.error));
    final c         = GenColors.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(icon: PhosphorIconsBold.fileText,
                    label: context.l10n.jobDescription, c: c),
                const SizedBox(height: 8),
                _JdTextArea(
                  controller: _jdCtrl,
                  wordCount:  _wordCount,
                  charCount:  _charCount,
                  focused:    _jdFocused,
                  onFocus:    (v) => setState(() => _jdFocused = v),
                  c:          c,
                ),
                const SizedBox(height: 20),

                _FieldLabel(icon: PhosphorIconsBold.note,
                    label: context.l10n.aiNote, optional: true, c: c),
                const SizedBox(height: 8),
                _NoteTextArea(
                  controller: _noteCtrl,
                  focused:    _noteFocused,
                  onFocus:    (v) => setState(() => _noteFocused = v),
                  c:          c,
                ),
                const SizedBox(height: 12),

                if (!_isValid && _charCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      context.l10n.validationHint(50 - _charCount),
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ),

                if (error != null) ...[
                  const SizedBox(height: 4),
                  _ErrorCard(message: error),
                ],
              ],
            ),
          ),
        ),
        _SubmitBar(isLoading: isLoading, enabled: _isValid, onTap: _submit, c: c),
      ],
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      optional;
  final GenColors c;

  const _FieldLabel({
    required this.icon,
    required this.label,
    this.optional = false,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color:        GenColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: GenColors.primary, size: 13),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
          if (optional) ...[
            const SizedBox(width: 6),
            Text(context.l10n.optional,
                style: TextStyle(color: c.muted, fontSize: 12)),
          ],
        ],
      );
}

// ── JD textarea ───────────────────────────────────────────────────────────────

class _JdTextArea extends StatelessWidget {
  final TextEditingController controller;
  final int   wordCount;
  final int   charCount;
  final bool  focused;
  final ValueChanged<bool> onFocus;
  final GenColors c;

  const _JdTextArea({
    required this.controller,
    required this.wordCount,
    required this.charCount,
    required this.focused,
    required this.onFocus,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = focused ? c.borderFoc : c.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: borderColor, width: focused ? 1.5 : 1),
        boxShadow: focused
            ? [BoxShadow(
                color:      GenColors.primary.withValues(alpha: 0.12),
                blurRadius: 8)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: onFocus,
            child: TextField(
              controller: controller,
              minLines:   9,
              maxLines:   18,
              style: TextStyle(color: c.text, fontSize: 13, height: 1.65),
              cursorColor: GenColors.primary,
              decoration: InputDecoration(
                hintText:       context.l10n.pasteJDHint,
                hintStyle:      TextStyle(color: c.hint, fontSize: 13, height: 1.65),
                filled:         true,
                fillColor:      c.card,
                border:         InputBorder.none,
                enabledBorder:  InputBorder.none,
                focusedBorder:  InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Text(
                  context.l10n.wordCharCount(wordCount, charCount),
                  style: TextStyle(color: c.muted, fontSize: 11),
                ),
                const Spacer(),
                if (charCount >= 50)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 13),
                      const SizedBox(width: 4),
                      const Text('Sufficient',
                          style: TextStyle(
                              color:      Color(0xFF10B981),
                              fontSize:   11,
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                else if (charCount > 0)
                  Text(
                    context.l10n.needMoreChars(50 - charCount),
                    style: const TextStyle(
                        color: Color(0xFFF59E0B), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Note textarea ─────────────────────────────────────────────────────────────

class _NoteTextArea extends StatelessWidget {
  final TextEditingController controller;
  final bool focused;
  final ValueChanged<bool> onFocus;
  final GenColors c;

  const _NoteTextArea({
    required this.controller,
    required this.focused,
    required this.onFocus,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = focused ? c.borderFoc : c.border;

    return Focus(
      onFocusChange: onFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        c.card,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: borderColor, width: focused ? 1.5 : 1),
          boxShadow: focused
              ? [BoxShadow(
                  color:      GenColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8)]
              : null,
        ),
        child: TextField(
          controller: controller,
          minLines:   4,
          maxLines:   7,
          style:      TextStyle(color: c.text, fontSize: 13, height: 1.65),
          cursorColor: GenColors.primary,
          decoration: InputDecoration(
            hintText:       context.l10n.aiNoteHint,
            hintStyle:      TextStyle(color: c.hint, fontSize: 12),
            filled:         true,
            fillColor:      c.card,
            border:         InputBorder.none,
            enabledBorder:  InputBorder.none,
            focusedBorder:  InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12, height: 1.4)),
            ),
          ],
        ),
      );
}

// ── Submit bar ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
  final GenColors c;

  const _SubmitBar({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:  c.bg,
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                      begin:  Alignment.centerLeft,
                      end:    Alignment.centerRight,
                    )
                  : null,
              color:        enabled ? null : c.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: (isLoading || !enabled) ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:        Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor:            Colors.transparent,
                foregroundColor:        Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisSize:      MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size:  18,
                            color: enabled ? Colors.white : c.muted),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.createPlanBtn,
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color: enabled ? Colors.white : c.muted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
}
