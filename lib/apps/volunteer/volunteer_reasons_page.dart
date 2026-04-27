import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';
import 'volunteer_service.dart';

import '../widgets/GradientScaffold.dart';
class VolunteerReasonsPage extends ConsumerStatefulWidget {
  const VolunteerReasonsPage({super.key});

  @override
  ConsumerState<VolunteerReasonsPage> createState() => _VolunteerReasonsPageState();
}

class _VolunteerReasonsPageState extends ConsumerState<VolunteerReasonsPage> {
  final _service = VolunteerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    // RBAC entry guard — volunteer sub_menu flag.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_volunteer',
    );
    _future = _service.fetchReasons();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header with back button and title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'volunteer_why_title'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('reasons_failed_to_load'.tr, style: GoogleFonts.ubuntu()));
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return Center(child: Text('reasons_empty'.tr, style: GoogleFonts.ubuntu()));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final item = list[i];
                      final title = (item['title'] ?? '').toString();
                      final reason = (item['reason'] ?? '').toString();
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL)),
                            const SizedBox(height: 8),
                            Text(reason, style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade800)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

