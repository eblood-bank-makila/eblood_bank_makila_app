import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../apps/config/api/ApiConfig.dart';
import '../../../../apps/config/api/dio_client.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/service/blood_request/BloodRequestNetworkService.dart';

class BloodRequestNetworkServiceImpl implements BloodRequestNetworkService {
  final String baseURL; // kept for backward compatibility, not used with Dio-based client

  BloodRequestNetworkServiceImpl(this.baseURL);

  @override
  Future<BloodRequestResponseModel?> getPendingDeliveryRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.pendingDelivery,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getInProgressDeliveryRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.inProgressDelivery,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getDeliveredRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.delivered,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getCompletedRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.completed,
      page,
      authToken,
    );
  }

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
    } catch (e) {
      debugPrint('Error resolving hospital id: $e');
    }
    return null;
  }

  @override
  Future<BloodRequestResponseModel?> getBloodRequestsByStatus(
    BloodRequestStatus status,
    int page,
    String authToken,
  ) async {
    try {
      final hospitalId = await _getDefaultHospitalId();
      final bool isHospitalContext = hospitalId != null && hospitalId.isNotEmpty;
      final endpoint = isHospitalContext
          ? ApiConfig.hospitalBloodRequestsList
          : ApiConfig.bankBloodRequestsList;

      // Build query parameters; send multiple keys to be compatible with various backends
      const int limit = 20;
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': status.value,
        'delivery_status': status.value,
        'blood_request_status': status.value,

      };

      debugPrint('🚀 Fetching blood requests: $endpoint');
      debugPrint('📄 Status: ${status.displayName}');
      debugPrint('📄 Page: $page');

      final res = await getWithDio(endpoint, queryParams: query);
      if (!res.success) {
        return BloodRequestResponseModel(
          success: false,
          message: res.message ?? 'Request failed',
          data: [],
          currentPage: page,
          totalPages: 0,
          totalItems: 0,
        );
      }

      // Extract list data safely
      List<dynamic> list = [];
      if (res.data is List) {
        list = List<dynamic>.from(res.data as List);
      } else if (res.data is Map && (res.data as Map).containsKey('data')) {
        final d = (res.data as Map)['data'];
        if (d is List) list = List<dynamic>.from(d);
      }

      final items = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(BloodRequestModel.fromJson)
          .toList();

      final total = res.total ?? 0;
      final currentPage = res.page ?? page;
      final usedLimit = res.limit ?? limit;
      final totalPages = usedLimit > 0 ? ((total + usedLimit - 1) / usedLimit).floor() : 0;

      return BloodRequestResponseModel(
        success: true,
        message: 'OK',
        data: items,
        currentPage: currentPage,
        totalPages: totalPages,
        totalItems: total,
      );
    } catch (e) {
      debugPrint('💥 Exception during blood request fetch: $e');
      return BloodRequestResponseModel(
        success: false,
        message: 'Erreur de connexion: $e',
        data: [],
      );
    }
  }
}
