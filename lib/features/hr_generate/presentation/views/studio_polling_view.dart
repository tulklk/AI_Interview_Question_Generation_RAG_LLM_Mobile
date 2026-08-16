import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gen_colors.dart';
import '../providers/studio_generation_provider.dart';
import '../../domain/models/studio_models.dart';

// ── Polling / generating screen ───────────────────────────────────────────────
// Shows while AI is creating a plan or generating questions.
// Matches the design: spinner → title → subtitle → progress bar → step checklist
// → interview structure below.

class StudioPollingView extends ConsumerWidget {
  const StudioPollingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state        = ref.watch(studioGenerationProvider);
    final pollingPhase = state.pollingPhase;
    final statusLabel  = state.statusLabel;
    final plan         = state.plan;
    final latestRun    = state.latestRun;
    final isPlan       = pollingPhase == 'plan';
    final c            = GenColors.of(context);

    // ── Progress percentage ──────────────────────────────────────────────────
    double progress = 0.0;
    if (latestRun != null && latestRun.requestedQuestionCount > 0) {
      progress =
          latestRun.generatedQuestionCount / latestRun.requestedQuestionCount;
      if (progress > 1.0) progress = 1.0;
    }
    final progressPct = (progress * 100).round();

    // ── Active step ──────────────────────────────────────────────────────────
    final activeStep = _activeStep(statusLabel, isPlan, progress);

