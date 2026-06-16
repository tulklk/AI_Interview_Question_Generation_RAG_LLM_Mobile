import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final role = ref.read(selectedRoleProvider);
    if (role == UserRole.hrManager) {
      await ref.read(authProvider.notifier).loginAsHR();
      if (mounted) context.go('/hr');
    } else {
      await ref.read(authProvider.notifier).loginAsCandidate();
      if (mounted) context.go('/candidate');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider);
    final isHR = role == UserRole.hrManager;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: Stack(
        children: [
          // Top gradient blob
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPurple.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Back button
                  GestureDetector(
                    onTap: () => context.go('/role'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Icon(
                        PhosphorIconsBold.arrowLeft,
                        size: 20,
                        color: isDark ? AppColors.white : AppColors.nearBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Header
                  Text(
                    isHR
                        ? 'Welcome back,\nrecruiter 👋'
                        : 'Continue your\ncareer journey 🚀',
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to ${isHR ? 'manage your recruitment' : 'explore opportunities'}',
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 40),
                  // Form
                  Column(
                    children: [
                      AppTextField(
                        label: 'Email address',
                        hint: 'you@company.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Icon(
                            PhosphorIconsBold.envelopeSimple,
                            size: 18,
                            color: AppColors.gray400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passCtrl,
                        obscureText: _obscure,
                        prefix: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Icon(
                            PhosphorIconsBold.lock,
                            size: 18,
                            color: AppColors.gray400,
                          ),
                        ),
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              _obscure
                                  ? PhosphorIconsBold.eye
                                  : PhosphorIconsBold.eyeSlash,
                              size: 18,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppGradientButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onTap: _login,
                    height: 54,
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 24),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray400,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Google button
                  AppSecondaryButton(
                    label: 'Continue with Google',
                    onTap: _login,
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('G', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEA4335))),
                      ),
                    ),
                    height: 52,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.gray500,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Sign up',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.brandPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
