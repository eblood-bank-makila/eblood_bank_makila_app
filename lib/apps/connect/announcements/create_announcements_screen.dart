import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../config/theme/ColorPages.dart';
import 'announcements_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPage.dart';

class CreateAnnouncementsScreen extends StatefulWidget {
  final String? initialType;
  const CreateAnnouncementsScreen({super.key, this.initialType});

  @override
  State<CreateAnnouncementsScreen> createState() => _CreateAnnouncementsScreenState();
}

class _CreateAnnouncementsScreenState extends State<CreateAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _type = 'Blood Request';
  String _priority = 'normal';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      _type = widget.initialType!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final service = AnnouncementsService();
      await service.createAnnouncement(
        title: _titleCtrl.text.trim(),
        type: _type,
        location: _locationCtrl.text.trim(),
        priority: _priority,
        description: _descriptionCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('announcement_created_success'.tr),
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
        ),
      );
      _formKey.currentState!.reset();
      _titleCtrl.clear();
      _locationCtrl.clear();
      _descriptionCtrl.clear();
      setState(() {
        _type = 'Blood Request';
        _priority = 'normal';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top header like Banquepage
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('app_name'.tr, style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('create_announcement'.tr, style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage(notification: [])));
                        },
                        icon: const Icon(Iconsax.notification, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Content container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('information'.tr),
                          const SizedBox(height: 8),
                          _input(
                            label: 'title'.tr,
                            controller: _titleCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'title_required'.tr : null,
                          ),
                          const SizedBox(height: 12),
                          _dropdown(
                            label: 'type'.tr,
                            value: _type,
                            items: const ['Blood Request', 'Campaign', 'Event', 'News'],
                            onChanged: (val) => setState(() => _type = val ?? _type),
                          ),
                          const SizedBox(height: 12),
                          _input(
                            label: 'location'.tr,
                            controller: _locationCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'location_required'.tr : null,
                          ),

                          const SizedBox(height: 24),
                          _sectionTitle('details'.tr),
                          const SizedBox(height: 8),
                          _dropdown(
                            label: 'priority'.tr,
                            value: _priority,
                            items: const ['urgent', 'high', 'normal', 'low'],
                            onChanged: (val) => setState(() => _priority = val ?? _priority),
                          ),
                          const SizedBox(height: 12),
                          _input(
                            label: 'description'.tr,
                            controller: _descriptionCtrl,
                            maxLines: 5,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'description_required'.tr : null,
                          ),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('publish'.tr, style: GoogleFonts.ubuntu(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.ubuntu(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(_translateDropdownValue(e)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _translateDropdownValue(String value) {
    switch (value) {
      case 'Blood Request':
        return 'blood_request'.tr;
      case 'Campaign':
        return 'campaign'.tr;
      case 'Event':
        return 'event'.tr;
      case 'News':
        return 'news'.tr;
      case 'urgent':
        return 'urgent'.tr;
      case 'high':
        return 'high'.tr;
      case 'normal':
        return 'normal'.tr;
      case 'low':
        return 'low'.tr;
      default:
        return value;
    }
  }
}
