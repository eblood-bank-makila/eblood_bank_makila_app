/// Address View Page
/// Displays hospital address after payment

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/search_flow_provider.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

class AddressViewPage extends ConsumerWidget {
  const AddressViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFlowProvider);
    final hospital = state.identifiedHospital;

    if (hospital == null) {
      return Scaffold(
        appBar: SearchFlowAppBar(
          title: 'address'.tr.isEmpty ? 'Address' : 'address'.tr,
          onBack: () => context.go('/blood-search'),
        ),
        body: Center(
          child: Text('no_hospital_selected'.tr.isEmpty 
              ? 'No hospital selected' 
              : 'no_hospital_selected'.tr),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'hospital_address'.tr.isEmpty ? 'Hospital Address' : 'hospital_address'.tr,
        onBack: () => context.go('/blood-search'),
        showClose: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'address_unlocked'.tr.isEmpty ? 'Address Unlocked!' : 'address_unlocked'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'you_can_now_visit'.tr.isEmpty
                        ? 'You can now visit the hospital to get your blood product'
                        : 'you_can_now_visit'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hospital details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital name
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.hospital,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            if (hospital.code.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${hospital.code}',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // Address
                  _InfoRow(
                    icon: Iconsax.location,
                    label: 'address'.tr.isEmpty ? 'Address' : 'address'.tr,
                    value: hospital.address ?? 'Address not available',
                    onCopy: () => _copyToClipboard(context, hospital.address ?? ''),
                  ),

                  const SizedBox(height: 16),

                  // Phone
                  if (hospital.phone != null && hospital.phone!.isNotEmpty) ...[
                    _InfoRow(
                      icon: Iconsax.call,
                      label: 'phone'.tr.isEmpty ? 'Phone' : 'phone'.tr,
                      value: hospital.phone!,
                      onCopy: () => _copyToClipboard(context, hospital.phone!),
                      onTap: () => _callPhone(hospital.phone!),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Coordinates
                  if (hospital.latitude != null && hospital.longitude != null) ...[
                    _InfoRow(
                      icon: Iconsax.gps,
                      label: 'coordinates'.tr.isEmpty ? 'Coordinates' : 'coordinates'.tr,
                      value: '${hospital.latitude!.toStringAsFixed(6)}, ${hospital.longitude!.toStringAsFixed(6)}',
                      onCopy: () => _copyToClipboard(
                        context, 
                        '${hospital.latitude!}, ${hospital.longitude!}',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Iconsax.map,
                    label: 'open_in_maps'.tr.isEmpty ? 'Open in Maps' : 'open_in_maps'.tr,
                    color: Colors.blue,
                    onTap: () => _openInMaps(hospital),
                  ),
                ),
                const SizedBox(width: 12),
                if (hospital.phone != null && hospital.phone!.isNotEmpty)
                  Expanded(
                    child: _ActionButton(
                      icon: Iconsax.call,
                      label: 'call'.tr.isEmpty ? 'Call' : 'call'.tr,
                      color: Colors.green,
                      onTap: () => _callPhone(hospital.phone!),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Blood type reminder
            if (state.searchedBloodType != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.searchedBloodType!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'blood_type_needed'.tr.isEmpty 
                                ? 'Blood Type Needed' 
                                : 'blood_type_needed'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'show_this_at_reception'.tr.isEmpty
                                ? 'Show this at the reception'
                                : 'show_this_at_reception'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Done button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(searchFlowProvider.notifier).resetFlow();
                  context.go('/blood-search');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'done'.tr.isEmpty ? 'Done' : 'done'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'copied_to_clipboard'.tr.isEmpty ? 'Copied to clipboard' : 'copied_to_clipboard'.tr,
          style: GoogleFonts.ubuntu(),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openInMaps(hospital) async {
    if (hospital.latitude != null && hospital.longitude != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${hospital.latitude},${hospital.longitude}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Open with address search
      final query = Uri.encodeComponent(hospital.address);
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? Colors.blue : Colors.grey.shade800,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            icon: Icon(Iconsax.copy, size: 18, color: Colors.grey.shade500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
