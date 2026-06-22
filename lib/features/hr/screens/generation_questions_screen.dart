import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../data/services/question_generation_service.dart';

class GenerationQuestionsScreen extends StatefulWidget {
  final String jobId;
  const GenerationQuestionsScreen({super.key, required this.jobId});

  @override
  State<GenerationQuestionsScreen> createState() =>
      _GenerationQuestionsScreenState();
}

class _GenerationQuestionsScreenState extends State<GenerationQuestionsScreen>
    with SingleTickerProviderStateMixin {
  GenerationJobModel?         _job;
  List<GeneratedQuestionItem> _questions = [];
  String?                     _error;
  bool                        _isRetrying = false;
  Timer?                      _pollTimer;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pollJob();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  Future<void> _pollJob() async {
    try {
      final job = await QuestionGenerationService.getJob(widget.jobId);
      if (!mounted) return;
      setState(() { _job = job; _error = null; });

      if (job.status == GenerationJobStatus.completed) {
        final qs = job.questions.isNotEmpty
            ? job.questions
            : await QuestionGenerationService.getQuestions(widget.jobId);
        if (mounted) setState(() => _questions = qs);
      } else if (job.status == GenerationJobStatus.failed) {
        setState(() => _error = job.errorMessage ?? 'Tạo câu hỏi thất bại.');
      } else if (job.status.isProcessing || job.status == GenerationJobStatus.unknown) {
        _pollTimer = Timer(const Duration(seconds: 3), _pollJob);
      }
      // planProposed shouldn't reach here, but if it does, stop polling
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Lỗi kết nối. Đang thử lại...');
      _pollTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _error = null);
          _pollJob();
        }
      });
    }
  }

  Future<void> _retryQuestions() async {
    setState(() { _isRetrying = true; _error = null; });
    try {
      await QuestionGenerationService.retryQuestions(widget.jobId);
      if (!mounted) return;
      setState(() { _isRetrying = false; });
      _pollJob();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isRetrying = false; _error = 'Retry thất bại.'; });
      _pollJob();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _job?.status ?? GenerationJobStatus.pending;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: _buildAppBar(isDark, status),
      body: _buildBody(isDark, status),
    );
  }

  AppBar _buildAppBar(bool isDark, GenerationJobStatus status) => AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/hr'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
              ),
            ),
            child: Icon(PhosphorIconsBold.house,
                size: 16,
                color: isDark ? AppColors.white : AppColors.nearBlack),
          ),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.35),
                blurRadius: 10, offset: const Offset(0, 3),
              )],
            ),
            child: const Icon(PhosphorIconsBold.sparkle, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Câu hỏi AI',
              style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
        ]),
        actions: [
          if (_questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_questions.length} câu',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          else if (status.isProcessing || status == GenerationJobStatus.unknown)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _StatusBadge(status: status),
            ),
        ],
      );

  Widget _buildBody(bool isDark, GenerationJobStatus status) {
    if (status == GenerationJobStatus.completed && _questions.isNotEmpty) {
      return _buildQuestions(isDark);
    }
    if (status == GenerationJobStatus.failed || (_error != null && _job?.status == GenerationJobStatus.failed)) {
      return _buildFailed(isDark);
    }
    return _buildProcessing(isDark, status);
  }

  // ── Processing ────────────────────────────────────────────────────────────

  Widget _buildProcessing(bool isDark, GenerationJobStatus status) {
    final label     = _statusLabel(status);
    final sublabel  = _statusSublabel(status);

    return Column(children: [
      // Step indicator
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: _StepIndicator(current: 3, isDark: isDark),
      ),

      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Pulse icon
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Stack(alignment: Alignment.center, children: [
                  // Outer glow ring
                  Container(
                    width: 96 + 12 * _pulseCtrl.value,
                    height: 96 + 12 * _pulseCtrl.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.brandPurple.withValues(
                            alpha: 0.08 + 0.08 * _pulseCtrl.value),
                        AppColors.brandPurple.withValues(alpha: 0.0),
                      ]),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        AppColors.brandPurple.withValues(
                            alpha: 0.18 + 0.10 * _pulseCtrl.value),
                        AppColors.deepBlue.withValues(alpha: 0.05),
                      ]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsBold.sparkle,
                        size: 36, color: AppColors.brandPurple),
                  ),
                ]),
              ),

              const SizedBox(height: 28),

              Text(label,
                  style: AppTextStyles.h4.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack)),
              const SizedBox(height: 8),
              Text(sublabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.gray400, fontSize: 14, height: 1.6)),
              const SizedBox(height: 24),

              // Progress bar
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.brandPurple.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandPurple),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 36),

              // Info card — can leave and come back
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.deepBlue.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.deepBlue.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(children: [
                  const Icon(PhosphorIconsBold.info, size: 16, color: AppColors.deepBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn có thể rời trang này. Quay lại với link:\n/hr/ai-generator/questions/${widget.jobId}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepBlue,
                        height: 1.55,
                      ),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              AppSecondaryButton(
                label: 'Về Dashboard',
                onTap: () => context.go('/hr'),
                icon: const Icon(PhosphorIconsRegular.house,
                    size: 15, color: AppColors.brandPurple),
              ),

              // Network error strip
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.30)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.amber))),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }

  String _statusLabel(GenerationJobStatus s) {
    switch (s) {
      case GenerationJobStatus.pending:            return 'Đang xếp hàng...';
      case GenerationJobStatus.generatingQuestions: return 'AI đang tạo câu hỏi...';
      default:                                     return 'Đang xử lý...';
    }
  }

  String _statusSublabel(GenerationJobStatus s) {
    switch (s) {
      case GenerationJobStatus.pending:
        return 'Job đang chờ được xử lý.\nQuá trình có thể mất vài phút.';
      case GenerationJobStatus.generatingQuestions:
        return 'AI đang phân tích JD và tạo câu hỏi\nbằng RAG. Vui lòng chờ hoặc quay lại sau.';
      default:
        return 'Hệ thống đang xử lý.\nVui lòng chờ trong giây lát.';
    }
  }

  // ── Failed ────────────────────────────────────────────────────────────────

  Widget _buildFailed(bool isDark) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _StepIndicator(current: 3, isDark: isDark),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 34, color: AppColors.error),
                ).animate().scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 18),
                Text('Tạo câu hỏi thất bại',
                    style: AppTextStyles.h4.copyWith(
                        color: isDark ? AppColors.white : AppColors.nearBlack)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error ?? _job?.errorMessage ?? 'Có lỗi xảy ra trong quá trình xử lý.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error, height: 1.55,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                AppGradientButton(
                  label: _isRetrying ? 'Đang thử lại...' : 'Thử lại',
                  isLoading: _isRetrying,
                  onTap: _isRetrying ? null : _retryQuestions,
                  height: 50,
                  icon: _isRetrying ? null : const Icon(
                      PhosphorIconsBold.arrowCounterClockwise,
                      size: 15, color: Colors.white),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Về Dashboard',
                  onTap: () => context.go('/hr'),
                ),
              ]),
            ),
          ),
        ),
      ]);

  // ── Questions list ────────────────────────────────────────────────────────

  Widget _buildQuestions(bool isDark) {
    return CustomScrollView(
      slivers: [
        // Step indicator
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: _StepIndicator(current: 3, isDark: isDark)
                .animate().fadeIn(duration: 300.ms),
          ),
        ),

        // Success banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandPurple.withValues(alpha: isDark ? 0.18 : 0.07),
                    AppColors.deepBlue.withValues(alpha: isDark ? 0.14 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.brandPurple.withValues(alpha: 0.20)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.35),
                      blurRadius: 10, offset: const Offset(0, 3),
                    )],
                  ),
                  child: const Icon(PhosphorIconsBold.checkCircle,
                      size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tạo câu hỏi thành công!',
                      style: AppTextStyles.label.copyWith(
                        color: isDark ? AppColors.white : AppColors.nearBlack,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text('${_questions.length} câu hỏi được tạo từ JD bằng RAG',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray400)),
                ])),
              ]),
            ).animate().fadeIn(delay: 80.ms),
          ),
        ),

        // Hint
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Nhấn vào câu hỏi để xem chi tiết',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          ),
        ),

        // Question cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuestionCard(
                  question: _questions[i],
                  index:    i + 1,
                  isDark:   isDark,
                ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.08, end: 0),
              ),
              childCount: _questions.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final GenerationJobStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GenerationJobStatus.pending            => ('Đang xếp hàng', AppColors.amber),
      GenerationJobStatus.generatingQuestions => ('Đang tạo', AppColors.brandPurple),
      _                                      => ('Đang xử lý', AppColors.deepBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 7, height: 7,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
    );
  }
}

