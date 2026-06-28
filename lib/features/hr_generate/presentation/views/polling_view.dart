import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';

class PollingView extends ConsumerStatefulWidget {
  const PollingView({super.key});

  @override
  ConsumerState<PollingView> createState() => _PollingViewState();
}

class _PollingViewState extends ConsumerState<PollingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(generationProvider);
    final isPlan = state.pollingPhase == 'plan';
    final c      = GenColors.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon with glow ring ──────────────────────────────────────
            SizedBox(
              width:  120,
              height: 120,
              child:  Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing outer ring
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder:   (_, __) => Opacity(
                      opacity: _glowCtrl.value.clamp(0.0, 1.0),
                      child:   Container(
                        width:  110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF7C3AED)
                                .withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Main icon circle
                  Container(
                    width:  88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      shape:     BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:      const Color(0xFF7C3AED)
                              .withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Phase badge ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        const Color(0xFF7C3AED).withValues(alpha: 0.15),
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

            // ── Title ────────────────────────────────────────────────────
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

            // ── Dots wave ────────────────────────────────────────────────
            _DotsWave(),
            const SizedBox(height: 16),

            // ── Status label ─────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                key:   ValueKey(state.statusLabel),
                state.statusLabel ??
                    (isPlan ? 'Đang sinh plan...' : 'Đang sinh câu hỏi...'),
                style: TextStyle(color: c.textSub, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dots bounce animation ─────────────────────────────────────────────────────

class _DotsWave extends StatefulWidget {
  @override
  State<_DotsWave> createState() => _DotsWaveState();
}

class _DotsWaveState extends State<_DotsWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder:   (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase offset
            final phase = (_ctrl.value - i * 0.25) % 1.0;
            // Sine-based scale: oscillates between 0.5 and 1.0
            final scale = 0.5 + 0.5 * _sine(phase);
            final color = Color.lerp(
              const Color(0xFF7C3AED),
              const Color(0xFF3B82F6),
              i / 2.0,
            )!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child:   Transform.scale(
                scale: scale.clamp(0.5, 1.0),
                child: Container(
                  width:  10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        ),
      );

  // Maps [0,1] phase to [0,1] via cosine (peak at phase=0, trough at 0.5)
  double _sine(double phase) =>
      (1.0 - math.cos(phase * 2 * math.pi)) / 2.0;
}
