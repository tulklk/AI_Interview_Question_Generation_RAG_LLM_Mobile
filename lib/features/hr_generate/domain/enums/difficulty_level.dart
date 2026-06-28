import 'package:flutter/material.dart';

enum HrDifficultyLevel {
  easy, medium, hard;

  static HrDifficultyLevel fromString(String? s) {
    switch ((s ?? '').toLowerCase().trim()) {
      case 'easy':   return HrDifficultyLevel.easy;
      case 'hard':   return HrDifficultyLevel.hard;
      default:       return HrDifficultyLevel.medium;
    }
  }

  String get displayName {
    switch (this) {
      case HrDifficultyLevel.easy:   return 'Easy';
      case HrDifficultyLevel.medium: return 'Medium';
      case HrDifficultyLevel.hard:   return 'Hard';
    }
  }

  String toApiString() => name.toLowerCase();

  Color get badgeColor {
    switch (this) {
      case HrDifficultyLevel.easy:   return const Color(0xFF10B981);
      case HrDifficultyLevel.medium: return const Color(0xFFF59E0B);
      case HrDifficultyLevel.hard:   return const Color(0xFFEF4444);
    }
  }
}
