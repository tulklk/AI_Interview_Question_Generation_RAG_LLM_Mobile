import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class PollingView extends ConsumerWidget {
  const PollingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = ref.watch(
      generationProvider.select((s) => s.statusLabel),
    );
    final pollingPhase = ref.watch(
      generationProvider.select((s) => s.pollingPhase),
    );
    final isPlan = pollingPhase == 'plan';
    final c      = GenColors.of(context);

    return RepaintBoundary(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width:  88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                ),
                child: Text(
                  isPlan
                      ? 'Phase 1 — Lập kế hoạch'
                      : 'Phase 2 — Tạo câu hỏi',
                  style: const TextStyle(
                      color:      Color(0xFF7C3AED),
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPlan
                    ? 'AI đang phân tích JD...'
                    : 'AI đang tạo câu hỏi...',
                style: TextStyle(
                    color:      c.text,
                    fontSize:   20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                isPlan
                    ? 'AI đang đọc JD và lên kế hoạch câu hỏi. Quá trình này thường mất 30–60 giây.'
                    : 'AI đang tạo câu hỏi chi tiết. Quá trình này thường mất 1–2 phút.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:    c.textSub,
                    fontSize: 13,
                    height:   1.5),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width:  32,
                height: 32,
                child:  CircularProgressIndicator(
                  strokeWidth: 3,
                  color:       Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusLabel ??
                    (isPlan ? 'Đang sinh plan...' : 'Đang sinh câu hỏi...'),
                style: TextStyle(color: c.textSub, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
