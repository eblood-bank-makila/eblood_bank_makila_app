import '../../config/api/dio_client.dart';

class AnnouncementsService {
  static const String _base = '/eblood/announcements';
  // static const String _base = '/eblood/connect/announcements';

  Future<List<Map<String, dynamic>>> fetchAll({String? filter}) async {
    final response = await getWithDio(
      _base,
      queryParams: filter != null && filter.isNotEmpty ? {'filter': filter} : null,
    );

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final response = await getWithDio('$_base/mine');

    if (response.success && response.data != null) {
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
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
    final response = await postWithDio(_base, body: payload);

    if (response.success && response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {'success': response.success, 'message': response.message};
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

    final response = await putWithDio('$_base/$id', body: payload);

    if (response.success && response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {'success': response.success, 'message': response.message};
  }

  Future<void> deleteAnnouncement(String id) async {
    await deleteWithDio('$_base/$id');
  }
}
