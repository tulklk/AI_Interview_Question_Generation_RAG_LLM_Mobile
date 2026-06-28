import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBaseUrl = 'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';

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
    ..interceptors.add(_GenAuthInterceptor())
    ..interceptors.add(LogInterceptor(
      requestBody:    true,
      responseBody:   true,
      requestHeader:  false,
      responseHeader: false,
    ));
  return dio;
}

class _GenAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final prefs        = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('auth_refresh_token') ?? '';
        if (refreshToken.isEmpty) return handler.next(err);

        final refresh = Dio(BaseOptions(
          baseUrl:        _kBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          headers:        {'Content-Type': 'application/json'},
        ));

        final res = await refresh.post('/api/auth/refresh',
            data: {'refreshToken': refreshToken});

        final payload = res.data is Map && res.data['data'] is Map
            ? res.data['data'] as Map<String, dynamic>
            : (res.data is Map ? res.data as Map<String, dynamic> : {});

        final newToken = (payload['accessToken'] ?? payload['access_token'] ?? '').toString();
        if (newToken.isEmpty) return handler.next(err);

        await prefs.setString('auth_access_token', newToken);

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retryDio = Dio(BaseOptions(baseUrl: _kBaseUrl));
        final retry = await retryDio.fetch(opts);
        return handler.resolve(retry);
      } catch (_) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}
