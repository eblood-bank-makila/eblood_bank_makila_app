import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../business/models/org_management_models.dart';
import '../../../business/service/OrgManagementService.dart';

class OrgRolePermissionsSheet extends StatefulWidget {
  final RbacRoleModel role;
  final String updateUrl;
  final String headUrl;
  final OrgManagementService service;

  const OrgRolePermissionsSheet({
    super.key,
    required this.role,
    required this.updateUrl,
    required this.headUrl,
    required this.service,
  });

  @override
  State<OrgRolePermissionsSheet> createState() =>
      _OrgRolePermissionsSheetState();
}

class _OrgRolePermissionsSheetState extends State<OrgRolePermissionsSheet> {
  List<RbacTitlePermissionGroup> _tree = [];
  final Set<String> _selected = {};
  final Set<String> _expanded = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await widget.service.fetchRolePermissions(
        widget.headUrl,
        widget.role.id,
      );
      final preSelected = <String>{};
      _collectPreSelected(tree, preSelected);
      if (mounted) {
        setState(() {
          _tree = tree;
          _selected.addAll(preSelected);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _collectPreSelected(
      List<RbacTitlePermissionGroup> nodes, Set<String> out) {
    for (final node in nodes) {
      for (final perm in node.permissions) {
        if (perm.isJoined) out.add(perm.id);
      }
      _collectPreSelected(node.children, out);
    }
  }

  void _togglePermission(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    final allIds = <String>{};
    _collectAllIds(_tree, allIds);
    if (_selected.length == allIds.length) {
      setState(() => _selected.clear());
    } else {
      setState(() {
        _selected.clear();
        _selected.addAll(allIds);
      });
    }
  }

  void _collectAllIds(List<RbacTitlePermissionGroup> nodes, Set<String> out) {
    for (final node in nodes) {
      for (final perm in node.permissions) {
        out.add(perm.id);
      }
      _collectAllIds(node.children, out);
    }
  }

  void _expandAll() {
    final ids = <String>{};
    _collectAllTitleIds(_tree, ids);
    setState(() => _expanded.addAll(ids));
  }

  void _collapseAll() => setState(() => _expanded.clear());

  void _collectAllTitleIds(
      List<RbacTitlePermissionGroup> nodes, Set<String> out) {
    for (final node in nodes) {
      out.add(node.titleId);
      _collectAllTitleIds(node.children, out);
    }
  }

  List<RbacTitlePermissionGroup> get _filteredTree {
    if (_searchQuery.isEmpty) return _tree;
    return _filterNodes(_tree);
  }

  List<RbacTitlePermissionGroup> _filterNodes(
      List<RbacTitlePermissionGroup> nodes) {
    final result = <RbacTitlePermissionGroup>[];
    for (final node in nodes) {
      final matchingPerms = node.permissions.where((p) {
        return p.label.toLowerCase().contains(_searchQuery) ||
            (p.description?.toLowerCase().contains(_searchQuery) ?? false) ||
            (p.identifier?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
      final filteredChildren = _filterNodes(node.children);
      final titleMatches =
          node.titleName.toLowerCase().contains(_searchQuery);
      if (matchingPerms.isNotEmpty ||
          filteredChildren.isNotEmpty ||
          titleMatches) {
        result.add(RbacTitlePermissionGroup(
          titleId: node.titleId,
          titleName: node.titleName,
          permissions: titleMatches ? node.permissions : matchingPerms,
          children: filteredChildren,
        ));
      }
    }
    return result;
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_permission_selected'.tr)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.updateRolePermissions(
        widget.updateUrl,
        widget.role.id,
        _selected.toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permissions_updated_successfully'.tr),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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
    final allIds = <String>{};
    _collectAllIds(_tree, allIds);
    final allSelected = allIds.isNotEmpty && _selected.length == allIds.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.grey[50],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ──
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Header ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.security_safe,
                          size: 20, color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'configure_permissions'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            widget.role.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_loading && _error == null) ...[
                      // Selected badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selected.isNotEmpty
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selected.length}/${allIds.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selected.isNotEmpty
                                ? const Color(0xFF2E7D32)
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Save button
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Iconsax.tick_circle, size: 16),
                        label: Text(
                            _saving ? 'saving'.tr : 'submit'.tr,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),

              if (!_loading && _error == null) ...[
                // ── Toolbar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'search_permissions'.tr,
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Iconsax.search_normal,
                                size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: _searchController.clear,
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHigh
                                : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expand all
                      _ToolbarIconBtn(
                        icon: Icons.unfold_more,
                        tooltip: 'expand_all'.tr,
                        onTap: _expandAll,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 4),
                      // Collapse all
                      _ToolbarIconBtn(
                        icon: Icons.unfold_less,
                        tooltip: 'collapse_all'.tr,
                        onTap: _collapseAll,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 4),
                      // Select / deselect all
                      _ToolbarIconBtn(
                        icon: allSelected
                            ? Icons.deselect
                            : Icons.select_all,
                        tooltip: allSelected
                            ? 'deselect_all'.tr
                            : 'select_all'.tr,
                        onTap: _toggleSelectAll,
                        colorScheme: colorScheme,
                        active: allSelected,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // ── Body ──
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.warning_2,
                                    size: 48,
                                    color: colorScheme.error),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _loadPermissions,
                                  icon: const Icon(Iconsax.refresh),
                                  label: Text('retry'.tr),
                                ),
                              ],
                            ),
                          )
                        : _filteredTree.isEmpty
                            ? Center(
                                child: Text(
                                  'no_search_results'.tr,
                                  style: TextStyle(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                    12, 8, 12, 24),
                                children: _filteredTree
                                    .map((node) => _TitleGroupTile(
                                          node: node,
                                          selected: _selected,
                                          expanded: _expanded,
                                          depth: 0,
                                          colorScheme: colorScheme,
                                          isDark: isDark,
                                          onTogglePermission:
                                              _togglePermission,
                                          onToggleExpanded: (id) {
                                            setState(() {
                                              if (_expanded.contains(id)) {
                                                _expanded.remove(id);
                                              } else {
                                                _expanded.add(id);
                                              }
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Small toolbar icon button ──────────────────────────────────────────────

class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool active;

  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colorScheme,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Recursive title group tile ─────────────────────────────────────────────

class _TitleGroupTile extends StatelessWidget {
  final RbacTitlePermissionGroup node;
  final Set<String> selected;
  final Set<String> expanded;
  final int depth;
  final ColorScheme colorScheme;
  final bool isDark;
  final void Function(String id) onTogglePermission;
  final void Function(String id) onToggleExpanded;

  const _TitleGroupTile({
    required this.node,
    required this.selected,
    required this.expanded,
    required this.depth,
    required this.colorScheme,
    required this.isDark,
    required this.onTogglePermission,
    required this.onToggleExpanded,
  });

  int _selectedCount() {
    int count = 0;
    for (final perm in node.permissions) {
      if (selected.contains(perm.id)) count++;
    }
    for (final child in node.children) {
      count += _countSelected(child);
    }
    return count;
  }

  int _countSelected(RbacTitlePermissionGroup n) {
    int count = 0;
    for (final perm in n.permissions) {
      if (selected.contains(perm.id)) count++;
    }
    for (final child in n.children) {
      count += _countSelected(child);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = expanded.contains(node.titleId);
    final selCount = _selectedCount();
    final total = node.totalPermissions;
    final hasContent =
        node.permissions.isNotEmpty || node.children.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0, bottom: 6),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            // ── Group header ──
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: hasContent
                  ? () => onToggleExpanded(node.titleId)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.security,
                      size: 16,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.titleName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: selCount > 0
                              ? const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$selCount/$total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selCount > 0
                                ? const Color(0xFF2E7D32)
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    if (hasContent) ...[
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Permissions list ──
            if (isExpanded && node.permissions.isNotEmpty) ...[
              const Divider(height: 1, indent: 14, endIndent: 14),
              ...node.permissions.map(
                (perm) => _PermissionCheckTile(
                  permission: perm,
                  isSelected: selected.contains(perm.id),
                  colorScheme: colorScheme,
                  onTap: () => onTogglePermission(perm.id),
                ),
              ),
            ],

            // ── Children ──
            if (isExpanded && node.children.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  children: node.children
                      .map((child) => _TitleGroupTile(
                            node: child,
                            selected: selected,
                            expanded: expanded,
                            depth: 0,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            onTogglePermission: onTogglePermission,
                            onToggleExpanded: onToggleExpanded,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Single permission checkbox tile ───────────────────────────────────────

class _PermissionCheckTile extends StatelessWidget {
  final RbacPermissionItem permission;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PermissionCheckTile({
    required this.permission,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5A5E39)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5A5E39)
                      : colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permission.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (permission.description != null &&
                      permission.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      permission.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
