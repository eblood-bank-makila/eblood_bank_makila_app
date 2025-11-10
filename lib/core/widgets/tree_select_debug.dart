import 'package:flutter/material.dart';

class TreeNode<T> {
  final String key;
  final String label;
  final T? data;
  final List<TreeNode<T>> children;
  final bool isSelectable;
  bool isExpanded;

  TreeNode({
    required this.key,
    required this.label,
    this.data,
    this.children = const [],
    this.isSelectable = true,
    this.isExpanded = false,
  });
}

class TreeSelect<T> extends StatefulWidget {
  final List<TreeNode<T>> nodes;
  final String? selectedKey;
  final ValueChanged<String?> onChanged;
  final String label;
  final String placeholder;
  final bool isRequired;
  final String? errorText;
  final bool showClear;
  final bool showSelectedPath;
  final Icon? prefixIcon;
  final bool isLoading;
  final double maxHeight;
  final bool showSearch;
  final String searchPlaceholder;
  final bool selectOnlyLastChild;
  final bool useWhiteBackground;

  const TreeSelect({
    Key? key,
    required this.nodes,
    this.selectedKey,
    required this.onChanged,
    this.label = '',
    this.placeholder = 'Please select...',
    this.isRequired = false,
    this.errorText,
    this.showClear = true,
    this.showSelectedPath = false,
    this.prefixIcon,
    this.isLoading = false,
    this.maxHeight = 300,
    this.showSearch = true,
    this.searchPlaceholder = 'Search...',
    this.selectOnlyLastChild = false,
    this.useWhiteBackground = false,
  }) : super(key: key);

  @override
  State<TreeSelect<T>> createState() => _TreeSelectState<T>();
}

