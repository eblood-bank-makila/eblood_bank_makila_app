import 'package:flutter/material.dart';
import '../../config/api/dio_client.dart';
import 'AdvertisementModel.dart';

/// Service to fetch advertisements from API
class AdvertisementService {
  AdvertisementService();

  /// Fetch active advertisements for a specific audience (general endpoint)
  Future<List<AdvertisementModel>> fetchAdvertisements({
    String? targetAudience,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'is_active': true,
        'sort_by': 'priority',
        'sort_order': 'desc',
        if (targetAudience != null && targetAudience.isNotEmpty) 'target_audience': targetAudience,
      };

      final response = await getWithDio('/eblood/advertisements', queryParams: queryParams);

      if (response.success && response.data != null) {
        return _parseList(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('💥 Error fetching advertisements: $e');
      return [];
    }
  }

  /// Fetch advertisements tailored for customers
  Future<List<AdvertisementModel>> fetchCustomerAdvertisements() async {
    try {
      final queryParams = <String, dynamic>{
        'is_active': true,
        'sort_by': 'priority',
        'sort_order': 'desc',
      };
      final response = await getWithDio('/eblood/customer-advertisements', queryParams: queryParams);

      if (response.success && response.data != null) {
        return _parseList(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('💥 Error fetching customer ads: $e');
      return [];
    }
  }

  List<AdvertisementModel> _parseList(dynamic data) {
    List<dynamic> adsData;
    if (data is Map && data.containsKey('data')) {
      adsData = data['data'] as List<dynamic>;
    } else if (data is List) {
      adsData = data;
    } else {
      debugPrint('⚠️ Unexpected response format');
      throw const FormatException('Unexpected response format');
    }
    final advertisements = adsData
        .map((json) => AdvertisementModel.fromJson(Map<String, dynamic>.from(json)))
        .where((ad) => ad.isValid)
        .toList();
    advertisements.sort((a, b) => b.priority.compareTo(a.priority));
    return advertisements;
  }

  /// Get mock/demo advertisements for testing
  static List<AdvertisementModel> getMockAdvertisements() {
    return [
      AdvertisementModel(
        id: '1',
        title: 'Campagne de Don de Sang',
        description: 'Participez à notre grande campagne de don de sang ce weekend',
        imageUrl: 'assets/images/baniere1.png',
        actionType: 'modal',
        isActive: true,
        priority: 10,
        targetAudience: 'all',
      ),
      AdvertisementModel(
        id: '2',
        title: 'Nouveau Service',
        description: 'Découvrez notre nouveau service de livraison express',
        imageUrl: 'assets/images/baniere.png',
        actionType: 'internal',
        actionUrl: '/services',
        isActive: true,
        priority: 5,
        targetAudience: 'hospital',
      ),
      AdvertisementModel(
        id: '3',
        title: 'Urgence Sang O-',
        description: 'Besoin urgent de donneurs de groupe O négatif',
        imageUrl: 'assets/images/baniere2.png',
        actionType: 'modal',
        isActive: true,
        priority: 15,
        targetAudience: 'all',
      ),
    ];
  }

  /// Track advertisement click
  Future<bool> trackClick(String advertisementId) async {
    try {
      final response = await postWithDio('/eblood/advertisements/$advertisementId/click');
      if (response.success) {
        debugPrint('✅ Advertisement click tracked successfully');
        return true;
      }
      debugPrint('❌ Failed to track click: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error tracking click: $e');
      return false;
    }
  }

  /// Track advertisement view
  Future<bool> trackView(String advertisementId) async {
    try {
      final response = await getWithDio(
        '/eblood/advertisements/fetch/one-advertisement',
        queryParams: {'advertisement_id': advertisementId, 'increment_view': true},
      );
      if (response.success) {
        debugPrint('✅ Advertisement view tracked successfully');
        return true;
      }
      debugPrint('❌ Failed to track view: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error tracking view: $e');
      return false;
    }
  }

  /// Track video analytics event (non-YouTube): start | pause | complete
  Future<bool> trackVideoEvent(
    String advertisementId,
    String event, {
    int? positionMs,
    int? durationMs,
  }) async {
    try {
      final response = await postWithDio(
        '/eblood/advertisements/$advertisementId/video-event',
        body: {
          'event': event,
          if (positionMs != null) 'position_ms': positionMs,
          if (durationMs != null) 'duration_ms': durationMs,
        },
      );
      if (response.success) {
        debugPrint('✅ Video event "$event" tracked');
        return true;
      }
      debugPrint('❌ Failed to track video event: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error tracking video event: $e');
      return false;
    }
  }

}

