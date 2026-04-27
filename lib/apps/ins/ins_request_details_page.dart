import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';

class InsRequestDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const InsRequestDetailsPage({super.key, required this.data});

  @override
  ConsumerState<InsRequestDetailsPage> createState() => _InsRequestDetailsPageState();
}

class _InsRequestDetailsPageState extends ConsumerState<InsRequestDetailsPage> {
  String _stringOf(dynamic v) => v?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_ins_request',
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final status = _stringOf(data['status']);
    final statusLbl = _stringOf(data['status_lbl']).isNotEmpty ? _stringOf(data['status_lbl']) : status;
    final insNumber = _stringOf(data['ins_number']);

    final firstName = _stringOf(data['first_name']);
    final lastName = _stringOf(data['last_name']);
    final middleName = _stringOf(data['middle_name']);
    final email = _stringOf(data['email']);
    final phone = _stringOf(data['phone_number']);
    final dob = _stringOf(data['date_of_birth']);
    final gender = _stringOf(data['gender']);

    final bloodTypeName = (data['blood_type'] is Map && (data['blood_type']['name']) != null)
        ? data['blood_type']['name'].toString()
        : '';
    final maritalStatusName = (data['marital_status'] is Map && (data['marital_status']['name']) != null)
        ? data['marital_status']['name'].toString()
        : '';
    final rhesus = _stringOf(data['rhesus_factor']);

    String _nameOfMap(dynamic v) => (v is Map && v['name'] != null) ? v['name'].toString() : '';

    final countryName = _nameOfMap(data['country_entiry']);
    final provinceName = _nameOfMap(data['province_entiry']);
    final townName = _nameOfMap(data['town_entity']);
    final townshipName = _nameOfMap(data['township_entity']);

    final idCardUrl = _stringOf(data['id_card_image_path']);
    final faceUrl = _stringOf(data['face_image_path']);

    final quarter = _stringOf(data['quarter']);
    final avenue = _stringOf(data['avenue']);
    final houseNumber = _stringOf(data['house_number']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ins_request_details'.tr,
          style: GoogleFonts.ubuntu(
            color: ColorPages.COLOR_PRINCIPAL,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section(
              title: 'status'.tr,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Text(
                      statusLbl.isNotEmpty ? statusLbl : (status.isEmpty ? 'N/A' : status),
                      style: GoogleFonts.ubuntu(color: Colors.indigo.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (insNumber.isNotEmpty)
                    Text('INS: $insNumber', style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade800)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'personal_information'.tr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('full_name'.tr, [firstName, middleName, lastName].where((s) => s.isNotEmpty).join(' ')),
                  if (gender.isNotEmpty) _kv('gender'.tr, gender),
                  if (dob.isNotEmpty) _kv('date_of_birth'.tr, dob),
                  if (email.isNotEmpty) _kv('email'.tr, email),
                  if (phone.isNotEmpty) _kv('phone_number'.tr, phone),
                  if (bloodTypeName.isNotEmpty) _kv('blood_type'.tr, bloodTypeName),
                  if (rhesus.isNotEmpty) _kv('rhesus_factor'.tr, rhesus),
                  if (maritalStatusName.isNotEmpty) _kv('marital_status'.tr, maritalStatusName),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'your_location'.tr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (countryName.isNotEmpty) _kv('country'.tr, countryName),
                  if (provinceName.isNotEmpty) _kv('province'.tr, provinceName),
                  if (townName.isNotEmpty) _kv('town'.tr, townName),
                  if (townshipName.isNotEmpty) _kv('township'.tr, townshipName),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'address'.tr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quarter.isNotEmpty) _kv('quarter'.tr, quarter),
                  if (avenue.isNotEmpty) _kv('avenue'.tr, avenue),
                  if (houseNumber.isNotEmpty) _kv('house_number'.tr, houseNumber),
                ],
              ),
            ),
            if (idCardUrl.isNotEmpty || faceUrl.isNotEmpty) const SizedBox(height: 12),
            if (idCardUrl.isNotEmpty || faceUrl.isNotEmpty)
              _section(
                title: 'documents'.tr,
                child: Row(
                  children: [
                    if (idCardUrl.isNotEmpty)
                      Expanded(
                        child: _imageCard(
                          context,
                          label: 'id_card'.tr,
                          url: idCardUrl,
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    if (idCardUrl.isNotEmpty && faceUrl.isNotEmpty) const SizedBox(width: 12),
                    if (faceUrl.isNotEmpty)
                      Expanded(
                        child: _imageCard(
                          context,
                          label: 'ins_step_photo'.tr,
                          url: faceUrl,
                          icon: Icons.face_retouching_natural_outlined,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _kv(String keyLabel, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(keyLabel, style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _imageCard(BuildContext context, {required String label, required String url, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showImageDialog(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Icon(icon, size: 36, color: Colors.grey.shade500),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

}

