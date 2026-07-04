import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_events.dart';

const _kBaseUrl = AppConstants.apiBaseUrl;

// Public routes that never need a token or refresh attempt
const _kPublicPaths = {
  '/api/auth/login',
  '/api/auth/register/hr',
  '/api/auth/register/candidate',
  '/api/auth/oauth/google/verify',
  '/api/auth/oauth/google',
  '/api/auth/forgot-password',
  '/api/auth/reset-password',
  '/api/auth/resend-verification',
  '/api/auth/verify-email',
  '/api/auth/refresh',
};

Dio buildGenerationDio() {
  final dio = Dio(BaseOptions(
    baseUrl:        _kBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    },
  ))
    ..interceptors.add(_AuthInterceptor());
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody:    true,
      responseBody:   true,
      requestHeader:  false,
      responseHeader: false,
    ));
  }
  return dio;
}

class _PrefsCache {
  static SharedPreferences? _instance;
  static Future<SharedPreferences> get prefs async =>
      _instance ??= await SharedPreferences.getInstance();
}

/// Singleton to serialize concurrent token-refresh calls.
class _RefreshSingleton {
  static Completer<String?>? _completer;

  static Future<String?> refresh() async {
    if (_completer != null) return _completer!.future;

    _completer = Completer<String?>();
    try {
      final prefs        = await _PrefsCache.prefs;
      final refreshToken = prefs.getString('auth_refresh_token') ?? '';
      if (refreshToken.isEmpty) {
        _completer!.complete(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl:        _kBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        headers:        {'Content-Type': 'application/json'},
      ));
      final res = await refreshDio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final payload = _unwrapPayload(res.data);
      final newAccess =
          (payload['accessToken'] ?? payload['access_token'] ?? payload['token'] ?? '')
              .toString();
      final newRefresh =
          (payload['refreshToken'] ?? payload['refresh_token'] ?? '').toString();

      if (newAccess.isEmpty) {
        _completer!.complete(null);
        return null;
      }

      await prefs.setString('auth_access_token', newAccess);
      if (newRefresh.isNotEmpty) {
        await prefs.setString('auth_refresh_token', newRefresh);
      }

      _completer!.complete(newAccess);
      return newAccess;
    } catch (_) {
      _completer!.complete(null);
      return null;
    } finally {
      _completer = null;
    }
  }

  static Map<String, dynamic> _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      if (raw['result'] is Map<String, dynamic>) return raw['result'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await _PrefsCache.prefs;
    final token = prefs.getString('auth_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) return handler.next(err);

    final path = err.requestOptions.path;

    // Public routes: never retry
    if (_kPublicPaths.any((p) => path.contains(p))) {
      return handler.next(err);
    }

    // Already retried: clear session and pass error through
    if (err.requestOptions.extra['_retry'] == true) {
      await _clearSession();
      return handler.next(err);
    }

    // Attempt token refresh
    final newToken = await _RefreshSingleton.refresh();
    if (newToken == null) {
      await _clearSession();
      return handler.next(err);
    }

    // Retry original request with new token
    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra['_retry'] = true;

      final retryDio = Dio(BaseOptions(
        baseUrl:        _kBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers:        {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ));
      final retryRes = await retryDio.fetch(opts);
      return handler.resolve(retryRes);
    } catch (e) {
      await _clearSession();
      return handler.next(err);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await _PrefsCache.prefs;
    await Future.wait([
      prefs.remove('auth_access_token'),
      prefs.remove('auth_refresh_token'),
      prefs.remove('auth_user_id'),
      prefs.remove('auth_user_role'),
      prefs.remove('auth_user_name'),
      prefs.remove('auth_user_email'),
    ]);
    AuthEvents.onSessionExpired?.call();
  }
}
