import 'package:flutter/foundation.dart';
import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../core/rbac/models/rbac_models.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';
import 'UserNetworkService.dart';

class UserNetworkServiceImpl implements UserNetworkService {
  final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  UserNetworkServiceImpl(this._crudInfo);

  @override
  Future<IApiResponse> listUsers({int page = 0, int limit = 20, String? searchQuery}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo);
      if (kDebugMode) print('[UserService] listUsers → $url');
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        params['search_key'] = searchQuery;
      }
      return await getWithDio(url, queryParams: params);
    } catch (e) {
      return IApiResponse.error('List users error: $e');
    }
  }

  @override
  Future<IApiResponse> createUser(Map<String, dynamic> userData) async {
    try {
      final url = _urlHelper.getCreateProcessingUrl(_crudInfo);
      if (kDebugMode) print('[UserService] createUser → $url');
      return await postWithDio(url, body: userData);
    } catch (e) {
      return IApiResponse.error('Create user error: $e');
    }
  }

  @override
  Future<IApiResponse> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      final baseUrl = _urlHelper.getUpdateProcessingUrl(_crudInfo);
      final url = '$baseUrl?item_id=$userId';
      if (kDebugMode) print('[UserService] updateUser → $url');
      return await putWithDio(url, body: updateData);
    } catch (e) {
      return IApiResponse.error('Update user error: $e');
    }
  }

  @override
  Future<IApiResponse> deleteUser(String userId) async {
    try {
      final url = _urlHelper.getDeleteProcessingUrl(_crudInfo);
      if (kDebugMode) print('[UserService] deleteUser → $url');
      return await deleteWithDio(url, queryParams: {
        'item_id': userId,
      });
    } catch (e) {
      return IApiResponse.error('Delete user error: $e');
    }
  }

  @override
  Future<IApiResponse> getRoles() async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_config_roles_url');
      if (kDebugMode) print('[UserService] getRoles → $url');
      return await getWithDio(url, queryParams: {
        'limit': 100,
        'page': 0,
      });
    } catch (e) {
      return IApiResponse.error('Get roles error: $e');
    }
  }

  Future<IApiResponse> resetPassword(Map<String, dynamic> data) async {
    try {
      final url = _urlHelper.getCreateProcessingUrl(
        _crudInfo,
        'password_reset_link_generation_process_url',
      );
      if (kDebugMode) print('[UserService] resetPassword → $url');
      return await postWithDio(url, body: data);
    } catch (e) {
      return IApiResponse.error('Reset password error: $e');
    }
  }

  Future<IApiResponse> fetchProfiles() async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_rbac_profiles_url');
      if (kDebugMode) print('[UserService] fetchProfiles → $url');
      return await getWithDio(url, queryParams: {
        'all_data': 'true',
        'output_data_type': 'data_table',
      });
    } catch (e) {
      return IApiResponse.error('Fetch profiles error: $e');
    }
  }

  Future<IApiResponse> fetchCreateHead() async {
    try {
      final url = _urlHelper.getCreateHeadProcessUrl(_crudInfo);
      if (kDebugMode) print('[UserService] fetchCreateHead → $url');
      return await getWithDio(url);
    } catch (e) {
      return IApiResponse.error('Fetch create head error: $e');
    }
  }
}