    final List<String> steps = isPlan
        ? [
            'Analyze job description',
            'Identify key skills',
            'Build interview structure',
            'Balance duration',
          ]
        : [
            'Analyzing interview plan',
            'Searching documents with RAG',
            'Generating questions & sample answers',
            'Finalizing question set',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Plan summary card ───────────────────────────────────────────────
        if (plan != null) ...[
          const SizedBox(height: 4),
          _PollPlanSummaryCard(plan: plan, c: c),
          const SizedBox(height: 28),
        ] else
          const SizedBox(height: 36),

        // ── Spinner + Title + Subtitle ──────────────────────────────────────
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 64, height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4.5,
                color:           GenColors.primary,
                backgroundColor: GenColors.primary.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isPlan ? 'Creating Interview Plan...' : 'Generating Questions...',
              style: TextStyle(
                  color: c.text, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              statusLabel ??
                  (isPlan
                      ? 'Designing interview structure...'
                      : 'Searching relevant documents from Knowledge Base...'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color:      GenColors.primary,
                  fontSize:   13,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Progress bar ────────────────────────────────────────────────────
        Row(children: [
          Text('Generation progress',
              style: TextStyle(color: c.textSub, fontSize: 12)),
          const Spacer(),
          Text('$progressPct%',
              style: const TextStyle(
                  color:      GenColors.primary,
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:      progress > 0 ? progress : null,
            minHeight:  6,
            backgroundColor: GenColors.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(GenColors.primary),
          ),
        ),

        const SizedBox(height: 20),

        // ── Step checklist ──────────────────────────────────────────────────
        ...List.generate(steps.length, (i) => _StepRow(
          label:  steps[i],
          done:   i < activeStep,
          active: i == activeStep,
          c: c,
        )),

        // ── Interview structure (below checklist) ───────────────────────────
        if (plan != null && plan.sections.isNotEmpty) ...[
          const SizedBox(height: 28),
          _PollInterviewStructure(plan: plan, c: c),
        ],
      ]),
    );
  }

  /// Map status label + progress → which step (0-based) is currently active.
  static int _activeStep(String? label, bool isPlan, double progress) {
    if (label != null) {
      final l = label.toLowerCase();
      if (isPlan) {
        if (l.contains('phân tích') || l.contains('analyz') || l.contains('đọc')) return 0;
        if (l.contains('cấu trúc') || l.contains('struct')) return 1;
        if (l.contains('chi tiết') || l.contains('detail'))  return 2;
        return 3;
      } else {
        if (l.contains('plan'))                                       { return 0; }
        if (l.contains('search') || l.contains('rag') ||
            l.contains('knowledge') || l.contains('document'))        { return 1; }
        if (l.contains('generat') || l.contains('answer'))            { return 2; }
        if (l.contains('finaliz'))                                     { return 3; }
      }
    }
    // Fallback: use progress ratio
    if (progress <= 0.0)  return 0;
    if (progress < 0.25)  return 1;
    if (progress < 0.80)  return 2;
    return 3;
  }
}

// ── Step row ──────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final String label;
  final bool done, active;
  final GenColors c;
  const _StepRow({
    required this.label, required this.done,
    required this.active, required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: active
          ? GenColors.primary.withValues(alpha: 0.07)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: active
            ? GenColors.primary.withValues(alpha: 0.35)
            : done
                ? Colors.transparent
                : c.border.withValues(alpha: 0.6),
      ),
    ),
    child: Row(children: [
      // Left icon
      SizedBox(
        width: 18, height: 18,
        child: done
            ? const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981))
            : active
                ? const CircularProgressIndicator(
                    strokeWidth: 2, color: GenColors.primary)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                  ),
      ),
      const SizedBox(width: 12),
      // Label
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color:      done ? c.muted : active ? c.text : c.muted,
            fontSize:   13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: c.muted,
          ),
        ),
      ),
      // "Done" badge
      if (done)
        Text('Done',
            style: const TextStyle(
                color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Plan summary card (top of polling view) ────────────────────────────────────

class _PollPlanSummaryCard extends StatelessWidget {
  final StudioPlanDetail plan;
  final GenColors c;
  const _PollPlanSummaryCard({required this.plan, required this.c});

  @override
  Widget build(BuildContext context) {
    final mix = plan.difficultyMix;
    String mixLabel = '';
    if (mix != null) {
      final e = (mix.easy   * 100).round();
      final m = (mix.medium * 100).round();
      final h = (mix.hard   * 100).round();
      if (e > 0 || m > 0 || h > 0) mixLabel = '${e}E·${m}M·${h}H';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _PollStatusChip(status: plan.status),
          const Spacer(),
          _PollInfoChip('${plan.totalQuestions} questions', c: c),
          const SizedBox(width: 6),
          _PollInfoChip('${plan.interviewLengthMinutes} min', c: c),
          if (mixLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            _PollInfoChip(mixLabel, c: c),
          ],
        ]),
        const SizedBox(height: 8),
        Text(plan.title,
            style: TextStyle(
                color: c.text, fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _PollStatusChip extends StatelessWidget {
  final String status;
  const _PollStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status.toLowerCase()) {
      case 'approved':
        label = 'Approved'; color = const Color(0xFF10B981);
      case 'awaitingapproval': case 'awaiting_approval':
        label = 'Pending Approval'; color = const Color(0xFFF59E0B);
      default:
        label = 'Draft'; color = const Color(0xFF9CA3AF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _PollInfoChip extends StatelessWidget {
  final String label;
  final GenColors c;
  const _PollInfoChip(this.label, {required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: c.bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.border),
    ),
    child: Text(label,
        style: TextStyle(
            color: c.textSub, fontSize: 10, fontWeight: FontWeight.w500)),
  );
}

// ── Interview structure panel (below step checklist) ──────────────────────────

class _PollInterviewStructure extends StatelessWidget {
  final StudioPlanDetail plan;
  final GenColors c;
  const _PollInterviewStructure({required this.plan, required this.c});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Text('INTERVIEW STRUCTURE',
            style: TextStyle(
                color:       c.muted, fontSize: 10,
                fontWeight:  FontWeight.w700, letterSpacing: 0.8)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Text('${plan.sections.length} sections',
              style: TextStyle(
                  color: c.textSub, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 10),
      // Section tiles
      ...List.generate(plan.sections.length, (i) =>
          _PollSectionTile(index: i + 1, section: plan.sections[i], c: c)),

      // Focus areas (RAG)
      if (plan.focusAreas.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('EVALUATION FOCUS (RAG)',
            style: TextStyle(
                color: c.muted, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        ...plan.focusAreas.map((fa) => _FocusAreaRow(area: fa, c: c)),
      ],

      // Sources used
      if (plan.sourcesUsed.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('SOURCES USED',
            style: TextStyle(
                color: c.muted, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: plan.sourcesUsed
              .map((s) => _SourceChip(label: s, c: c))
              .toList(),
        ),
      ],
    ]);
  }
}

class _PollSectionTile extends StatelessWidget {
  final int index;
  final StudioPlanSection section;
  final GenColors c;
  const _PollSectionTile({required this.index, required this.section, required this.c});

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor(section.difficulty);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: c.border),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color:        GenColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('$index',
                style: const TextStyle(
                    color: GenColors.primary, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.name,
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${section.numberOfQuestions} questions · ${section.estimatedMinutes} min',
                style: TextStyle(color: c.muted, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color:        diffColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: diffColor.withValues(alpha: 0.3)),
          ),
          child: Text(section.difficulty.toApiString(),
              style: TextStyle(
                  color: diffColor, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.muted),
      ]),
    );
  }

  Color _diffColor(StudioQuestionDifficulty d) {
    switch (d) {
      case StudioQuestionDifficulty.easy: return const Color(0xFF10B981);
      case StudioQuestionDifficulty.hard: return const Color(0xFFEF4444);
      default:                            return const Color(0xFFF59E0B);
    }
  }
}

// ── Evaluation Focus (RAG) row ─────────────────────────────────────────────────

class _FocusAreaRow extends StatelessWidget {
  final StudioFocusArea area;
  final GenColors c;
  const _FocusAreaRow({required this.area, required this.c});

  @override
  Widget build(BuildContext context) {
    final pct    = (area.weight * 100).round();
    final source = area.sourceFiles.isNotEmpty ? area.sourceFiles.first : null;
    final label  = source != null ? '${area.name} — $source' : area.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: c.text, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('$pct%',
              style: const TextStyle(
                  color:      GenColors.primary,
                  fontSize:   12,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value:      area.weight.clamp(0.0, 1.0),
            minHeight:  4,
            backgroundColor: GenColors.primary.withValues(alpha: 0.10),
            valueColor:  const AlwaysStoppedAnimation<Color>(GenColors.primary),
          ),
        ),
      ]),
    );
  }
}

// ── Source chip ────────────────────────────────────────────────────────────────

class _SourceChip extends StatelessWidget {
  final String label;
  final GenColors c;
  const _SourceChip({required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        c.card,
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: c.border),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.description_outlined, size: 11, color: c.muted),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(color: c.textSub, fontSize: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}
