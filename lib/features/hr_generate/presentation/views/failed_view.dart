import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class FailedView extends ConsumerStatefulWidget {
  const FailedView({super.key});

  @override
  ConsumerState<FailedView> createState() => _FailedViewState();
}

class _FailedViewState extends ConsumerState<FailedView> {
  bool _showEditInput = false;
  final _jdCtrl = TextEditingController();

  @override
  void dispose() { _jdCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(generationProvider);
    final notifier = ref.read(generationProvider.notifier);
    final session  = state.session;
    final action   = (session?.suggestedAction ?? '').toUpperCase();
    final c        = GenColors.of(context);

    final canRetryPlan      = action == 'RETRY_PLAN'      || session?.canRetryPlan      == true;
    final canRetryQuestions = action == 'RETRY_QUESTIONS' || session?.canRetryQuestions == true;
    final canEditInput      = action == 'EDIT_INPUT'      || session?.canEditInput      == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child:   Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width:  80, height: 80,
            decoration: BoxDecoration(
              color:  const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 2),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 40),
          ),
          const SizedBox(height: 20),
          Text('Tạo câu hỏi thất bại',
              style: TextStyle(
                  color:      c.text,
                  fontSize:   20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          if (session?.failureMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child:   Text(session!.failureMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:    c.textSub,
                      fontSize: 13,
                      height:   1.5)),
            ),
          const SizedBox(height: 28),

          if (state.error != null)
            Container(
              width:   double.infinity,
              margin:  const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(state.error!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ),

          if (canRetryPlan)
            _ActionCard(
              icon:        PhosphorIconsBold.arrowsClockwise,
              title:       'Thử lại tạo Plan',
              description: 'AI sẽ phân tích lại JD và đề xuất plan mới.',
              color:       const Color(0xFF3B82F6),
              isLoading:   state.isLoading,
              onTap:       () => notifier.retryPlan(),
              c:           c,
            ),

          if (canRetryQuestions) ...[
            const SizedBox(height: 12),
            _ActionCard(
              icon:        PhosphorIconsBold.arrowsClockwise,
              title:       'Thử lại tạo câu hỏi',
              description: 'AI sẽ tạo lại bộ câu hỏi từ plan đã duyệt.',
              color:       const Color(0xFF7C3AED),
              isLoading:   state.isLoading,
              onTap:       () => notifier.retryQuestions(),
              c:           c,
            ),
          ],

          if (canEditInput) ...[
            const SizedBox(height: 12),
            if (!_showEditInput)
              _ActionCard(
                icon:        PhosphorIconsBold.pencil,
                title:       'Chỉnh sửa JD và thử lại',
                description: 'Cập nhật mô tả công việc và bắt đầu lại quy trình.',
                color:       const Color(0xFFF59E0B),
                isLoading:   false,
                onTap:       () => setState(() => _showEditInput = true),
                c:           c,
              )
            else
              _EditInputForm(
                controller: _jdCtrl,
                isLoading:  state.isLoading,
                onSubmit:   () => notifier.resubmitInput(_jdCtrl.text.trim()),
                onCancel:   () => setState(() => _showEditInput = false),
                c:          c,
              ),
          ],

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed:  state.isLoading ? null : () => notifier.reset(),
            icon:  const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Bắt đầu lại từ đầu'),
            style: TextButton.styleFrom(foregroundColor: c.textSub),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData  icon;
  final String    title;
  final String    description;
  final Color     color;
  final bool      isLoading;
  final VoidCallback onTap;
  final GenColors c;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isLoading,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Container(
              padding:    const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width:  20, height: 20,
                      child:  CircularProgressIndicator(
                          color: color, strokeWidth: 2.5))
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color:      c.text,
                          fontSize:   14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(description,
                      style: TextStyle(
                          color:    c.textSub,
                          fontSize: 12,
                          height:   1.4)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ]),
        ),
      );
}

class _EditInputForm extends StatelessWidget {
  final TextEditingController controller;
  final bool         isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final GenColors    c;

  const _EditInputForm({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
    required this.onCancel,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding:    const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cập nhật mô tả công việc',
                style: TextStyle(
                    color:      c.text,
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines:   6,
              style: TextStyle(color: c.text, fontSize: 13),
              decoration: InputDecoration(
                hintText:  'Dán JD mới vào đây...',
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
                    borderSide:   const BorderSide(color: Color(0xFFF59E0B))),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSub,
                    side: BorderSide(color: c.border),
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
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text('Gửi lại',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      );
}
