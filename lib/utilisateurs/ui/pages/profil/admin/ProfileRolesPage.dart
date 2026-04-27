import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../../core/rbac/services/rbac_guard.dart';
import '../../../../../core/rbac/providers/rbac_provider.dart';
import '../../../../../core/rbac/services/rbac_url_helper.dart';
import '../../../../../core/rbac/enums/collection_crud_info_flag.dart';
import '../../../../../core/rbac/models/rbac_models.dart';
import '../../../../business/service/RolesNetworkServiceImpl.dart';
import 'RolePermissionsPage.dart';

class ProfileRolesPage extends ConsumerStatefulWidget {
  const ProfileRolesPage({super.key});

  @override
  ConsumerState<ProfileRolesPage> createState() => _ProfileRolesPageState();
}

class _ProfileRolesPageState extends ConsumerState<ProfileRolesPage> {
  late final RolesNetworkServiceImpl _service;
  late final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _canCreate => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.createProcessingUrl, 'main', _crudInfo);
  bool get _canEdit => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.updateProcessingUrl, 'main', _crudInfo);
  bool get _canDelete => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.deleteProcessingUrl, 'main', _crudInfo);
  bool get _canConfigurePermissions => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.fetchUrl, 'fetch_role_permissions_url', _crudInfo);

  @override
  void initState() {
    super.initState();
    guardPageEntry(ref, context, 'flutter_apps_eblood_bank_profile_roles');
    _crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_profile_roles',
    );
    _service = RolesNetworkServiceImpl(_crudInfo);
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final resp = await _service.listRoles(allData: true);
      if (!mounted) return;
      if (resp.success) {
        final data = resp.data;
        List<dynamic> items;
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        } else {
          items = const [];
        }
        setState(() {
          _roles = items.whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = resp.message ?? 'error_loading_data'.tr;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchRoles();
  }

  String _getRoleName(Map<String, dynamic> role) {
    final name = role['name'];
    if (name is Map) {
      return name['display_value']?.toString() ?? '';
    }
    if (name is String) return name;
    return '';
  }

  String _getRoleDescription(Map<String, dynamic> role) {
    return role['description_str']?.toString() ?? '';
  }

  void _showRoleBottomSheet({Map<String, dynamic>? existingRole}) {
    final nameController = TextEditingController(
      text: existingRole != null ? _getRoleName(existingRole) : '',
    );
    final descController = TextEditingController(
      text: existingRole != null ? _getRoleDescription(existingRole) : '',
    );
    final formKey = GlobalKey<FormState>();
    final isEditing = existingRole != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        isEditing ? 'edit_role'.tr : 'create_role'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditing
                            ? 'edit_role_description'.tr
                            : 'create_role_description'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      Text(
                        'role_name'.tr,
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: GoogleFonts.ubuntu(),
                        decoration: InputDecoration(
                          hintText: 'enter_role_name'.tr,
                          hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Iconsax.shield_tick, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'field_required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      Text(
                        'description'.tr,
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descController,
                        style: GoogleFonts.ubuntu(),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'enter_role_description'.tr,
                          hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade400),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Iconsax.document_text, size: 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('cancel'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _onSaveRole(
                                ctx,
                                formKey,
                                nameController.text.trim(),
                                descController.text.trim(),
                                existingRole,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                isEditing ? 'save'.tr : 'create'.tr,
                                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSaveRole(
    BuildContext sheetContext,
    GlobalKey<FormState> formKey,
    String name,
    String description,
    Map<String, dynamic>? existingRole,
  ) async {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(sheetContext);

    try {
      final isEditing = existingRole != null;
      final body = <String, dynamic>{
        'name': name,
        'description_str': description,
      };

      final resp = isEditing
          ? await _service.updateRole(existingRole['_id'], body)
          : await _service.createRole(body);

      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'role_updated_successfully'.tr : 'role_created_successfully'.tr,
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRoles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'operation_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _onConfigurePermissions(Map<String, dynamic> role) {
    if (kDebugMode) print('[ProfileRolesPage] _onConfigurePermissions role keys: ${role.keys.toList()}');
    // Try common ID field names
    final rawId = role['_id'] ?? role['id'];
    String roleId;
    if (rawId is Map) {
      roleId = rawId['display_value']?.toString() ?? '';
    } else {
      roleId = rawId?.toString() ?? '';
    }
    final roleName = _getRoleName(role);
    if (kDebugMode) print('[ProfileRolesPage] roleId=$roleId, roleName=$roleName');
    if (roleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RolePermissionsPage(
          roleId: roleId,
          roleName: roleName,
          service: _service,
        ),
      ),
    );
  }

  Future<void> _onDeleteRole(Map<String, dynamic> role) async {
    final roleName = _getRoleName(role);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.trash, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_role'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '${'confirm_delete_role'.tr}\n\n$roleName',
          style: GoogleFonts.ubuntu(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('delete'.tr, style: GoogleFonts.ubuntu()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final resp = await _service.deleteRole(role['_id']);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('role_deleted_successfully'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRoles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'operation_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'roles_management'.tr,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showRoleBottomSheet(),
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
              icon: const Icon(Iconsax.add_circle),
              label: Text('create_role'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmerList();
    if (_hasError) return _buildErrorState();
    if (_roles.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 80, left: 12, right: 12),
        itemCount: _roles.length,
        itemBuilder: (context, index) => _buildRoleCard(_roles[index]),
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final roleName = _getRoleName(role);
    final description = _getRoleDescription(role);
    final flag = role['flag']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.shield_tick,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName.isNotEmpty ? roleName : 'unnamed_role'.tr,
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // if (flag.isNotEmpty) ...[
                  //   const SizedBox(height: 6),
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey.shade100,
                  //       borderRadius: BorderRadius.circular(6),
                  //     ),
                  //     child: Text(
                  //       flag,
                  //       style: GoogleFonts.ubuntu(
                  //         fontSize: 11,
                  //         color: Colors.grey.shade600,
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ),

            // Action menu
            if (_canConfigurePermissions || _canEdit || _canDelete)
              PopupMenuButton<String>(
                icon: Icon(Iconsax.more, color: Colors.grey.shade500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  switch (value) {
                    case 'permissions':
                      _onConfigurePermissions(role);
                      break;
                    case 'edit':
                      _showRoleBottomSheet(existingRole: role);
                      break;
                    case 'delete':
                      _onDeleteRole(role);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (_canConfigurePermissions)
                    PopupMenuItem(
                      value: 'permissions',
                      child: Row(
                        children: [
                          Icon(Iconsax.shield_tick, size: 18, color: Colors.green.shade600),
                          const SizedBox(width: 10),
                          Text('configure_permissions'.tr, style: GoogleFonts.ubuntu()),
                        ],
                      ),
                    ),
                  if (_canConfigurePermissions && (_canEdit || _canDelete))
                    const PopupMenuDivider(),
                  if (_canEdit)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Iconsax.edit_2, size: 18, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text('edit'.tr, style: GoogleFonts.ubuntu()),
                        ],
                      ),
                    ),
                  if (_canEdit && _canDelete)
                    const PopupMenuDivider(),
                  if (_canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 18, color: Colors.red.shade600),
                          const SizedBox(width: 10),
                          Text('delete'.tr, style: GoogleFonts.ubuntu(color: Colors.red.shade600)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: double.infinity, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'error_occurred'.tr,
              style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr, style: GoogleFonts.ubuntu()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.shield_cross, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'no_roles_found'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'pull_to_refresh'.tr,
                    style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
