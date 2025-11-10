import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/GradientScaffold.dart';
import '../volunteer/volunteer_registration_stepper.dart';
import 'ins_request_stepper.dart';

class InsLandingPage extends StatelessWidget {
  const InsLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back + title
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
                      'request_your_ins'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionCard(
                        context,
                        title: 'ins_button_what'.tr,
                        subtitle: 'ins_button_what_sub'.tr,
                        icon: Icons.help_outline,
                        color: Colors.indigo,
                        onTap: () => _showWhatIsInsSheet(context),
                      ),
                      const SizedBox(height: 16),
                      _actionCard(
                        context,
                        title: 'ins_button_yes'.tr,
                        subtitle: 'ins_button_yes_sub'.tr,
                        icon: Icons.badge_outlined,
                        color: Colors.red,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const InsRequestStepper()),
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

  void _showWhatIsInsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge_outlined, color: ColorPages.COLOR_PRINCIPAL),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ins_explain_title'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('ins_explain_body'.tr, style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: ColorPages.COLOR_PRINCIPAL),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('ins_explain_hint'.tr, style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

