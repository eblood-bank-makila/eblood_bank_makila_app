import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../../core/rbac/services/rbac_guard.dart';
import '../../../../business/service/RolesNetworkServiceImpl.dart';

class RolePermissionsPage extends ConsumerStatefulWidget {
  final String roleId;
  final String roleName;
  final RolesNetworkServiceImpl service;

  const RolePermissionsPage({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.service,
  });

  @override
  ConsumerState<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends ConsumerState<RolePermissionsPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _titleNodes = [];
  final Set<String> _selectedPermissionIds = {};
  final Set<String> _expandedTitleIds = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // RBAC guard — ensure user has the permissions fetch endpoint
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_profile_roles',
    );
    _loadPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final resp = await widget.service.getRolePermissions(widget.roleId);
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
        _titleNodes = items.whereType<Map<String, dynamic>>().toList();
        _selectedPermissionIds.clear();
        for (final node in _titleNodes) {
          _recursivePreSelect(node);
        }
        setState(() => _isLoading = false);
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

  void _recursivePreSelect(Map<String, dynamic> node) {
    final permissions = node['permissions'];
    if (permissions is List) {
      for (final perm in permissions) {
        if (perm is Map<String, dynamic>) {
          if (perm['role_and_permission_are_joined'] == true) {
            final id = _getDisplayValue(perm, 'id');
            if (id.isNotEmpty) _selectedPermissionIds.add(id);
          }
        }
      }
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) _recursivePreSelect(child);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _getDisplayValue(Map<String, dynamic> map, String key) {
    final val = map[key];
    if (val is Map) return val['display_value']?.toString() ?? '';
    if (val is String) return val;
    return '';
  }

  String _getTitleId(Map<String, dynamic> node) {
    final title = node['rbac_title'];
    if (title is Map<String, dynamic>) return _getDisplayValue(title, 'id');
    return '';
  }

  String _getTitleLabel(Map<String, dynamic> node) {
    final title = node['rbac_title'];
    if (title is Map<String, dynamic>) return _getDisplayValue(title, 'label');
    return '';
  }

  // ── Permission Toggle ─────────────────────────────────────────────────

  void _togglePermission(String permId) {
    setState(() {
      if (_selectedPermissionIds.contains(permId)) {
        _selectedPermissionIds.remove(permId);
      } else {
        _selectedPermissionIds.add(permId);
      }
    });
  }

  // ── Tree Expand / Collapse ────────────────────────────────────────────

  void _toggleTitle(String titleId) {
    setState(() {
      if (_expandedTitleIds.contains(titleId)) {
        _expandedTitleIds.remove(titleId);
      } else {
        _expandedTitleIds.add(titleId);
      }
    });
  }

  void _expandAll() {
    final allIds = <String>{};
    for (final node in _titleNodes) {
      _collectAllTitleIds(node, allIds);
    }
    setState(() => _expandedTitleIds.addAll(allIds));
  }

  void _collapseAll() {
    setState(() => _expandedTitleIds.clear());
  }

  void _collectAllTitleIds(Map<String, dynamic> node, Set<String> ids) {
    final titleId = _getTitleId(node);
    if (titleId.isNotEmpty) ids.add(titleId);
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) _collectAllTitleIds(child, ids);
      }
    }
  }

  // ── Select / Deselect All ─────────────────────────────────────────────

  int _getTotalPermissionsCount() {
    int count = 0;
    for (final node in _titleNodes) {
      count += _countPermissionsRecursive(node);
    }
    return count;
  }

  int _countPermissionsRecursive(Map<String, dynamic> node) {
    int count = 0;
    final perms = node['permissions'];
    if (perms is List) count += perms.length;
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          count += _countPermissionsRecursive(child);
        }
      }
    }
    return count;
  }

  int _getNodeSelectedCount(Map<String, dynamic> node) {
    int count = 0;
    final perms = node['permissions'];
    if (perms is List) {
      for (final perm in perms) {
        if (perm is Map<String, dynamic>) {
          final id = _getDisplayValue(perm, 'id');
          if (_selectedPermissionIds.contains(id)) count++;
        }
      }
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) count += _getNodeSelectedCount(child);
      }
    }
    return count;
  }

  void _selectAll() {
    setState(() {
      for (final node in _titleNodes) {
        _collectAllPermissionIds(node);
      }
    });
  }

  void _deselectAll() {
    setState(() => _selectedPermissionIds.clear());
  }

  void _toggleSelectAll() {
    final total = _getTotalPermissionsCount();
    if (total > 0 && _selectedPermissionIds.length >= total) {
      _deselectAll();
    } else {
      _selectAll();
    }
  }

  void _collectAllPermissionIds(Map<String, dynamic> node) {
    final perms = node['permissions'];
    if (perms is List) {
      for (final perm in perms) {
        if (perm is Map<String, dynamic>) {
          final id = _getDisplayValue(perm, 'id');
          if (id.isNotEmpty) _selectedPermissionIds.add(id);
        }
      }
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) _collectAllPermissionIds(child);
      }
    }
  }

  // ── Search / Filter ───────────────────────────────────────────────────

  bool _matchesSearch(Map<String, dynamic> node) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();

    final titleLabel = _getTitleLabel(node).toLowerCase();
    if (titleLabel.contains(query)) return true;

    final perms = node['permissions'];
    if (perms is List) {
      for (final perm in perms) {
        if (perm is Map<String, dynamic>) {
          final label = _getDisplayValue(perm, 'label').toLowerCase();
          final desc = _getDisplayValue(perm, 'description_str').toLowerCase();
          if (label.contains(query) || desc.contains(query)) return true;
        }
      }
    }

    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic> && _matchesSearch(child)) return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> get _filteredTreeData {
    if (_searchQuery.isEmpty) return _titleNodes;
    return _titleNodes.where((node) => _matchesSearch(node)).toList();
  }

  List<Map<String, dynamic>> _getFilteredPermissions(List<dynamic> permissions) {
    final typed = permissions.whereType<Map<String, dynamic>>().toList();
    if (_searchQuery.isEmpty) return typed;
    final query = _searchQuery.toLowerCase();
    return typed.where((perm) {
      final label = _getDisplayValue(perm, 'label').toLowerCase();
      final desc = _getDisplayValue(perm, 'description_str').toLowerCase();
      return label.contains(query) || desc.contains(query);
    }).toList();
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submitPermissions() async {
    if (_selectedPermissionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_permission_selected'.tr),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final resp = await widget.service.updateRolePermissions(
        widget.roleId,
        {'rbac_permissions': _selectedPermissionIds.toList()},
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permissions_updated_successfully'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _loadPermissions();
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
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'role_permissions'.tr,
              style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              widget.roleName,
              style: GoogleFonts.ubuntu(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _isLoading ? null : _loadPermissions,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _hasError
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: (!_isLoading && !_hasError) ? _buildSubmitBar() : null,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildToolbar(),
        _buildStatsBar(),
        Expanded(
          child: _filteredTreeData.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPermissions,
                  color: ColorPages.COLOR_PRINCIPAL,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 8, bottom: 16, left: 12, right: 12,
                    ),
                    itemCount: _filteredTreeData.length,
                    itemBuilder: (context, index) =>
                        _buildTitleNode(_filteredTreeData[index], 0),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    final total = _getTotalPermissionsCount();
    final allSelected = total > 0 && _selectedPermissionIds.length >= total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.ubuntu(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'search'.tr,
                hintStyle: GoogleFonts.ubuntu(
                  color: Colors.grey.shade400, fontSize: 14,
                ),
                prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(width: 8),
          _toolbarButton(
            icon: Iconsax.arrow_down_1,
            tooltip: 'expand_all'.tr,
            onTap: _expandAll,
          ),
          const SizedBox(width: 4),
          _toolbarButton(
            icon: Iconsax.arrow_up_1,
            tooltip: 'collapse_all'.tr,
            onTap: _collapseAll,
          ),
          const SizedBox(width: 4),
          _toolbarButton(
            icon: allSelected ? Iconsax.close_square : Iconsax.tick_square,
            tooltip: allSelected ? 'deselect_all'.tr : 'select_all'.tr,
            onTap: _toggleSelectAll,
            color: allSelected ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  // ── Stats Bar ─────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _statChip(
            icon: Iconsax.shield_tick,
            label: '${_getTotalPermissionsCount()} ${'permissions'.tr}',
            color: ColorPages.COLOR_PRINCIPAL,
          ),
          const SizedBox(width: 8),
          _statChip(
            icon: Iconsax.tick_circle,
            label: '${_selectedPermissionIds.length} ${'selected'.tr}',
            color: Colors.green,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: _statChip(
                icon: Iconsax.close_circle,
                label: 'clear_filter'.tr,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 12, fontWeight: FontWeight.w500, color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tree Node ─────────────────────────────────────────────────────────

  Widget _buildTitleNode(Map<String, dynamic> node, int depth) {
    final titleId = _getTitleId(node);
    final titleLabel = _getTitleLabel(node);
    final isExpanded = _expandedTitleIds.contains(titleId);
    final permissions = node['permissions'] as List? ?? [];
    final children = (node['children'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final selectedCount = _getNodeSelectedCount(node);

    return Container(
      margin: EdgeInsets.only(left: depth * 16.0, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => _toggleTitle(titleId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Iconsax.arrow_down_1
                        : Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.folder,
                      size: 16,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleLabel,
                          style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '${permissions.length} ${'permissions'.tr}'
                          '${children.isNotEmpty ? ' · ${children.length} ${'children'.tr}' : ''}',
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.tick_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$selectedCount',
                            style: GoogleFonts.ubuntu(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            if (permissions.isNotEmpty)
              ..._getFilteredPermissions(permissions)
                  .map((perm) => _buildPermissionRow(perm)),
            if (children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 8, right: 8, bottom: 8, top: 4,
                ),
                child: Column(
                  children: children
                      .where((child) => _matchesSearch(child))
                      .map((child) => _buildTitleNode(child, depth + 1))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Permission Row ────────────────────────────────────────────────────

  Widget _buildPermissionRow(Map<String, dynamic> perm) {
    final permId = _getDisplayValue(perm, 'id');
    final label = _getDisplayValue(perm, 'label');
    final description = _getDisplayValue(perm, 'description_str');
    final isSelected = _selectedPermissionIds.contains(permId);

    return InkWell(
      onTap: () => _togglePermission(permId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _togglePermission(permId),
                  activeColor: ColorPages.COLOR_PRINCIPAL,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  isSelected ? Iconsax.shield_tick : Iconsax.shield_cross,
                  size: 14,
                  color: isSelected ? Colors.green : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        description,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSelected ? 'selected'.tr : 'not_selected'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.green : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit Bar ────────────────────────────────────────────────────────

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _statChip(
              icon: Iconsax.tick_circle,
              label: '${_selectedPermissionIds.length} ${'selected'.tr}',
              color: ColorPages.COLOR_PRINCIPAL,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitPermissions,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.tick_circle, size: 18),
              label: Text(
                'submit'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer / Error / Empty ───────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 160, color: Colors.white),
                const SizedBox(height: 10),
                Container(
                  height: 10,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(height: 10, width: 200, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
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
              style: GoogleFonts.ubuntu(
                fontSize: 18, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                color: Colors.grey.shade600, fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPermissions,
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr, style: GoogleFonts.ubuntu()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.shield_cross, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'no_permissions_found'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
