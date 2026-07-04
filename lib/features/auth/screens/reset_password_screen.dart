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
import '../widgets/auth_widgets.dart' hide AuthBackground;

class ResetPasswordScreen extends StatefulWidget {
  /// Token delivered via deep-link query param: /reset-password?token=xxx
  /// May be empty when the user lands on the screen without a link.
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenCtrl    = TextEditingController();
  final _newPwCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _showNew     = false;
  bool _showConfirm = false;
  bool _isLoading   = false;
  String? _tokenError;
  String? _newPwError;
  String? _confirmError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    // Pre-fill token if provided via deep link
    if (widget.token.isNotEmpty) {
      _tokenCtrl.text = widget.token;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _tokenError   = null;
      _newPwError   = null;
      _confirmError = null;
      _generalError = null;

      if (_tokenCtrl.text.trim().isEmpty) {
        _tokenError = 'Vui lòng nhập mã đặt lại';
        ok = false;
      }
      if (_newPwCtrl.text.isEmpty) {
        _newPwError = 'Vui lòng nhập mật khẩu mới';
        ok = false;
      } else if (_newPwCtrl.text.length < 8) {
        _newPwError = 'Tối thiểu 8 ký tự';
        ok = false;
      }
      if (_confirmCtrl.text != _newPwCtrl.text) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() { _isLoading = true; _generalError = null; });
    try {
      await AuthService.resetPassword(
        token:       _tokenCtrl.text.trim(),
        newPassword: _newPwCtrl.text,
      );
      if (!mounted) return;
      // Navigate to login with a success query param
      context.go('/login?reset=success');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // If the token was supplied by deep link, hide the manual token field
    final tokenFromLink = widget.token.isNotEmpty;

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            children: [
              // ── Back button ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
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

              // ── Icon ─────────────────────────────────────────────────
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
                child: const Icon(PhosphorIconsBold.shieldCheck,
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

              // ── Card ─────────────────────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đặt lại mật khẩu',
                      style: AppTextStyles.h1.copyWith(
                          color: isDark ? Colors.white : AppColors.nearBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tokenFromLink
                          ? 'Nhập mật khẩu mới của bạn bên dưới.'
                          : 'Nhập mã xác nhận từ email và mật khẩu mới của bạn.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.gray500, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // General error banner
                    if (_generalError != null) ...[
                      AuthErrorBanner(
                        message: _generalError!,
                        isDark: isDark,
                      ).animate().fadeIn(duration: 250.ms).slideY(
                            begin: -0.2,
                            end: 0,
                          ),
                      const SizedBox(height: 16),
                    ],

                    // Token field — only shown when NOT pre-filled from deep link
                    if (!tokenFromLink) ...[
                      AuthInputField(
                        controller: _tokenCtrl,
                        label: 'Mã xác nhận',
                        hint: 'Dán mã từ email vào đây',
                        icon: PhosphorIconsBold.key,
                        error: _tokenError,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // New password
                    AuthInputField(
                      controller: _newPwCtrl,
                      label: 'Mật khẩu mới *',
                      hint: '••••••••',
                      icon: PhosphorIconsBold.lockKey,
                      obscureText: !_showNew,
                      trailing: _EyeButton(
                        show: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                      ),
                      error: _newPwError,
                    ),
                    const SizedBox(height: 14),

                    // Confirm password
                    AuthInputField(
                      controller: _confirmCtrl,
                      label: 'Xác nhận mật khẩu mới *',
                      hint: '••••••••',
                      icon: PhosphorIconsBold.lockKeyOpen,
                      obscureText: !_showConfirm,
                      trailing: _EyeButton(
                        show: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      error: _confirmError,
                    ),
                    const SizedBox(height: 6),

                    // Password hint
                    Text(
                      'Mật khẩu phải có ít nhất 8 ký tự',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray400, fontSize: 11),
                    ),
                    const SizedBox(height: 20),

                    ShimmerButton(
                      label: 'Đặt lại mật khẩu',
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _submit,
                      trailingIcon: PhosphorIconsBold.checkCircle,
                    ),
                    const SizedBox(height: 16),
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
                    ),
                  ],
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EyeButton extends StatelessWidget {
  final bool show;
  final VoidCallback onToggle;
  const _EyeButton({required this.show, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            show ? PhosphorIconsBold.eyeSlash : PhosphorIconsBold.eye,
            size: 18,
            color: AppColors.gray400,
          ),
        ),
      );
}
