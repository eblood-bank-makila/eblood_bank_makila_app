import 'package:get_storage/get_storage.dart';

import '../config/api/dio_client.dart';
import '../config/api/ApiConfig.dart';
import '../models/api_response.dart';

class BloodDeliveryService {
  static final BloodDeliveryService _instance = BloodDeliveryService._internal();
  factory BloodDeliveryService() => _instance;
  BloodDeliveryService._internal();

  Future<String?> _getDefaultHospitalId() async {
    try {
      final storage = GetStorage();
      final dynamic storedProfiles = storage.read('user_profiles') ?? storage.read('user_profils');

      String? sysOrgId;
      if (storedProfiles is List) {
        for (final p in storedProfiles) {
          if (p is Map) {
            final candidate = (p['sys_organization_id'] ?? p['organization_id'] ?? p['org_id'])?.toString();
            if (candidate != null && candidate.isNotEmpty) {
              sysOrgId = candidate;
              break;
            }
          }
        }
      } else if (storedProfiles is Map) {
        sysOrgId = (storedProfiles['sys_organization_id'] ?? storedProfiles['organization_id'])?.toString();
      }

      if (sysOrgId == null || sysOrgId.isEmpty) {
        final userData = storage.read('user_data');
        if (userData is Map) {
          sysOrgId = (userData['sys_organization_id'] ?? userData['organization_id'])?.toString();
        }
      }

      if (sysOrgId == null || sysOrgId.isEmpty) return null;

      final res = await getWithDio(
        ApiConfig.hospitalsList,
        queryParams: {
          'filter__sys_organization_id': sysOrgId,
          'limit': 1,
          'page': 0,
        },
      );

      if (res.success) {
        final data = res.data;
        if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = Map<String, dynamic>.from(data['data'][0] as Map);
          return first['id']?.toString() ?? first['_id']?.toString();
        }
        if (data is List && data.isNotEmpty) {
          final first = Map<String, dynamic>.from(data.first as Map);
          return first['id']?.toString() ?? first['_id']?.toString();
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> findDeliveredByCode(String code) async {
    final hid = await _getDefaultHospitalId();
    if (hid == null || hid.isEmpty) return null;
    final res = await getWithDio(ApiConfig.deliveriesForHospitalDelivered(hid));
    if (!res.success) return null;
    final data = res.data;
    List<dynamic> list = [];
    if (data is Map && data['data'] is List) {
      list = List<dynamic>.from(data['data'] as List);
    } else if (data is List) {
      list = List<dynamic>.from(data);
    }
    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final deliveryCode = (m['delivery_code'] ?? m['code'] ?? '').toString();
        if (deliveryCode == code) return m;
      }
    }
    return null;
  }

  Future<IApiResponse> receiveDelivery({required String deliveryId, required String code}) async {
    return await postWithDio(ApiConfig.receiveDelivery(deliveryId), body: {
      'delivery_code': code,
    });
  }
}

