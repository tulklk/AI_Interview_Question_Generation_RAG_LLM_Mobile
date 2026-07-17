import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _ctrlList =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _submitting = false;
  String? _submitError;
  bool _success = false;

  int _cooldown = 60;
  bool _resendLoading = false;
  Timer? _cooldownTimer;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();
    _setupKeyHandlers();
    for (final node in _nodes) {
      node.addListener(() { if (mounted) setState(() {}); });
    }
    _startCooldown();
  }

  void _setupKeyHandlers() {
    for (int i = 0; i < 6; i++) {
      final idx = i;
      _nodes[idx].onKeyEvent = (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _ctrlList[idx].text.isEmpty &&
            idx > 0) {
          _ctrlList[idx - 1].clear();
          _nodes[idx - 1].requestFocus();
          setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (final c in _ctrlList) { c.dispose(); }
    for (final f in _nodes) { f.dispose(); }
    _cooldownTimer?.cancel();
    _autoNavTimer?.cancel();
    super.dispose();
  }

  String get _otp => _ctrlList.map((c) => c.text).join();
  bool get _complete => _ctrlList.every((c) => c.text.isNotEmpty);

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { if (--_cooldown <= 0) t.cancel(); });
    });
  }

  void _clearBoxes() {
    for (final c in _ctrlList) { c.clear(); }
    setState(() => _submitError = null);
    _nodes[0].requestFocus();
  }

  void _onDigitInput(int i, String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _ctrlList[i].clear();
      setState(() {});
      return;
    }

    // Full OTP paste
    if (digits.length >= 6) {
      for (int j = 0; j < 6; j++) {
        _ctrlList[j].text = digits[j];
      }
      _nodes[5].requestFocus();
      setState(() => _submitError = null);
      return;
    }

    // Single digit — keep only the last char typed
    final char = digits[digits.length - 1];
    _ctrlList[i].text = char;
    _ctrlList[i].selection = const TextSelection.collapsed(offset: 1);
    if (i < 5) _nodes[i + 1].requestFocus();
    setState(() => _submitError = null);
  }

  Future<void> _submit() async {
    if (!_complete || _submitting) return;
    setState(() { _submitting = true; _submitError = null; });
    try {
      await AuthService.verifyEmail(email: widget.email, otp: _otp);
      if (!mounted) return;
      setState(() { _submitting = false; _success = true; });
      _autoNavTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) context.go('/login');
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthException
          ? e.message
          : 'Mã xác minh không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.';
      setState(() { _submitting = false; _submitError = msg; });
      _clearBoxes();
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resendLoading) return;
    setState(() => _resendLoading = true);
    try {
      await AuthService.resendVerification(widget.email);
      if (!mounted) return;
      setState(() => _resendLoading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Mã xác minh mới đã được gửi đến email của bạn.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _resendLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Gửi lại mã xác minh thất bại. Vui lòng thử lại.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/login');
      },
      child: AuthBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: _success
                  ? _SuccessContent(
                      key: const ValueKey('success'),
                      onNavigate: () => context.go('/login'),
                    )
                  : _OtpContent(
                      key: const ValueKey('otp'),
                      email: widget.email,
                      ctrlList: _ctrlList,
                      nodes: _nodes,
                      submitting: _submitting,
                      submitError: _submitError,
                      complete: _complete,
                      cooldown: _cooldown,
                      resendLoading: _resendLoading,
                      onDigitInput: _onDigitInput,
                      onSubmit: _submit,
                      onResend: _resend,
                      isDark: isDark,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── OTP content ───────────────────────────────────────────────────────────────

class _OtpContent extends StatelessWidget {
  final String email;
  final List<TextEditingController> ctrlList;
  final List<FocusNode> nodes;
  final bool submitting;
  final String? submitError;
  final bool complete;
  final int cooldown;
  final bool resendLoading;
  final void Function(int, String) onDigitInput;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final bool isDark;

  const _OtpContent({
    super.key,
    required this.email,
    required this.ctrlList,
    required this.nodes,
    required this.submitting,
    required this.submitError,
    required this.complete,
    required this.cooldown,
    required this.resendLoading,
    required this.onDigitInput,
    required this.onSubmit,
    required this.onResend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Pulsing envelope icon
      _PulsingMailIcon()
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
      const SizedBox(height: 36),

      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              'Xác minh email của bạn',
              style: AppTextStyles.h1.copyWith(
                color: isDark ? Colors.white : AppColors.nearBlack,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Nhập mã 6 số đã được gửi đến',
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 130.ms),
            const SizedBox(height: 8),

            // Email chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.brandPurple.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(PhosphorIconsBold.envelopeSimple,
                    size: 13, color: AppColors.brandPurple),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    email,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ).animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 28),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => _OtpBox(
                  controller: ctrlList[i],
                  focusNode: nodes[i],
                  hasError: submitError != null,
                  disabled: submitting,
                  onChanged: (v) => onDigitInput(i, v),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 14),

            // Inline error (animated in/out)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(sizeFactor: anim, child: child),
              ),
              child: submitError != null
                  ? Padding(
                      key: ValueKey(submitError),
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _InlineError(message: submitError!),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-error')),
            ),

            // Submit button
            ShimmerButton(
              label: _submitting
                  ? 'Đang xác minh...'
                  : 'Xác minh',
              isLoading: submitting,
              onTap: complete && !submitting ? onSubmit : null,
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 14),

            // Resend row
            _ResendRow(
              cooldown: cooldown,
              loading: resendLoading,
              onTap: onResend,
            ).animate().fadeIn(delay: 290.ms),
            const SizedBox(height: 20),

            // Back to login
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                '← Quay lại đăng nhập',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ).animate().fadeIn(delay: 330.ms),
          ],
        ),
      )
          .animate(delay: 200.ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.08, end: 0, duration: 600.ms),
    ]);
  }

  bool get _submitting => submitting;
}

