import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../data/services/auth_service.dart' show AuthErrorType;

// ─── Error banner ────────────────────────────────────────────────────────────

class AuthErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;
  final AuthErrorType? type;

  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
    this.type,
  });

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
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(_icon, size: 16, color: _color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style: AppTextStyles.caption.copyWith(
                color: _color, fontWeight: FontWeight.w500, height: 1.4)),
      ),
    ]),
  );
}

// ─── Logo ────────────────────────────────────────────────────────────────────

class AuthLogo extends StatelessWidget {
  final bool isDark;
  const AuthLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppLogoImage(
        size: 72,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(AppConstants.appName,
        style: AppTextStyles.h3.copyWith(
          color: isDark ? AppColors.white : AppColors.nearBlack,
          fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text('AI-Powered Interview Question Generator',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray400, fontSize: 12)),
    ],
  );
}

// ─── Card ────────────────────────────────────────────────────────────────────

class AuthCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const AuthCard({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF111827) : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
          blurRadius: 40, offset: const Offset(0, 12)),
      ],
    ),
    padding: const EdgeInsets.all(24),
    child: child,
  );
}

// ─── Field label ─────────────────────────────────────────────────────────────

class AuthFieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const AuthFieldLabel(this.text, this.isDark, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(
      color: isDark ? AppColors.white.withValues(alpha: 0.85) : AppColors.nearBlack,
      fontWeight: FontWeight.w600, fontSize: 13),
  );
}

// ─── Text field ──────────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool isDark;
  final Widget? trailing;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
      ),
    ),
    child: Row(children: [
      const SizedBox(width: 14),
      Icon(icon, size: 17, color: AppColors.gray400),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack,
            fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.gray400, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
    ]),
  );
}

// ─── Button ──────────────────────────────────────────────────────────────────

class AuthButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const AuthButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.35),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                  style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 16, color: Colors.white),
                ],
              ]),
      ),
    ),
  );
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class AuthOrDivider extends StatelessWidget {
  final bool isDark;
  final String text;
  const AuthOrDivider({super.key, required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(
      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray400, fontSize: 12)),
    ),
    Expanded(child: Divider(
      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
  ]);
}

// ─── Social button ───────────────────────────────────────────────────────────

class AuthSocialButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final bool isDark;
  final VoidCallback? onTap;
  final double height;

  const AuthSocialButton({
    super.key,
    required this.label,
    required this.leading,
    required this.isDark,
    this.onTap,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 150),
    opacity: onTap != null ? 1.0 : 0.45,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          leading,
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.white : AppColors.nearBlack,
            fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

// ─── Google logo ─────────────────────────────────────────────────────────────

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppConstants.googleLogoAsset,
    width: size,
    height: size,
  );
}

class AuthGoogleLogo extends StatelessWidget {
  const AuthGoogleLogo({super.key});

  @override
  Widget build(BuildContext context) => const GoogleLogoIcon(size: 18);
}

// ─── Github logo ─────────────────────────────────────────────────────────────

class AuthGithubLogo extends StatelessWidget {
  final bool isDark;
  const AuthGithubLogo({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Icon(
    PhosphorIconsBold.githubLogo, size: 18,
    color: isDark ? AppColors.white : AppColors.nearBlack,
  );
}

// ─── Role tab bar ────────────────────────────────────────────────────────────

class AuthRoleTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const AuthRoleTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      _TabItem(label: 'HR Manager', selected: selectedIndex == 0,
        onTap: () => onChanged(0), isDark: isDark),
      _TabItem(label: 'Job Seeker', selected: selectedIndex == 1,
        onTap: () => onChanged(1), isDark: isDark),
    ]),
  );
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _TabItem({required this.label, required this.selected,
    required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(label,
            style: AppTextStyles.label.copyWith(
              color: selected ? Colors.white
                  : (isDark ? AppColors.white.withValues(alpha: 0.5) : AppColors.gray500),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13)),
        ),
      ),
    ),
  );
}

// ─── Step indicator ──────────────────────────────────────────────────────────

class AuthStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool isDark;
  const AuthStepIndicator({super.key, required this.currentStep, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StepDot(number: 1, label: 'Account Information',
        active: currentStep >= 1, isDark: isDark),
      Expanded(child: Container(
        height: 1.5,
        color: currentStep >= 2 ? AppColors.brandPurple
            : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      )),
      _StepDot(number: 2, label: 'Your Profile',
        active: currentStep >= 2, isDark: isDark),
    ],
  );
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool isDark;
  const _StepDot({required this.number, required this.label,
    required this.active, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26, height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.brandPurple : Colors.transparent,
          border: Border.all(
            color: active ? AppColors.brandPurple
                : (isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
            width: 1.5),
        ),
        child: Center(
          child: Text('$number',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: active ? Colors.white
                  : (isDark ? AppColors.white.withValues(alpha: 0.4) : AppColors.gray400)))),
      ),
      const SizedBox(height: 4),
      Text(label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          color: active ? AppColors.brandPurple
              : (isDark ? AppColors.white.withValues(alpha: 0.4) : AppColors.gray400),
          fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ],
  );
}

// ─── Background orbs ─────────────────────────────────────────────────────────

class AuthBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const AuthBackground({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: isDark ? const Color(0xFF070B18) : const Color(0xFFF1F2F7),
    body: Stack(children: [
      Positioned(top: -80, left: -60,
        child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: AppColors.brandPurple.withValues(alpha: isDark ? 0.14 : 0.06)))),
      Positioned(bottom: -50, right: -40,
        child: Container(width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: AppColors.deepBlue.withValues(alpha: isDark ? 0.10 : 0.04)))),
      child,
    ]),
  );
}
