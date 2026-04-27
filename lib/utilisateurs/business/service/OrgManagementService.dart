import 'package:flutter/foundation.dart';
import '../../../apps/config/api/dio_client.dart';
import '../models/org_management_models.dart';

/// Service for managing organization roles and role permissions.
/// URLs are resolved at the page layer via RBAC and passed in.
class OrgManagementService {
  // ──────────────────────────────────────────────────
  // Roles
  // ──────────────────────────────────────────────────

  Future<List<RbacRoleModel>> fetchRoles(String fetchUrl) async {
    try {
      final response = await getWithDio(fetchUrl, queryParams: {
        'output_data_type': 'default',
        'page': 0,
        'limit': 20,
        'all_data': true,
      });
      if (response.success && response.data is List) {
        final List<dynamic> list = response.data as List<dynamic>;
        return list
            .map((json) =>
                RbacRoleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching roles: $e');
      rethrow;
    }
  }

  Future<bool> createRole(String createUrl, Map<String, dynamic> body) async {
    try {
      final response = await postWithDio(createUrl, body: body);
      return response.success;
    } catch (e) {
      debugPrint('Error creating role: $e');
      rethrow;
    }
  }

  Future<bool> deleteRole(String deleteUrl, String roleId) async {
    try {
      final response = await deleteWithDio(
        deleteUrl,
        queryParams: {'item_id': roleId},
      );
      return response.success;
    } catch (e) {
      debugPrint('Error deleting role: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────
  // Role Permissions
  // ──────────────────────────────────────────────────

  Future<List<RbacTitlePermissionGroup>> fetchRolePermissions(
      String headUrl, String roleId) async {
    try {
      final response = await getWithDio(headUrl, queryParams: {
        'output_data_type': 'data_table',
        'all_data': false,
        'page': 0,
        'rbac_role_id': roleId,
      });
      if (response.success && response.data is List) {
        return (response.data as List<dynamic>)
            .map((e) => RbacTitlePermissionGroup.fromJson(
                e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching role permissions: $e');
      rethrow;
    }
  }

  Future<bool> updateRolePermissions(
      String updateUrl, String roleId, List<String> permissionIds) async {
    try {
      final response = await putWithDio(updateUrl, body: {
        'rbac_role_id': roleId,
        'rbac_permissions': permissionIds,
      });
      return response.success;
    } catch (e) {
      debugPrint('Error updating role permissions: $e');
      rethrow;
    }
  }
}
