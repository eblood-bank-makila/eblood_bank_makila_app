import 'package:dio/dio.dart';
import '../../../core/network/dio_client_improved.dart';

class AnnouncementsService {
  final Dio _dio = DioClient().dio;
  static const String _base = '/api/v1/eblood/connect/announcements';

  Future<List<Map<String, dynamic>>> fetchAll({String? filter}) async {
    final response = await _dio.get(
      _base,
      queryParameters: filter != null && filter.isNotEmpty ? {'filter': filter} : null,
    );
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final response = await _dio.get('$_base/mine');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String type,
    required String location,
    required String priority,
    required String description,
  }) async {
    final payload = {
      'title': title,
      'type': type,
      'location': location,
      'priority': priority,
      'description': description,
    };
    final response = await _dio.post(_base, data: payload);
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {'success': true};
  }
}
