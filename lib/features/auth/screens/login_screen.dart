import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/auth_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_background.dart';
import 'google_profile_sheet.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_widgets.dart' hide AuthBackground;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure       = true;
  bool _rememberMe    = false;
  bool _googleLoading = false;
  String? _emailError;
  String? _passError;
  int _focusCount  = 0;

  @override
  void initState() {
    super.initState();
    // Clear API error whenever the user edits a field
    _emailCtrl.addListener(_clearProviderError);
    _passCtrl.addListener(_clearProviderError);
  }

  void _clearProviderError() {
    if (ref.read(authProvider).error != null) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _onFieldFocus(bool focused) =>
      setState(() => _focusCount = (_focusCount + (focused ? 1 : -1)).clamp(0, 10));

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    final email = _emailCtrl.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Email không hợp lệ';
      } else {
        _emailError = null;
      }
      _passError = _passCtrl.text.isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    });
    return _emailError == null && _passError == null;
  }

  // ── Login with email/password ───────────────────────────────────────────────

  Future<void> _login() async {
    if (!_validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    // GoRouter redirect handles navigation after user is set
  }

  // ── Login with Google ──────────────────────────────────────────────────────

  Future<void> _loginWithGoogle() async {
    try {
      final account = await GoogleSignIn(
        serverClientId:
            '593842710212-vg9t701m2prpeh0g4sq5maspreuvjmm7.apps.googleusercontent.com',
      ).signIn();
      if (account == null) return;

      final auth    = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        ref.read(authProvider.notifier).setError(
          'Không thể lấy thông tin từ Google. Vui lòng thử lại.',
          AuthErrorType.serverError,
        );
        return;
      }

      // Step 1: verify — check if account already exists
      setState(() => _googleLoading = true);
      final verify = await AuthService.verifyGoogleToken(idToken);

      if (!mounted) return;

      if (verify.isExistingUser) {
        // Existing account → login directly
        await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      } else {
        // New account → show profile completion sheet
        setState(() => _googleLoading = false);
        final profile = await showGoogleProfileSheet(
          context,
          email: verify.email ?? account.email,
          name:  verify.name  ?? account.displayName ?? '',
        );
        if (!mounted) return;
        if (profile == null) return; // user dismissed sheet
        await ref.read(authProvider.notifier).loginWithGoogle(
          idToken,
          profile: profile,
        );
      }
    } catch (_) {
      if (mounted) {
        ref.read(authProvider.notifier).setError(
          'Đăng nhập Google thất bại. Vui lòng thử lại.',
          AuthErrorType.serverError,
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final authState    = ref.watch(authProvider);
    final isLoading    = authState.isLoading;
    final queryParams  = GoRouterState.of(context).uri.queryParameters;
    final passwordReset = queryParams['reset'] == 'success';

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            children: [
              // Logo
              AuthLogo(isDark: isDark)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 28),

              // Glass card
              GlassCard(
                hasFocus: _focusCount > 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    AnimatedHeading(
                      text: 'Chào mừng trở lại',
                      style: AppTextStyles.h1.copyWith(
                          color: isDark ? Colors.white : AppColors.nearBlack,
                          fontSize: 26, fontWeight: FontWeight.w800),
                      initialDelay: 300.ms,
                    ),
                    const SizedBox(height: 4),
                    Text('Đăng nhập để tiếp tục sử dụng HireGen AI',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.gray500, fontSize: 14))
                        .animate()
                        .fadeIn(delay: 550.ms, duration: 400.ms),
                    const SizedBox(height: 20),

                    // Password-reset success banner
                    if (passwordReset) ...[
                      _SuccessBanner(isDark: isDark)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.2, end: 0),
                      const SizedBox(height: 14),
                    ],

                    // API error banner
                    if (authState.error != null)
                      _ErrorBanner(
                        message: authState.error!,
                        type: authState.errorType,
                        isDark: isDark,
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.2, end: 0),

                    // Email
                    AuthInputField(
                      controller: _emailCtrl,
                      label: 'Địa chỉ email',
                      hint: 'ban@congty.com',
                      icon: PhosphorIconsBold.envelopeSimple,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailError,
                      onFocusChanged: _onFieldFocus,
                    ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 16),

                    // Password row header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mật khẩu',
                            style: AppTextStyles.label.copyWith(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.nearBlack,
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: Text('Quên mật khẩu?',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.brandPurple,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 6),
                    _PasswordField(
                      controller: _passCtrl,
                      obscure: _obscure,
                      error: _passError,
                      onToggle: () => setState(() => _obscure = !_obscure),
                      onFocusChanged: _onFieldFocus,
                    ).animate().fadeIn(delay: 720.ms).slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 14),

                    // Remember me
                    _RememberMe(
                      value: _rememberMe,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _rememberMe = v),
                    ).animate().fadeIn(delay: 780.ms),
                    const SizedBox(height: 20),

                    // Sign in button
                    ShimmerButton(
                      label: 'Đăng nhập',
                      isLoading: isLoading,
                      onTap: isLoading ? null : _login,
                      trailingIcon: PhosphorIconsBold.arrowRight,
                    ).animate().fadeIn(delay: 820.ms).slideY(begin: 0.10, end: 0),
                    const SizedBox(height: 20),

                    // Divider
                    _OrDivider(isDark: isDark, text: 'hoặc tiếp tục với')
                        .animate().fadeIn(delay: 860.ms),
                    const SizedBox(height: 14),

                    // Social
                    _SocialRow(
                      isDark: isDark,
                      onGoogle: (isLoading || _googleLoading) ? null : _loginWithGoogle,
                      googleLoading: _googleLoading,
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.10, end: 0),
                    const SizedBox(height: 20),

                    // Sign up link
                    Center(
                      child: Wrap(alignment: WrapAlignment.center, children: [
                        Text('Chưa có tài khoản? ',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray500, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text('Đăng ký miễn phí',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.brandPurple,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 940.ms),
                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                          'Bằng cách tiếp tục, bạn đồng ý với Điều khoản & Chính sách bảo mật',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray400, fontSize: 11),
                          textAlign: TextAlign.center),
                    ).animate().fadeIn(delay: 960.ms),
                  ],
                ),
              ).animate(delay: 200.ms)
                  .fadeIn(duration: 700.ms, curve: AuthAnimations.easeOutCubic)
                  .slideY(begin: 0.08, end: 0, duration: 700.ms,
                      curve: AuthAnimations.easeOutCubic)
                  .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1),
                      duration: 700.ms, curve: AuthAnimations.easeOutCubic),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final AuthErrorType? type;
  final bool isDark;

  const _ErrorBanner({required this.message, this.type, required this.isDark});

  IconData get _icon {
    switch (type) {
      case AuthErrorType.notVerified:
        return PhosphorIconsBold.envelopeSimple;
      case AuthErrorType.accountLocked:
        return PhosphorIconsBold.lockSimple;
      case AuthErrorType.networkError:
        return PhosphorIconsBold.wifiSlash;
      default:
        return PhosphorIconsBold.warningCircle;
    }
  }

  Color get _color {
    if (type == AuthErrorType.notVerified) return AppColors.amber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _color.withValues(alpha: 0.30)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_icon, size: 16, color: _color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.caption.copyWith(
                  color: _color, fontWeight: FontWeight.w500, height: 1.4)),
        ),
      ],
    ),
  );
}

