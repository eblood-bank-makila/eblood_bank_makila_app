import 'package:get_storage/get_storage.dart';

import '../config/api/dio_client.dart';
import '../models/api_response.dart';
import '../config/api/ApiConfig.dart';

class HospitalInventoryService {
  static final HospitalInventoryService _instance = HospitalInventoryService._internal();
  factory HospitalInventoryService() => _instance;
  HospitalInventoryService._internal();

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
    } catch (e) {
      return null;
    }
  }

  Future<IApiResponse> listItems({String? status, int page = 0, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    return await getWithDio(ApiConfig.inventoryItemsList, queryParams: params);
  }

  Future<IApiResponse> markAsExpired(String itemId) async {
    return await putWithDio(ApiConfig.inventoryItemUpdate(itemId), body: {
      'status': 'expired',
    });
  }

  Future<IApiResponse> markAsTransfused(String itemId, {required String patientId}) async {
    // Derive current user id for auditing if available
    final storage = GetStorage();
    String? userId;
    final userData = storage.read('user_data');
    if (userData is Map) {
      userId = (userData['id'] ?? userData['_id'])?.toString();
    }

    final body = <String, dynamic>{
      'patient_id': patientId,
    };
    if (userId != null && userId.isNotEmpty) {
      body['administered_by'] = userId;
      body['ordered_by'] = userId;
    }

    return await postWithDio(ApiConfig.inventoryItemTransfuse(itemId), body: body);
  }
}

