import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../data/services/question_generation_service.dart';

// ─── Supported MIME / extensions ─────────────────────────────────────────────

const _allowedExtensions = ['pdf', 'doc', 'docx'];
const _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

// ─── Screen ───────────────────────────────────────────────────────────────────

class AIGeneratorScreen extends ConsumerStatefulWidget {
  const AIGeneratorScreen({super.key});

  @override
  ConsumerState<AIGeneratorScreen> createState() => _AIGeneratorScreenState();
}

class _AIGeneratorScreenState extends ConsumerState<AIGeneratorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _jdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  late TabController _inputTabCtrl;
  late AnimationController _glowCtrl;

  // ── config state ────────────────────────────────────────────────────────────
  int _count = 10;
  String _difficulty = 'medium';
  final Set<String> _types = {'technical', 'behavioral'};
  final List<String> _skills = [];

  // ── file state ──────────────────────────────────────────────────────────────
  PlatformFile? _pickedFile;
  String? _fileError;

  // ── submit state ────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _jdError; // field-level validation, shown inline in JD field
  String? _submitError; // API-level errors, shown in banner below config

  @override
  void initState() {
    super.initState();
    _inputTabCtrl = TabController(length: 2, vsync: this);
    _inputTabCtrl.addListener(() => setState(() {
          _fileError = null;
          _jdError = null;
          _submitError = null;
        }));
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _jdCtrl.dispose();
    _noteCtrl.dispose();
    _skillCtrl.dispose();
    _inputTabCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── file picker ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() => _fileError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        setState(() => _fileError = 'Chỉ chấp nhận PDF, DOC, DOCX');
        return;
      }
      if ((file.size) > _maxFileSizeBytes) {
        setState(() => _fileError = 'File phải nhỏ hơn 10 MB');
        return;
      }
      if (file.size == 0) {
        setState(() => _fileError = 'File không được trống');
        return;
      }
      setState(() => _pickedFile = file);
    } catch (_) {
      setState(() => _fileError = 'Không thể chọn file. Vui lòng thử lại.');
    }
  }

  // ── skill tag input ─────────────────────────────────────────────────────────

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isEmpty || _skills.contains(s)) {
      _skillCtrl.clear();
      return;
    }
    setState(() {
      _skills.add(s);
      _skillCtrl.clear();
    });
  }

  void _removeSkill(String s) => setState(() => _skills.remove(s));

  // ── submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _jdError = null;
      _submitError = null;
    });
    final isFile = _inputTabCtrl.index == 1;

    // Validate
    if (isFile) {
      if (_pickedFile == null) {
        setState(() => _fileError = 'Vui lòng chọn file JD');
        return;
      }
    } else {
      if (_jdCtrl.text.trim().isEmpty) {
        setState(() => _jdError = 'Vui lòng nhập mô tả công việc (JD)');
        return;
      }
    }

    final config = GenerationConfig(
      numberOfQuestions: _count,
      questionTypes: _types.toList(),
      skills: _skills,
      difficulty: _difficulty,
      hrNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    setState(() => _isSubmitting = true);
    try {
      GenerationJobModel job;
      if (isFile) {
        final f = File(_pickedFile!.path!);
        job = await QuestionGenerationService.createJobFromFile(
          file: f,
          fileName: _pickedFile!.name,
          config: config,
        );
      } else {
        job = await QuestionGenerationService.createJobFromText(
          jobDescription: _jdCtrl.text.trim(),
          config: config,
        );
      }
      if (!mounted) return;
      if (job.id.isEmpty) {
        setState(() =>
            _submitError = 'Server không trả về ID job. Vui lòng thử lại.');
        return;
      }
      context.push('/hr/ai-generator/plan/${job.id}');
    } catch (e) {
      if (!mounted) return;
      String msg = 'Có lỗi xảy ra. Vui lòng thử lại.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          msg = (data['message'] ?? data['title'] ?? data['error'] ?? msg)
              .toString();
        } else if (data is String && data.isNotEmpty) {
          msg = data;
        }
      }
      setState(() => _submitError = msg);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          // ── Ambient background glow ──────────────────────────────────────
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Positioned(
              top: -60,
              left: -40,
              right: -40,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      AppColors.brandPurple.withValues(
                          alpha:
                              (isDark ? 0.07 : 0.04) + 0.03 * _glowCtrl.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Main form ───────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // ── Step indicator ─────────────────────────────────────────
                _StepIndicator(current: 1, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(
                        begin: -0.15,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 20),

                // ── Input mode toggle ──────────────────────────────────────
                _InputModeToggle(controller: _inputTabCtrl, isDark: isDark)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(
                        begin: 0.2,
                        end: 0,
                        delay: 100.ms,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 16),

                // ── Tab content ────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _inputTabCtrl,
                  builder: (_, __) {
                    final isText = _inputTabCtrl.index == 0;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(isText ? -0.06 : 0.06, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      child: isText
                          ? _JdTextInput(
                              controller: _jdCtrl,
                              isDark: isDark,
                              error: _jdError,
                            )
                          : _FileUploadZone(
                              picked: _pickedFile,
                              error: _fileError,
                              isDark: isDark,
                              onPick: _pickFile,
                              onRemove: () =>
                                  setState(() => _pickedFile = null),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Config card ────────────────────────────────────────────
                _ConfigCard(
                  isDark: isDark,
                  count: _count,
                  difficulty: _difficulty,
                  types: _types,
                  skills: _skills,
                  skillCtrl: _skillCtrl,
                  onCountChanged: (v) => setState(() => _count = v),
                  onDifficultyChanged: (v) => setState(() => _difficulty = v),
                  onTypeToggled: (t) => setState(() {
                    if (_types.contains(t)) {
                      if (_types.length > 1) _types.remove(t);
                    } else {
                      _types.add(t);
                    }
                  }),
                  onAddSkill: _addSkill,
                  onRemoveSkill: _removeSkill,
                  noteCtrl: _noteCtrl,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                    begin: 0.15,
                    end: 0,
                    delay: 200.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic),
                const SizedBox(height: 24),

                // ── Error ──────────────────────────────────────────────────
                if (_submitError != null) ...[
                  _ErrorBanner(message: _submitError!)
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                ],

                // ── Submit button with pulsing glow ────────────────────────
                AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSubmitting
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.brandPurple.withValues(
                                    alpha: 0.28 + 0.22 * _glowCtrl.value),
                                blurRadius: 18 + 14 * _glowCtrl.value,
                                spreadRadius: -4,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: AppColors.deepBlue.withValues(
                                    alpha: 0.10 + 0.08 * _glowCtrl.value),
                                blurRadius: 32,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: child!,
                  ),
                  child: AppGradientButton(
                    label: _isSubmitting ? 'Đang xử lý...' : 'Tạo câu hỏi AI',
                    isLoading: _isSubmitting,
                    onTap: _isSubmitting ? null : _submit,
                    height: 56,
                    icon: _isSubmitting
                        ? null
                        : const Icon(PhosphorIconsBold.sparkle,
                            size: 18, color: Colors.white),
                  ),
                ).animate().fadeIn(delay: 320.ms, duration: 400.ms).slideY(
                    begin: 0.25,
                    end: 0,
                    delay: 320.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack),
              ],
            ),
          ),
        ],
      ),
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
                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(PhosphorIconsBold.sparkle,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('AI Question Generator',
              style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack,
              )),
        ]),
      );
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatefulWidget {
  final int  current;
  final bool isDark;
  const _StepIndicator({required this.current, required this.isDark});

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Ring 1: expands and fades in first half
    _ring1 = CurvedAnimation(
      parent: _ringCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    // Ring 2: slightly delayed, expands further
    _ring2 = CurvedAnimation(
      parent: _ringCtrl,
      curve: const Interval(0.25, 0.90, curve: Curves.easeOut),
    );
    // Dot pulse: gentle scale breathe
    _pulse = CurvedAnimation(
      parent: _ringCtrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps  = ['Nhập JD', 'Xem Plan', 'Câu hỏi'];
    final isDark = widget.isDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: steps.asMap().entries.expand((e) {
        final i      = e.key + 1;
        final label  = e.value;
        final done   = i < widget.current;
        final active = i == widget.current;

        // ── dot column ────────────────────────────────────────
        final dot = Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ── ripple ring 1 (wide, fades fast) ────────
                if (active)
                  AnimatedBuilder(
                    animation: _ring1,
                    builder: (_, __) => OverflowBox(
                      maxWidth: 80, maxHeight: 80,
                      child: Container(
                        width:  28 + 28 * _ring1.value,
                        height: 28 + 28 * _ring1.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandPurple.withValues(
                                alpha: 0.55 * (1 - _ring1.value)),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                // ── ripple ring 2 (tighter, filled glow) ────
                if (active)
                  AnimatedBuilder(
                    animation: _ring2,
                    builder: (_, __) => OverflowBox(
                      maxWidth: 72, maxHeight: 72,
                      child: Container(
                        width:  28 + 18 * _ring2.value,
                        height: 28 + 18 * _ring2.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandPurple.withValues(
                              alpha: 0.16 * (1 - _ring2.value)),
                        ),
                      ),
                    ),
                  ),
                // ── glow background (static) ─────────────────
                if (active)
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brandPurple.withValues(alpha: 0.22),
                          AppColors.brandPurple.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                // ── actual dot (pulses scale slightly) ───────
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: active
                        ? 1.0 + 0.06 * (_pulse.value < 0.5
                            ? _pulse.value * 2
                            : (1 - _pulse.value) * 2)
                        : 1.0,
                    child: child,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width:  active ? 34 : 28,
                    height: active ? 34 : 28,
                    decoration: BoxDecoration(
                      gradient: (active || done) ? AppColors.primaryGradient : null,
                      color: (active || done)
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.gray200),
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.brandPurple.withValues(alpha: 0.55),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: AppColors.deepBlue.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : done
                              ? [BoxShadow(
                                  color: AppColors.brandPurple.withValues(alpha: 0.20),
                                  blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : Text('$i',
                              style: TextStyle(
                                fontSize: active ? 13 : 12,
                                fontWeight: FontWeight.w700,
                                color: (active || done)
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.35)
                                        : AppColors.gray400),
                              )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── label ─────────────────────────────────────────
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTextStyles.caption.copyWith(
              fontSize: active ? 10.5 : 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active
                  ? AppColors.brandPurple
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.30)
                      : AppColors.gray400),
            ),
            child: Text(label),
          ),
          // ── active underline dot ──────────────────────────
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width:  active ? 18 : 0,
            height: 2,
            decoration: BoxDecoration(
              gradient: active ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ]);

        if (e.key == steps.length - 1) return [dot];

        // ── connector line ────────────────────────────────────
        final line = Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              gradient: done ? AppColors.primaryGradient : null,
              color: done
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.gray200),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
        return [dot, line];
      }).toList(),
    );
  }
}

