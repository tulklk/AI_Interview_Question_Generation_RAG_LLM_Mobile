import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Primary
  static const Color brandPurple    = Color(0xFF6C47FF);
  static const Color primaryHover   = Color(0xFF5535DD);
  static const Color accentViolet   = Color(0xFF7C3AED);
  static const Color accentCyan     = Color(0xFF22D3EE);
  static const Color deepBlue       = Color(0xFF3B82F6);
  static const Color purpleShadow   = Color(0xFF7C3AED);

  // Accent
  static const Color magenta = Color(0xFFEC4899);
  static const Color teal = Color(0xFF14B8A6);
  static const Color reactCyan = Color(0xFF61DAFB);
  static const Color typescriptNavy = Color(0xFF3178C6);
  static const Color amber = Color(0xFFF59E0B);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Neutral
  static const Color nearBlack = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F7FB);
  static const Color faintLight = Color(0xFFF8FAFC);
  static const Color violetWash = Color(0xFFF5F3FF);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);

  // Borders
  static Color cardBorder = const Color(0xFF7C3AED).withValues(alpha: 0.12);
  static Color formBorder = const Color(0xFF000000).withValues(alpha: 0.1);

  // Dark mode surfaces
  static const Color darkBg = Color(0xFF0A0A14);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1A1F35);
  static const Color darkCardBorder = Color(0xFF2D3562);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandPurple, deepBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A0533), Color(0xFF0D1B4B), Color(0xFF091425)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0A0A14), Color(0xFF0F0F23), Color(0xFF0A1628)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
