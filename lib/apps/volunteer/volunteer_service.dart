import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/dio_client_improved.dart';

class VolunteerService {
  VolunteerService();
  final Dio _dio = DioClient().dio;

  /// Fetch reasons to become volunteer donor
  Future<List<Map<String, dynamic>>> fetchReasons() async {
    try {
      final res = await _dio.get('/blood-donors/fetch/registration-reasons');
      final data = res.data;
      List<dynamic> list;
      if (data is Map && data.containsKey('data')) {
        list = data['data'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        throw const FormatException('Unexpected response format');
      }
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('VolunteerService.fetchReasons error: $e');
      }
      rethrow;
    }
  }
}

