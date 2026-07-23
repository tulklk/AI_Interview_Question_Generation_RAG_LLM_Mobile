import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final String? error;
  final ValueChanged<bool>? onFocusChanged;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.error,
    this.onFocusChanged,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late AnimationController _shakeCtrl;
  bool _shaking = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  void _onFocus() {
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  @override
  void didUpdateWidget(AuthInputField old) {
    super.didUpdateWidget(old);
    if (widget.error != null && old.error == null) {
      _shake();
    }
  }

  void _shake() async {
    if (_shaking) return;
    setState(() => _shaking = true);
    await _shakeCtrl.forward();
    _shakeCtrl.reset();
    setState(() => _shaking = false);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.error != null;

    final borderColor = hasError
        ? AppColors.error
        : isDark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(widget.label,
          style: AppTextStyles.label.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.85)
                : AppColors.nearBlack,
            fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),

        // Field
        AnimatedBuilder(
          animation: _shakeCtrl,
          builder: (_, child) {
            final shake = _shaking
                ? (math.sin(_shakeCtrl.value * 6 * math.pi) * 4)
                : 0.0;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                child: Icon(widget.icon, size: 17,
                  color: hasError ? AppColors.error : AppColors.gray400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? Colors.white : AppColors.nearBlack,
                    fontSize: 14, height: 1.2),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.gray400, fontSize: 14, height: 1.2),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[widget.trailing!, const SizedBox(width: 12)],
            ]),
          ),
        ),

        // Error text
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.error!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error, fontSize: 11)),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2, end: 0),
      ],
    );
  }
}

// ─── Animated heading (word-by-word) ─────────────────────────────────────────

class AnimatedHeading extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration initialDelay;

  const AnimatedHeading({
    super.key,
    required this.text,
    required this.style,
    this.initialDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Wrap(
      children: List.generate(words.length, (i) {
        final delay = initialDelay + Duration(milliseconds: i * 90);
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Text(words[i], style: style)
            .animate()
            .fadeIn(delay: delay, duration: 500.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.28, end: 0, delay: delay, duration: 500.ms,
              curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.82, 0.82), end: const Offset(1, 1),
              delay: delay, duration: 500.ms, curve: Curves.easeOutCubic)
            .blur(
              begin: const Offset(6, 6), end: Offset.zero,
              delay: delay, duration: 500.ms),
        );
      }),
    );
  }
}
