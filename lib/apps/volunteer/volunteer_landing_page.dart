import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';
import 'volunteer_reasons_page.dart';
import 'benevol_donor_landing_page.dart';
import '../widgets/GradientScaffold.dart';

class VolunteerLandingPage extends ConsumerStatefulWidget {
  const VolunteerLandingPage({super.key});

  @override
  ConsumerState<VolunteerLandingPage> createState() => _VolunteerLandingPageState();
}

class _VolunteerLandingPageState extends ConsumerState<VolunteerLandingPage> {
  @override
  void initState() {
    super.initState();
    // RBAC entry guard — volunteer sub_menu flag.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_volunteer',
    );
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
                      'volunteer_page_title'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SVG Illustration
                      SvgPicture.asset(
                        'assets/svg/blood-donation-rafiki.svg',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      _actionCard(
                        context,
                        title: 'volunteer_button_why'.tr,
                        subtitle: 'volunteer_button_why_sub'.tr,
                        icon: Icons.help_outline,
                        color: Colors.indigo,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VolunteerReasonsPage()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _actionCard(
                        context,
                        title: 'volunteer_button_yes'.tr,
                        subtitle: 'volunteer_button_yes_sub'.tr,
                        icon: Icons.volunteer_activism,
                        color: Colors.red,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BenevolDonorLandingPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required MaterialColor color, required VoidCallback onTap}) {
    final Color bg = color.shade200;
    final Color textColor = color.shade900;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(fontSize: 13, color: textColor.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