// ─── Input mode toggle ────────────────────────────────────────────────────────

class _InputModeToggle extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  const _InputModeToggle({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: [
          _tab(PhosphorIconsRegular.textT, 'Nhập text', controller.index == 0),
          _tab(PhosphorIconsRegular.uploadSimple, 'Upload file',
              controller.index == 1),
        ],
      ),
    );
  }

  Widget _tab(IconData icon, String label, bool active) => Tab(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 14,
              color: active
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.gray500)),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : AppColors.gray500),
              )),
        ]),
      );
}

// ─── JD text input ────────────────────────────────────────────────────────────

class _JdTextInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String? error;
  const _JdTextInput(
      {required this.controller, required this.isDark, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(PhosphorIconsRegular.fileText,
              size: 14, color: AppColors.brandPurple),
        ),
        const SizedBox(width: 8),
        Text('Mô tả công việc (JD)',
            style: AppTextStyles.label.copyWith(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.85)
                  : AppColors.nearBlack,
            )),
        const Spacer(),
        Text('* Bắt buộc',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.brandPurple.withValues(alpha: 0.70),
                fontSize: 10)),
      ]),
      const SizedBox(height: 10),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error != null
                ? AppColors.error.withValues(alpha: 0.60)
                : (isDark ? AppColors.darkCardBorder : AppColors.gray200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: 8,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack,
            fontSize: 13,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText:
                'Dán mô tả công việc tại đây...\n\nVí dụ: Backend Developer với 3+ năm kinh nghiệm Java/Spring Boot, có kinh nghiệm với microservices và cloud (AWS/GCP)...',
            hintStyle: AppTextStyles.body.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.gray400,
              fontSize: 13,
              height: 1.6,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Text(error!,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.error, fontSize: 11)),
      ],
    ]);
  }
}

