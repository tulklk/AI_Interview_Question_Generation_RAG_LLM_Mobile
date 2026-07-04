/// Decoupled hook so the Dio interceptor (in hr_generate/data) can signal
/// a forced logout to the Riverpod AuthNotifier without a circular import.
class AuthEvents {
  AuthEvents._();

  /// Set by AuthNotifier on construction; called by _AuthInterceptor when a
  /// token refresh fails and the local session is wiped.
  static void Function()? onSessionExpired;
}