class _TreeSelectState<T> extends State<TreeSelect<T>> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _inputFieldKey = GlobalKey(); // Key for the input field specifically
  final FocusNode _focusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode(); // Dedicated focus node for search
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  
  // Selected node info
  String? _selectedNodeKey;
  String? _selectedNodeLabel;
  List<String> _selectedPath = [];
  
  // Debug flag
  final bool _debugMode = true;
  
  @override
  void initState() {
    super.initState();
    _selectedNodeKey = widget.selectedKey;
    _updateSelectedNodeInfo();
    
    // Debug: log node structure when initializing
    if (_debugMode) {
      _logTreeStructure(widget.nodes, 0);
    }
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_searchFocusNode.hasFocus && _isDropdownOpen) {
        // Add a small delay to prevent immediate closing when focus changes
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_focusNode.hasFocus && !_searchFocusNode.hasFocus && mounted) {
            _closeDropdown();
          }
        });
      }
    });
    
    _searchFocusNode.addListener(() {
      // We don't want to close the dropdown when the search field is focused
      if (_searchFocusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(TreeSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedKey != oldWidget.selectedKey) {
      _selectedNodeKey = widget.selectedKey;
      _updateSelectedNodeInfo();
    }
    
    // If nodes list changed, rebuild the dropdown if it's open
    if (widget.nodes != oldWidget.nodes && _isDropdownOpen) {
      _rebuildOverlay();
    }
  }

  void _updateSelectedNodeInfo() {
    if (_selectedNodeKey == null) {
      _selectedNodeLabel = null;
      _selectedPath = [];
      return;
    }
    
    final path = <String>[];
    final label = _findNodeAndBuildPath(widget.nodes, _selectedNodeKey!, path);
    
    setState(() {
      _selectedNodeLabel = label;
      _selectedPath = path;
    });
  }

  String? _findNodeAndBuildPath(List<TreeNode<T>> nodes, String key, List<String> path) {
    for (final node in nodes) {
      // Check if this is the target node
      if (node.key == key) {
        path.add(node.label);
        return node.label;
      }
      
      // If not found, search in children
      if (node.children.isNotEmpty) {
        final List<String> currentPath = [node.label];
        final String? result = _findNodeAndBuildPath(node.children, key, currentPath);
        
        if (result != null) {
          // Node found in this branch
          path.addAll(currentPath);
          return result;
        }
      }
    }
    
    return null; // Not found in this branch
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _focusNode.requestFocus();
    _isDropdownOpen = true;
    _searchText = '';
    _searchController.clear();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    
    // Do not auto-expand nodes anymore - let user control expansion
    // Uncomment if auto-expansion is needed for debugging:
    /*
    for (var node in widget.nodes) {
      node.isExpanded = true;
    }
    */
    
    setState(() {});
    
    // Ensure the UI is updated and search gets focus if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isDropdownOpen) {
        _rebuildOverlay();
        
        // Focus the search field if search is enabled
        if (widget.showSearch) {
          // Set autofocus and request focus explicitly for better reliability
          _searchFocusNode.requestFocus();
          print("Search focus requested");
        }
      }
    });
  }

  void _closeDropdown() {
    if (!mounted) return;
    
    _focusNode.unfocus();
    _searchFocusNode.unfocus();
    _isDropdownOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    // Get the RenderBox of the input field specifically, not the whole Column
    final RenderBox? inputRenderBox = _inputFieldKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (inputRenderBox == null) {
      // Fallback to the layerLink's context if key context is not available yet
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final double screenHeight = MediaQuery.of(context).size.height;
      
      // Use approximate calculation as fallback
      final double labelHeight = widget.label.isNotEmpty ? 30.0 : 0.0;
      final double inputFieldHeight = 48.0;
      final double offsetFromTop = labelHeight + inputFieldHeight + 5;
      
      final double spaceBelow = screenHeight - (position.dy + offsetFromTop);
      final double effectiveMaxHeight = (spaceBelow - 16).clamp(160.0, widget.maxHeight);
      
      return _buildOverlayEntry(size.width, offsetFromTop, effectiveMaxHeight);
    }
    
    // Use the actual input field's dimensions
    final Size inputSize = inputRenderBox.size;
    final Offset inputPosition = inputRenderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Position overlay exactly below the input field
    final double offsetFromInputTop = inputSize.height + 5;
    
    final double spaceBelow = screenHeight - (inputPosition.dy + offsetFromInputTop);
    final double effectiveMaxHeight = (spaceBelow - 16).clamp(160.0, widget.maxHeight);
    
    return _buildOverlayEntry(inputSize.width, offsetFromInputTop, effectiveMaxHeight);
  }

  OverlayEntry _buildOverlayEntry(double width, double offsetFromTop, double effectiveMaxHeight) {
    
    // Let the user control node expansion via clicks - don't expand automatically
    // If debugging is needed, uncomment this block:
    /*
    for (var node in widget.nodes) {
      node.isExpanded = true;
      
      for (var child in node.children) {
        child.isExpanded = true;
      }
    }
    */
    
    // Build tree items with empty search text initially
    final List<Widget> treeItems = _buildTreeItems(widget.nodes, 0);
    print("Creating overlay entry with ${widget.nodes.length} root nodes and ${treeItems.length} tree items");

    // Calculate content height based on number of items
    final double searchBoxHeight = widget.showSearch ? 56.0 : 0.0;
    final double itemHeight = 48.0; // Approximate height per tree item
    final int visibleItemCount = treeItems.length.clamp(1, 8); // Show max 8 items before scrolling
    final double contentHeight = searchBoxHeight + (itemHeight * visibleItemCount) + 16.0; // 16 for padding
    final double actualHeight = contentHeight.clamp(100.0, effectiveMaxHeight);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Close dropdown when tapping outside
          _closeDropdown();
        },
        child: Stack(
          children: [
            // Positioned overlay that doesn't block the tap detector
            Positioned(
              width: width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                // Position below the input field
                offset: Offset(0, offsetFromTop),
                child: GestureDetector(
                  // Prevent taps inside dropdown from closing it
                  onTap: () {},
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: widget.useWhiteBackground ? Colors.white : Colors.transparent,
                    child: Container(
                      height: actualHeight, // Use calculated height
                      decoration: BoxDecoration(
                        color: widget.useWhiteBackground ? Colors.white : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  // Search box
                  if (widget.showSearch)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true, // Always autofocus on search field
                        decoration: InputDecoration(
                          hintText: widget.searchPlaceholder,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchText = '';
                                  });
                                  _rebuildOverlay();
                                  _searchFocusNode.requestFocus();
                                },
                              )
                            : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        onChanged: (value) {
                          print("Search text changed: '$value'");
                          if (_searchText != value) {
                            setState(() {
                              _searchText = value;
                            });
                            // Expand all nodes when searching for better results visibility
                            if (value.isNotEmpty) {
                              _expandNodesWithMatches(widget.nodes, value.toLowerCase());
                            }
                            _rebuildOverlay();
                          }
                          // Always ensure the search field keeps focus
                          Future.microtask(() => _searchFocusNode.requestFocus());
                        },
                      ),
                    ),
                  
                  // Tree items - wrap with Flexible to allow shrinking when content is small
                  Flexible(
                    fit: FlexFit.loose, // Allow content to determine height
                    child: Builder(
                      builder: (context) {
                        print("TreeSelect: Rendering overlay with ${widget.nodes.length} root nodes and ${treeItems.length} tree items");
                        
                        // Debug output for tree nodes
                        if (_debugMode) {
                          print("DEBUG: Tree Structure Detail:");
                          _logTreeStructure(widget.nodes, 0);
                          
                          if (treeItems.isEmpty) {
                            print("WARNING: Tree items list is empty despite having ${widget.nodes.length} root nodes");
                          }
                        }
                        
                        if (widget.nodes.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No data available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (treeItems.isEmpty && _searchText.isNotEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No results found for "${_searchText}"',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // Debug forced items if tree items are empty but we have nodes
                        if (treeItems.isEmpty && widget.nodes.isNotEmpty) {
                          print("WARNING: TreeItems is empty but we have ${widget.nodes.length} nodes. Forcing display...");
                          List<Widget> forcedItems = [];
                          
                          // Create forced items from root nodes
                          for (var node in widget.nodes) {
                            forcedItems.add(
                              Container(
                                color: Colors.amber.withOpacity(0.2),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DEBUG: ${node.label} (${node.key})',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Has ${node.children.length} children'),
                                    if (node.children.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: node.children.map((child) => Text(
                                            '- ${child.label} (${child.children.length} children)',
                                          )).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.red.shade100,
                                child: const Text(
                                  'DEBUG MODE: Rendering forced items',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...forcedItems,
                            ],
                          );
                        }
                        
                        if (treeItems.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No items available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: false,
                          physics: const ClampingScrollPhysics(),
                          children: treeItems,
                        );
                      },
                    ),
                  ),
                ],
                      ), // Column
                    ), // Container
                  ), // Material
                ), // GestureDetector
              ), // CompositedTransformFollower
            ), // Positioned
          ], // children of Stack
        ), // Stack
      ), // GestureDetector builder
    ); // OverlayEntry
  }

  void _rebuildOverlay() {
    if (!mounted) return;
    
    if (_overlayEntry != null) {
      try {
        // Save the current search text before rebuilding
        final currentSearchText = _searchText;
        final searchFieldHasFocus = _searchFocusNode.hasFocus;
        
        // Remove and recreate the overlay for a complete refresh
        _overlayEntry!.remove();
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
        
        // Ensure search field keeps focus in the next frame and restore cursor position
        if (widget.showSearch && searchFieldHasFocus) {
          Future.microtask(() {
            _searchFocusNode.requestFocus();
            
            // Restore cursor position to end of text
            if (currentSearchText.isNotEmpty) {
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: currentSearchText.length),
              );
            }
          });
        }
        
        print("TreeSelect: Overlay rebuilt with ${widget.nodes.length} nodes and search '${_searchText}'");
      } catch (e) {
        print("TreeSelect: Error rebuilding overlay: $e");
      }
    }
  }
  
  bool _shouldShowNode(TreeNode<T> node) {
    if (_searchText.isEmpty) {
      return true;
    }
    
    final searchTextLower = _searchText.toLowerCase();
    final nodeLabelLower = node.label.toLowerCase();
    
    // Show if the node itself matches
    if (nodeLabelLower.contains(searchTextLower)) {
      return true;
    }
    
    // Show if any descendants match
    return _hasMatchingDescendants(node, _searchText);
  }

  List<Widget> _buildTreeItems(List<TreeNode<T>> nodes, int level, {bool forceVisible = false}) {
    List<Widget> items = [];
    bool isSearching = _searchText.isNotEmpty;
    
    // Debug output for this level
    if (_debugMode) {
      print('Building tree level $level with ${nodes.length} nodes' + (forceVisible ? ' (forced visible)' : ''));
    }

    for (var node in nodes) {
      bool nodeVisible = forceVisible || _shouldShowNode(node);
      bool isMatchingSearch = isSearching && node.label.toLowerCase().contains(_searchText.toLowerCase());
      
      if (nodeVisible) {
        // Add this node
        items.add(_buildTreeItem(node, level, isMatchingSearch));
        
        // No longer auto-expanding nodes for troubleshooting
        /*
        if (_debugMode) {
          node.isExpanded = true;
        }
        */
        
        // Add children if:
        // 1. Node is expanded OR 
        // 2. We're searching and this node or its descendants match the search
        if (node.isExpanded || (isSearching && (_hasMatchingDescendants(node, _searchText) || isMatchingSearch))) {
          // Debug logging
          if (_debugMode && node.children.isNotEmpty) {
            print('Adding ${node.children.length} children for node ${node.label} at level $level');
          }
          
          items.addAll(_buildTreeItems(node.children, level + 1, forceVisible: isSearching));
        }
      }
    }
    
    return items;
  }
  
  bool _hasMatchingDescendants(TreeNode<T> node, String searchText) {
    // Case-insensitive search
    final searchTextLower = searchText.toLowerCase();
    
    // Check direct children
    for (final child in node.children) {
      if (child.label.toLowerCase().contains(searchTextLower)) {
        return true;
      }
      
      // Recursively check grandchildren
      if (_hasMatchingDescendants(child, searchTextLower)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Helper method to automatically expand nodes that have matching descendants
  void _expandNodesWithMatches(List<TreeNode<T>> nodes, String searchText) {
    for (final node in nodes) {
      // Check if this node matches
      final bool nodeMatches = node.label.toLowerCase().contains(searchText);
      
      // Check if any descendants match
      final bool descendantsMatch = _hasMatchingDescendants(node, searchText);
      
      // Expand this node if it has matching descendants or matches itself
      if (descendantsMatch || nodeMatches) {
        node.isExpanded = true;
        
        // Recursively check children to expand all relevant parent nodes
        _expandNodesWithMatches(node.children, searchText);
      }
    }
  }

  void _handleNodeClick(TreeNode<T> node, bool isFiltering) {
    final bool hasChildren = node.children.isNotEmpty;
    
    // Toggle expansion if the node has children and we're not filtering
    if (hasChildren && !isFiltering) {
      setState(() {
        node.isExpanded = !node.isExpanded;
        _rebuildOverlay();
      });
    }
    
    // Check if we can select this node
    bool canSelectNode = node.isSelectable;
    
    // If selectOnlyLastChild is true, only allow selecting nodes without children
    if (widget.selectOnlyLastChild && hasChildren) {
      canSelectNode = false;
    }
    
    // If node is selectable based on our rules, select it and close dropdown
    if (canSelectNode) {
      setState(() {
        _selectedNodeKey = node.key;
        _selectedNodeLabel = node.label;
        _updateSelectedNodeInfo();
      });
      widget.onChanged(node.key);
      _closeDropdown();
    }
  }

  void _toggleNodeExpansion(TreeNode<T> node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
      _rebuildOverlay();
    });
  }

  Widget _buildTreeItem(TreeNode<T> node, int level, bool isMatchingSearch) {
    final bool hasChildren = node.children.isNotEmpty;
    final bool isSelected = _selectedNodeKey == node.key;
    final bool isFiltering = _searchText.isNotEmpty;
    
    // Determine background color based on selection/search status
    Color backgroundColor = Colors.transparent;
    if (isSelected) {
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (isFiltering && node.label.toLowerCase().contains(_searchText.toLowerCase())) {
      backgroundColor = Colors.yellow.withOpacity(0.1);
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _handleNodeClick(node, isFiltering);
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0 + (level * 16.0),
            right: 16.0,
            top: 12.0,
            bottom: 12.0,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Expand/collapse icon or spacer
              SizedBox(
                width: 24,
                child: hasChildren
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Stop event propagation
                          _toggleNodeExpansion(node);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Icon(
                            isFiltering ? Icons.arrow_drop_down : (node.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right),
                            size: 20,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              
              // Node label
              Expanded(
                child: isFiltering && node.label.toLowerCase().contains(_searchText.toLowerCase())
                  ? _highlightSearchText(node.label, _searchText)
                  : Text(
                      node.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                          ? Colors.blue 
                          : (widget.selectOnlyLastChild && hasChildren) 
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontStyle: (widget.selectOnlyLastChild && hasChildren) 
                          ? FontStyle.italic 
                          : FontStyle.normal,
                      ),
                    ),
              ),
              
              // Selected indicator or node type indicator
              if (isSelected)
                const Icon(Icons.check, color: Colors.blue, size: 18)
              else if (hasChildren)
                Icon(
                  Icons.chevron_right_rounded, // iOS-style right arrow icon
                  color: Colors.grey.shade600,
                  size: 16,
                )
              else
                Icon(
                  Icons.circle,
                  color: Colors.blue.shade300,
                  size: 8,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Debug method to log tree structure
  void _logTreeStructure(List<TreeNode<T>> nodes, int level) {
    for (var node in nodes) {
      print('${' ' * level * 2}${node.key}: ${node.label} (${node.children.length} children)');
      if (node.children.isNotEmpty) {
        _logTreeStructure(node.children, level + 1);
      }
    }
  }
  
  // Helper method to highlight search text
  Widget _highlightSearchText(String text, String searchTerm) {
    if (searchTerm.isEmpty) {
      return Text(text);
    }
    
    final String textLower = text.toLowerCase();
    final String searchLower = searchTerm.toLowerCase();
    final List<InlineSpan> spans = [];
    
    int start = 0;
    int indexOfMatch;
    while (true) {
      indexOfMatch = textLower.indexOf(searchLower, start);
      
      if (indexOfMatch < 0) {
        // Add the rest of the text
        if (start < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(start),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          );
        }
        break;
      }
      
      // Add text before the match
      if (indexOfMatch > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, indexOfMatch),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      }
      
      // Add the match with highlighting
      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + searchTerm.length),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            backgroundColor: const Color(0xFFFFEF9C),
          ),
        ),
      );
      
      // Update start position for next iteration
      start = indexOfMatch + searchTerm.length;
    }
    
    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        
        // TreeSelect Field
        CompositedTransformTarget(
          link: _layerLink,
          child: Material(
            key: _inputFieldKey, // Add key to get precise dimensions
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: widget.isLoading ? null : _toggleDropdown,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.errorText != null
                        ? Colors.red.shade300
                        : _isDropdownOpen
                          ? Colors.blue.shade400
                          : Colors.grey.shade300,
                    width: _isDropdownOpen ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  color: widget.isLoading 
                    ? Colors.grey.shade50 
                    : _isDropdownOpen 
                      ? widget.useWhiteBackground ? Colors.white : Colors.blue.shade50.withOpacity(0.05)
                      : widget.useWhiteBackground ? Colors.white : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Prefix Icon
                    if (widget.prefixIcon != null) ...[
                      widget.prefixIcon!,
                      const SizedBox(width: 8),
                    ],
                    
                    // Display selected item or placeholder
                    Expanded(
                      child: widget.isLoading
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Loading...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _selectedNodeLabel ?? widget.placeholder,
                              style: TextStyle(
                                color: _selectedNodeLabel != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    
                    // Clear Button
                    if (widget.showClear && _selectedNodeKey != null && !widget.isLoading)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            // Stop event propagation by handling separately
                            setState(() {
                              _selectedNodeKey = null;
                              _selectedNodeLabel = null;
                              _selectedPath = [];
                            });
                            widget.onChanged(null);
                            return;
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    
                    // Dropdown Icon
                    if (!widget.isLoading)
                      AnimatedRotation(
                        turns: _isDropdownOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: _isDropdownOpen ? Colors.blue.shade400 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Error Text
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        
        // Selected Path
        if (widget.showSelectedPath && _selectedPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _selectedPath.join(' > '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}