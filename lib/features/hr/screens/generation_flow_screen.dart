import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/generation_repository.dart';
import '../models/generation_models.dart';
import '../notifiers/generation_notifier.dart';

// ─── Entry screen ─────────────────────────────────────────────────────────────

class GenerationFlowScreen extends StatefulWidget {
  final String? resumeJobId;

  const GenerationFlowScreen({super.key, this.resumeJobId});

  @override
  State<GenerationFlowScreen> createState() => _GenerationFlowScreenState();
}

class _GenerationFlowScreenState extends State<GenerationFlowScreen>
    with WidgetsBindingObserver {
  late final GenerationNotifier _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifier = GenerationNotifier(GenerationRepository());
    _notifier.addListener(_onStateChange);
    if (widget.resumeJobId != null && widget.resumeJobId!.isNotEmpty) {
      _notifier.resumeJob(widget.resumeJobId!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifier.removeListener(_onStateChange);
    _notifier.dispose();
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notifier.onAppResume();
    }
  }

  int _stepFor(GenerationFlowState fs) {
    switch (fs) {
      case GenerationFlowState.form:             return 1;
      case GenerationFlowState.pollingPlan:      return 2;
      case GenerationFlowState.planReview:       return 3;
      case GenerationFlowState.pollingQuestions: return 4;
      case GenerationFlowState.questionReview:   return 5;
      case GenerationFlowState.failed:
        final job = _notifier.state.job;
        if (job == null) return 1;
        return job.isPlanPhase ? 2 : 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s  = _notifier.state;
    final fs = s.flowState;

    Widget body;
    switch (fs) {
      case GenerationFlowState.form:
        body = _FormView(notifier: _notifier);
      case GenerationFlowState.pollingPlan:
        body = _PollingView(
          notifier:   _notifier,
          isPlanPhase: true,
        );
      case GenerationFlowState.planReview:
        body = _PlanReviewView(notifier: _notifier);
      case GenerationFlowState.pollingQuestions:
        body = _PollingView(
          notifier:    _notifier,
          isPlanPhase: false,
        );
      case GenerationFlowState.questionReview:
        body = _QuestionReviewView(notifier: _notifier);
      case GenerationFlowState.failed:
        body = _FailureView(notifier: _notifier);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('AI Question Generator',
            style: AppTextStyles.h2
                .copyWith(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _stepFor(fs)),
          if (s.error != null && !s.isLoading)
            _ErrorBanner(
              message: s.error!,
              onDismiss: _notifier.clearError,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(fs), child: body),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep; // 1–5

  const _StepIndicator({required this.currentStep});

  static const _labels = [
    'Nhập JD',
    'Tạo Plan',
    'Review Plan',
    'Tạo Q&A',
    'Kết Quả',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1120),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final leftStep = (i ~/ 2) + 1;
            final done     = currentStep > leftStep;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: done
                      ? const LinearGradient(colors: [
                          AppColors.brandPurple,
                          AppColors.deepBlue,
                        ])
                      : null,
                  color: done ? null : const Color(0xFF1E2640),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step  = (i ~/ 2) + 1;
          final done  = currentStep > step;
          final active = currentStep == step;
          return _StepDot(
            step:   step,
            label:  _labels[step - 1],
            done:   done,
            active: active,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final String label;
  final bool done;
  final bool active;

  const _StepDot({
    required this.step,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = done
        ? AppColors.success
        : active
            ? AppColors.brandPurple
            : const Color(0xFF1E2640);
    final Color borderColor = done
        ? AppColors.success
        : active
            ? AppColors.brandPurple
            : const Color(0xFF2A3350);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:  active ? 30 : 24,
          height: active ? 30 : 24,
          decoration: BoxDecoration(
            color:  dotColor,
            shape:  BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color:      AppColors.brandPurple.withValues(alpha: 0.50),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : Text(
                    '$step',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   active ? 12 : 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : done
                    ? AppColors.success
                    : const Color(0xFF4A5578),
            fontSize:   9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFF2D0A0A),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsBold.warningCircle,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.error, fontSize: 12)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded,
                color: AppColors.error.withValues(alpha: 0.7), size: 18),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW 1 — Form
// ═══════════════════════════════════════════════════════════════════════════════

class _FormView extends StatefulWidget {
  final GenerationNotifier notifier;

  const _FormView({required this.notifier});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _jdCtrl   = TextEditingController();
  final _noteCtrl = TextEditingController();

  int _count = 10;
  DifficultyLevel _difficulty = DifficultyLevel.medium;
  final Set<QuestionType> _types = {
    QuestionType.technical,
    QuestionType.behavioral,
  };

  static const _minChars = 400;

  @override
  void dispose() {
    _jdCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _jdCtrl.text.trim().length >= _minChars && _types.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final input = GenerationFormInput(
      jobDescription:  _jdCtrl.text.trim(),
      hrNote:          _noteCtrl.text.trim().isEmpty
                           ? null : _noteCtrl.text.trim(),
      numberOfQuestions: _count,
      difficulty:       _difficulty,
      questionTypes:    _types.toList(),
    );
    await widget.notifier.submitJob(input);
  }

  @override
  Widget build(BuildContext context) {
    final chars = _jdCtrl.text.trim().length;
    final enough = chars >= _minChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── JD input ──
          _SectionLabel(
            icon:  PhosphorIconsBold.fileText,
            label: 'Mô tả công việc (JD) *',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color:        const Color(0xFF0D1120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enough
                    ? AppColors.brandPurple.withValues(alpha: 0.5)
                    : const Color(0xFF1E2640),
              ),
            ),
            child: TextField(
              controller:  _jdCtrl,
              maxLines:    10,
              style:       AppTextStyles.body
                  .copyWith(color: Colors.white, fontSize: 14, height: 1.55),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText: 'Dán mô tả công việc vào đây...\n\nVí dụ: Chúng tôi đang tìm kiếm Flutter Developer với 2+ năm kinh nghiệm...',
                hintStyle:  AppTextStyles.body.copyWith(
                    color: const Color(0xFF4A5578), fontSize: 13, height: 1.55),
                border:      InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!enough && chars > 0)
                Text(
                  'Cần thêm ${_minChars - chars} ký tự nữa',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.amber, fontSize: 11),
                )
              else if (enough)
                Row(children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 12),
                  const SizedBox(width: 4),
                  Text('Đủ độ dài',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success, fontSize: 11)),
                ])
              else
                const SizedBox(),
              Text('$chars / $_minChars+',
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF4A5578), fontSize: 11)),
            ],
          ),

          const SizedBox(height: 20),

          // ── HR Note ──
          _SectionLabel(
            icon:  PhosphorIconsBold.notepad,
            label: 'Ghi chú thêm (tùy chọn)',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color:        const Color(0xFF0D1120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2640)),
            ),
            child: TextField(
              controller:  _noteCtrl,
              maxLines:    3,
              style:       AppTextStyles.body
                  .copyWith(color: Colors.white, fontSize: 14),
              decoration:  InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText:  'Ưu tiên câu hỏi về kiến trúc, tránh câu hỏi về framework cụ thể...',
                hintStyle: AppTextStyles.body.copyWith(
                    color: const Color(0xFF4A5578), fontSize: 13),
                border:    InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Count + Difficulty ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                        icon: PhosphorIconsBold.listNumbers,
                        label: 'Số câu hỏi'),
                    const SizedBox(height: 8),
                    _CountStepper(
                      value:     _count,
                      onChanged: (v) => setState(() => _count = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                        icon: PhosphorIconsBold.chartBar,
                        label: 'Độ khó'),
                    const SizedBox(height: 8),
                    _DifficultyPicker(
                      value:     _difficulty,
                      onChanged: (v) => setState(() => _difficulty = v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Question types ──
          _SectionLabel(
              icon: PhosphorIconsBold.tag, label: 'Loại câu hỏi'),
          const SizedBox(height: 8),
          Wrap(
            spacing:    8,
            runSpacing: 8,
            children: QuestionType.values.map((t) {
              final sel = _types.contains(t);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel && _types.length > 1) {
                    _types.remove(t);
                  } else if (!sel) {
                    _types.add(t);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color:    sel ? null : const Color(0xFF0D1120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : const Color(0xFF1E2640),
                    ),
                  ),
                  child: Text(
                    t.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color:      sel ? Colors.white : const Color(0xFF7A8AB0),
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      fontSize:   12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // ── Submit button ──
          SizedBox(
            width:  double.infinity,
            height: 52,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity:  _canSubmit ? 1.0 : 0.45,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:     _canSubmit ? AppColors.primaryGradient : null,
                  color:        _canSubmit ? null : const Color(0xFF1E2640),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _canSubmit
                      ? [
                          BoxShadow(
                            color:      AppColors.brandPurple.withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset:     const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: TextButton(
                  onPressed: widget.notifier.state.isLoading || !_canSubmit
                      ? null
                      : _submit,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: widget.notifier.state.isLoading
                      ? const SizedBox(
                          width:  22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsBold.sparkle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('Tạo Plan',
                                style: AppTextStyles.label.copyWith(
                                    color:      Colors.white,
                                    fontSize:   16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW 2 / 4 — Polling
// ═══════════════════════════════════════════════════════════════════════════════

class _PollingView extends StatefulWidget {
  final GenerationNotifier notifier;
  final bool isPlanPhase;

  const _PollingView({required this.notifier, required this.isPlanPhase});

  @override
  State<_PollingView> createState() => _PollingViewState();
}

class _PollingViewState extends State<_PollingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job         = widget.notifier.state.job;
    final statusLabel = job?.statusLabel;

    final title = widget.isPlanPhase
        ? 'AI đang phân tích JD...'
        : 'AI đang tạo câu hỏi...';

    final subtitle = widget.isPlanPhase
        ? 'Đang xây dựng kế hoạch phỏng vấn phù hợp'
        : 'Đang tạo câu hỏi chi tiết với gợi ý trả lời';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing brain / sparkle icon
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                final scale = 1.0 + 0.08 * _ctrl.value;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width:  90,
                height: 90,
                decoration: BoxDecoration(
                  gradient:     AppColors.primaryGradient,
                  shape:        BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      AppColors.brandPurple.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isPlanPhase
                      ? PhosphorIconsBold.brain
                      : PhosphorIconsBold.sparkle,
                  color: Colors.white,
                  size:  42,
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(title,
                style: AppTextStyles.h2.copyWith(
                    color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              statusLabel ?? subtitle,
              style: AppTextStyles.body
                  .copyWith(color: const Color(0xFF7A8AB0), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Animated progress dots
            _ProgressDots(ctrl: _ctrl),
            const SizedBox(height: 32),

            Text(
              'Quá trình này có thể mất 15–30 giây.\nBạn có thể để app chạy nền.',
              style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF4A5578), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final AnimationController ctrl;

  const _ProgressDots({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay  = i / 3;
            final t      = ((ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale  = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            final opacity = 0.3 + 0.7 * scale;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width:  8 * scale,
                  height: 8 * scale,
                  decoration: const BoxDecoration(
                    color: AppColors.brandPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW 3 — Plan Review
// ═══════════════════════════════════════════════════════════════════════════════

class _PlanReviewView extends StatefulWidget {
  final GenerationNotifier notifier;

  const _PlanReviewView({required this.notifier});

  @override
  State<_PlanReviewView> createState() => _PlanReviewViewState();
}

class _PlanReviewViewState extends State<_PlanReviewView> {
  late final TextEditingController _roleCtrl;
  late final TextEditingController _topicsCtrl;
  late final TextEditingController _constraintsCtrl;
  late DifficultyLevel _difficulty;
  late ExperienceLevel _experience;
  late int _count;
  late Set<QuestionType> _types;

  @override
  void initState() {
    super.initState();
    final plan = widget.notifier.state.job?.planDraft ?? const PlanDraft(
      role:            '',
      experienceLevel: ExperienceLevel.junior,
      difficulty:      DifficultyLevel.medium,
      questionCount:   10,
      questionTypes:   [QuestionType.technical, QuestionType.behavioral],
    );
    _roleCtrl        = TextEditingController(text: plan.role);
    _topicsCtrl      = TextEditingController(text: plan.topics.join(', '));
    _constraintsCtrl = TextEditingController(text: plan.constraints ?? '');
    _difficulty  = plan.difficulty;
    _experience  = plan.experienceLevel;
    _count       = plan.questionCount;
    _types       = plan.questionTypes.toSet();
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _topicsCtrl.dispose();
    _constraintsCtrl.dispose();
    super.dispose();
  }

  PlanDraft _buildEdited() {
    final topics = _topicsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return PlanDraft(
      role:            _roleCtrl.text.trim(),
      experienceLevel: _experience,
      difficulty:      _difficulty,
      questionCount:   _count,
      questionTypes:   _types.toList(),
      topics:          topics,
      constraints:     _constraintsCtrl.text.trim().isEmpty
                           ? null : _constraintsCtrl.text.trim(),
      summary:         widget.notifier.state.job?.planDraft?.summary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state  = widget.notifier.state;
    final plan   = state.job?.planDraft;
    final summary = plan?.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI summary ──
          if (summary != null && summary.isNotEmpty) ...[
            _AiInsightCard(text: summary),
            const SizedBox(height: 20),
          ],

          // ── Role ──
          _SectionLabel(icon: PhosphorIconsBold.briefcase, label: 'Role Title'),
          const SizedBox(height: 8),
          _DarkTextField(controller: _roleCtrl, hint: 'Frontend Developer'),
          const SizedBox(height: 16),

          // ── Experience + Difficulty ──
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                      icon:  PhosphorIconsBold.medalMilitary,
                      label: 'Kinh nghiệm'),
                  const SizedBox(height: 8),
                  _DropdownField<ExperienceLevel>(
                    value:   _experience,
                    items:   ExperienceLevel.values,
                    label:   (v) => v.displayName,
                    onChanged: (v) => setState(() => _experience = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                      icon: PhosphorIconsBold.chartBar, label: 'Độ khó'),
                  const SizedBox(height: 8),
                  _DropdownField<DifficultyLevel>(
                    value:   _difficulty,
                    items:   DifficultyLevel.values,
                    label:   (v) => v.displayName,
                    onChanged: (v) => setState(() => _difficulty = v),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Count ──
          _SectionLabel(
              icon: PhosphorIconsBold.listNumbers, label: 'Số câu hỏi'),
          const SizedBox(height: 8),
          _CountStepper(
            value:     _count,
            onChanged: (v) => setState(() => _count = v),
          ),
          const SizedBox(height: 16),

          // ── Types ──
          _SectionLabel(icon: PhosphorIconsBold.tag, label: 'Loại câu hỏi'),
          const SizedBox(height: 8),
          Wrap(
            spacing:    8,
            runSpacing: 8,
            children: QuestionType.values.map((t) {
              final sel = _types.contains(t);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel && _types.length > 1) {
                    _types.remove(t);
                  } else if (!sel) {
                    _types.add(t);
                  }
                }),
                child: AnimatedContainer(
                  duration:     const Duration(milliseconds: 160),
                  padding:      const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient:     sel ? AppColors.primaryGradient : null,
                    color:        sel ? null : const Color(0xFF0D1120),
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(
                      color: sel ? Colors.transparent : const Color(0xFF1E2640),
                    ),
                  ),
                  child: Text(t.displayName,
                      style: AppTextStyles.caption.copyWith(
                        color:      sel ? Colors.white : const Color(0xFF7A8AB0),
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        fontSize:   12,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Topics/Skills ──
          _SectionLabel(
              icon:  PhosphorIconsBold.code,
              label: 'Skills / Topics (phân cách bằng dấu phẩy)'),
          const SizedBox(height: 8),
          _DarkTextField(
              controller: _topicsCtrl,
              hint: 'React, TypeScript, REST API, Clean Architecture...'),
          const SizedBox(height: 16),

          // ── Constraints ──
          _SectionLabel(
              icon:  PhosphorIconsBold.notepad,
              label: 'Ghi chú / Ràng buộc (tùy chọn)'),
          const SizedBox(height: 8),
          _DarkTextField(
            controller: _constraintsCtrl,
            hint:       'Tránh câu hỏi về framework cụ thể...',
            maxLines:   3,
          ),
          const SizedBox(height: 28),

          // ── Buttons ──
          Row(children: [
            Expanded(
              child: _OutlineButton(
                label: 'Tạo lại Plan',
                icon:  PhosphorIconsBold.arrowCounterClockwise,
                onTap: state.isLoading ? null : () async {
                  await widget.notifier.retryPlan();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _GradientButton(
                label:     'Duyệt Plan',
                icon:      PhosphorIconsBold.check,
                isLoading: state.isLoading,
                onTap:     state.isLoading ? null : () async {
                  await widget.notifier.approvePlan(_buildEdited());
                },
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW 5 — Question Review
// ═══════════════════════════════════════════════════════════════════════════════

class _QuestionReviewView extends StatefulWidget {
  final GenerationNotifier notifier;

  const _QuestionReviewView({required this.notifier});

  @override
  State<_QuestionReviewView> createState() => _QuestionReviewViewState();
}

class _QuestionReviewViewState extends State<_QuestionReviewView> {
  String? _copiedId;

  @override
  Widget build(BuildContext context) {
    final state     = widget.notifier.state;
    final questions = state.questions;

    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsBold.question,
                color: const Color(0xFF4A5578), size: 48),
            const SizedBox(height: 12),
            Text('Chưa có câu hỏi nào',
                style: AppTextStyles.body
                    .copyWith(color: const Color(0xFF4A5578))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${questions.length} câu hỏi đã tạo',
                  style: AppTextStyles.label.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              if (state.savedDraftId != null)
                Row(children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 4),
                  Text('Đã lưu',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success, fontSize: 12)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Question list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount:     questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder:  (_, i) => _QuestionCard(
              q:         questions[i],
              index:     i + 1,
              isCopied:  _copiedId == questions[i].id,
              onCopy:    () => _copy(questions[i]),
              onDelete:  () => widget.notifier.deleteQuestion(questions[i].id),
            ),
          ),
        ),

        // Action bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1120),
            border: Border(
                top: BorderSide(
                    color: const Color(0xFF1E2640), width: 1)),
          ),
          child: Row(children: [
            Expanded(
              child: _OutlineButton(
                label: 'Bắt đầu lại',
                icon:  PhosphorIconsBold.plus,
                onTap: widget.notifier.reset,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _GradientButton(
                label:     state.savedDraftId != null
                               ? 'Đã lưu Draft'
                               : 'Lưu Draft',
                icon:      state.savedDraftId != null
                               ? PhosphorIconsBold.check
                               : PhosphorIconsBold.floppyDisk,
                isLoading: state.isLoading,
                onTap:     state.isLoading || state.savedDraftId != null
                               ? null
                               : widget.notifier.saveDraft,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _copy(GeneratedQuestion q) async {
    await Clipboard.setData(ClipboardData(text: q.question));
    setState(() => _copiedId = q.id);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copiedId = null);
  }
}

class _QuestionCard extends StatefulWidget {
  final GeneratedQuestion q;
  final int index;
  final bool isCopied;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.q,
    required this.index,
    required this.isCopied,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  Color get _diffColor {
    switch (widget.q.difficulty) {
      case DifficultyLevel.easy:   return AppColors.success;
      case DifficultyLevel.medium: return AppColors.amber;
      case DifficultyLevel.hard:   return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFF0D1120),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFF1E2640)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width:  26,
                  height: 26,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape:    BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${widget.index}',
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.question,
                      style: AppTextStyles.body.copyWith(
                          color: Colors.white, fontSize: 14, height: 1.5)),
                ),
              ],
            ),
          ),

          // ── Badges + actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 10, 10),
            child: Row(
              children: [
                _Badge(label: q.questionType.displayName,
                    color: AppColors.brandPurple),
                const SizedBox(width: 6),
                _Badge(label: q.difficulty.displayName, color: _diffColor),
                const Spacer(),
                // Copy
                GestureDetector(
                  onTap: widget.onCopy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isCopied
                          ? Icons.check_rounded
                          : PhosphorIconsBold.copy,
                      key:   ValueKey(widget.isCopied),
                      color: widget.isCopied
                          ? AppColors.success
                          : const Color(0xFF4A5578),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Delete
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(PhosphorIconsBold.trash,
                      color: AppColors.error.withValues(alpha: 0.7), size: 18),
                ),
                const SizedBox(width: 6),
                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns:    _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF4A5578), size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable detail ──
          AnimatedCrossFade(
            firstChild:  const SizedBox.shrink(),
            secondChild: _QuestionDetail(q: q),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _QuestionDetail extends StatelessWidget {
  final GeneratedQuestion q;

  const _QuestionDetail({required this.q});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        const Color(0xFF080B14),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFF1E2640)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.sampleAnswer != null && q.sampleAnswer!.isNotEmpty) ...[
            _DetailSection(
              icon:    PhosphorIconsBold.lightbulb,
              title:   'Gợi ý trả lời',
              content: q.sampleAnswer!,
              color:   AppColors.deepBlue,
            ),
            const SizedBox(height: 10),
          ],
          if (q.rationale != null && q.rationale!.isNotEmpty) ...[
            _DetailSection(
              icon:    PhosphorIconsBold.question,
              title:   'Lý do câu hỏi này',
              content: q.rationale!,
              color:   AppColors.brandPurple,
            ),
          ],
          if (q.citations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(PhosphorIconsBold.bookOpen,
                  color: AppColors.amber, size: 14),
              const SizedBox(width: 6),
              Text('Nguồn tham khảo',
                  style: AppTextStyles.caption.copyWith(
                      color:      AppColors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize:   12)),
            ]),
            const SizedBox(height: 6),
            ...q.citations.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${e.key + 1}. ${e.value}',
                    style: AppTextStyles.caption.copyWith(
                        color:   const Color(0xFF7A8AB0),
                        fontSize: 11,
                        height:   1.4),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(title,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        Text(content,
            style: AppTextStyles.caption.copyWith(
                color:   const Color(0xFF9CAAC4),
                fontSize: 12,
                height:   1.5)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w600, fontSize: 10)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIEW — Failure
// ═══════════════════════════════════════════════════════════════════════════════

class _FailureView extends StatefulWidget {
  final GenerationNotifier notifier;

  const _FailureView({required this.notifier});

  @override
  State<_FailureView> createState() => _FailureViewState();
}

class _FailureViewState extends State<_FailureView> {
  bool _showEditForm = false;
  final _jdCtrl   = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _jdCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state  = widget.notifier.state;
    final job    = state.job;
    final action = (job?.suggestedAction ?? '').toUpperCase();
    final msg    = job?.failureMessage ?? state.error ?? 'Đã xảy ra lỗi không xác định';

    if (_showEditForm) {
      return _EditInputForm(
        jdCtrl:   _jdCtrl,
        noteCtrl: _noteCtrl,
        isLoading: state.isLoading,
        onSubmit: () async {
          final input = GenerationFormInput(
            jobDescription: _jdCtrl.text.trim(),
            hrNote: _noteCtrl.text.trim().isEmpty
                ? null : _noteCtrl.text.trim(),
          );
          await widget.notifier.editAndResubmit(input);
        },
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color:        AppColors.error.withValues(alpha: 0.12),
                shape:        BoxShape.circle,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Icon(PhosphorIconsBold.warningCircle,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Xử lý thất bại',
                style: AppTextStyles.h2.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            Text(msg,
                style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF7A8AB0), fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 36),

            if (action == 'RETRY_PLAN' || job?.canRetryPlan == true) ...[
              _GradientButton(
                label:     'Thử lại Plan',
                icon:      PhosphorIconsBold.arrowCounterClockwise,
                isLoading: state.isLoading,
                onTap:     state.isLoading ? null : widget.notifier.retryPlan,
              ),
              const SizedBox(height: 12),
            ],

            if (action == 'RETRY_QUESTIONS' || job?.canRetryQuestions == true) ...[
              _GradientButton(
                label:     'Thử lại tạo câu hỏi',
                icon:      PhosphorIconsBold.arrowCounterClockwise,
                isLoading: state.isLoading,
                onTap:
                    state.isLoading ? null : widget.notifier.retryQuestions,
              ),
              const SizedBox(height: 12),
            ],

            if (action == 'EDIT_INPUT' || job?.canEditInput == true) ...[
              _OutlineButton(
                label: 'Chỉnh sửa JD',
                icon:  PhosphorIconsBold.pencil,
                onTap: () => setState(() => _showEditForm = true),
              ),
              const SizedBox(height: 12),
            ],

            _OutlineButton(
              label: 'Bắt đầu lại từ đầu',
              icon:  PhosphorIconsBold.house,
              onTap: widget.notifier.reset,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditInputForm extends StatelessWidget {
  final TextEditingController jdCtrl;
  final TextEditingController noteCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EditInputForm({
    required this.jdCtrl,
    required this.noteCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cập nhật mô tả công việc',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          _DarkTextField(
              controller: jdCtrl,
              hint:       'Nhập lại mô tả công việc...',
              maxLines:   10),
          const SizedBox(height: 12),
          _DarkTextField(
              controller: noteCtrl,
              hint:       'Ghi chú (tùy chọn)',
              maxLines:   3),
          const SizedBox(height: 24),
          _GradientButton(
            label:     'Gửi lại',
            icon:      PhosphorIconsBold.paperPlaneTilt,
            isLoading: isLoading,
            onTap:     isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.brandPurple, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.label.copyWith(
                  color:      Colors.white.withValues(alpha: 0.85),
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF0D1120),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: const Color(0xFF1E2640)),
        ),
        child: TextField(
          controller: controller,
          maxLines:   maxLines,
          style:      AppTextStyles.body.copyWith(
              color: Colors.white, fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            hintText:  hint,
            hintStyle: AppTextStyles.body.copyWith(
                color: const Color(0xFF4A5578), fontSize: 13),
            border: InputBorder.none,
          ),
        ),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color:        const Color(0xFF0D1120),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: const Color(0xFF1E2640)),
        ),
        child: DropdownButton<T>(
          value:           value,
          isExpanded:      true,
          underline:       const SizedBox(),
          dropdownColor:   const Color(0xFF0D1120),
          style:           AppTextStyles.body.copyWith(
              color: Colors.white, fontSize: 13),
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(label(i)),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      );
}

class _CountStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CountStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF0D1120),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: const Color(0xFF1E2640)),
        ),
        child: Row(
          children: [
            IconButton(
              icon:  const Icon(Icons.remove_rounded,
                  color: Colors.white, size: 18),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: Text('$value',
                  style: AppTextStyles.body.copyWith(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   16),
                  textAlign: TextAlign.center),
            ),
            IconButton(
              icon:  const Icon(Icons.add_rounded,
                  color: Colors.white, size: 18),
              onPressed: value < 50 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      );
}

class _DifficultyPicker extends StatelessWidget {
  final DifficultyLevel value;
  final ValueChanged<DifficultyLevel> onChanged;

  const _DifficultyPicker(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final levels = DifficultyLevel.values;
    return Row(
      children: levels.map((d) {
        final sel = d == value;
        final Color c = d == DifficultyLevel.easy
            ? AppColors.success
            : d == DifficultyLevel.medium
                ? AppColors.amber
                : AppColors.error;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin:   EdgeInsets.only(right: d != levels.last ? 4 : 0),
              padding:  const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:        sel ? c.withValues(alpha: 0.18) : const Color(0xFF0D1120),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: sel ? c : const Color(0xFF1E2640)),
              ),
              child: Text(d.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color:      sel ? c : const Color(0xFF4A5578),
                    fontSize:   11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final String text;

  const _AiInsightCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandPurple.withValues(alpha: 0.12),
              AppColors.deepBlue.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PhosphorIconsBold.sparkle,
                color: AppColors.brandPurple, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Insight',
                      style: AppTextStyles.caption.copyWith(
                          color:      AppColors.brandPurple,
                          fontWeight: FontWeight.w700,
                          fontSize:   12)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: AppTextStyles.caption.copyWith(
                          color:   const Color(0xFF9CAAC4),
                          fontSize: 13,
                          height:   1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return SizedBox(
      width:  double.infinity,
      height: 50,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity:  enabled ? 1.0 : 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient:     enabled ? AppColors.primaryGradient : null,
            color:        enabled ? null : const Color(0xFF1E2640),
            borderRadius: BorderRadius.circular(13),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color:      AppColors.brandPurple.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset:     const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: TextButton(
            onPressed: enabled ? onTap : null,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            child: isLoading
                ? const SizedBox(
                    width:  22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 17),
                      const SizedBox(width: 8),
                      Text(label,
                          style: AppTextStyles.label.copyWith(
                              color:      Colors.white,
                              fontSize:   15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width:  double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon:  Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CAAC4),
            side: const BorderSide(color: Color(0xFF2A3350), width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
            textStyle: AppTextStyles.label.copyWith(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
