class AppConstants {
  AppConstants._();

  static const String appName = 'HireGen AI';
  static const String appTagline = 'Hire smarter with AI';
  static const String logoAsset = 'assets/images/logo.png';
  static const String googleLogoAsset = 'assets/images/google_logo.svg';

  // Spacing
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Touch targets
  static const double minTouchTarget = 48;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // Role keys
  static const String roleHR = 'hr_manager';
  static const String roleCandidate = 'candidate';

  // API
  static const String apiBaseUrl =
      'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';
  static const String googleServerClientId =
      '593842710212-vg9t701m2prpeh0g4sq5maspreuvjmm7.apps.googleusercontent.com';
}