// ─── File upload zone ─────────────────────────────────────────────────────────

class _FileUploadZone extends StatelessWidget {
  final PlatformFile? picked;
  final String? error;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _FileUploadZone({
    required this.picked,
    required this.error,
    required this.isDark,
    required this.onPick,
    required this.onRemove,
  });

  String get _sizeLabel {
    if (picked == null) return '';
    final kb = picked!.size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  IconData get _fileIcon {
    final ext = (picked?.extension ?? '').toLowerCase();
    if (ext == 'pdf') return PhosphorIconsFill.filePdf;
    return PhosphorIconsFill.fileDoc;
  }

  @override
  Widget build(BuildContext context) {
    if (picked != null) {
      // File selected state
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_fileIcon, size: 22, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(picked!.name,
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_sizeLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.gray400)),
              ])),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.error),
            ),
          ),
        ]),
      );
    }

    // Empty state — dashed upload zone
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : AppColors.violetWash.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? AppColors.error.withValues(alpha: 0.60)
                  : AppColors.brandPurple.withValues(alpha: 0.25),
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  AppColors.brandPurple.withValues(alpha: 0.14),
                  AppColors.brandPurple.withValues(alpha: 0.03),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.uploadSimple,
                  size: 24, color: AppColors.brandPurple),
            ),
            const SizedBox(height: 14),
            Text('Chọn hoặc kéo file JD',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.80)
                      : AppColors.nearBlack,
                )),
            const SizedBox(height: 4),
            Text('PDF, DOC, DOCX • Tối đa 10 MB',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          ]),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Text(error!,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.error, fontSize: 11)),
      ],
    ]);
  }
}

