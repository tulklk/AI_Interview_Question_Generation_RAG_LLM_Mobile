import 'package:flutter/material.dart';

/// Theme-aware colour palette for the HR Generate feature.
class GenColors {
  final Color bg;
  final Color card;
  final Color border;
  final Color borderFoc;
  final Color hint;
  final Color muted;
  final Color text;
  final Color textSub;

  const GenColors._({
    required this.bg,
    required this.card,
    required this.border,
    required this.borderFoc,
    required this.hint,
    required this.muted,
    required this.text,
    required this.textSub,
  });

  static GenColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _dark = GenColors._(
    bg:        Color(0xFF080B14),
    card:      Color(0xFF0D1117),
    border:    Color(0xFF1E2640),
    borderFoc: Color(0xFF7C3AED),
    hint:      Color(0xFF3A4568),
    muted:     Color(0xFF4A5578),
    text:      Colors.white,
    textSub:   Color(0xFF9CAAC4),
  );

  static const _light = GenColors._(
    bg:        Color(0xFFF4F5FB),
    card:      Colors.white,
    border:    Color(0xFFE5E7EB),
    borderFoc: Color(0xFF7C3AED),
    hint:      Color(0xFFD1D5DB),
    muted:     Color(0xFF9CA3AF),
    text:      Color(0xFF111827),
    textSub:   Color(0xFF6B7280),
  );

  static const primary = Color(0xFF7C3AED);
}
