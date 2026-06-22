import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../data/services/question_generation_service.dart';

class GenerationPlanScreen extends StatefulWidget {
  final String jobId;
  const GenerationPlanScreen({super.key, required this.jobId});

  @override
  State<GenerationPlanScreen> createState() => _GenerationPlanScreenState();
}

class _GenerationPlanScreenState extends State<GenerationPlanScreen>
    with SingleTickerProviderStateMixin {
  GenerationJobModel? _job;
  String?  _error;
  bool     _isSending    = false;
  bool     _isApproving  = false;
  Timer?   _pollTimer;

  final _answerCtrl    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _fetchJob();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _answerCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Polling ──────────────────────────────────────────────────────────────────

  Future<void> _fetchJob() async {
    try {
      final job = await QuestionGenerationService.getJob(widget.jobId);
      if (!mounted) return;
      setState(() { _job = job; _error = null; });

      if (job.status.isProcessing) {
        _pollTimer = Timer(const Duration(seconds: 3), _fetchJob);
      } else if (job.status == GenerationJobStatus.failed) {
        setState(() => _error = job.errorMessage ?? 'Xử lý thất bại. Vui lòng thử lại.');
      }
      // clarifying / planProposed → no auto-poll, wait for user action
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không thể tải dữ liệu. Vui lòng thử lại.');
    }
  }

  // ── Send clarify answer ──────────────────────────────────────────────────────

  Future<void> _sendAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    setState(() { _isSending = true; _error = null; });
    _answerCtrl.clear();
    try {
      final job = await QuestionGenerationService.sendClarifyAnswer(
        jobId: widget.jobId, answer: answer,
      );
      if (!mounted) return;
      setState(() { _job = job; });

      // If still clarifying, poll again after short delay
      if (job.status.isProcessing || job.status == GenerationJobStatus.clarifying) {
        _pollTimer = Timer(const Duration(seconds: 2), _fetchJob);
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gửi thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Approve plan ─────────────────────────────────────────────────────────────

  Future<void> _approvePlan() async {
    setState(() { _isApproving = true; _error = null; });
    try {
      await QuestionGenerationService.approvePlan(widget.jobId);
      if (!mounted) return;
      context.pushReplacement('/hr/ai-generator/questions/${widget.jobId}');
    } catch (e) {
      if (!mounted) return;
      setState(() { _isApproving = false; _error = 'Không thể xác nhận plan.'; });
    }
  }

  // ── Retry ────────────────────────────────────────────────────────────────────

  Future<void> _retryPlan() async {
    setState(() { _error = null; _job = null; });
    try {
      await QuestionGenerationService.retryPlan(widget.jobId);
      _fetchJob();
    } catch (_) {
      setState(() => _error = 'Retry thất bại. Vui lòng thử lại.');
      _fetchJob();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: _buildAppBar(isDark),
      body: _buildBody(isDark),
    );
  }

  AppBar _buildAppBar(bool isDark) => AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
            ),
            child: Icon(PhosphorIconsBold.arrowLeft,
                size: 18,
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
            child: const Icon(PhosphorIconsBold.brain, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('Làm rõ & Plan',
              style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _StepIndicator(current: 2, isDark: isDark),
          ),
        ),
      );

  Widget _buildBody(bool isDark) {
    // Initial loading
    if (_job == null && _error == null) {
      return _buildProcessing(isDark, 'AI đang phân tích JD...');
    }

    // Fatal error with no job loaded
    if (_job == null && _error != null) {
      return _buildFatalError(isDark);
    }

    final job = _job!;

    // Processing (pending / planning / generating)
    if (job.status.isProcessing) {
      return _buildProcessing(isDark, 'AI đang xử lý...');
    }

    // Failed
    if (job.status == GenerationJobStatus.failed) {
      return _buildFailed(isDark, job);
    }

    // Clarifying phase — show chat + input
    if (job.status == GenerationJobStatus.clarifying ||
        (job.status == GenerationJobStatus.unknown && job.currentQuestion != null)) {
      return _buildClarifyChat(isDark, job);
    }

    // Plan proposed — show plan + approve button
    if (job.status == GenerationJobStatus.planProposed) {
      return _buildPlanPreview(isDark, job);
    }

    // Unknown state: show what we have + poll
    return _buildProcessing(isDark, 'Đang chờ phản hồi từ AI...');
  }

  // ─── Processing state ─────────────────────────────────────────────────────

  Widget _buildProcessing(bool isDark, String message) {
    return Column(children: [
      Expanded(child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: 0.92 + 0.08 * _pulseCtrl.value,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [
                    AppColors.brandPurple.withValues(alpha: 0.20 + 0.10 * _pulseCtrl.value),
                    AppColors.brandPurple.withValues(alpha: 0.03),
                  ]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsBold.brain,
                    size: 36, color: AppColors.brandPurple),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(message,
              style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
          const SizedBox(height: 8),
          Text('Vui lòng chờ trong giây lát...',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          const SizedBox(height: 20),
          SizedBox(
            width: 130,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.brandPurple.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.brandPurple),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ]),
      )),
    ]);
  }

  // ─── Clarify chat view ────────────────────────────────────────────────────

  Widget _buildClarifyChat(bool isDark, GenerationJobModel job) {
    // Merge chatHistory + currentQuestion if not already in history
    final messages = List<ChatMessage>.from(job.chatHistory);
    final currentQ = job.currentQuestion;
    if (currentQ != null && currentQ.isNotEmpty) {
      final alreadyAdded = messages.isNotEmpty &&
          messages.last.isAI && messages.last.content == currentQ;
      if (!alreadyAdded) {
        messages.add(ChatMessage(role: 'assistant', content: currentQ));
      }
    }

    return Column(children: [
      // Chat history
      Expanded(
        child: messages.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsBold.chatDots,
                        size: 28, color: AppColors.brandPurple),
                  ),
                  const SizedBox(height: 14),
                  Text('AI đang chuẩn bị câu hỏi...',
                      style: AppTextStyles.label.copyWith(color: AppColors.gray400)),
                ]),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                itemCount: messages.length,
                itemBuilder: (_, i) => _ChatBubble(
                  message: messages[i],
                  isDark:  isDark,
                ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.1, end: 0),
              ),
      ),

      // Error strip
      if (_error != null)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error))),
            GestureDetector(
              onTap: () => setState(() => _error = null),
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
            ),
          ]),
        ),

      // Input bar
      _buildAnswerInput(isDark),
    ]);
  }

  Widget _buildAnswerInput(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.gray200,
          ),
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        top: false,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.offWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.gray200,
                ),
              ),
              child: TextField(
                controller: _answerCtrl,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                  fontSize: 14, height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập câu trả lời của bạn...',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.30)
                        : AppColors.gray400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _sendAnswer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: _isSending ? null : AppColors.primaryGradient,
                color: _isSending
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.gray200)
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSending ? [] : [BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.35),
                  blurRadius: 10, offset: const Offset(0, 3),
                )],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.brandPurple),
                      ),
                    )
                  : const Icon(PhosphorIconsBold.paperPlaneTilt,
                      size: 18, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Plan preview ─────────────────────────────────────────────────────────

  Widget _buildPlanPreview(bool isDark, GenerationJobModel job) {
    return Column(children: [
      Expanded(
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            // Success badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('Plan đã sẵn sàng!',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w700)),
                ]),
              ).animate().fadeIn().scale(begin: const Offset(0.85, 0.85)),
            ),
            const SizedBox(height: 16),

            // Chat history (collapsed)
            if (job.chatHistory.isNotEmpty) ...[
              _CollapsibleChatHistory(history: job.chatHistory, isDark: isDark)
                  .animate().fadeIn(delay: 60.ms),
              const SizedBox(height: 16),
            ],

            // Plan card
            _PlanCard(plan: job.plan, jobId: widget.jobId, isDark: isDark)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // Error
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),

      // Bottom action buttons
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          border: Border(
              top: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : AppColors.gray200)),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppGradientButton(
              label: _isApproving ? 'Đang tạo câu hỏi...' : 'Xác nhận Plan & Tạo câu hỏi',
              isLoading: _isApproving,
              onTap: _isApproving ? null : _approvePlan,
              height: 54,
              icon: _isApproving ? null : const Icon(
                  PhosphorIconsBold.sparkle, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: 'Chỉnh sửa & Hỏi lại',
              onTap: _isSending ? null : () => setState(() {
                if (_job != null) {
                  _job = GenerationJobModel(
                    id:              _job!.id,
                    status:          GenerationJobStatus.clarifying,
                    chatHistory:     _job!.chatHistory,
                    plan:            _job!.plan,
                    currentQuestion: 'Bạn muốn điều chỉnh gì trong plan trên?',
                  );
                }
              }),
              icon: const Icon(PhosphorIconsRegular.pencilSimple,
                  size: 15, color: AppColors.brandPurple),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ─── Failed state ─────────────────────────────────────────────────────────

  Widget _buildFailed(bool isDark, GenerationJobModel job) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 30, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text('Tạo plan thất bại',
              style: AppTextStyles.h4.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
          const SizedBox(height: 8),
          Text(job.errorMessage ?? _error ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray400)),
          const SizedBox(height: 24),
          AppGradientButton(
            label: 'Thử lại',
            onTap: _retryPlan,
            height: 48,
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(label: 'Quay lại', onTap: () => context.pop()),
        ]),
      ),
    );
  }

  Widget _buildFatalError(bool isDark) => _buildFailed(isDark,
      GenerationJobModel(id: widget.jobId, status: GenerationJobStatus.failed,
          errorMessage: _error));
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool        isDark;
  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            // AI avatar
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.30),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: const Icon(PhosphorIconsBold.robot, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                gradient: isAI ? null : AppColors.primaryGradient,
                color: isAI
                    ? (isDark ? AppColors.darkCard : AppColors.white)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isAI ? 4 : 16),
                  bottomRight: Radius.circular(isAI ? 16 : 4),
                ),
                border: isAI ? Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                ) : null,
                boxShadow: [BoxShadow(
                  color: isAI
                      ? Colors.black.withValues(alpha: 0.04)
                      : AppColors.brandPurple.withValues(alpha: 0.25),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI) ...[
                    Row(children: [
                      const Icon(PhosphorIconsBold.sparkle,
                          size: 10, color: AppColors.brandPurple),
                      const SizedBox(width: 4),
                      Text('AI Assistant',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          )),
                    ]),
                    const SizedBox(height: 5),
                  ],
                  Text(message.content,
                      style: AppTextStyles.body.copyWith(
                        color: isAI
                            ? (isDark ? AppColors.white : AppColors.nearBlack)
                            : Colors.white,
                        fontSize: 14, height: 1.55,
                      )),
                ],
              ),
            ),
          ),

          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.user,
                  size: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.60)
                      : AppColors.gray500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Collapsible chat history ─────────────────────────────────────────────────

