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
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _isLoading = false;
  bool _submitted = false;
  // Resend cooldown
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = 'Địa chỉ email không hợp lệ';
      } else {
        _emailError = null;
      }
    });
    return _emailError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(_emailCtrl.text.trim());
    } on AuthException catch (e) {
      // Only network errors surface as a real error; all others show neutral UI
      if (e.type == AuthErrorType.networkError && mounted) {
        setState(() { _isLoading = false; _emailError = e.message; });
        return;
      }
    } catch (_) {
      // Swallow — show neutral success regardless
    }
    if (!mounted) return;
    setState(() { _isLoading = false; _submitted = true; });
    _startResendCooldown();
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(_emailCtrl.text.trim());
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isLoading = false);
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            children: [
              // ── Back button ────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/login'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      PhosphorIconsBold.arrowLeft,
                      size: 18,
                      color: isDark ? Colors.white : AppColors.nearBlack,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),

              // ── Icon ───────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsBold.lockKey,
                    size: 30, color: Colors.white),
              )
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 28),

              // ── Card ───────────────────────────────────────────────────
              GlassCard(
                child: _submitted
                    ? _SentContent(
                        email: _emailCtrl.text.trim(),
                        isDark: isDark,
                        isLoading: _isLoading,
                        resendCountdown: _resendCountdown,
                        onResend: _resend,
                      )
                    : _FormContent(
                        emailCtrl: _emailCtrl,
                        emailError: _emailError,
                        isDark: isDark,
                        isLoading: _isLoading,
                        onSubmit: _submit,
                      ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.08, end: 0, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input form ────────────────────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  final TextEditingController emailCtrl;
  final String? emailError;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _FormContent({
    required this.emailCtrl,
    required this.emailError,
    required this.isDark,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quên mật khẩu?',
            style: AppTextStyles.h1.copyWith(
                color: isDark ? Colors.white : AppColors.nearBlack,
                fontSize: 24,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập email của bạn và chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
            style: AppTextStyles.body
                .copyWith(color: AppColors.gray500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          AuthInputField(
            controller: emailCtrl,
            label: 'Email',
            hint: 'you@company.com',
            icon: PhosphorIconsBold.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            error: emailError,
          ),
          const SizedBox(height: 20),
          ShimmerButton(
            label: 'Gửi hướng dẫn đặt lại',
            isLoading: isLoading,
            onTap: isLoading ? null : onSubmit,
            trailingIcon: PhosphorIconsBold.paperPlaneRight,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/login'),
              child: Text(
                'Quay lại đăng nhập',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
}

// ── Sent / success state ──────────────────────────────────────────────────────

class _SentContent extends StatelessWidget {
  final String email;
  final bool isDark;
  final bool isLoading;
  final int resendCountdown;
  final VoidCallback onResend;

  const _SentContent({
    required this.email,
    required this.isDark,
    required this.isLoading,
    required this.resendCountdown,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.30)),
            ),
            child: const Icon(PhosphorIconsBold.envelopeOpen,
                size: 30, color: AppColors.success),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Text(
            'Kiểm tra hộp thư!',
            style: AppTextStyles.h3.copyWith(
                color: isDark ? Colors.white : AppColors.nearBlack,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // Neutral message — does not confirm account existence
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.body
                  .copyWith(color: AppColors.gray500, fontSize: 13),
              children: [
                const TextSpan(
                    text:
                        'Nếu địa chỉ '),
                TextSpan(
                    text: email,
                    style: const TextStyle(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w600)),
                const TextSpan(
                    text:
                        ' tồn tại trong hệ thống, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu.'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Không thấy email? Kiểm tra mục Thư rác hoặc gửi lại.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.gray400, fontSize: 12),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 24),

          // Resend button
          ShimmerButton(
            label: resendCountdown > 0
                ? 'Gửi lại (${resendCountdown}s)'
                : 'Gửi lại email',
            isLoading: isLoading,
            onTap: (resendCountdown > 0 || isLoading) ? null : onResend,
            trailingIcon: PhosphorIconsBold.arrowClockwise,
          ).animate().fadeIn(delay: 240.ms),
          const SizedBox(height: 12),

          // Back to login
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                'Quay lại đăng nhập',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ).animate().fadeIn(delay: 280.ms),
        ],
      );
}
