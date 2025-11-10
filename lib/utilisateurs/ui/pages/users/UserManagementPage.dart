import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/models/user_model.dart';
import '../../../business/service/UserNetworkServiceImpl.dart';
import 'AddUserPage.dart';
import 'EditUserPage.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _service = UserNetworkServiceImpl();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<TUserModel> _users = const [];
  int _page = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> m) {
    final out = Map<String, dynamic>.from(m);
    if (!out.containsKey('email_address')) {
      if (out['email_address'] == null && out['email'] != null) out['email_address'] = out['email'];
      if (out['email_address'] == null && out['emails'] is List && (out['emails'] as List).isNotEmpty) {
        final first = (out['emails'] as List).first;
        if (first is String) {
          out['email_address'] = first;
        } else if (first is Map && first['email'] != null) {
          out['email_address'] = first['email'];
        }
      }
    }
    if (!out.containsKey('phone_number')) {
      if (out['phone_number'] == null && out['phone'] != null) out['phone_number'] = out['phone'];
      if (out['phone_number'] == null && out['phone_numbers'] is List && (out['phone_numbers'] as List).isNotEmpty) {
        final first = (out['phone_numbers'] as List).first;
        if (first is String) {
          out['phone_number'] = first;
        } else if (first is Map && first['phone_number'] != null) {
          out['phone_number'] = first['phone_number'];
        }
      }
    }
    return out;
  }

  Future<void> _fetchUsers({String? query, bool reset = true}) async {
    setState(() => _loading = true);
    final resp = await _service.listUsers(page: reset ? 0 : _page, limit: _limit, searchQuery: query);
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
          .map((e) => TUserModel.fromJson(_normalizeUser(e)))
          .toList();
      setState(() {
        _users = parsed;
        _page = reset ? 0 : _page;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (resp.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message!)));
      }
    }
  }

  Future<void> _onAddUser() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddUserPage()),
    );
    if (result == true) {
      _fetchUsers(reset: true);
    }
  }

  Future<void> _onEditUser(TUserModel u) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditUserPage(user: u)),
    );
    if (result == true) {
      _fetchUsers(reset: true);
    }
  }

  Future<void> _onDeleteUser(TUserModel u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_user'.tr),
        content: Text('confirm_delete_user'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (confirm != true) return;
    final resp = await _service.deleteUser(u.id);
    if (!mounted) return;
    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('user_deleted_successfully'.tr)));
      _fetchUsers(reset: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message ?? 'operation_failed'.tr)));
    }
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('no_users_found'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final u = _users[index];
        final title = u.username.isNotEmpty ? u.username : (u.emailAddress.isNotEmpty ? u.emailAddress : 'user_details'.tr);
        final subtitleParts = <String>[];
        if (u.firstName.isNotEmpty || u.lastName.isNotEmpty) subtitleParts.add([u.firstName, u.lastName].where((e) => e.isNotEmpty).join(' '));
        if (u.emailAddress.isNotEmpty) subtitleParts.add(u.emailAddress);
        if (u.phoneNumber.isNotEmpty) subtitleParts.add(u.phoneNumber);

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(title),
          subtitle: Text(subtitleParts.join(' • ')),
          onTap: () => _onEditUser(u),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _onEditUser(u)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _onDeleteUser(u)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user_management'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search_users'.tr,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) => _fetchUsers(query: value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _fetchUsers(reset: true);
                  },
                )
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        onPressed: _onAddUser,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

