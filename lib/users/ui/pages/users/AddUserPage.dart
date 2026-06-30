import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../core/rbac/services/rbac_guard.dart';
import '../../../../core/rbac/providers/rbac_provider.dart';
import '../../../../core/dynamic_form/models/dynamic_form_field.dart';
import '../../../../core/dynamic_form/services/dynamic_form_parser.dart';
import '../../../../core/dynamic_form/widgets/dynamic_form_widget.dart';
import '../../../business/service/UserNetworkServiceImpl.dart';

class AddUserPage extends ConsumerStatefulWidget {
  final String rbacFlag;
  const AddUserPage({
    super.key,
    this.rbacFlag = 'flutter_apps_eblood_bank_hosp_home_users',
  });

  @override
  ConsumerState<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends ConsumerState<AddUserPage> {
  late final UserNetworkServiceImpl _service;
  final _parser = DynamicFormParser();
  final _formWidgetKey = GlobalKey<DynamicFormWidgetState>();

  List<DynamicFormField> _fields = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    guardPageEntry(ref, context, widget.rbacFlag);
    final crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      widget.rbacFlag,
    );
    _service = UserNetworkServiceImpl(crudInfo);
    _loadHead();
  }

  Future<void> _loadHead() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final resp = await _service.fetchCreateHead();
    if (!mounted) return;

    if (kDebugMode) print('[AddUserPage] HEAD response: ${resp.data}');

    if (resp.success && resp.data != null) {
      try {
        Map<String, dynamic> headData;
        if (resp.data is Map<String, dynamic>) {
          headData = resp.data as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected HEAD response format');
        }

        final fields = _parser.parse(headData);
        setState(() {
          _fields = fields;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = resp.message ?? 'error_loading_data'.tr;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final payload = _parser.collectValues(_fields);
    if (kDebugMode) print('[AddUserPage] Submitting payload: $payload');

    final resp = await _service.createUser(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user_created_successfully'.tr),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.message ?? 'operation_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'add_user'.tr,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_hasError) return _buildError();
    if (_fields.isEmpty) return _buildEmpty();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DynamicFormWidget(
        key: _formWidgetKey,
        fields: _fields,
        isSubmitting: _submitting,
        onSubmit: _submit,
        submitLabel: 'save'.tr,
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            6,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
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
              onPressed: _loadHead,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.document, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'no_form_fields'.tr,
            style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

