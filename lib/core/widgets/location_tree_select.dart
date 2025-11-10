import 'package:flutter/material.dart';
import './tree_select_debug.dart';

class LocationTreeSelect extends StatefulWidget {
  final List<dynamic> locations; // Accept any location model
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
  final bool useWhiteBackground; // Toggle between white and transparent background

  const LocationTreeSelect({
    Key? key,
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
    this.selectOnlyLastChild = true, // Default to true for location selection
    this.useWhiteBackground = false, // Default to transparent
  }) : super(key: key);

  @override
  State<LocationTreeSelect> createState() => _LocationTreeSelectState();
}

class _LocationTreeSelectState extends State<LocationTreeSelect> {
  List<TreeNode<Map<String, String>>> _treeNodes = [];
  String? _selectedNodeKey;
  String? _validationError;
  
  @override
  void initState() {
    super.initState();
    _convertLocationsToTreeNodes();
    _selectedNodeKey = widget.selectedLocationId;
  }
  
  @override
  void didUpdateWidget(LocationTreeSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _convertLocationsToTreeNodes();
    }
    if (oldWidget.selectedLocationId != widget.selectedLocationId) {
      _selectedNodeKey = widget.selectedLocationId;
    }
    if (oldWidget.errorText != widget.errorText) {
      _validationError = widget.errorText;
    }
  }
  
  void _convertLocationsToTreeNodes() {
    _treeNodes = [];
    print('Converting locations to tree nodes. Number of locations: ${widget.locations.length}');
    
    // Convert all location nodes recursively
    for (final location in widget.locations) {
      try {
        final treeNode = _convertNodeToTreeNode(location, null, null, 0);
        _treeNodes.add(treeNode);
      } catch (e) {
        print('Error processing location node: $e');
      }
    }
    
    print('Finished creating tree nodes. Root nodes count: ${_treeNodes.length}');
    
    // Debug tree structure if needed
    _logTreeStructure();
  }
  
  /// Recursively converts a location node and its children to TreeNode objects
  TreeNode<Map<String, String>> _convertNodeToTreeNode(
    dynamic node, 
    Map<String, String>? parentData, 
    String? parentType, 
    int level
  ) {
    // Extract common properties using dynamic access
    final String nodeId = node.id?.toString() ?? '';
    final String nodeName = node.name?.toString() ?? '';
    final String entityFlag = node.namedEntityFlag?.toString() ?? '';
    
    // Generate a type based on entity flag or level
    final String nodeType = entityFlag.isNotEmpty ? entityFlag.toLowerCase() : 'level_$level';
    
    // Generate a unique key using type and id
    final String nodeKey = '$nodeType-$nodeId';
    
    // Create data map with parent information if available
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

    // Merge additional properties exposed by the model when possible
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
    } catch (_) {
      // Ignore silently if reflection fails
    }

    // Country nodes should always carry their id for downstream lookup
    nodeData.putIfAbsent('country_id', () => nodeId);
    
    // Add parent data if available
    if (parentData != null && parentType != null) {
      nodeData['parent_id'] = parentData['id'] ?? '';
      nodeData['parent_name'] = parentData['name'] ?? '';
      nodeData['parent_type'] = parentType;
      if (parentType.contains('country')) {
        nodeData['country_id'] = parentData['id'] ?? '';
      } else if (parentType.contains('province')) {
        nodeData['province_id'] = parentData['id'] ?? '';
        if (parentData.containsKey('country_id')) {
          nodeData['country_id'] = parentData['country_id'] ?? nodeData['country_id'] ?? '';
        }
      }
    }
    
    // Ensure flag information is available for this node
    if (!nodeData.containsKey('country_flag')) {
      try {
        final dynamic flag = (node as dynamic).countryFlag;
        if (flag is String && flag.isNotEmpty) {
          nodeData['country_flag'] = flag;
        }
      } catch (_) {
        // Ignore if property not accessible
      }
    }

    if (!nodeData.containsKey('country_flag') && parentData != null) {
      final String? parentFlag = parentData['country_flag'];
      if (parentFlag != null && parentFlag.isNotEmpty) {
        nodeData['country_flag'] = parentFlag;
      }
    }

    // Process children if any
    final List<TreeNode<Map<String, String>>> childNodes = [];
    
    if (node.children != null && node.children is List && node.children.isNotEmpty) {
      for (final child in node.children) {
        try {
          final childNode = _convertNodeToTreeNode(child, nodeData, nodeType, level + 1);
          childNodes.add(childNode);
        } catch (e) {
          print('Error processing child node: $e');
        }
      }
    }
    
    // Create and return tree node
    return TreeNode<Map<String, String>>(
      key: nodeKey,
      label: nodeName,
      data: nodeData,
      children: childNodes,
      isExpanded: false, // Default to collapsed, user expands manually
    );
  }
  
  /// Logs the current tree structure for debugging
  void _logTreeStructure() {
    if (_treeNodes.isEmpty) {
      print('WARNING: No location tree nodes available. Is location data loaded?');
      if (widget.locations.isEmpty) {
        print('The locations list is empty. Check that your API is returning data.');
      } else {
        print('Locations data exists but conversion to tree nodes failed.');
      }
      return;
    }
    
    print('==================== LOCATION TREE STRUCTURE ====================');
    _logNodeAndChildren(_treeNodes, 0);
    print('==============================================================');
  }
  
  /// Helper method to log node and its children recursively
  void _logNodeAndChildren(List<TreeNode<Map<String, String>>> nodes, int level) {
    final indent = '  ' * level;
    
    for (var node in nodes) {
      print('$indent${node.label} (${node.key}) with ${node.children.length} children');
      if (node.children.isNotEmpty) {
        _logNodeAndChildren(node.children, level + 1);
      }
    }
  }

  void _handleLocationSelected(String? nodeKey) {
    if (nodeKey == null) {
      widget.onLocationSelected({});
      return;
    }
    
    // Find the selected node
    TreeNode<Map<String, String>>? selectedNode = _findNodeByKey(_treeNodes, nodeKey);
    
    if (selectedNode != null && selectedNode.data != null) {
      widget.onLocationSelected(selectedNode.data!);
      
      // Reset validation error
      setState(() {
        _validationError = null;
      });
    }
  }

  TreeNode<Map<String, String>>? _findNodeByKey(
      List<TreeNode<Map<String, String>>> nodes, String key) {
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

  @override
  Widget build(BuildContext context) {
    // Log the tree nodes we've built
    print('LocationTreeSelect: Rendering with ${_treeNodes.length} root nodes');
    
    // Log tree structure for debugging if needed
    // _logTreeStructure();

    return TreeSelect<Map<String, String>>(
      nodes: _treeNodes,
      selectedKey: _selectedNodeKey,
      onChanged: _handleLocationSelected,
      label: widget.label,
      placeholder: widget.hint,
      isRequired: widget.isRequired,
      errorText: _validationError ?? widget.errorText,
      isLoading: widget.isLoading,
      showSelectedPath: widget.showPath,
      prefixIcon: widget.prefixIcon,
      showSearch: true,
      searchPlaceholder: 'Search locations...',
      selectOnlyLastChild: widget.selectOnlyLastChild,
      useWhiteBackground: widget.useWhiteBackground,
    );
  }
}