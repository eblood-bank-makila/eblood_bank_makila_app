import 'package:flutter/foundation.dart';
import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../core/rbac/models/rbac_models.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';

class RolesNetworkServiceImpl {
  final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  RolesNetworkServiceImpl(this._crudInfo);

  Future<IApiResponse> listRoles({int page = 0, int limit = 20, bool allData = false}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo);
      if (kDebugMode) print('[RolesService] listRoles → $url');
      return await getWithDio(url, queryParams: {
        'output_data_type': 'default',
        'page': page,
        'limit': limit,
        'all_data': allData,
      });
    } catch (e) {
      return IApiResponse.error('List roles error: $e');
    }
  }

  Future<IApiResponse> listProfiles({int page = 0, int limit = 50}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_rbac_profiles_url');
      if (kDebugMode) print('[RolesService] listProfiles → $url');
      return await getWithDio(url, queryParams: {
        'output_data_type': 'default',
        'page': page,
        'limit': limit,
        'all_data': true,
      });
    } catch (e) {
      return IApiResponse.error('List profiles error: $e');
    }
  }

  Future<IApiResponse> fetchMainProfile() async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_organization_main_profil_url');
      if (kDebugMode) print('[RolesService] fetchMainProfile → $url');
      return await getWithDio(url);
    } catch (e) {
      return IApiResponse.error('Fetch main profile error: $e');
    }
  }

  Future<IApiResponse> createRole(Map<String, dynamic> roleData) async {
    try {
      final url = _urlHelper.getCreateProcessingUrl(_crudInfo);
      if (kDebugMode) print('[RolesService] createRole → $url');
      return await postWithDio(url, body: roleData);
    } catch (e) {
      return IApiResponse.error('Create role error: $e');
    }
  }

  Future<IApiResponse> updateRole(String roleId, Map<String, dynamic> updateData) async {
    try {
      final baseUrl = _urlHelper.getUpdateProcessingUrl(_crudInfo);
      final url = '$baseUrl?item_id=$roleId';
      if (kDebugMode) print('[RolesService] updateRole → $url');
      return await putWithDio(url, body: updateData);
    } catch (e) {
      return IApiResponse.error('Update role error: $e');
    }
  }

  Future<IApiResponse> deleteRole(String roleId) async {
    try {
      final url = _urlHelper.getDeleteProcessingUrl(_crudInfo);
      if (kDebugMode) print('[RolesService] deleteRole → $url');
      return await deleteWithDio(url, queryParams: {'item_id': roleId});
    } catch (e) {
      return IApiResponse.error('Delete role error: $e');
    }
  }

  Future<IApiResponse> getRolePermissions(String roleId, {int page = 0, bool allData = false}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_role_permissions_url');
      if (kDebugMode) print('[RolesService] getRolePermissions → $url');
      return await getWithDio(url, queryParams: {
        'output_data_type': 'data_table',
        'all_data': allData,
        'page': page,
        'rbac_role_id': roleId,
      });
    } catch (e) {
      return IApiResponse.error('Get role permissions error: $e');
    }
  }

  Future<IApiResponse> updateRolePermissions(String roleId, Map<String, dynamic> permissionsData) async {
    try {
      final url = _urlHelper.getUpdateProcessingUrl(
        _crudInfo,
        'custom_update_role_permissions_process_url',
      );
      if (kDebugMode) print('[RolesService] updateRolePermissions → $url');
      return await putWithDio(url, body: {
        'rbac_role_id': roleId,
        ...permissionsData,
      });
    } catch (e) {
      return IApiResponse.error('Update role permissions error: $e');
    }
  }
}
