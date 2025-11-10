import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../business/service/UserNetworkServiceImpl.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserNetworkServiceImpl();

  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  String _gender = 'm';
  String? _selectedRoleId;
  bool _autoPassword = true;
  bool _submitting = false;
  List<Map<String, String>> _roles = const [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final resp = await _service.getRoles();
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
        _roles = items.whereType<Map<String, dynamic>>()
            .map((e) => {
                  'id': (e['id'] ?? e['_id'] ?? '').toString(),
                  'name': (e['name'] ?? e['label'] ?? e['role_name'] ?? '').toString(),
                })
            .where((e) => e['id']!.isNotEmpty)
            .map((e) => {'id': e['id']!, 'name': e['name']!.isEmpty ? e['id']! : e['name']!})
            .toList();
      });
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_autoPassword && _passwordCtrl.text != _password2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('passwords_dont_match'.tr)));
      return;
    }
    if (_selectedRoleId == null || _selectedRoleId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_role'.tr)));
      return;
    }

    setState(() => _submitting = true);

    final payload = {
      'username': _usernameCtrl.text.trim(),
      'password': _autoPassword ? 'Auto1234!' : _passwordCtrl.text,
      'password2': _autoPassword ? 'Auto1234!' : _password2Ctrl.text,
      'telephones': [_phoneCtrl.text.trim()],
      'emails': [_emailCtrl.text.trim()],
      'others': <String>[],
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'sur_name': null,
      'gender': _gender,
      'birth_city': null,
      'birth_day': null,
      'address': null,
      'is_auto_password_selected': _autoPassword,
      'rbac_role_id': _selectedRoleId,
    };

    final resp = await _service.createUser(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('user_created_successfully'.tr)));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message ?? 'operation_failed'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('add_user'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(labelText: 'username'.tr),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: InputDecoration(labelText: 'first_name'.tr),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: InputDecoration(labelText: 'last_name'.tr),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(labelText: 'gender'.tr),
                items: [
                  DropdownMenuItem(value: 'm', child: Text('male'.tr)),
                  DropdownMenuItem(value: 'f', child: Text('female'.tr)),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'm'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'email'.tr),
                keyboardType: TextInputType.emailAddress,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'phone_number'.tr),
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _autoPassword,
                title: Text('auto_generate_password'.tr),
                onChanged: (v) => setState(() => _autoPassword = v),
              ),
              if (!_autoPassword) ...[
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: InputDecoration(labelText: 'password'.tr),
                  obscureText: true,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password2Ctrl,
                  decoration: InputDecoration(labelText: 'confirm_password'.tr),
                  obscureText: true,
                  validator: _required,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRoleId,
                decoration: InputDecoration(labelText: 'role'.tr),
                items: _roles
                    .map((e) => DropdownMenuItem<String>(
                          value: e['id'],
                          child: Text(e['name'] ?? e['id']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoleId = v),
                validator: (v) => v == null || v.isEmpty ? 'select_role'.tr : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('save'.tr),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

