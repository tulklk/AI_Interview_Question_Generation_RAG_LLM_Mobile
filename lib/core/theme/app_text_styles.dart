import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.beVietnamPro(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: AppColors.nearBlack,
      );

  static TextStyle get h1 => GoogleFonts.beVietnamPro(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.nearBlack,
      );

  static TextStyle get h2 => GoogleFonts.beVietnamPro(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.nearBlack,
      );

  static TextStyle get h3 => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get h4 => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get body => GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.nearBlack,
      );

  static TextStyle get bodyEmphasis => GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get label => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get labelBold => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get caption => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.gray500,
      );

  static TextStyle get overline => GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.5,
        color: AppColors.gray500,
      );

  static TextStyle get buttonText => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.white,
      );

  static TextStyle get buttonTextDark => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.nearBlack,
      );

  static TextStyle get chipText => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.brandPurple,
      );
}
