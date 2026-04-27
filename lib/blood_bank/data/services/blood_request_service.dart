import 'package:dio/dio.dart';
import 'package:eblood_bank_mak_app/core/rbac/models/rbac_models.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_url_helper.dart';
import '../../../apps/config/api/dio_client.dart';
import '../models/blood_request_model.dart';

/// Service for fetching blood requests from the backend
class BloodRequestService {
  /// App-level crudInfo for list endpoint (flutter_apps_eblood_bank_blood_bank_requests_app)
  final List<RbacCollectionCrudItem> _appCrudInfo;

  /// Menu-level crudInfo for detail/confirm endpoints (flutter_apps_eblood_bank_bb_requests_detail)
  final List<RbacCollectionCrudItem> _detailCrudInfo;

  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  BloodRequestService(this._appCrudInfo, this._detailCrudInfo);
  /// Fetch blood requests with optional filters
  Future<BloodRequestsResponse> getBloodRequests({
    String? statusFilter,
    String? urgencyLevel,
    String? requestType,
    String? searchQuery,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['status_filter'] = statusFilter;
      }
      if (urgencyLevel != null && urgencyLevel.isNotEmpty) {
        queryParams['urgency_level'] = urgencyLevel;
      }
      if (requestType != null && requestType.isNotEmpty) {
        queryParams['request_type'] = requestType;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }

      print('🔍 Fetching blood requests with params: $queryParams');

      // Use dio_client for automatic auth header injection
      final response = await getWithDio(
        _urlHelper.getFetchUrl(_appCrudInfo),
        queryParams: queryParams,
      );

      print('📡 Blood requests response: ${response.statusCode}');
      print('📄 Response success: ${response.success}');

      if (response.success && response.data != null) {
        // The response.data already contains {data: [], total: 0, page: 0, limit: 20}
        final responseData = response.data as Map<String, dynamic>;

        final items = (responseData['data'] as List<dynamic>? ?? []);
        final parsed = items
            .whereType<Map<String, dynamic>>()
            .map(BloodRequestModel.fromApiJson)
            .toList();

        final total = (responseData['total'] as num?)?.toInt() ?? parsed.length;
        final pageResp = (responseData['page'] as num?)?.toInt() ?? page;
        final limitResp = (responseData['limit'] as num?)?.toInt() ?? limit;

        print('✅ Blood requests fetched successfully: $total total');
        return BloodRequestsResponse(
          data: parsed,
          total: total,
          page: pageResp,
          limit: limitResp,
        );
      } else {
        throw Exception(response.message ?? 'Failed to fetch blood requests');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching blood requests: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error fetching blood requests: $e');
      rethrow;
    }
  }

  /// Fetch a single blood request by ID
  Future<BloodRequestModel> getBloodRequestById(String requestId) async {
    try {
      print('🔍 Fetching blood request by ID: $requestId');

      final response = await getWithDio(
        _urlHelper.getFetchOneInfoUrl(_detailCrudInfo),
        queryParams: {'item_id': requestId},
      );

      print('📡 Blood request response: ${response.statusCode}');

      if (response.success && response.data != null) {
        final responseData = response.data['data'] as Map<String, dynamic>?;
        
        if (responseData != null) {
          print('✅ Blood request fetched successfully');
          return BloodRequestModel.fromApiJson(responseData);
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception(response.message ?? 'Failed to fetch blood request');
      }
    } on DioException catch (e) {
      print('❌ Dio error fetching blood request: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error fetching blood request: $e');
      rethrow;
    }
  }

  /// Confirm pickup of blood request by delivery person
  Future<BloodRequestModel> confirmPickup(String requestId) async {
    try {
      print('📦 Confirming pickup for request: $requestId');

      final response = await putWithDio(
        _urlHelper.getUpdateProcessingUrl(_detailCrudInfo, 'confirm_pickup_url'),
        queryParams: {'item_id': requestId},
        body: {
          'status': 'picked_up_from_blood_bank',
        },
      );

      print('📡 Confirm pickup response: ${response.statusCode}');

      if (response.success && response.data != null) {
        final responseData = response.data['data'] as Map<String, dynamic>?;

        if (responseData != null) {
          print('✅ Pickup confirmed successfully');
          return BloodRequestModel.fromApiJson(responseData);
        } else {
          throw Exception('Response data is null');
        }
      } else {
        throw Exception(response.message ?? 'Failed to confirm pickup');
      }
    } on DioException catch (e) {
      print('❌ Dio error confirming pickup: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error confirming pickup: $e');
      rethrow;
    }
  }
}

