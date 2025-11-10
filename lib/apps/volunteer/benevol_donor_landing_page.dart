import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme/ColorPages.dart';
import 'volunteer_reasons_page.dart';
import 'benevol_donor_registration_stepper.dart';
import '../widgets/GradientScaffold.dart';

class BenevolDonorLandingPage extends StatelessWidget {
  const BenevolDonorLandingPage({super.key});

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
                      'become_benevol_donor'.tr,
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
                        title: 'benevol_button_why'.tr,
                        subtitle: 'benevol_button_why_sub'.tr,
                        icon: Icons.help_outline,
                        color: Colors.indigo,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VolunteerReasonsPage()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _actionCard(
                        context,
                        title: 'benevol_button_yes'.tr,
                        subtitle: 'benevol_button_yes_sub'.tr,
                        icon: Icons.volunteer_activism,
                        color: Colors.red,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BenevolDonorRegistrationStepper()),
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

  Widget _actionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700, color: ColorPages.COLOR_NOIR),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w400, color: ColorPages.COLOR_GRIS),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

