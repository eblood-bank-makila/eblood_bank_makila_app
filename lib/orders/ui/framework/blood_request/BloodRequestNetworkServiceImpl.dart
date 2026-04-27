import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../apps/config/api/ApiConfig.dart';
import '../../../../apps/config/api/dio_client.dart';
import '../../../../apps/models/api_response.dart';

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

  /// Determines if the current user is a hospital account
  Future<bool> _isHospitalAccount() async {
    try {
      final storage = GetStorage();

      // Check user_profiles for account type flags
      final dynamic storedProfiles = storage.read('user_profiles') ?? storage.read('user_profils');
      if (storedProfiles is List && storedProfiles.isNotEmpty) {
        final flags = storedProfiles
            .whereType<Map>()
            .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toSet();

        // Hospital has priority over blood bank in this check
        if (flags.contains('mobile_app_health_structure_profil')) {
          debugPrint('🏥 Account type: Hospital (from profiles)');
          return true;
        }
        if (flags.contains('mobile_app_blood_bank_profil')) {
          debugPrint('🩸 Account type: Blood Bank (from profiles)');
          return false;
        }
      }

      // Fallback: check stored account_type
      final accountType = (storage.read('account_type') as String?)?.toLowerCase() ?? '';
      if (accountType.contains('hospital') || accountType.contains('hopital') || accountType.contains('hôpital')) {
        debugPrint('🏥 Account type: Hospital (from account_type)');
        return true;
      }
      if (accountType.contains('blood_bank') || accountType.contains('bloodbank') || accountType.contains('banque')) {
        debugPrint('🩸 Account type: Blood Bank (from account_type)');
        return false;
      }

      // Default to hospital if unclear
      debugPrint('⚠️ Account type unclear, defaulting to Hospital');
      return true;
    } catch (e) {
      debugPrint('❌ Error determining account type: $e');
      return true; // Default to hospital
    }
  }

  @override
  Future<BloodRequestResponseModel?> getBloodRequestsByStatus(
    BloodRequestStatus status,
    int page,
    String authToken,
  ) async {
    try {
      // Determine account type to use correct endpoint
      final bool isHospital = await _isHospitalAccount();
      final endpoint = isHospital
          ? ApiConfig.hospitalBloodRequestsList  // /blood-requests/fetch/blood-requests
          : ApiConfig.bankBloodRequestsList;     // /eblood-connect/blood-requests/list

      // Build query parameters
      const int limit = 20;
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        // Always add status filter for all statuses
        'status_filter': status.value,
      };

      debugPrint('🚀 Fetching blood requests');
      debugPrint('   Account type: ${isHospital ? "Hospital" : "Blood Bank"}');
      debugPrint('   Endpoint: $endpoint');
      debugPrint('   Status: ${status.displayName} (${status.value})');
      debugPrint('   Page: $page');
      debugPrint('   Query params: $query');

      final res = await getWithDio(endpoint, queryParams: query);

      debugPrint('📡 Response received:');
      debugPrint('   Success: ${res.success}');
      debugPrint('   Status code: ${res.statusCode}');

      if (!res.success) {
        debugPrint('❌ Request failed: ${res.message}');
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

      debugPrint('📊 Parsing ${list.length} blood requests');

      final items = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(BloodRequestModel.fromJson)
          .toList();

      final total = res.total ?? list.length;
      final currentPage = res.page ?? page;
      final usedLimit = res.limit ?? limit;
      final totalPages = usedLimit > 0 ? ((total + usedLimit - 1) / usedLimit).floor() : 0;

      debugPrint('✅ Blood requests fetched successfully');
      debugPrint('   Total items: $total');
      debugPrint('   Current page: $currentPage');
      debugPrint('   Total pages: $totalPages');
      debugPrint('   Items in this page: ${items.length}');

      return BloodRequestResponseModel(
        success: true,
        message: 'OK',
        data: items,
        currentPage: currentPage,
        totalPages: totalPages,
        totalItems: total,
      );
    } catch (e, stackTrace) {
      debugPrint('💥 Exception during blood request fetch: $e');
      debugPrint('Stack trace: $stackTrace');
      return BloodRequestResponseModel(
        success: false,
        message: 'Erreur de connexion: $e',
        data: [],
      );
    }

  }


  @override
  Future<IApiResponse> confirmDelivery(
    String requestId,
    String verificationCode,
    String confirmationMethod,
  ) async {
    try {
      final endpoint = ApiConfig.confirmDeliveryForRequest(requestId);
      final res = await postWithDio(
        endpoint,
        body: {
          'verification_code': verificationCode,
          'confirmation_method': confirmationMethod,
        },
      );
      return IApiResponse.fromData(res);
    } catch (e) {
      debugPrint('💥 confirmDelivery error: $e');
      return IApiResponse.error('Erreur: $e');
    }
  }

  @override
  Future<IApiResponse> markBloodBagUsed(
    String bloodBagRequestId, {
    String? patientId,
    String? usageNotes,
  }) async {
    try {
      final endpoint = ApiConfig.markBloodBagUsedFor(bloodBagRequestId);
      final body = <String, dynamic>{};
      if (patientId != null && patientId.isNotEmpty) body['patient_id'] = patientId;
      if (usageNotes != null && usageNotes.isNotEmpty) body['usage_notes'] = usageNotes;
      final res = await postWithDio(endpoint, body: body);
      return IApiResponse.fromData(res);
    } catch (e) {
      debugPrint('💥 markBloodBagUsed error: $e');
      return IApiResponse.error('Erreur: $e');
    }
  }

  @override
  Future<IApiResponse> requestCoolboxPassword(String deliveryId) async {
    try {
      final endpoint = ApiConfig.requestCoolboxPasswordForDelivery(deliveryId);
      final res = await postWithDio(endpoint);
      return IApiResponse.fromData(res);
    } catch (e) {
      debugPrint('💥 requestCoolboxPassword error: $e');
      return IApiResponse.error('Erreur: $e');
    }
  }

}