// ─── Question card ────────────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final GeneratedQuestionItem question;
  final int  index;
  final bool isDark;
  const _QuestionCard(
      {required this.question, required this.index, required this.isDark});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;
  bool _copied   = false;

  Color get _diffColor {
    switch ((widget.question.difficulty ?? '').toLowerCase()) {
      case 'easy':   return AppColors.success;
      case 'hard':   return AppColors.error;
      default:       return AppColors.amber;
    }
  }

  String get _diffLabel {
    switch ((widget.question.difficulty ?? '').toLowerCase()) {
      case 'easy':   return 'Dễ';
      case 'hard':   return 'Khó';
      default:       return 'Trung bình';
    }
  }

  String get _typeLabel {
    final t = (widget.question.type ?? '').toLowerCase();
    if (t.contains('technical'))  return 'Kỹ thuật';
    if (t.contains('behavioral')) return 'Hành vi';
    if (t.contains('situation'))  return 'Tình huống';
    if (t.contains('open'))       return 'Mở';
    if (t.isEmpty)                return '';
    return widget.question.type!;
  }

  Future<void> _copyQuestion() async {
    await Clipboard.setData(ClipboardData(text: widget.question.question));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasSampleAnswer = (widget.question.sampleAnswer ?? '').isNotEmpty;
    final hasRationale    = (widget.question.rationale ?? '').isNotEmpty;
    final hasCitations    = widget.question.citations.isNotEmpty;
    final hasSkill        = (widget.question.skill ?? '').isNotEmpty;
    final hasType         = _typeLabel.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppColors.brandPurple.withValues(alpha: 0.40)
                : (widget.isDark
                    ? AppColors.darkCardBorder
                    : AppColors.gray200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
            if (_expanded) BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.08),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Number badge
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.30),
                    blurRadius: 6, offset: const Offset(0, 2),
                  )],
                ),
                child: Center(
                  child: Text('${widget.index}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.question.question,
                    style: AppTextStyles.body.copyWith(
                      color: widget.isDark ? AppColors.white : AppColors.nearBlack,
                      fontSize: 14, height: 1.5,
                    ),
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded ? null : TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              // Copy + expand icons
              Column(children: [
                GestureDetector(
                  onTap: _copyQuestion,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _copied
                          ? PhosphorIconsBold.checkCircle
                          : PhosphorIconsRegular.copy,
                      key: ValueKey(_copied),
                      size: 16,
                      color: _copied ? AppColors.success : AppColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  _expanded ? PhosphorIconsBold.caretUp : PhosphorIconsBold.caretDown,
                  size: 14, color: AppColors.gray400,
                ),
              ]),
            ]),

            const SizedBox(height: 10),

            // Chips row
            Wrap(spacing: 6, runSpacing: 6, children: [
              // Difficulty
              _Chip(label: _diffLabel, color: _diffColor),
              // Type
              if (hasType)
                _Chip(
                    label: _typeLabel,
                    color: AppColors.deepBlue,
                    icon: PhosphorIconsRegular.listBullets),
              // Skill
              if (hasSkill)
                _Chip(
                    label: widget.question.skill!,
                    color: AppColors.brandPurple,
                    icon: PhosphorIconsRegular.code),
            ]),

            // ── Expanded details ──
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.gray200),
              const SizedBox(height: 14),

              // Sample answer
              if (hasSampleAnswer) ...[
                _DetailSection(
                  icon: PhosphorIconsBold.sparkle,
                  label: 'Câu trả lời gợi ý',
                  color: AppColors.brandPurple,
                  content: widget.question.sampleAnswer!,
                  isDark: widget.isDark,
                  bgAlpha: widget.isDark ? 0.10 : 0.05,
                ),
                const SizedBox(height: 10),
              ],

              // Rationale
              if (hasRationale) ...[
                _DetailSection(
                  icon: PhosphorIconsBold.lightbulb,
                  label: 'Lý do chọn câu hỏi này',
                  color: AppColors.teal,
                  content: widget.question.rationale!,
                  isDark: widget.isDark,
                  bgAlpha: widget.isDark ? 0.10 : 0.05,
                ),
                const SizedBox(height: 10),
              ],

              // Citations (RAG sources)
              if (hasCitations) ...[
                _CitationsSection(
                  citations: widget.question.citations,
                  isDark: widget.isDark,
                ),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData? icon;
  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );
}

