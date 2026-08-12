import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/studio_generation_provider.dart';

class StudioFailedView extends ConsumerStatefulWidget {
  const StudioFailedView({super.key});
  @override
  ConsumerState<StudioFailedView> createState() => _StudioFailedViewState();
}

class _StudioFailedViewState extends ConsumerState<StudioFailedView> {
  bool _showEditInput = false;
  final _jdCtrl = TextEditingController();

  @override
  void dispose() { _jdCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(studioGenerationProvider);
    final notifier = ref.read(studioGenerationProvider.notifier);
    final c        = GenColors.of(context);

    final canRetryPlan      = state.pollingPhase == 'plan';
    final canRetryQuestions = state.pollingPhase == 'questions';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color:  const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape:  BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    width: 2)),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 40),
          ),
          const SizedBox(height: 20),
          Text(
              canRetryPlan ? 'Lập kế hoạch thất bại' : 'Tạo câu hỏi thất bại',
              style: TextStyle(
                  color:      c.text,
                  fontSize:   20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.textSub, fontSize: 13, height: 1.5)),
            ),
          const SizedBox(height: 28),

          // ── Retry plan ────────────────────────────────────────────────
          if (canRetryPlan) ...[
            _ActionButton(
              label:       'Thử lại lập kế hoạch',
              icon:        Icons.refresh_rounded,
              color:       const Color(0xFF7C3AED),
              isLoading:   state.isLoading,
              onPressed:   () => notifier.retryPlan(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Retry questions ───────────────────────────────────────────
          if (canRetryQuestions) ...[
            _ActionButton(
              label:       'Thử lại tạo câu hỏi',
              icon:        Icons.auto_awesome_rounded,
              color:       const Color(0xFF10B981),
              isLoading:   state.isLoading,
              onPressed:   () => notifier.retryQuestions(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Resubmit JD ───────────────────────────────────────────────
          if (!_showEditInput)
            _ActionButton(
              label:     'Nhập lại mô tả công việc',
              icon:      Icons.edit_document,
              color:     const Color(0xFF6B7280),
              isLoading: false,
              onPressed: () => setState(() => _showEditInput = true),
              outlined:  true,
            ),

          if (_showEditInput) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _jdCtrl,
              maxLines:   6,
              style:      TextStyle(color: c.text, fontSize: 13),
              decoration: InputDecoration(
                hintText:  'Nhập mô tả công việc mới...',
                hintStyle: TextStyle(color: c.textSub),
                filled:    true,
                fillColor: c.card,
                border:    OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide(color: c.border)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showEditInput = false),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: c.textSub,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            final jd = _jdCtrl.text.trim();
                            if (jd.length < 50) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Nhập ít nhất 50 ký tự')),
                              );
                              return;
                            }
                            notifier.resubmitInput(jd);
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GenColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Gửi lại'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          TextButton(
            onPressed: () => notifier.goBackToForm(),
            child: Text('Quay về trang tạo mới',
                style: TextStyle(color: c.textSub, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white))
        else
          Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );

    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14));

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: shape),
          child: child,
        ),
      );
    }

    return SizedBox(
      width:  double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: shape),
        child: child,
      ),
    );
  }
}
