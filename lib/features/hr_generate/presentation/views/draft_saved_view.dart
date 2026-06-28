import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class DraftSavedView extends ConsumerWidget {
  const DraftSavedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(generationProvider.notifier);
    final c        = GenColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                shape:     BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:      const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.bookmark_added_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),

            Text('Đã lưu bộ câu hỏi!',
                style: TextStyle(
                    color:      c.text,
                    fontSize:   22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Bộ câu hỏi đã được lưu vào thư viện của bạn.\nBạn có thể sử dụng nó cho các buổi phỏng vấn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSub, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),

            // ── View library ──
            SizedBox(
              width:  double.infinity,
              height: 50,
              child:  ElevatedButton.icon(
                onPressed: () {
                  notifier.reset();
                  context.go('/hr/questions');
                },
                icon:  const Icon(Icons.library_books_rounded, size: 20),
                label: const Text('Xem thư viện câu hỏi',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Create new ──
            SizedBox(
              width:  double.infinity,
              height: 50,
              child:  OutlinedButton.icon(
                onPressed: () => notifier.reset(),
                icon:  const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text('Tạo bộ câu hỏi mới',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(
                      color: Color(0xFF7C3AED), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
