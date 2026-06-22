import 'package:dio/dio.dart';
import '../../models/user_model.dart';
import 'storage_service.dart';

// ── Error types ──────────────────────────────────────────────────────────────

enum AuthErrorType {
  invalidCredentials,
  notVerified,
  accountLocked,
  serverError,
  networkError,
}

class AuthException implements Exception {
  final String message;
  final AuthErrorType type;

  const AuthException({required this.message, required this.type});

  @override
  String toString() => 'AuthException(${type.name}): $message';
}

// ── Google OAuth models ───────────────────────────────────────────────────────

class GoogleVerifyResult {
  final bool isExistingUser;
  final String? email;
  final String? name;
  final String? avatarUrl;

  const GoogleVerifyResult({
    required this.isExistingUser,
    this.email,
    this.name,
    this.avatarUrl,
  });
}

class GoogleProfileData {
  final String intendedRole;   // 'hrManager' | 'candidate'
  final String? companyName;
  final String? companyId;
  final String? jobTitle;
  final String? targetRole;
  final String? seniorityLevel;
  final List<String> techStack;

  const GoogleProfileData({
    required this.intendedRole,
    this.companyName,
    this.companyId,
    this.jobTitle,
    this.targetRole,
    this.seniorityLevel,
    this.techStack = const [],
  });

  Map<String, dynamic> toJson() => {
        'intendedRole': intendedRole,
        if (companyName != null && companyName!.isNotEmpty) 'companyName': companyName,
        if (companyId != null && companyId!.isNotEmpty) 'companyId': companyId,
        if (jobTitle != null && jobTitle!.isNotEmpty) 'jobTitle': jobTitle,
        if (targetRole != null && targetRole!.isNotEmpty) 'targetRole': targetRole,
        if (seniorityLevel != null && seniorityLevel!.isNotEmpty) 'seniorityLevel': seniorityLevel,
        if (techStack.isNotEmpty) 'techStack': techStack,
      };
}

// ── Result ───────────────────────────────────────────────────────────────────

class LoginResult {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

// ── Service ──────────────────────────────────────────────────────────────────

class AuthService {
  static const _baseUrl =
      'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';

