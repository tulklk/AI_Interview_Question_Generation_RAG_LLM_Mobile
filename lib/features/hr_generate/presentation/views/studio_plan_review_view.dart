import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/studio_generation_provider.dart';
import '../../domain/models/studio_models.dart';

class StudioPlanReviewView extends ConsumerWidget {
  const StudioPlanReviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(studioGenerationProvider);
    final notifier = ref.read(studioGenerationProvider.notifier);
    final plan     = state.plan;
    final c        = GenColors.of(context);

    if (plan == null) {
      return const Center(
          child: CircularProgressIndicator(color: GenColors.primary));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Plan summary card ────────────────────────────────────
                _PlanSummaryCard(plan: plan, c: c),
                const SizedBox(height: 16),

                // ── Sections ─────────────────────────────────────────────
                if (plan.sections.isNotEmpty) ...[
                  Text('Cấu trúc phỏng vấn',
                      style: TextStyle(
                          color:      c.text,
                          fontSize:   15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...plan.sections.map((s) => _SectionCard(section: s, c: c)),
                  const SizedBox(height: 16),
                ],

                // ── Focus areas ──────────────────────────────────────────
                if (plan.focusAreas.isNotEmpty) ...[
                  Text('Trọng tâm',
                      style: TextStyle(
                          color:      c.text,
                          fontSize:   15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: plan.focusAreas.map((fa) => _FocusChip(
                        name: fa.name,
                        weight: fa.weight,
                        c: c)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Error ────────────────────────────────────────────────
                if (state.error != null)
                  _ErrorBanner(message: state.error!),
              ],
            ),
          ),
        ),

        // ── Actions ──────────────────────────────────────────────────────
        _ActionBar(
          isLoading:   state.isLoading,
          planStatus:  plan.status,
          onApprove:   () => notifier.approvePlan(),
          onRetry:     () => notifier.retryPlan(),
          onBack:      () => notifier.goBackToForm(),
          c:           c,
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PlanSummaryCard extends StatelessWidget {
  final StudioPlanDetail plan;
  final GenColors c;
  const _PlanSummaryCard({required this.plan, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status
          Row(
            children: [
              Expanded(
                child: Text(plan.title.isNotEmpty ? plan.title : 'Kế hoạch phỏng vấn',
                    style: TextStyle(
                        color:      c.text,
                        fontSize:   16,
                        fontWeight: FontWeight.w700)),
              ),
              _StatusBadge(status: plan.status),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _Stat(label: 'Câu hỏi',   value: '${plan.totalQuestions}'),
              const SizedBox(width: 16),
              _Stat(label: 'Thời gian', value: '${plan.interviewLengthMinutes} phút'),
              const SizedBox(width: 16),
              _Stat(label: 'Độ khó',    value: plan.difficulty.displayName),
            ],
          ),

          if (plan.difficultyMix != null) ...[
            const SizedBox(height: 12),
            _DifficultyBar(mix: plan.difficultyMix!),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

class _DifficultyBar extends StatelessWidget {
  final StudioDifficultyMix mix;
  const _DifficultyBar({required this.mix});
  @override
  Widget build(BuildContext context) {
    final total  = mix.easy + mix.medium + mix.hard;
    if (total == 0) return const SizedBox.shrink();
    final easyP  = mix.easy   / total;
    final medP   = mix.medium / total;
    final hardP  = mix.hard   / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phân bổ độ khó',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              if (easyP > 0) Expanded(flex: (easyP * 100).round(),
                  child: Container(height: 8, color: const Color(0xFF10B981))),
              if (medP > 0)  Expanded(flex: (medP  * 100).round(),
                  child: Container(height: 8, color: const Color(0xFFF59E0B))),
              if (hardP > 0) Expanded(flex: (hardP * 100).round(),
                  child: Container(height: 8, color: const Color(0xFFEF4444))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _Legend(color: const Color(0xFF10B981), label: 'Dễ ${(easyP * 100).round()}%'),
            const SizedBox(width: 10),
            _Legend(color: const Color(0xFFF59E0B), label: 'TB ${(medP  * 100).round()}%'),
            const SizedBox(width: 10),
            _Legend(color: const Color(0xFFEF4444), label: 'Khó ${(hardP * 100).round()}%'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
      ]);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'approved'          => ('Đã duyệt',   const Color(0xFF10B981)),
      'awaitingapproval'  => ('Chờ duyệt',  const Color(0xFFF59E0B)),
      'refining'          => ('Đang tinh chỉnh', const Color(0xFF7C3AED)),
      _                   => ('Bản nháp',   const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(label,
          style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final StudioPlanSection section;
  final GenColors c;
  const _SectionCard({required this.section, required this.c});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border)),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Center(
                child: Text('${section.orderIndex + 1}',
                    style: const TextStyle(
                        color:      Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                        fontSize:   13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.name,
                      style: TextStyle(
                          color:      c.text,
                          fontWeight: FontWeight.w600,
                          fontSize:   13)),
                  if (section.description != null)
                    Text(section.description!,
                        style: TextStyle(
                            color:    c.textSub,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${section.numberOfQuestions} câu',
                    style: TextStyle(
                        color:      c.text,
                        fontSize:   12,
                        fontWeight: FontWeight.w600)),
                Text(section.difficulty.displayName,
                    style: TextStyle(color: c.textSub, fontSize: 11)),
              ],
            ),
          ],
        ),
      );
}

class _FocusChip extends StatelessWidget {
  final String name;
  final double weight;
  final GenColors c;
  const _FocusChip({required this.name, required this.weight, required this.c});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color:        const Color(0xFF7C3AED).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3))),
        child: Text('$name  ${(weight * 100).round()}%',
            style: const TextStyle(
                color:      Color(0xFF7C3AED),
                fontSize:   12,
                fontWeight: FontWeight.w600)),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        width:   double.infinity,
        margin:  const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3))),
        child: Text(message,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
      );
}

class _ActionBar extends StatelessWidget {
  final bool isLoading;
  final String planStatus;
  final VoidCallback onApprove;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final GenColors c;
  const _ActionBar({
    required this.isLoading,
    required this.planStatus,
    required this.onApprove,
    required this.onRetry,
    required this.onBack,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = planStatus.toLowerCase() == 'approved';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isApproved)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onApprove,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                      isLoading ? 'Đang xử lý...' : 'Duyệt & Tạo câu hỏi',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GenColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (!isApproved) const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tạo lại plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSub,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Nhập lại JD'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSub,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
