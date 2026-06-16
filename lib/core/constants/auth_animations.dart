import 'package:flutter/material.dart';

class AuthAnimations {
  AuthAnimations._();

  // Durations
  static const pageEnter     = Duration(milliseconds: 400);
  static const headingWord   = Duration(milliseconds: 500);
  static const headingStagger= Duration(milliseconds: 90);
  static const formRow       = Duration(milliseconds: 450);
  static const formStagger   = Duration(milliseconds: 80);
  static const stepSlide     = Duration(milliseconds: 300);
  static const tabSwitch     = Duration(milliseconds: 220);
  static const shimmerSweep  = Duration(milliseconds: 550);
  static const aurora        = Duration(seconds: 32);
  static const cardBreathe   = Duration(seconds: 9);
  static const cardFloat     = Duration(seconds: 8);
  static const cardShine     = Duration(seconds: 6);

  // Curves
  static const easeOutCubic  = Cubic(0.33, 1.0, 0.68, 1.0);
  static const spring        = SpringDescription(mass: 1, stiffness: 400, damping: 30);
}