  static final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ))..interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    requestHeader: false,
    responseHeader: false,
    logPrint: (o) => print('[AuthService] $o'),
  ));

  // ── Email / password login ──────────────────────────────────────────────

  static Future<LoginResult> loginWithEmail(
      String email, String password) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _parseResponse(res.data, fallbackEmail: email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

    // ── Google OAuth verify (check if account exists) ──────────────────────

  static Future<GoogleVerifyResult> verifyGoogleToken(String idToken) async {
    try {
      final res = await _dio.post('/api/auth/oauth/google/verify', data: {
        'idToken': idToken,
      });
      final payload = (res.data is Map && res.data['data'] is Map)
          ? res.data['data'] as Map<String, dynamic>
          : (res.data is Map ? res.data as Map<String, dynamic> : <String, dynamic>{});

      final isNewUser = payload['isNewUser'] as bool? ??
          !(payload.containsKey('accessToken') ||
            payload.containsKey('userId') ||
            payload.containsKey('id'));

      return GoogleVerifyResult(
        isExistingUser: !isNewUser,
        email:     payload['email']?.toString(),
        name:      (payload['fullName'] ?? payload['name'])?.toString(),
        avatarUrl: payload['avatarUrl']?.toString(),
      );
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) == 404) {
        return const GoogleVerifyResult(isExistingUser: false);
      }
      throw _mapDioError(e, isOAuth: true);
    }
  }

  // ── Google OAuth login / register ───────────────────────────────────────

  static Future<LoginResult> loginWithGoogle(
    String idToken, {
    GoogleProfileData? profile,
  }) async {
    try {
      final res = await _dio.post('/api/auth/oauth/google', data: {
        'idToken': idToken,
        if (profile != null) ...profile.toJson(),
      });
      return _parseResponse(res.data);
    } on DioException catch (e) {
      throw _mapDioError(e, isOAuth: true);
    }
  }

  // ── Register HR ──────────────────────────────────────────────────────────

  static Future<void> registerHR({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String companyName,
    String? companyId,
    String? jobTitle,
  }) async {
    try {
      await _dio.post('/api/auth/register/hr', data: {
        'email':           email,
        'password':        password,
        'confirmPassword': confirmPassword,
        'fullName':        fullName,
        'companyName':     companyName,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (jobTitle != null && jobTitle.isNotEmpty) 'jobTitle': jobTitle,
      });
    } on DioException catch (e) {
      throw _mapRegisterError(e);
    }
  }

  // ── Register Candidate ───────────────────────────────────────────────────

  static Future<void> registerCandidate({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _dio.post('/api/auth/register/candidate', data: {
        'email':    email,
        'password': password,
        'fullName': fullName,
      });
    } on DioException catch (e) {
      throw _mapRegisterError(e);
    }
  }

  // ── Resend verification email ─────────────────────────────────────────────

  static Future<void> resendVerification(String email) async {
    try {
      await _dio.post('/api/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        throw const AuthException(
          message: 'Không thể kết nối. Vui lòng kiểm tra kết nối mạng.',
          type: AuthErrorType.networkError,
        );
      }
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    try {
      final token        = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();
      await _dio.post(
        '/api/auth/logout',
        data: {
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refreshToken': refreshToken,
        },
        options: (token != null && token.isNotEmpty)
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
    } catch (_) {
      // Swallow all errors — local session cleared regardless (AC-06 graceful degradation)
    }
  }

  // ── Forgot password ──────────────────────────────────────────────────────

  static Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      // Only throw on network-level failures; 4xx are swallowed per AC-02
      // (backend returns same response regardless of email existence)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        throw const AuthException(
          message: 'Không thể kết nối. Vui lòng kiểm tra kết nối mạng.',
          type: AuthErrorType.networkError,
        );
      }
      // For any other HTTP error, still show the neutral success message
      // to prevent account enumeration (backend behaviour may vary).
    }
  }

  // ── Reset password ────────────────────────────────────────────────────────

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/api/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 400 || status == 404 || status == 410) {
        throw const AuthException(
          message:
              'Đường dẫn đặt lại không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu đường dẫn mới.',
          type: AuthErrorType.serverError,
        );
      }
      throw _mapDioError(e);
    }
  }

  // ── Parsers ─────────────────────────────────────────────────────────────

  static LoginResult _parseResponse(dynamic raw, {String? fallbackEmail}) {
    // Backend response shape: { "data": { ... }, "code": 200, "message": "OK" }
    // Fall back to raw itself when the wrapper is absent (e.g. different endpoint).
    final payload = (raw is Map && raw['data'] is Map)
        ? raw['data'] as Map<String, dynamic>
        : (raw as Map<String, dynamic>);

    final user = UserModel(
      id:        (payload['userId']   ?? payload['id']   ?? '').toString(),
      name:      (payload['fullName'] ?? payload['name'] ?? '').toString(),
      email:     (payload['email']    ?? fallbackEmail   ?? '').toString(),
      role:      _parseRole(payload['role']),
      avatarUrl: payload['avatarUrl']?.toString() ?? payload['avatar']?.toString(),
    );

    final accessToken = (payload['accessToken'] ??
            payload['access_token'] ??
            payload['token'] ??
            '')
        .toString();

    final refreshToken =
        (payload['refreshToken'] ?? payload['refresh_token'] ?? '').toString();

    return LoginResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static UserRole _parseRole(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase();
    if (s.contains('admin')) return UserRole.admin;
    if (s.contains('hr') || s.contains('manager') || s.contains('recruiter')) {
      return UserRole.hrManager;
    }
    return UserRole.candidate;
  }

  // ── Register error mapping ───────────────────────────────────────────────

  static AuthException _mapRegisterError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout) {
      return const AuthException(
        message: 'Không thể kết nối. Vui lòng kiểm tra kết nối mạng.',
        type: AuthErrorType.networkError,
      );
    }
    final status = e.response?.statusCode ?? 0;
    final body   = e.response?.data;

    String rawMsg = '';
    String details = '';
    if (body is Map) {
      rawMsg = (body['message'] ?? body['error'] ?? '').toString();
      final errs = body['errors'];
      if (errs is Map) {
        details = errs.entries.map((entry) {
          final v = entry.value;
          final msg = v is List ? v.join(', ') : v.toString();
          return msg;
        }).join(' • ');
      } else if (errs is List) {
        details = errs.map((v) => v.toString()).join(' • ');
      } else if (errs is String) {
        details = errs;
      }
    } else {
      rawMsg = body?.toString() ?? '';
    }

    final displayMsg = [rawMsg, details].where((s) => s.isNotEmpty).join('\n');
    final lower = displayMsg.toLowerCase();

    if (status == 409 ||
        (status == 400 &&
            (lower.contains('exist') ||
             lower.contains('used') ||
             lower.contains('duplicate') ||
             lower.contains('already') ||
             lower.contains('email')))) {
      return const AuthException(
        message: 'Email này đã được sử dụng. Vui lòng dùng email khác hoặc đăng nhập.',
        type: AuthErrorType.invalidCredentials,
      );
    }
    if (displayMsg.isNotEmpty) {
      return AuthException(message: displayMsg, type: AuthErrorType.serverError);
    }
    return const AuthException(
      message: 'Có lỗi xảy ra. Vui lòng thử lại sau.',
      type: AuthErrorType.serverError,
    );
  }

  // ── Error mapping ────────────────────────────────────────────────────────

  static AuthException _mapDioError(DioException e, {bool isOAuth = false}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout) {
      return const AuthException(
        message: 'Không thể kết nối. Vui lòng kiểm tra kết nối mạng.',
        type: AuthErrorType.networkError,
      );
    }

    final status = e.response?.statusCode ?? 0;
    final body   = e.response?.data;
    final msg    = (body is Map
            ? (body['message'] ?? body['error'] ?? '')
            : body?.toString() ?? '')
        .toString()
        .toLowerCase();

    if (isOAuth) {
      return const AuthException(
        message: 'Đăng nhập bằng Google thất bại. Vui lòng thử lại.',
        type: AuthErrorType.serverError,
      );
    }

    if (status == 401) {
      return const AuthException(
        message: 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
        type: AuthErrorType.invalidCredentials,
      );
    }

    if (status == 403) {
      if (msg.contains('verif') || msg.contains('confirm') || msg.contains('email')) {
        return const AuthException(
          message: 'Vui lòng xác minh email trước khi đăng nhập.',
          type: AuthErrorType.notVerified,
        );
      }
      if (msg.contains('lock') || msg.contains('ban') || msg.contains('block')) {
        return const AuthException(
          message: 'Tài khoản đã bị khóa. Vui lòng liên hệ hỗ trợ.',
          type: AuthErrorType.accountLocked,
        );
      }
      // Default 403 → not verified (most common case for new accounts)
      return const AuthException(
        message: 'Vui lòng xác minh email trước khi đăng nhập.',
        type: AuthErrorType.notVerified,
      );
    }

    if (status == 404) {
      // Don't leak account existence — treat as invalid credentials
      return const AuthException(
        message: 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.',
        type: AuthErrorType.invalidCredentials,
      );
    }

    return const AuthException(
      message: 'Có lỗi xảy ra. Vui lòng thử lại sau.',
      type: AuthErrorType.serverError,
    );
  }
}
