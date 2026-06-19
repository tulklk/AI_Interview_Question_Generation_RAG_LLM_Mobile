import 'dart:async';
import 'package:flutter/material.dart';
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
  int _countdown = 60;
  bool _isSending = false;
  String? _msg;
  bool _msgSuccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _isSending) return;
    setState(() { _isSending = true; _msg = null; });
    try {
      await AuthService.resendVerification(widget.email);
      if (!mounted) return;
      setState(() {
        _isSending   = false;
        _msgSuccess  = true;
        _msg         = 'Email xác minh đã được gửi lại.';
      });
      _startCountdown();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _msg = null);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending  = false;
        _msgSuccess = false;
        _msg        = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending  = false;
        _msgSuccess = false;
        _msg        = 'Không thể gửi lại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          child: Column(children: [
            // ── Envelope icon ────────────────────────────────────────
            _PulsingEnvelope()
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 36),

            // ── Card ─────────────────────────────────────────────────
            GlassCard(
              child: Column(children: [
                Text(
                  'Xác minh email của bạn',
                  style: AppTextStyles.h1.copyWith(
                      color: isDark ? Colors.white : AppColors.nearBlack,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),

                // Email display
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppColors.brandPurple.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsBold.envelopeSimple,
                          size: 15, color: AppColors.brandPurple),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.email,
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.brandPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),

                Text(
                  'Chúng tôi đã gửi một đường dẫn xác minh đến địa chỉ email trên. '
                  'Vui lòng kiểm tra hộp thư đến (và thư mục Spam) rồi nhấp vào đường dẫn để kích hoạt tài khoản.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.gray500, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),

                // Message banner
                if (_msg != null) ...[
                  _MsgBanner(message: _msg!, success: _msgSuccess)
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 14),
                ],

                // Resend button
                ShimmerButton(
                  label: _countdown > 0
                      ? 'Gửi lại email (${_countdown}s)'
                      : 'Gửi lại email xác minh',
                  isLoading: _isSending,
                  onTap: (_countdown > 0 || _isSending) ? null : _resend,
                  trailingIcon: PhosphorIconsBold.arrowClockwise,
                ).animate().fadeIn(delay: 260.ms),
                const SizedBox(height: 16),

                // Tips
                _TipCard(isDark: isDark)
                    .animate()
                    .fadeIn(delay: 320.ms),
                const SizedBox(height: 20),

                // Back to login
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Quay lại đăng nhập',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ).animate().fadeIn(delay: 360.ms),
              ]),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.08, end: 0, duration: 600.ms),
          ]),
        ),
      ),
    );
  }
}

// ── Animated pulsing envelope ─────────────────────────────────────────────────

class _PulsingEnvelope extends StatefulWidget {
  @override
  State<_PulsingEnvelope> createState() => _PulsingEnvelopeState();
}

class _PulsingEnvelopeState extends State<_PulsingEnvelope>
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
              gradient: RadialGradient(
                colors: [
                  AppColors.brandPurple.withValues(alpha: glow),
                  AppColors.brandPurple.withValues(alpha: 0.02),
                ],
              ),
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
                      color: AppColors.brandPurple
                          .withValues(alpha: 0.35 + _ctrl.value * 0.15),
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

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final bool isDark;
  const _TipCard({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.gray100.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppColors.gray200.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(PhosphorIconsBold.lightbulb,
                  size: 14, color: AppColors.amber),
              const SizedBox(width: 6),
              Text('Không nhận được email?',
                  style: AppTextStyles.label.copyWith(
                      color: isDark ? Colors.white : AppColors.nearBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            _TipRow('Kiểm tra thư mục Spam / Junk', isDark),
            _TipRow('Đảm bảo địa chỉ email đã nhập đúng', isDark),
            _TipRow('Chờ vài phút trước khi gửi lại', isDark),
          ],
        ),
      );
}

class _TipRow extends StatelessWidget {
  final String text;
  final bool isDark;
  const _TipRow(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray400.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500, fontSize: 11, height: 1.4)),
          ),
        ]),
      );
}

// ── Message banner ─────────────────────────────────────────────────────────────

class _MsgBanner extends StatelessWidget {
  final String message;
  final bool success;
  const _MsgBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    final icon  = success
        ? PhosphorIconsBold.checkCircle
        : PhosphorIconsBold.warningCircle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
