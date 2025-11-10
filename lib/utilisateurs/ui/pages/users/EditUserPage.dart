import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/models/user_model.dart';
import '../../../business/service/UserNetworkServiceImpl.dart';

class EditUserPage extends StatefulWidget {
  final TUserModel user;
  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserNetworkServiceImpl();

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  String _gender = 'm';
  String? _selectedRoleId;
  bool _submitting = false;
  List<Map<String, String>> _roles = const [];

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _emailCtrl = TextEditingController(text: widget.user.emailAddress);
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber);
    _gender = (widget.user.gender.toLowerCase().startsWith('f')) ? 'f' : 'm';
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

    setState(() => _submitting = true);

    final payload = {
      'username': _usernameCtrl.text.trim(),
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'gender': _gender,
      'email': _emailCtrl.text.trim(),
      'email_address': _emailCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      if (_selectedRoleId != null && _selectedRoleId!.isNotEmpty) 'rbac_role_id': _selectedRoleId,
    };

    final resp = await _service.updateUser(widget.user.id, payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('user_updated_successfully'.tr)));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message ?? 'operation_failed'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_user'.tr),
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

