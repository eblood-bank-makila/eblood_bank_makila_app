import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/rbac/enums/collection_crud_info_flag.dart';
import '../../../../core/rbac/models/rbac_models.dart';
import '../../../../core/rbac/providers/rbac_provider.dart';
import '../../../../core/rbac/services/rbac_guard.dart';
import '../../../../core/rbac/services/rbac_url_helper.dart';
import '../../../business/models/org_management_models.dart';
import '../../../business/service/OrgManagementService.dart';
import 'org_role_permissions_sheet.dart';

class OrgRolesPage extends ConsumerStatefulWidget {
  const OrgRolesPage({super.key});

  @override
  ConsumerState<OrgRolesPage> createState() => _OrgRolesPageState();
}

class _OrgRolesPageState extends ConsumerState<OrgRolesPage> {
  final OrgManagementService _service = OrgManagementService();
  late final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  List<RbacRoleModel> _roles = [];
  List<RbacRoleModel> _filteredRoles = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  String _fetchUrl = '';
  String _deleteUrl = '';
  String _createUrl = '';
  String _updatePermUrl = '';
  String _updatePermHeadUrl = '';

  @override
  void initState() {
    super.initState();
    guardPageEntry(ref, context, 'flutter_apps_eblood_bank_profile_roles');
    _crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_profile_roles',
    );
    _resolveRbacUrls();
    _fetchRoles();
    _searchController.addListener(_filterRoles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resolveRbacUrls() {
    _fetchUrl = _urlHelper.getRbacUrl(
      CollectionCrudInfoFlag.fetchUrl, 'main', _crudInfo,
    );
    _deleteUrl = _urlHelper.getRbacUrl(
      CollectionCrudInfoFlag.deleteProcessingUrl, 'main', _crudInfo,
    );
    _createUrl = _urlHelper.getRbacUrl(
      CollectionCrudInfoFlag.createProcessingUrl, 'main', _crudInfo,
    );
    _updatePermUrl = _urlHelper.getRbacUrl(
      CollectionCrudInfoFlag.updateProcessingUrl,
      'custom_update_role_permissions_process_url',
      _crudInfo,
    );
    _updatePermHeadUrl = _urlHelper.getRbacUrl(
      CollectionCrudInfoFlag.fetchUrl,
      'fetch_role_permissions_url',
      _crudInfo,
    );
  }

  Future<void> _fetchRoles() async {
    if (_fetchUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'URL de chargement non disponible';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final roles = await _service.fetchRoles(_fetchUrl);
      if (mounted) {
        setState(() {
          _roles = roles;
          _filteredRoles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterRoles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRoles = _roles;
      } else {
        _filteredRoles = _roles.where((r) {
          return r.name.toLowerCase().contains(query) ||
              (r.description?.toLowerCase().contains(query) ?? false) ||
              (r.profileName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _showCreateRoleSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
              ),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'create_role'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'role_name'.tr,
                        prefixIcon: const Icon(Iconsax.shield_tick),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'field_required'.tr : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'role_description'.tr,
                        prefixIcon: const Icon(Iconsax.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => submitting = true);
                                try {
                                  await _service.createRole(_createUrl, {
                                    'name': nameController.text.trim(),
                                    'description_str':
                                        descController.text.trim(),
                                  });
                                  if (mounted) {
                                    Navigator.pop(sheetCtx);
                                    _fetchRoles();
                                  }
                                } catch (e) {
                                  setSheetState(() => submitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Iconsax.add),
                        label: Text(submitting ? 'loading'.tr : 'create_role'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPermissionsSheet(RbacRoleModel role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrgRolePermissionsSheet(
        role: role,
        updateUrl: _updatePermUrl,
        headUrl: _updatePermHeadUrl,
        service: _service,
      ),
    );
  }

  Future<void> _deleteRole(RbacRoleModel role) async {
    if (_deleteUrl.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_role'.tr),
        content: Text('${'delete_confirmation'.tr} ${role.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteRole(_deleteUrl, role.id);
      _fetchRoles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'roles_management'.tr,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchRoles,
            icon: const Icon(Iconsax.refresh),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      floatingActionButton: _createUrl.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showCreateRoleSheet,
              tooltip: 'create_role'.tr,
              child: const Icon(Iconsax.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_roles'.tr,
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor:
                    isDark ? colorScheme.surfaceContainerHigh : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(child: _buildBody(colorScheme, isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchRoles,
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }
    if (_filteredRoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.shield_tick,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'no_search_results'.tr
                  : 'no_roles_found'.tr,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRoles,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredRoles.length,
        itemBuilder: (context, index) =>
            _buildRoleCard(_filteredRoles[index], colorScheme, isDark),
      ),
    );
  }

  Widget _buildRoleCard(
      RbacRoleModel role, ColorScheme colorScheme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Iconsax.shield_tick,
                  size: 20, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (role.profileName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      role.profileName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (role.description != null &&
                      role.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      role.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (_deleteUrl.isNotEmpty || _updatePermUrl.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onSelected: (value) {
                  if (value == 'permissions') _showPermissionsSheet(role);
                  if (value == 'delete') _deleteRole(role);
                },
                itemBuilder: (context) => [
                  if (_updatePermUrl.isNotEmpty)
                    PopupMenuItem(
                      value: 'permissions',
                      child: Row(
                        children: [
                          Icon(Iconsax.security_safe,
                              size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('configure_permissions'.tr,
                              style: TextStyle(color: colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  if (_updatePermUrl.isNotEmpty && _deleteUrl.isNotEmpty)
                    const PopupMenuDivider(),
                  if (_deleteUrl.isNotEmpty)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text('delete'.tr,
                              style: TextStyle(color: colorScheme.error)),
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
}
