import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import './tree_select_debug.dart';

/// A widget that displays a location tree in a full-screen bottom sheet
/// for better visibility and easier navigation.
class LocationBottomSheetSelect extends StatefulWidget {
  final List<dynamic> locations;
  final ValueChanged<Map<String, String>> onLocationSelected;
  final String? selectedLocationId;
  final String label;
  final String hint;
  final bool isRequired;
  final String? errorText;
  final bool isLoading;
  final bool showPath;
  final String? Function(String?)? validator;
  final Icon? prefixIcon;
  final bool selectOnlyLastChild;

  const LocationBottomSheetSelect({
    super.key,
    required this.locations,
    required this.onLocationSelected,
    this.selectedLocationId,
    this.label = 'Location',
    this.hint = 'Select a location',
    this.isRequired = false,
    this.errorText,
    this.isLoading = false,
    this.showPath = true,
    this.validator,
    this.prefixIcon,
    this.selectOnlyLastChild = true,
  });

  @override
  State<LocationBottomSheetSelect> createState() =>
      _LocationBottomSheetSelectState();
}

class _LocationBottomSheetSelectState extends State<LocationBottomSheetSelect> {
  List<TreeNode<Map<String, String>>> _treeNodes = [];
  String? _selectedNodeKey;
  String? _selectedNodeLabel;
  List<String> _selectedPath = [];
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _convertLocationsToTreeNodes();
    _selectedNodeKey = widget.selectedLocationId;
    _updateSelectedNodeInfo();
  }

  @override
  void didUpdateWidget(LocationBottomSheetSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _convertLocationsToTreeNodes();
    }
    if (oldWidget.selectedLocationId != widget.selectedLocationId) {
      _selectedNodeKey = widget.selectedLocationId;
      _updateSelectedNodeInfo();
    }
    if (oldWidget.errorText != widget.errorText) {
      _validationError = widget.errorText;
    }
  }

  void _convertLocationsToTreeNodes() {
    _treeNodes = [];

    for (final location in widget.locations) {
      try {
        final treeNode = _convertNodeToTreeNode(location, null, null, 0);
        _treeNodes.add(treeNode);
      } catch (e) {
        debugPrint('Error processing location node: $e');
      }
    }
  }

  TreeNode<Map<String, String>> _convertNodeToTreeNode(
    dynamic node,
    Map<String, String>? parentData,
    String? parentType,
    int level,
  ) {
    final String nodeId = node.id?.toString() ?? '';
    final String nodeName = node.name?.toString() ?? '';
    final String entityFlag = node.namedEntityFlag?.toString() ?? '';
    final String nodeType = entityFlag.isNotEmpty
        ? entityFlag.toLowerCase()
        : 'level_$level';
    final String nodeKey = '$nodeType-$nodeId';

    final Map<String, String> nodeData = {
      'id': nodeId,
      'name': nodeName,
      'type': nodeType,
      'entity_flag': entityFlag,
    };

    void addField(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isNotEmpty) {
        nodeData[key] = value;
      } else if (value is num || value is bool) {
        nodeData[key] = value.toString();
      }
    }

    try {
      if (node is Map) {
        node.forEach((key, value) => addField(key.toString(), value));
      } else {
        final dynamic jsonMethod = (node as dynamic).toJson;
        if (jsonMethod is Function) {
          final dynamic json = jsonMethod();
          if (json is Map) {
            json.forEach((key, value) => addField(key.toString(), value));
          }
        }
      }
    } catch (_) {}

    nodeData.putIfAbsent('country_id', () => nodeId);

    if (parentData != null && parentType != null) {
      nodeData['parent_id'] = parentData['id'] ?? '';
      nodeData['parent_name'] = parentData['name'] ?? '';
      nodeData['parent_type'] = parentType;
      if (parentType.contains('country')) {
        nodeData['country_id'] = parentData['id'] ?? '';
      } else if (parentType.contains('province')) {
        nodeData['province_id'] = parentData['id'] ?? '';
        if (parentData.containsKey('country_id')) {
          nodeData['country_id'] =
              parentData['country_id'] ?? nodeData['country_id'] ?? '';
        }
      }
    }

    if (!nodeData.containsKey('country_flag')) {
      try {
        final dynamic flag = (node as dynamic).countryFlag;
        if (flag is String && flag.isNotEmpty) {
          nodeData['country_flag'] = flag;
        }
      } catch (_) {}
    }

    if (!nodeData.containsKey('country_flag') && parentData != null) {
      final String? parentFlag = parentData['country_flag'];
      if (parentFlag != null && parentFlag.isNotEmpty) {
        nodeData['country_flag'] = parentFlag;
      }
    }

    final List<TreeNode<Map<String, String>>> childNodes = [];

    if (node.children != null &&
        node.children is List &&
        node.children.isNotEmpty) {
      for (final child in node.children) {
        try {
          final childNode = _convertNodeToTreeNode(
            child,
            nodeData,
            nodeType,
            level + 1,
          );
          childNodes.add(childNode);
        } catch (e) {
          debugPrint('Error processing child node: $e');
        }
      }
    }

    return TreeNode<Map<String, String>>(
      key: nodeKey,
      label: nodeName,
      data: nodeData,
      children: childNodes,
      isExpanded: false,
    );
  }

  void _updateSelectedNodeInfo() {
    if (_selectedNodeKey == null) {
      _selectedNodeLabel = null;
      _selectedPath = [];
      return;
    }

    final path = <String>[];
    final label = _findNodeAndBuildPath(_treeNodes, _selectedNodeKey!, path);

    setState(() {
      _selectedNodeLabel = label;
      _selectedPath = path;
    });
  }

  String? _findNodeAndBuildPath(
    List<TreeNode<Map<String, String>>> nodes,
    String key,
    List<String> path,
  ) {
    for (final node in nodes) {
      if (node.key == key) {
        path.add(node.label);
        return node.label;
      }

      if (node.children.isNotEmpty) {
        final List<String> currentPath = [node.label];
        final String? result = _findNodeAndBuildPath(
          node.children,
          key,
          currentPath,
        );

        if (result != null) {
          path.addAll(currentPath);
          return result;
        }
      }
    }

    return null;
  }

  TreeNode<Map<String, String>>? _findNodeByKey(
    List<TreeNode<Map<String, String>>> nodes,
    String key,
  ) {
    for (final node in nodes) {
      if (node.key == key) {
        return node;
      }

      if (node.children.isNotEmpty) {
        final foundNode = _findNodeByKey(node.children, key);
        if (foundNode != null) {
          return foundNode;
        }
      }
    }

    return null;
  }

  void _handleLocationSelected(String? nodeKey) {
    if (nodeKey == null) {
      widget.onLocationSelected({});
      return;
    }

    TreeNode<Map<String, String>>? selectedNode = _findNodeByKey(
      _treeNodes,
      nodeKey,
    );

    if (selectedNode != null && selectedNode.data != null) {
      widget.onLocationSelected(selectedNode.data!);

      setState(() {
        _selectedNodeKey = nodeKey;
        _validationError = null;
      });
      _updateSelectedNodeInfo();
    }
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationTreeBottomSheet(
        nodes: _treeNodes,
        selectedKey: _selectedNodeKey,
        onSelect: (nodeKey) {
          Navigator.of(context).pop();
          _handleLocationSelected(nodeKey);
        },
        selectOnlyLastChild: widget.selectOnlyLastChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _validationError != null || widget.errorText != null;
    final errorMessage = _validationError ?? widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (widget.isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),

        // Input field
        InkWell(
          onTap: widget.isLoading ? null : _openBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey.shade300,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 12),
                ],
                if (widget.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedNodeLabel != null) ...[
                        Text(
                          _selectedNodeLabel!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        if (widget.showPath && _selectedPath.length > 1)
                          Text(
                            _selectedPath.join(' > '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ] else
                        Text(
                          widget.hint,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),

        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }
}

/// The bottom sheet content with the location tree
class _LocationTreeBottomSheet extends StatefulWidget {
  final List<TreeNode<Map<String, String>>> nodes;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;
  final bool selectOnlyLastChild;

  const _LocationTreeBottomSheet({
    required this.nodes,
    this.selectedKey,
    required this.onSelect,
    this.selectOnlyLastChild = true,
  });

  @override
  State<_LocationTreeBottomSheet> createState() =>
      _LocationTreeBottomSheetState();
}

class _LocationTreeBottomSheetState extends State<_LocationTreeBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  late List<TreeNode<Map<String, String>>> _displayNodes;

  @override
  void initState() {
    super.initState();
    _displayNodes = _deepCopyNodes(widget.nodes);
  }

  List<TreeNode<Map<String, String>>> _deepCopyNodes(
    List<TreeNode<Map<String, String>>> nodes,
  ) {
    return nodes.map((node) {
      return TreeNode<Map<String, String>>(
        key: node.key,
        label: node.label,
        data: node.data,
        children: _deepCopyNodes(node.children),
        isExpanded: node.isExpanded,
        isSelectable: node.isSelectable,
      );
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.toLowerCase();
      if (_searchText.isNotEmpty) {
        _expandMatchingNodes(_displayNodes, _searchText);
      }
    });
  }

  bool _expandMatchingNodes(
    List<TreeNode<Map<String, String>>> nodes,
    String searchText,
  ) {
    bool hasMatch = false;

    for (var node in nodes) {
      final labelMatches = node.label.toLowerCase().contains(searchText);
      final childHasMatch = _expandMatchingNodes(node.children, searchText);

      if (labelMatches || childHasMatch) {
        node.isExpanded = true;
        hasMatch = true;
      }
    }

    return hasMatch;
  }

  bool _nodeMatchesSearch(TreeNode<Map<String, String>> node) {
    if (_searchText.isEmpty) return true;

    // Only match on town names for more precise results
    final type = node.data?['type']?.toLowerCase() ?? '';
    final isTown = type.contains('town') || type.contains('city');
    
    // If it's a town/city, check if it matches the search
    if (isTown) {
      return node.label.toLowerCase().contains(_searchText);
    }

    // For non-town nodes (countries, provinces), only show if they have matching children
    for (var child in node.children) {
      if (_nodeMatchesSearch(child)) {
        return true;
      }
    }

    return false;
  }

  List<TreeNode<Map<String, String>>> _filterNodes(
    List<TreeNode<Map<String, String>>> nodes,
  ) {
    if (_searchText.isEmpty) return nodes;

    final filtered = <TreeNode<Map<String, String>>>[];

    for (var node in nodes) {
      final type = node.data?['type']?.toLowerCase() ?? '';
      final isTown = type.contains('town') || type.contains('city');

      // If it's a town and matches, include it
      if (isTown && node.label.toLowerCase().contains(_searchText)) {
        filtered.add(TreeNode<Map<String, String>>(
          key: node.key,
          label: node.label,
          data: node.data,
          children: [], // Don't include children for matched towns
          isExpanded: node.isExpanded,
          isSelectable: node.isSelectable,
        ));
        continue;
      }

      // For non-town nodes, recursively filter children
      if (!isTown && node.children.isNotEmpty) {
        final filteredChildren = _filterNodes(node.children);
        
        if (filteredChildren.isNotEmpty) {
          // Include this node with its filtered children
          filtered.add(TreeNode<Map<String, String>>(
            key: node.key,
            label: node.label,
            data: node.data,
            children: filteredChildren,
            isExpanded: true, // Auto-expand to show results
            isSelectable: node.isSelectable,
          ));
        }
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredNodes = _searchText.isEmpty 
        ? _displayNodes 
        : _filterNodes(_displayNodes);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Modern handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorPages.COLOR_PRINCIPAL,
                            ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorPages.COLOR_PRINCIPAL.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'select_location'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'choose_your_region'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Modern search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'search_location'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          ),

          // Tree content
          Expanded(
            child: filteredNodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_results_found'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'try_different_search'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filteredNodes.length,
                    itemBuilder: (context, index) {
                      return _TreeNodeWidget(
                        node: filteredNodes[index],
                        level: 0,
                        selectedKey: widget.selectedKey,
                        onSelect: widget.onSelect,
                        selectOnlyLastChild: widget.selectOnlyLastChild,
                        searchText: _searchText,
                        onToggleExpand: () => setState(() {}),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual tree node widget with modern design
class _TreeNodeWidget extends StatelessWidget {
  final TreeNode<Map<String, String>> node;
  final int level;
  final String? selectedKey;
  final ValueChanged<String?> onSelect;
  final bool selectOnlyLastChild;
  final String searchText;
  final VoidCallback onToggleExpand;

  const _TreeNodeWidget({
    required this.node,
    required this.level,
    this.selectedKey,
    required this.onSelect,
    this.selectOnlyLastChild = true,
    this.searchText = '',
    required this.onToggleExpand,
  });

  IconData _getNodeIcon() {
    final type = node.data?['type']?.toLowerCase() ?? '';

    if (type.contains('country')) {
      return Icons.public_rounded;
    } else if (type.contains('province') || type.contains('state')) {
      return Icons.map_rounded;
    } else if (type.contains('town') || type.contains('city')) {
      return Icons.location_city_rounded;
    } else if (node.children.isNotEmpty) {
      return Icons.folder_rounded;
    } else {
      return Icons.place_rounded;
    }
  }

  Color _getNodeColor() {
    final type = node.data?['type']?.toLowerCase() ?? '';

    if (type.contains('country')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (type.contains('province') || type.contains('state')) {
      return const Color(0xFFF59E0B); // Amber
    } else if (type.contains('town') || type.contains('city')) {
      return const Color(0xFF10B981); // Emerald
    } else {
      return const Color(0xFF6366F1); // Indigo
    }
  }

  String _getNodeTypeLabel() {
    final type = node.data?['type']?.toLowerCase() ?? '';

    if (type.contains('country')) {
      return 'country'.tr;
    } else if (type.contains('province') || type.contains('state')) {
      return 'province'.tr;
    } else if (type.contains('town') || type.contains('city')) {
      return 'city'.tr;
    } else if (node.children.isNotEmpty) {
      return 'region'.tr;
    } else {
      return 'location'.tr;
    }
  }

  Widget _buildHighlightedText(String text, {bool isTitle = false}) {
    final baseStyle = TextStyle(
      fontSize: isTitle ? 15 : 14,
      fontWeight: isTitle
          ? (level == 0 ? FontWeight.w600 : FontWeight.w500)
          : FontWeight.w400,
      color: isTitle ? Colors.black87 : Colors.grey.shade600,
      letterSpacing: isTitle ? -0.2 : 0,
    );

    if (searchText.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerSearch = searchText.toLowerCase();
    final startIndex = lowerText.indexOf(lowerSearch);

    if (startIndex == -1) {
      return Text(text, style: baseStyle);
    }

    final endIndex = startIndex + searchText.length;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              backgroundColor: ColorPages.COLOR_PRINCIPAL.withValues(
                alpha: 0.15,
              ),
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.children.isNotEmpty;
    final isSelected = node.key == selectedKey;
    final canSelect = !selectOnlyLastChild || !hasChildren;
    final countryFlag = node.data?['country_flag'] ?? '';
    final nodeColor = _getNodeColor();

    // Root level items (countries) get special card treatment
    if (level == 0) {
      return _buildRootLevelCard(
        context,
        hasChildren: hasChildren,
        isSelected: isSelected,
        canSelect: canSelect,
        countryFlag: countryFlag,
        nodeColor: nodeColor,
      );
    }

    // Child level items
    return _buildChildLevelItem(
      context,
      hasChildren: hasChildren,
      isSelected: isSelected,
      canSelect: canSelect,
      nodeColor: nodeColor,
    );
  }

  Widget _buildRootLevelCard(
    BuildContext context, {
    required bool hasChildren,
    required bool isSelected,
    required bool canSelect,
    required String countryFlag,
    required Color nodeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (hasChildren) {
                  node.isExpanded = !node.isExpanded;
                  onToggleExpand();
                }
                if (canSelect) {
                  onSelect(node.key);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Country flag or icon with gradient background
                    if (countryFlag.isNotEmpty)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              nodeColor.withValues(alpha: 0.1),
                              nodeColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: nodeColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            countryFlag,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              nodeColor,
                              nodeColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: nodeColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getNodeIcon(),
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHighlightedText(node.label, isTitle: true),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: nodeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getNodeTypeLabel(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: nodeColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (hasChildren) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${node.children.length} ${'sub_regions'.tr}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Selection indicator
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorPages.COLOR_PRINCIPAL.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: ColorPages.COLOR_PRINCIPAL,
                              size: 18,
                            ),
                          )
                        else if (canSelect)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 14, height: 14),
                          ),

                        // Expand/collapse
                        if (hasChildren) ...[
                          const SizedBox(width: 12),
                          AnimatedRotation(
                            turns: node.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Children with animated container
          if (hasChildren && node.isExpanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(height: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: node.children
                            .map(
                              (child) => _TreeNodeWidget(
                                node: child,
                                level: level + 1,
                                selectedKey: selectedKey,
                                onSelect: onSelect,
                                selectOnlyLastChild: selectOnlyLastChild,
                                searchText: searchText,
                                onToggleExpand: onToggleExpand,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildLevelItem(
    BuildContext context, {
    required bool hasChildren,
    required bool isSelected,
    required bool canSelect,
    required Color nodeColor,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                node.isExpanded = !node.isExpanded;
                onToggleExpand();
              }
              if (canSelect) {
                onSelect(node.key);
              }
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 20.0 + (level * 20.0),
                right: 16,
                top: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Connection line indicator
                  Container(
                    width: 2,
                    height: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorPages.COLOR_PRINCIPAL
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? nodeColor.withValues(alpha: 0.15)
                          : nodeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getNodeIcon(),
                      size: 18,
                      color: isSelected
                          ? nodeColor
                          : nodeColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(node.label, isTitle: true),
                        if (hasChildren)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${node.children.length} ${'sub_areas'.tr}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: ColorPages.COLOR_PRINCIPAL,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      else if (canSelect)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),

                      if (hasChildren) ...[
                        const SizedBox(width: 10),
                        AnimatedRotation(
                          turns: node.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Children
        if (hasChildren && node.isExpanded)
          ...node.children.map(
            (child) => _TreeNodeWidget(
              node: child,
              level: level + 1,
              selectedKey: selectedKey,
              onSelect: onSelect,
              selectOnlyLastChild: selectOnlyLastChild,
              searchText: searchText,
              onToggleExpand: onToggleExpand,
            ),
          ),
      ],
    );
  }
}
