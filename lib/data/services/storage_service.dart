import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens and session metadata using SharedPreferences.
/// All keys are prefixed to avoid collisions.
class StorageService {
  static const _kAccessToken    = 'auth_access_token';
  static const _kRefreshToken   = 'auth_refresh_token';
  static const _kUserId         = 'auth_user_id';
  static const _kUserRole       = 'auth_user_role';
  static const _kUserName       = 'auth_user_name';
  static const _kUserEmail      = 'auth_user_email';
  static const _kOnboardingSeen = 'onboarding_seen';

  // ── Write ────────────────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kAccessToken,  accessToken),
      prefs.setString(_kRefreshToken, refreshToken),
      prefs.setString(_kUserId,       userId),
      prefs.setString(_kUserRole,     userRole),
      prefs.setString(_kUserName,     userName),
      prefs.setString(_kUserEmail,    userEmail),
    ]);
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  static Future<Map<String, String>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token  = prefs.getString(_kAccessToken);
    if (token == null || token.isEmpty) return null;
    final userId    = prefs.getString(_kUserId)    ?? '';
    final userName  = prefs.getString(_kUserName)  ?? '';
    final userEmail = prefs.getString(_kUserEmail) ?? '';
    // Treat as no session if any critical field is missing
    if (userId.isEmpty || userName.isEmpty || userEmail.isEmpty) return null;
    return {
      'accessToken':  token,
      'refreshToken': prefs.getString(_kRefreshToken) ?? '',
      'userId':       userId,
      'userRole':     prefs.getString(_kUserRole)     ?? '',
      'userName':     userName,
      'userEmail':    userEmail,
    };
  }

  // ── Onboarding ───────────────────────────────────────────────────────────

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeen) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
  }

  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, token);
  }

  // ── Clear ────────────────────────────────────────────────────────────────

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kAccessToken),
      prefs.remove(_kRefreshToken),
      prefs.remove(_kUserId),
      prefs.remove(_kUserRole),
      prefs.remove(_kUserName),
      prefs.remove(_kUserEmail),
    ]);
  }
}