// ─── Detail section ───────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final String   content;
  final bool     isDark;
  final double   bgAlpha;

  const _DetailSection({
    required this.icon,
    required this.label,
    required this.color,
    required this.content,
    required this.isDark,
    this.bgAlpha = 0.06,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(10),
          border: const Border(left: BorderSide(width: 3, color: Colors.transparent)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 7),
          Text(content,
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.gray500,
                height: 1.6, fontSize: 13,
              )),
        ]),
      );
}

// ─── Citations section ────────────────────────────────────────────────────────

class _CitationsSection extends StatelessWidget {
  final List<String> citations;
  final bool         isDark;
  const _CitationsSection({required this.citations, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: isDark ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(PhosphorIconsBold.bookOpen, size: 12, color: AppColors.amber),
            const SizedBox(width: 6),
            Text('Nguồn tham khảo (RAG)',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.amber, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ...citations.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('[${e.key + 1}]',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(e.value,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.70)
                              : AppColors.gray500,
                          fontSize: 12, height: 1.5,
                        )),
                  ),
                ]),
              )),
        ]),
      );
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int  current;
  final bool isDark;
  const _StepIndicator({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = ['Nhập JD', 'Xem Plan', 'Câu hỏi'];
    return Row(
      children: steps.asMap().entries.expand((e) {
        final i      = e.key + 1;
        final label  = e.value;
        final done   = i < current;
        final active = i == current;

        final dot = Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: (active || done) ? AppColors.primaryGradient : null,
              color: (active || done)
                  ? null
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.gray200),
              shape: BoxShape.circle,
              boxShadow: active ? [BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.40),
                blurRadius: 10, offset: const Offset(0, 3),
              )] : [],
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text('$i', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? Colors.white
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : AppColors.gray400),
                    )),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.brandPurple
                : (isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppColors.gray400),
          )),
        ]);

        if (e.key == steps.length - 1) return [dot];
        final line = Expanded(child: Container(
          height: 2, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: done ? AppColors.primaryGradient : null,
            color: done ? null
                : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.gray200),
            borderRadius: BorderRadius.circular(1),
          ),
        ));
        return [dot, line];
      }).toList(),
    );
  }
}
