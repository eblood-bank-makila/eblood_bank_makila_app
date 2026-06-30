import 'package:flutter/foundation.dart';
import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../core/rbac/models/rbac_models.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';

class UserDevicesNetworkServiceImpl {
  final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  UserDevicesNetworkServiceImpl(this._crudInfo);

  Future<IApiResponse> listDevices({int page = 0, int limit = 20, bool allData = false}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo);
      if (kDebugMode) print('[DevicesService] listDevices → $url');
      return await getWithDio(url, queryParams: {
        'output_data_type': 'default',
        'page': page,
        'limit': limit,
        'all_data': allData,
      });
    } catch (e) {
      return IApiResponse.error('List devices error: $e');
    }
  }

  Future<IApiResponse> validateDevice(String deviceId) async {
    try {
      final baseUrl = _urlHelper.getUpdateProcessingUrl(_crudInfo);
      final url = '$baseUrl?item_id=$deviceId';
      if (kDebugMode) print('[DevicesService] validateDevice → $url');
      return await putWithDio(url, body: {
        'status': 'allowed',
      });
    } catch (e) {
      return IApiResponse.error('Validate device error: $e');
    }
  }

  Future<IApiResponse> lockUnlockDevice(String deviceId, String newStatus) async {
    try {
      final baseUrl = _urlHelper.getUpdateProcessingUrl(_crudInfo);
      final url = '$baseUrl?item_id=$deviceId';
      if (kDebugMode) print('[DevicesService] lockUnlockDevice → $url');
      return await putWithDio(url, body: {
        'status': newStatus,
      });
    } catch (e) {
      return IApiResponse.error('Lock/unlock device error: $e');
    }
  }

  Future<IApiResponse> deleteDevice(String deviceId) async {
    try {
      final url = _urlHelper.getDeleteProcessingUrl(_crudInfo);
      if (kDebugMode) print('[DevicesService] deleteDevice → $url');
      return await deleteWithDio('$url?item_id=$deviceId');
    } catch (e) {
      return IApiResponse.error('Delete device error: $e');
    }
  }

  Future<IApiResponse> updateAllowedDeviceCount(String userId, int count) async {
    try {
      final url = _urlHelper.getUpdateProcessingUrl(
        _crudInfo,
        'custom_all_user_device_count_update_process_url',
      );
      if (kDebugMode) print('[DevicesService] updateAllowedDeviceCount → $url');
      return await putWithDio(url, body: {
        'user_id': userId,
        'allowed_device_count': count,
      });
    } catch (e) {
      return IApiResponse.error('Update device count error: $e');
    }
  }
}