class _CollapsibleChatHistory extends StatefulWidget {
  final List<ChatMessage> history;
  final bool isDark;
  const _CollapsibleChatHistory({required this.history, required this.isDark});

  @override
  State<_CollapsibleChatHistory> createState() => _CollapsibleChatHistoryState();
}

class _CollapsibleChatHistoryState extends State<_CollapsibleChatHistory> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.darkCardBorder : AppColors.gray200,
        ),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(PhosphorIconsRegular.chatDots,
                  size: 14, color: AppColors.brandPurple),
              const SizedBox(width: 8),
              Text('Lịch sử làm rõ (${widget.history.length} tin nhắn)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPurple, fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Icon(
                _expanded ? PhosphorIconsBold.caretUp : PhosphorIconsBold.caretDown,
                size: 12, color: AppColors.gray400,
              ),
            ]),
          ),
        ),
        if (_expanded) ...[
          Divider(height: 1,
              color: widget.isDark ? AppColors.darkCardBorder : AppColors.gray200),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: widget.history.length,
            itemBuilder: (_, i) => _ChatBubble(
                message: widget.history[i], isDark: widget.isDark),
          ),
        ],
      ]),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final GenerationPlanModel? plan;
  final String jobId;
  final bool   isDark;
  const _PlanCard({required this.plan, required this.jobId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 3,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                const Icon(PhosphorIconsBold.clipboardText,
                    size: 15, color: AppColors.brandPurple),
                const SizedBox(width: 8),
                Text('Interview Plan',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                      fontWeight: FontWeight.w700,
                    )),
                if (plan?.totalQuestions != null && plan!.totalQuestions > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${plan!.totalQuestions} câu',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),

              if (plan == null || (plan!.summary == null &&
                  plan!.role == null && plan!.topics.isEmpty)) ...[
                const SizedBox(height: 14),
                Center(child: Text(
                    'Plan đã được tạo. Nhấn xác nhận để bắt đầu tạo câu hỏi.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray400))),
              ] else ...[
                const SizedBox(height: 16),

                // Role + Level row
                if (plan!.role != null || plan!.level != null)
                  Row(children: [
                    if (plan!.role != null)
                      _MetaChip(
                        icon: PhosphorIconsRegular.briefcase,
                        label: plan!.role!,
                        color: AppColors.deepBlue,
                        isDark: isDark,
                      ),
                    if (plan!.role != null && plan!.level != null)
                      const SizedBox(width: 8),
                    if (plan!.level != null)
                      _MetaChip(
                        icon: PhosphorIconsRegular.chartBar,
                        label: plan!.level!,
                        color: AppColors.accentViolet,
                        isDark: isDark,
                      ),
                  ]),

                if (plan!.role != null || plan!.level != null)
                  const SizedBox(height: 14),

                // Summary
                if (plan!.summary != null && plan!.summary!.isNotEmpty) ...[
                  Text('Tóm tắt',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.50)
                            : AppColors.gray500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                  const SizedBox(height: 6),
                  Text(plan!.summary!,
                      style: AppTextStyles.body.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.80)
                            : AppColors.gray500,
                        fontSize: 13, height: 1.6,
                      )),
                  const SizedBox(height: 14),
                ],

                // Question types
                if (plan!.questionTypes.isNotEmpty) ...[
                  _ChipSection(
                    title: 'Loại câu hỏi',
                    icon: PhosphorIconsBold.listBullets,
                    color: AppColors.brandPurple,
                    items: plan!.questionTypes,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],

                // Topics
                if (plan!.topics.isNotEmpty) ...[
                  _ChipSection(
                    title: 'Chủ đề',
                    icon: PhosphorIconsBold.lightbulb,
                    color: AppColors.teal,
                    items: plan!.topics,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],

                // Skills
                if (plan!.skills.isNotEmpty) ...[
                  _ChipSection(
                    title: 'Kỹ năng yêu cầu',
                    icon: PhosphorIconsBold.code,
                    color: AppColors.deepBlue,
                    items: plan!.skills,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],

                // Constraints
                if (plan!.constraints != null && plan!.constraints!.isNotEmpty) ...[
                  Text('Ràng buộc',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.50)
                            : AppColors.gray500,
                        fontWeight: FontWeight.w700, fontSize: 11,
                      )),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: isDark ? 0.10 : 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.30)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(plan!.constraints!,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.70)
                                : AppColors.gray500,
                            height: 1.5,
                          ))),
                    ]),
                  ),
                ],
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     isDark;
  const _MetaChip({required this.icon, required this.label,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w700, fontSize: 12,
              )),
        ]),
      );
}

