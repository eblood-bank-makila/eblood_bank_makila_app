import 'package:get_storage/get_storage.dart';

import '../config/api/dio_client.dart';
import '../models/api_response.dart';
import '../config/api/ApiConfig.dart';

class HospitalInventoryService {
  static final HospitalInventoryService _instance = HospitalInventoryService._internal();
  factory HospitalInventoryService() => _instance;
  HospitalInventoryService._internal();

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

