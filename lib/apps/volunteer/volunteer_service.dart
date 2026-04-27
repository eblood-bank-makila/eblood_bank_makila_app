import 'package:flutter/foundation.dart';
import '../config/api/dio_client.dart';

class VolunteerService {
  VolunteerService();

  /// Fetch reasons to become volunteer donor
  Future<List<Map<String, dynamic>>> fetchReasons() async {
    try {
      final res = await getWithDio('/blood-donors/fetch/registration-reasons');
      if (res.success && res.data != null) {
        List<dynamic> list;
        if (res.data is List) {
          list = res.data as List<dynamic>;
        } else {
          throw const FormatException('Unexpected response format');
        }
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw const FormatException('Request failed');
    } catch (e) {
      if (kDebugMode) {
        print('VolunteerService.fetchReasons error: $e');
      }
      rethrow;
    }
  }
}