class _ChipSection extends StatelessWidget {
  final String     title;
  final IconData   icon;
  final Color      color;
  final List<String> items;
  final bool       isDark;
  const _ChipSection({required this.title, required this.icon,
      required this.color, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
          const SizedBox(height: 7),
          Wrap(spacing: 6, runSpacing: 6, children: items.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Text(s,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600, fontSize: 11)),
          )).toList()),
        ],
      );
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int  current;
  final bool isDark;
  const _StepIndicator({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = ['Nhập JD', 'Làm rõ & Plan', 'Câu hỏi'];
    return Row(
      children: steps.asMap().entries.expand((e) {
        final i      = e.key + 1;
        final label  = e.value;
        final done   = i < current;
        final active = i == current;

        final dot = Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 26, height: 26,
            decoration: BoxDecoration(
              gradient: (active || done) ? AppColors.primaryGradient : null,
              color: (active || done) ? null
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.gray200),
              shape: BoxShape.circle,
              boxShadow: active ? [BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.40),
                blurRadius: 10, offset: const Offset(0, 3),
              )] : [],
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : Text('$i', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: active ? Colors.white
                          : (isDark ? Colors.white.withValues(alpha: 0.35) : AppColors.gray400),
                    )),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.brandPurple
                : (isDark ? Colors.white.withValues(alpha: 0.35) : AppColors.gray400),
          )),
        ]);

        if (e.key == steps.length - 1) return [dot];
        final line = Expanded(child: Container(
          height: 2, margin: const EdgeInsets.only(bottom: 18),
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

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error))),
        ]),
      );
}
