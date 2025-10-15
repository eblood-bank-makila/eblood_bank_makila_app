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

  Future<Map<String, dynamic>> updateAnnouncement({
    required String id,
    String? title,
    String? type,
    String? location,
    String? priority,
    String? description,
  }) async {
    final Map<String, dynamic> payload = {};
    if (title != null) payload['title'] = title;
    if (type != null) payload['type'] = type;
    if (location != null) payload['location'] = location;
    if (priority != null) payload['priority'] = priority;
    if (description != null) payload['description'] = description;

    final response = await _dio.put('$_base/$id', data: payload);
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {'success': true};
  }

  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete('$_base/$id');
  }
}
