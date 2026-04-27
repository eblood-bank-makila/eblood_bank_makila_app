/// Model representing an RBAC role.
class RbacRoleModel {
  final String id;
  final String? identifier;
  final String name;
  final String? description;
  final String? profileName;
  final String? profileId;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RbacRoleModel({
    required this.id,
    required this.name,
    this.identifier,
    this.description,
    this.profileName,
    this.profileId,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory RbacRoleModel.fromJson(Map<String, dynamic> json) {
    final profile = json['sys_profil'];
    String? profileName;
    String? profileId;
    if (profile is Map<String, dynamic>) {
      profileName = profile['name']?.toString();
      profileId = profile['id']?.toString();
    }

    return RbacRoleModel(
      id: json['id']?.toString() ?? '',
      identifier: json['identifier']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description_str']?.toString(),
      profileName: profileName ?? json['profile_name']?.toString(),
      profileId: profileId ?? json['sys_profil_id']?.toString() ?? json['rbac_profile_id']?.toString(),
      isDeleted: json['is_deleted'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

/// A single permission item within a title group.
class RbacPermissionItem {
  final String id;
  final String label;
  final String? description;
  final String? identifier;
  final bool isJoined; // role_and_permission_are_joined

  const RbacPermissionItem({
    required this.id,
    required this.label,
    this.description,
    this.identifier,
    required this.isJoined,
  });

  factory RbacPermissionItem.fromJson(Map<String, dynamic> json) {
    String _val(dynamic field) =>
        (field is Map) ? (field['display_value']?.toString() ?? '') : (field?.toString() ?? '');
    return RbacPermissionItem(
      id: _val(json['id']),
      label: _val(json['label']),
      description: _val(json['description_str']),
      identifier: _val(json['identifier']),
      isJoined: json['role_and_permission_are_joined'] == true,
    );
  }
}

/// A tree node grouping permissions under a title, with optional children.
class RbacTitlePermissionGroup {
  final String titleId;
  final String titleName;
  final List<RbacPermissionItem> permissions;
  final List<RbacTitlePermissionGroup> children;

  const RbacTitlePermissionGroup({
    required this.titleId,
    required this.titleName,
    required this.permissions,
    required this.children,
  });

  factory RbacTitlePermissionGroup.fromJson(Map<String, dynamic> json) {
    String _val(dynamic field) =>
        (field is Map) ? (field['display_value']?.toString() ?? '') : (field?.toString() ?? '');
    final title = json['rbac_title'];
    return RbacTitlePermissionGroup(
      titleId: title is Map ? _val(title['id']) : '',
      titleName: title is Map ? _val(title['label']) : '',
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((p) => RbacPermissionItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => RbacTitlePermissionGroup.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalPermissions =>
      permissions.length +
      children.fold(0, (sum, c) => sum + c.totalPermissions);
}
