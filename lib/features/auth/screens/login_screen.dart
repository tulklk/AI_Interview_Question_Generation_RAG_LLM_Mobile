import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/auth_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/user_model.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_button.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure       = true;
  bool _rememberMe    = false;
  bool _isLoading     = false;
  String? _emailError;
  String? _passError;
  int _focusCount     = 0;

  void _onFieldFocus(bool focused) =>
      setState(() => _focusCount = (_focusCount + (focused ? 1 : -1)).clamp(0, 10));

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty ? 'Email is required' : null;
      _passError  = _passCtrl.text.isEmpty ? 'Password is required' : null;
    });
    return _emailError == null && _passError == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    final role = ref.read(selectedRoleProvider);
    if (role == UserRole.hrManager) {
      await ref.read(authProvider.notifier).loginAsHR();
    } else {
      await ref.read(authProvider.notifier).loginAsCandidate();
    }
    if (mounted) setState(() => _isLoading = false);
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
              // Logo
              _AuthLogo(isDark: isDark)
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
                      text: 'Welcome back',
                      style: AppTextStyles.h1.copyWith(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontSize: 26, fontWeight: FontWeight.w800),
                      initialDelay: 300.ms,
                    ),
                    const SizedBox(height: 4),
                    Text('Sign in to your account to continue',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray500, fontSize: 14))
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Email
                    AuthInputField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      hint: 'you@company.com',
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
                        Text('Password',
                          style: AppTextStyles.label.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.nearBlack,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                        GestureDetector(
                          onTap: () {},
                          child: Text('Forgot password?',
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
                      label: 'Sign in',
                      isLoading: _isLoading,
                      onTap: _login,
                      trailingIcon: PhosphorIconsBold.arrowRight,
                    ).animate().fadeIn(delay: 820.ms).slideY(begin: 0.10, end: 0),
                    const SizedBox(height: 20),

                    // Divider
                    _OrDivider(isDark: isDark, text: 'or continue with')
                        .animate().fadeIn(delay: 860.ms),
                    const SizedBox(height: 14),

                    // Social
                    _SocialRow(isDark: isDark, onTap: _login)
                        .animate().fadeIn(delay: 900.ms).slideY(begin: 0.10, end: 0),
                    const SizedBox(height: 20),

                    // Sign up link
                    Center(
                      child: Wrap(alignment: WrapAlignment.center, children: [
                        Text("Don't have an account? ",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray500, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text('Sign up free',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brandPurple,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 940.ms),
                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
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

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _AuthLogo extends StatelessWidget {
  final bool isDark;
  const _AuthLogo({required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.40),
              blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Icon(PhosphorIconsBold.sparkle, size: 26, color: Colors.white),
      ),
      const SizedBox(height: 10),
      Text('HireGen AI',
        style: AppTextStyles.h3.copyWith(
          color: isDark ? Colors.white : AppColors.nearBlack,
          fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text('AI-Powered Interview Question Generator',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray400, fontSize: 12)),
    ],
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
  const _RememberMe({required this.value, required this.isDark, required this.onChanged});

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
              ? [BoxShadow(color: AppColors.brandPurple.withValues(alpha: 0.30),
                  blurRadius: 6)]
              : null,
        ),
        child: value
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
      const SizedBox(width: 8),
      Text('Remember me for 30 days',
        style: AppTextStyles.caption.copyWith(
          color: isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.gray500)),
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
      child: Text(text, style: AppTextStyles.caption.copyWith(
        color: AppColors.gray400, fontSize: 12))),
    Expanded(child: Divider(
      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
  ]);
}

// ─── Social row ───────────────────────────────────────────────────────────────

class _SocialRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _SocialRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _SocialBtn(label: 'Google',
      icon: _GoogleIcon(), isDark: isDark, onTap: onTap)),
    const SizedBox(width: 10),
    Expanded(child: _SocialBtn(label: 'Github',
      icon: Icon(PhosphorIconsBold.githubLogo, size: 18,
        color: isDark ? Colors.white : AppColors.nearBlack),
      isDark: isDark, onTap: onTap)),
  ]);
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SocialBtn({required this.label, required this.icon,
    required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2235) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon, const SizedBox(width: 8),
        Text(label, style: AppTextStyles.label.copyWith(
          color: isDark ? Colors.white : AppColors.nearBlack,
          fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: const BoxDecoration(
      shape: BoxShape.circle, color: Color(0xFFF1F3F4)),
    child: const Center(
      child: Text('G', style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w800,
        color: Color(0xFFEA4335), height: 1.0))),
  );
}
