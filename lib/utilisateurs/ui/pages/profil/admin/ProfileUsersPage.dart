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
import '../../../../business/service/UserNetworkServiceImpl.dart';
import '../../users/AddUserPage.dart';

class ProfileUsersPage extends ConsumerStatefulWidget {
  const ProfileUsersPage({super.key});

  @override
  ConsumerState<ProfileUsersPage> createState() => _ProfileUsersPageState();
}

class _ProfileUsersPageState extends ConsumerState<ProfileUsersPage> {
  late final UserNetworkServiceImpl _service;
  late final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _page = 0;
  final int _limit = 20;
  bool _hasMore = true;

  bool get _canCreate => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.createProcessingUrl, 'main', _crudInfo);
  bool get _canEdit => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.updateProcessingUrl, 'main', _crudInfo);
  bool get _canDelete => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.deleteProcessingUrl, 'main', _crudInfo);
  bool get _canResetPassword => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.createProcessingUrl, 'password_reset_link_generation_process_url', _crudInfo);

  @override
  void initState() {
    super.initState();
    guardPageEntry(ref, context, 'flutter_apps_eblood_bank_profile_users');
    _crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_profile_users',
    );
    _service = UserNetworkServiceImpl(_crudInfo);
    _scrollController.addListener(_onScroll);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchUsers({String? query, bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _page = 0;
        _hasMore = true;
      });
    }
    try {
      final resp = await _service.listUsers(
        page: reset ? 0 : _page,
        limit: _limit,
        searchQuery: query,
      );
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
        final parsed = items
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          if (reset) {
            _users = parsed;
          } else {
            _users.addAll(parsed);
          }
          _hasMore = parsed.length >= _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = true;
          _errorMessage = resp.message ?? 'error_loading_data'.tr;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _fetchUsers(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
      reset: false,
    );
  }

  Future<void> _onRefresh() async {
    await _fetchUsers(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  void _onSearch(String query) {
    _fetchUsers(query: query.isNotEmpty ? query : null);
  }

  Future<void> _onAddUser() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddUserPage(rbacFlag: 'flutter_apps_eblood_bank_profile_users')),
    );
    if (result == true) {
      _fetchUsers();
    }
  }

  Future<void> _onLockUnlock(Map<String, dynamic> user) async {
    final userId = user['_id'] ?? '';
    final currentStatus = (user['account_status'] ?? '').toString().toLowerCase();
    final newStatus = currentStatus == 'locked' ? 'active' : 'locked';
    try {
      final resp = await _service.updateUser(userId, {'account_status': newStatus});
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('operation_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUsers();
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

  Future<void> _onResetPassword(Map<String, dynamic> user) async {
    final userId = user['_id'] ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'reset_password'.tr,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'confirm_reset_password'.tr,
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('confirm'.tr, style: GoogleFonts.ubuntu()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final resp = await _service.updateUser(userId, {'reset_password': true});
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('password_reset_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _onDeleteUser(Map<String, dynamic> user) async {
    final userId = user['_id'] ?? '';
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
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
                'delete_user'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '${'confirm_delete_user'.tr}\n\n$fullName',
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
      final resp = await _service.deleteUser(userId);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user_deleted_successfully'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUsers();
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.amber.shade700;
      case 'locked':
        return Colors.blue;
      case 'revoqued':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'active'.tr;
      case 'inactive':
        return 'inactive'.tr;
      case 'locked':
        return 'locked'.tr;
      case 'revoqued':
        return 'revoqued'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'users_management'.tr,
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _onAddUser,
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
              icon: const Icon(Iconsax.user_add),
              label: Text('add_user'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.isEmpty) _onSearch('');
        },
        onSubmitted: _onSearch,
        style: GoogleFonts.ubuntu(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'search_by_name_username'.tr,
          hintStyle: GoogleFonts.ubuntu(color: Colors.white70),
          prefixIcon: const Icon(Iconsax.search_normal_1, color: Colors.white70),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmerList();
    if (_hasError) return _buildErrorState();
    if (_users.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: ColorPages.COLOR_PRINCIPAL),
              ),
            );
          }
          return _buildUserTile(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final username = user['username'] ?? '';
    final status = (user['account_status'] ?? 'inactive').toString().toLowerCase();
    final role = user['role'] is Map ? (user['role']['name'] ?? '') : '';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Iconsax.user, color: statusColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName.isNotEmpty ? fullName : username,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _statusLabel(status),
                style: GoogleFonts.ubuntu(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (username.isNotEmpty)
                Text(
                  '@$username',
                  style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade600),
                ),
              if (role.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Iconsax.shield_tick, size: 14, color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        role,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: ColorPages.COLOR_PRINCIPAL,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        trailing: (_canEdit || _canResetPassword || _canDelete)
            ? PopupMenuButton<String>(
                icon: const Icon(Iconsax.more, color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddUserPage(rbacFlag: 'flutter_apps_eblood_bank_profile_users')),
                      );
                      break;
                    case 'lock_unlock':
                      _onLockUnlock(user);
                      break;
                    case 'reset_password':
                      _onResetPassword(user);
                      break;
                    case 'delete':
                      _onDeleteUser(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
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
                  if (_canEdit)
                    PopupMenuItem(
                      value: 'lock_unlock',
                      child: Row(
                        children: [
                          Icon(
                            status == 'locked' ? Iconsax.unlock : Iconsax.lock,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status == 'locked' ? 'unlock'.tr : 'lock'.tr,
                            style: GoogleFonts.ubuntu(),
                          ),
                        ],
                      ),
                    ),
                  if (_canResetPassword)
                    PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          const Icon(Iconsax.key, size: 18, color: Colors.purple),
                          const SizedBox(width: 10),
                          Text('reset_password'.tr, style: GoogleFonts.ubuntu()),
                        ],
                      ),
                    ),
                  if (_canDelete) ...[
                    const PopupMenuDivider(),
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
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 100, color: Colors.white),
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
                  Icon(Iconsax.user_search, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'no_users_found'.tr,
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
