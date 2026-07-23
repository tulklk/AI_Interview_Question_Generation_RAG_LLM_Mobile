import 'package:dio/dio.dart';
import 'generation_api.dart';
import '../domain/models/candidate_recommendation.dart';

class RecommendationRepository {
  final Dio _dio = buildGenerationDio();
  static const _base = '/api/hr/recommendations';

  Future<RecommendationPage> list({
    String? questionSetId,
    String? status,
    int? minScore,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (questionSetId != null && questionSetId.isNotEmpty) {
      params['questionSetId'] = questionSetId;
    }
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (minScore != null) {
      params['minScore'] = minScore;
    }

    final res = await _dio.get(_base, queryParameters: params);
    return RecommendationPage.fromJson(res.data);
  }

  Future<CandidateRecommendation> getDetail(String id) async {
    final res = await _dio.get('$_base/$id');
    return CandidateRecommendation.fromJson(
        res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {});
  }

  /// Shortlist a recommendation (mark as interested)
  Future<void> shortlist(String id) async {
    await _dio.post('$_base/$id/shortlist');
  }

  /// Dismiss a recommendation (hide from NEW/SHORTLISTED)
  Future<void> dismiss(String id) async {
    await _dio.post('$_base/$id/dismiss');
  }

  /// Invite a candidate for interview
  Future<void> invite(String id, {String? message}) async {
    await _dio.post(
      '$_base/$id/invite',
      data: message != null && message.isNotEmpty ? {'message': message} : null,
    );
  }

  String friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) return 'Phiên đăng nhập hết hạn.';
      if (code == 404) return 'Không tìm thấy dữ liệu.';
      if (code == 409) return 'Thao tác không hợp lệ với trạng thái hiện tại.';
      if (code != null && code >= 500) return 'Lỗi máy chủ, thử lại sau.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối quá thời gian, kiểm tra mạng.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối, kiểm tra mạng.';
      }
    }
    return 'Đã xảy ra lỗi, thử lại.';
  }
}
