import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/user_model.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFF0F9FF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative blobs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPurple.withOpacity(0.07),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Header
                  Column(
                    children: [
                      Text(
                        'I am a...',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.brandPurple,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      Text(
                        'Choose your role',
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll personalize your experience\nbased on your role',
                        style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 150.ms),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Role cards
                  _RoleCard(
                    role: UserRole.hrManager,
                    title: 'HR Manager',
                    subtitle: 'Manage jobs, create AI interview\nkits, and evaluate candidates',
                    icon: PhosphorIconsBold.briefcase,
                    gradientColors: const [Color(0xFF6C47FF), Color(0xFF3B82F6)],
                    isSelected: selectedRole == UserRole.hrManager,
                    onTap: () => ref.read(selectedRoleProvider.notifier).state =
                        UserRole.hrManager,
                  ).animate().slideX(begin: -0.3, end: 0, delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  _RoleCard(
                    role: UserRole.candidate,
                    title: 'Candidate',
                    subtitle: 'Apply for jobs, practice AI\ninterviews, and track progress',
                    icon: PhosphorIconsBold.student,
                    gradientColors: const [Color(0xFF14B8A6), Color(0xFF3B82F6)],
                    isSelected: selectedRole == UserRole.candidate,
                    onTap: () => ref.read(selectedRoleProvider.notifier).state =
                        UserRole.candidate,
                  ).animate().slideX(begin: 0.3, end: 0, delay: 300.ms, duration: 400.ms),
                  const Spacer(),
                  AppGradientButton(
                    label: 'Continue',
                    onTap: selectedRole != null
                        ? () => context.go('/login')
                        : null,
                    height: 54,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors[0].withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? gradientColors[0].withOpacity(0.6)
                : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected
                    ? null
                    : gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : gradientColors[0],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      color: isSelected ? gradientColors[0] : AppColors.nearBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected ? null : AppColors.gray200,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