// ─── Config card ──────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final bool isDark;
  final int count;
  final String difficulty;
  final Set<String> types;
  final List<String> skills;
  final TextEditingController skillCtrl;
  final TextEditingController noteCtrl;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<String> onTypeToggled;
  final VoidCallback onAddSkill;
  final ValueChanged<String> onRemoveSkill;

  const _ConfigCard({
    required this.isDark,
    required this.count,
    required this.difficulty,
    required this.types,
    required this.skills,
    required this.skillCtrl,
    required this.noteCtrl,
    required this.onCountChanged,
    required this.onDifficultyChanged,
    required this.onTypeToggled,
    required this.onAddSkill,
    required this.onRemoveSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title
              Row(children: [
                const Icon(PhosphorIconsBold.slidersHorizontal,
                    size: 15, color: AppColors.brandPurple),
                const SizedBox(width: 8),
                Text('Cấu hình câu hỏi',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
              const SizedBox(height: 20),

              // Count slider
              _SectionLabel('Số lượng câu hỏi: $count', isDark),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  thumbColor: AppColors.brandPurple,
                  activeTrackColor: AppColors.brandPurple,
                  inactiveTrackColor:
                      AppColors.brandPurple.withValues(alpha: 0.14),
                  overlayColor: AppColors.brandPurple.withValues(alpha: 0.10),
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: count.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 27,
                  onChanged: (v) => onCountChanged(v.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.gray400, fontSize: 10)),
                  Text('30',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.gray400, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 20),

              // Type multi-select
              _SectionLabel('Loại câu hỏi', isDark),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _typeChip(
                        'technical', 'Technical', types, isDark, onTypeToggled)
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 300.ms)
                    .scale(
                        begin: const Offset(0.55, 0.55),
                        delay: 60.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                _typeChip('behavioral', 'Behavioral', types, isDark,
                        onTypeToggled)
                    .animate()
                    .fadeIn(delay: 110.ms, duration: 300.ms)
                    .scale(
                        begin: const Offset(0.55, 0.55),
                        delay: 110.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                _typeChip('problem-solving', 'Problem Solving', types, isDark,
                        onTypeToggled)
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 300.ms)
                    .scale(
                        begin: const Offset(0.55, 0.55),
                        delay: 160.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                _typeChip('situational', 'Situational', types, isDark,
                        onTypeToggled)
                    .animate()
                    .fadeIn(delay: 210.ms, duration: 300.ms)
                    .scale(
                        begin: const Offset(0.55, 0.55),
                        delay: 210.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                _typeChip('system-design', 'System Design', types, isDark,
                        onTypeToggled)
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 300.ms)
                    .scale(
                        begin: const Offset(0.55, 0.55),
                        delay: 260.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut),
              ]),
              const SizedBox(height: 20),

              // Difficulty
              _SectionLabel('Mức độ khó', isDark),
              const SizedBox(height: 10),
              Row(children: [
                _diffBtn('easy', 'Dễ', AppColors.success, difficulty,
                    onDifficultyChanged),
                const SizedBox(width: 8),
                _diffBtn('medium', 'Trung bình', AppColors.amber, difficulty,
                    onDifficultyChanged),
                const SizedBox(width: 8),
                _diffBtn('hard', 'Khó', AppColors.error, difficulty,
                    onDifficultyChanged),
              ]),
              const SizedBox(height: 20),

              // Focus skills
              _SectionLabel('Kỹ năng trọng tâm (tuỳ chọn)', isDark),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: skillCtrl,
                    onSubmitted: (_) => onAddSkill(),
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập kỹ năng rồi nhấn + hoặc Enter',
                      hintStyle: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.30)
                            : AppColors.gray400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.gray200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.gray200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.brandPurple),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAddSkill,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ]),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills
                      .map((s) => _SkillTag(
                            label: s,
                            isDark: isDark,
                            onRemove: () => onRemoveSkill(s),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Additional notes
              _SectionLabel('Ghi chú thêm (tuỳ chọn)', isDark),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack,
                  fontSize: 13,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Ví dụ: Ưu tiên kinh nghiệm với Docker, focus vào system design...',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : AppColors.gray400,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.offWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.darkCardBorder : AppColors.gray200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.darkCardBorder : AppColors.gray200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.brandPurple),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _typeChip(String val, String label, Set<String> active, bool isDark,
      ValueChanged<String> onToggle) {
    final isActive = active.contains(val);
    return _PressableChip(
      onTap: () => onToggle(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.gray100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.gray200),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
              color: isActive
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.50)
                      : AppColors.gray500),
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  Widget _diffBtn(String val, String label, Color color, String current,
      ValueChanged<String> onChanged) {
    final isActive = current == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.14)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.gray100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.50)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.gray200),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? color
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.40)
                        : AppColors.gray400),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ),
      ),
    );
  }
}

// ─── Small sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel(this.label, this.isDark);

  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.caption.copyWith(
        color:
            isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.gray500,
        fontWeight: FontWeight.w600,
      ));
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onRemove;
  const _SkillTag(
      {required this.label, required this.isDark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.brandPurple.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.brandPurple,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            )),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded,
              size: 13, color: AppColors.brandPurple.withValues(alpha: 0.65)),
        ),
      ]),
    );
  }
}

class _PressableChip extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableChip({required this.child, required this.onTap});

  @override
  State<_PressableChip> createState() => _PressableChipState();
}

class _PressableChipState extends State<_PressableChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.87 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            size: 15, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error)),
        ),
      ]),
    );
  }
}