// ── Success content ───────────────────────────────────────────────────────────

class _SuccessContent extends StatelessWidget {
  final VoidCallback onNavigate;
  const _SuccessContent({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      // Animated checkmark
      _SuccessIcon()
          .animate()
          .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1.0, 1.0),
            duration: 700.ms,
            curve: Curves.elasticOut,
          ),
      const SizedBox(height: 36),

      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Email đã được xác minh!',
              style: AppTextStyles.h1.copyWith(
                color: isDark ? Colors.white : AppColors.nearBlack,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 10),

            Text(
              'Tài khoản của bạn đã được kích hoạt.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),

            Text(
              'Tự động chuyển hướng sau 3 giây...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 28),

            ShimmerButton(
              label: 'Đến trang đăng nhập',
              onTap: onNavigate,
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      )
          .animate(delay: 100.ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.08, end: 0, duration: 600.ms),
    ]);
  }
}

// ── OTP box ───────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool disabled;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isFocused = focusNode.hasFocus;
    final isFilled = controller.text.isNotEmpty;

    final Color borderColor;
    final double borderWidth;
    if (hasError) {
      borderColor = AppColors.error;
      borderWidth = 2.0;
    } else if (isFocused) {
      borderColor = primary;
      borderWidth = 2.0;
    } else if (isFilled) {
      borderColor = primary.withValues(alpha: 0.55);
      borderWidth = 1.5;
    } else {
      borderColor = isDark ? AppColors.darkCardBorder : AppColors.formBorder;
      borderWidth = 1.0;
    }

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 52,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !disabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.nearBlack,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasError
              ? AppColors.error.withValues(alpha: 0.06)
              : isFilled
                  ? primary.withValues(alpha: 0.07)
                  : (isDark ? AppColors.darkCard : AppColors.white),
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: (isDark ? AppColors.darkCardBorder : AppColors.formBorder)
                  .withValues(alpha: 0.45),
            ),
          ),
          counterText: '',
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Inline error banner ───────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(PhosphorIconsBold.warningCircle,
              size: 15, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ]),
      );
}

// ── Resend row ────────────────────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  final int cooldown;
  final bool loading;
  final VoidCallback onTap;

  const _ResendRow({
    required this.cooldown,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = cooldown <= 0 && !loading;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (loading) ...[
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.brandPurple),
        ),
        const SizedBox(width: 8),
      ],
      TextButton(
        onPressed: canResend ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPurple,
          disabledForegroundColor: AppColors.gray400,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          cooldown > 0 ? 'Gửi lại sau ${cooldown}s' : 'Gửi lại mã',
          style: AppTextStyles.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: canResend ? AppColors.brandPurple : AppColors.gray400,
          ),
        ),
      ),
    ]);
  }
}

// ── Pulsing envelope icon ─────────────────────────────────────────────────────

class _PulsingMailIcon extends StatefulWidget {
  @override
  State<_PulsingMailIcon> createState() => _PulsingMailIconState();
}

class _PulsingMailIconState extends State<_PulsingMailIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final glow = 0.25 + _ctrl.value * 0.20;
          return Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.brandPurple.withValues(alpha: glow),
                AppColors.brandPurple.withValues(alpha: 0.02),
              ]),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(
                          alpha: 0.35 + _ctrl.value * 0.15),
                      blurRadius: 20 + _ctrl.value * 10,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsBold.envelopeOpen,
                    size: 34, color: Colors.white),
              ),
            ),
          );
        },
      );
}

// ── Success checkmark icon ────────────────────────────────────────────────────

class _SuccessIcon extends StatefulWidget {
  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final glow = 0.25 + _ctrl.value * 0.20;
          return Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.success.withValues(alpha: glow),
                AppColors.success.withValues(alpha: 0.02),
              ]),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(
                          alpha: 0.35 + _ctrl.value * 0.15),
                      blurRadius: 20 + _ctrl.value * 10,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsBold.checkCircle,
                    size: 34, color: Colors.white),
              ),
            ),
          );
        },
      );
}
