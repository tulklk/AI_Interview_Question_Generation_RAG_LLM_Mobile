import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'storage_service.dart';

class CompanyModel {
  final String id;
  final String name;

  const CompanyModel({required this.id, required this.name});

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
        id: (json['id'] ?? json['companyId'] ?? '').toString(),
        name: (json['name'] ?? json['companyName'] ?? '').toString(),
      );
}

class CompanyService {
  static const _baseUrl = AppConstants.apiBaseUrl;

  static final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  /// Searches companies by name. Returns at most 10 results.
  /// Falls back to client-side filtering if the server doesn't support query params.
  static Future<List<CompanyModel>> search(String query) async {
    try {
      final token = await StorageService.getAccessToken();
      final res = await _dio.get(
        '/api/companies',
        // Try common search param names; server ignores unknown params harmlessly
        queryParameters: query.isNotEmpty ? {'q': query, 'name': query} : null,
        options: (token != null && token.isNotEmpty)
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      final raw = res.data;
      List<dynamic> list;

      if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is Map &&
          raw['data'] is Map &&
          (raw['data'] as Map)['content'] is List) {
        // Spring-boot pageable style
        list = (raw['data'] as Map)['content'] as List;
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }

      final all = list
          .whereType<Map<String, dynamic>>()
          .map(CompanyModel.fromJson)
          .where((c) => c.name.isNotEmpty)
          .toList();

      // Always apply client-side filter so the field works even if the server
      // returns all companies without server-side search support.
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        return all.where((c) => c.name.toLowerCase().contains(q)).take(10).toList();
      }
      return all.take(10).toList();
    } catch (_) {
      return [];
    }
  }
}
