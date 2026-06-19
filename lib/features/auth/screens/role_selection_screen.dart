import 'dart:math';
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

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blobCtrl;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFF0F9FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Animated blobs ────────────────────────────────────────────
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) {
                final t = _blobCtrl.value * 2 * pi;
                return Stack(
                  children: [
                    Positioned(
                      top: -90 + 30 * sin(t),
                      right: -80 + 20 * cos(t * 0.7),
                      child: _Blob(
                        size: 260,
                        color: AppColors.brandPurple.withValues(alpha: 0.10),
                      ),
                    ),
                    Positioned(
                      bottom: -60 + 20 * cos(t * 0.85),
                      left: -70 + 15 * sin(t * 1.1),
                      child: _Blob(
                        size: 200,
                        color: AppColors.deepBlue.withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      top: 200 + 15 * sin(t * 0.6),
                      left: -40 + 12 * cos(t),
                      child: _Blob(
                        size: 150,
                        color: AppColors.teal.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // AI badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPurple.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsBold.sparkle,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'AI Interview Platform',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Header
                  Text(
                    'Choose your role',
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll personalize your experience\nbased on your role',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 48),

                  // HR card
                  _RoleCard(
                    role: UserRole.hrManager,
                    title: 'HR Manager',
                    subtitle:
                        'Manage jobs, create AI interview\nkits, and evaluate candidates',
                    icon: PhosphorIconsBold.briefcase,
                    gradientColors: const [
                      Color(0xFF6C47FF),
                      Color(0xFF3B82F6)
                    ],
                    isSelected: selectedRole == UserRole.hrManager,
                    onTap: () =>
                        ref.read(selectedRoleProvider.notifier).state =
                            UserRole.hrManager,
                  ).animate().slideX(
                      begin: -0.25,
                      end: 0,
                      delay: 200.ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // Candidate card
                  _RoleCard(
                    role: UserRole.candidate,
                    title: 'Candidate',
                    subtitle:
                        'Apply for jobs, practice AI\ninterviews, and track progress',
                    icon: PhosphorIconsBold.student,
                    gradientColors: const [
                      Color(0xFF14B8A6),
                      Color(0xFF3B82F6)
                    ],
                    isSelected: selectedRole == UserRole.candidate,
                    onTap: () =>
                        ref.read(selectedRoleProvider.notifier).state =
                            UserRole.candidate,
                  ).animate().slideX(
                      begin: 0.25,
                      end: 0,
                      delay: 300.ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic),

                  const Spacer(),

                  AppGradientButton(
                    label: 'Continue',
                    onTap:
                        selectedRole != null ? () => context.go('/login') : null,
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

// ── Role card ─────────────────────────────────────────────────────────────────

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
              ? gradientColors[0].withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? gradientColors[0].withValues(alpha: 0.55)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            // Near contact
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isSelected ? 0.04 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            // Mid depth
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isSelected ? 0.09 : 0.05),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            // Coloured ambient (selected only)
            if (isSelected)
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.22),
                blurRadius: 32,
                spreadRadius: -6,
                offset: const Offset(0, 14),
              ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected
                    ? null
                    : gradientColors[0].withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.42),
                          blurRadius: 16,
                          spreadRadius: -2,
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
                      color: isSelected
                          ? gradientColors[0]
                          : AppColors.nearBlack,
                    ),
                  ),
                  const SizedBox(height: 5),
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
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected ? null : AppColors.gray200,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.38),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
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

// ── Blob helper ───────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
