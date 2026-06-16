import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/user_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _register() async {
    final role = ref.read(selectedRoleProvider);
    if (role == UserRole.hrManager) {
      await ref.read(authProvider.notifier).loginAsHR();
      if (mounted) context.go('/hr');
    } else {
      await ref.read(authProvider.notifier).loginAsCandidate();
      if (mounted) context.go('/candidate');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Icon(PhosphorIconsBold.arrowLeft, size: 20,
                    color: isDark ? AppColors.white : AppColors.nearBlack),
                ),
              ),
              const SizedBox(height: 32),
              Text('Create account', style: AppTextStyles.h1.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack)).animate().fadeIn(),
              const SizedBox(height: 8),
              Text('Start your AI recruitment journey',
                style: AppTextStyles.body.copyWith(color: AppColors.gray500)).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Full name',
                hint: 'Nguyen Van A',
                controller: _nameCtrl,
                prefix: const Padding(padding: EdgeInsets.all(14),
                  child: Icon(PhosphorIconsBold.user, size: 18, color: AppColors.gray400)),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email address',
                hint: 'you@company.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefix: const Padding(padding: EdgeInsets.all(14),
                  child: Icon(PhosphorIconsBold.envelopeSimple, size: 18, color: AppColors.gray400)),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Min. 8 characters',
                controller: _passCtrl,
                obscureText: _obscure,
                prefix: const Padding(padding: EdgeInsets.all(14),
                  child: Icon(PhosphorIconsBold.lock, size: 18, color: AppColors.gray400)),
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(padding: const EdgeInsets.all(14),
                    child: Icon(_obscure ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
                      size: 18, color: AppColors.gray400)),
                ),
              ),
              const SizedBox(height: 32),
              AppGradientButton(label: 'Create Account', onTap: _register, height: 54),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ",
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Sign in',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.brandPurple, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
