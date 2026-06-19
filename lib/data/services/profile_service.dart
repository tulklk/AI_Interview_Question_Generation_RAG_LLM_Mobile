import 'package:dio/dio.dart';
import '../../models/user_model.dart';

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
}

class ProfileService {
  static const _baseUrl =
      'https://iqgs-be-e2eefsdvd9fydtfx.eastasia-01.azurewebsites.net';

  static Dio _dio(String token) => Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

  // ── GET /api/users/me ─────────────────────────────────────────────────────

  static Future<UserModel> getProfile(String token) async {
    try {
      final res = await _dio(token).get('/api/users/me');
      return _parseUser(_unwrap(res.data));
    } on DioException catch (e) {
      throw ProfileException(_mapError(e));
    }
  }

  // ── PATCH /api/users/me/hr-profile ───────────────────────────────────────

  static Future<void> updateHRProfile({
    required String token,
    required String fullName,
    String? phone,
    String? company,
    String? jobTitle,
  }) async {
    try {
      await _dio(token).patch('/api/users/me/hr-profile', data: {
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (company != null && company.isNotEmpty) 'company': company,
        if (jobTitle != null && jobTitle.isNotEmpty) 'jobTitle': jobTitle,
      });
    } on DioException catch (e) {
      throw ProfileException(_mapError(e));
    }
  }

  // ── PATCH /api/users/me/candidate-profile ────────────────────────────────

  static Future<void> updateCandidateProfile({
    required String token,
    required String fullName,
    String? phone,
    String? targetPosition,
    String? experienceLevel,
    List<String>? techStack,
  }) async {
    try {
      await _dio(token).patch('/api/users/me/candidate-profile', data: {
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (targetPosition != null && targetPosition.isNotEmpty)
          'targetPosition': targetPosition,
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          'experienceLevel': experienceLevel,
        if (techStack != null) 'techStack': techStack,
      });
    } on DioException catch (e) {
      throw ProfileException(_mapError(e));
    }
  }

  // ── PATCH /api/users/me/password ─────────────────────────────────────────

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio(token).patch('/api/users/me/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ProfileException(_mapError(e));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map<String, dynamic>?) ?? {};
  }

  static UserModel _parseUser(Map<String, dynamic> p) {
    UserRole role(dynamic r) {
      final s = (r ?? '').toString().toLowerCase();
      if (s.contains('admin')) return UserRole.admin;
      if (s.contains('hr') || s.contains('manager') || s.contains('recruiter')) {
        return UserRole.hrManager;
      }
      return UserRole.candidate;
    }

    return UserModel(
      id: (p['userId'] ?? p['id'] ?? '').toString(),
      name: (p['fullName'] ?? p['name'] ?? '').toString(),
      email: (p['email'] ?? '').toString(),
      role: role(p['role']),
      phone: p['phone']?.toString(),
      company: p['company']?.toString(),
      title: (p['jobTitle'] ?? p['title'] ?? p['targetPosition'])?.toString(),
      experienceLevel: p['experienceLevel']?.toString(),
      techStack: (p['techStack'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  static String _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Không thể kết nối. Vui lòng kiểm tra mạng.';
    }
    final body = e.response?.data;
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    }
    switch (e.response?.statusCode) {
      case 400:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case 401:
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      default:
        return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }
}
