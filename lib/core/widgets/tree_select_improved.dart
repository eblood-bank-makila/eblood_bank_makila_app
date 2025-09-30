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
  }) : super(key: key);

  @override
  State<TreeSelect<T>> createState() => _TreeSelectState<T>();
}

class _TreeSelectState<T> extends State<TreeSelect<T>> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  
  // Selected node info
  String? _selectedNodeKey;
  String? _selectedNodeLabel;
  List<String> _selectedPath = [];
  
  @override
  void initState() {
    super.initState();
    _selectedNodeKey = widget.selectedKey;
    _updateSelectedNodeInfo();
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isDropdownOpen) {
        _closeDropdown();
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
    setState(() {});
  }

  void _closeDropdown() {
    _focusNode.unfocus();
    _isDropdownOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    
    // Build tree items
    final List<Widget> treeItems = _buildTreeItems(widget.nodes, 0);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight,
                minHeight: 100, // Ensure minimum height for search results
              ),
              decoration: BoxDecoration(
                color: Colors.white,
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
                                    _rebuildOverlay();
                                  });
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
                          setState(() {
                            _searchText = value;
                            _rebuildOverlay();
                          });
                        },
                        autofocus: true, // Automatically focus the search field
                      ),
                    ),
                  
                  // Tree items
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: treeItems.isEmpty && _searchText.isNotEmpty
                        ? Center(
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
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: treeItems,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _rebuildOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
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

    for (var node in nodes) {
      bool nodeVisible = forceVisible || _shouldShowNode(node);
      bool isMatchingSearch = isSearching && node.label.toLowerCase().contains(_searchText.toLowerCase());
      
      if (nodeVisible) {
        items.add(_buildTreeItem(node, level, isMatchingSearch));
        
        // If node is expanded OR we're searching and this node or its descendants match the search
        if (node.isExpanded || (isSearching && (_hasMatchingDescendants(node, _searchText) || isMatchingSearch))) {
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
          if (hasChildren && !isFiltering) {
            setState(() {
              node.isExpanded = !node.isExpanded;
              _rebuildOverlay();
            });
          }
          
          if (node.isSelectable) {
            setState(() {
              _selectedNodeKey = node.key;
              _selectedNodeLabel = node.label;
              _updateSelectedNodeInfo();
            });
            widget.onChanged(node.key);
            _closeDropdown();
          }
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
                width: 20,
                child: hasChildren
                  ? Icon(
                      isFiltering ? Icons.arrow_drop_down : (node.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right),
                      size: 20,
                      color: Colors.grey.shade700,
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
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
              ),
              
              // Selected indicator
              if (isSelected)
                const Icon(Icons.check, color: Colors.blue, size: 18),
            ],
          ),
        ),
      ),
    );
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
            backgroundColor: Color(0xFFFFEF9C),
          ),
        ),
      );
      
      // Update start position for next iteration
      start = indexOfMatch + searchTerm.length;
    }
    
    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
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
                      ? Colors.blue.shade50.withOpacity(0.05)
                      : Colors.transparent,
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
                            // Prevent event bubbling to parent
                            setState(() {
                              _selectedNodeKey = null;
                              _selectedNodeLabel = null;
                              _selectedPath = [];
                            });
                            widget.onChanged(null);
                            return; // Stop propagation
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
    _searchController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}