// ─── Success banner (post password-reset) ─────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  final bool isDark;
  const _SuccessBanner({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
        ),
        child: Row(children: [
          const Icon(PhosphorIconsBold.checkCircle,
              size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập.',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
          ),
        ]),
      );
}

// ─── Password field wrapper ───────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final String? error;
  final VoidCallback onToggle;
  final ValueChanged<bool>? onFocusChanged;

  const _PasswordField({
    required this.controller, required this.obscure,
    required this.onToggle, this.error, this.onFocusChanged,
  });

  @override
  Widget build(BuildContext context) => AuthInputField(
        controller: controller,
        label: '',
        hint: '••••••••',
        icon: PhosphorIconsBold.lock,
        obscureText: obscure,
        error: error,
        onFocusChanged: onFocusChanged,
        trailing: GestureDetector(
          onTap: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              obscure ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
              key: ValueKey(obscure),
              size: 18, color: AppColors.gray400),
          ),
        ),
      );
}

// ─── Remember me ─────────────────────────────────────────────────────────────

class _RememberMe extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _RememberMe(
      {required this.value, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: value ? AppColors.brandPurple : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: value ? AppColors.brandPurple : AppColors.gray400,
                  width: 1.5),
              boxShadow: value
                  ? [BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.30),
                      blurRadius: 6)]
                  : null,
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text('Ghi nhớ đăng nhập 30 ngày',
              style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.gray500)),
        ]),
      );
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  final bool isDark;
  final String text;
  const _OrDivider({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray400, fontSize: 12))),
        Expanded(child: Divider(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
      ]);
}

// ─── Social row ───────────────────────────────────────────────────────────────

class _SocialRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onGoogle;
  final bool googleLoading;
  const _SocialRow({required this.isDark, this.onGoogle, this.googleLoading = false});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _SocialBtn(
            label: 'Google',
            icon: googleLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.brandPurple),
                  )
                : const GoogleLogoIcon(),
            isDark: isDark,
            onTap: onGoogle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialBtn(
            label: 'Microsoft',
            icon: Icon(PhosphorIconsBold.microsoftOutlookLogo,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF0078D4)),
            isDark: isDark,
            onTap: null, // Coming soon — no Microsoft OAuth endpoint yet
          ),
        ),
      ]);
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback? onTap;
  const _SocialBtn(
      {required this.label, required this.icon,
       required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2235) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon, const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.label.copyWith(
                    color: isDark ? Colors.white : AppColors.nearBlack,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
