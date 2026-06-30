import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../config/theme/ColorPages.dart';
import '../components/SponsorFooter.dart';

class AccountTypeSelectionPage extends StatelessWidget {
  final Map<String, dynamic>? extra;
  
  const AccountTypeSelectionPage({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorPages.COLOR_BLANCHE),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'select_account_type'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ColorPages.COLOR_BLANCHE,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'account_type_description'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Account type cards
              Expanded(
                child: Column(
                  children: [
                    // Personal Account
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: _buildAccountTypeCard(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'personal_account'.tr,
                        description: 'personal_account_description'.tr,
                        color: ColorPages.COLOR_PRINCIPAL,
                        onTap: () => _navigateToRegistration(context, 'personal'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hospital Account
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: _buildAccountTypeCard(
                        context: context,
                        icon: Icons.medical_services_outlined,
                        title: 'health_structure_account'.tr,
                        description: 'health_structure_account_description'.tr,
                        color: ColorPages.COLOR_PRINCIPAL,
                        onTap: () => _navigateToRegistration(context, 'hospital'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Blood Bank Account
                    // FadeInUp(
                    //   duration: const Duration(milliseconds: 600),
                    //   delay: const Duration(milliseconds: 600),
                    //   child: _buildAccountTypeCard(
                    //     context: context,
                    //     icon: Icons.water_drop_outlined,
                    //     title: 'blood_bank_account'.tr,
                    //     description: 'blood_bank_account_description'.tr,
                    //     color: Colors.red[600]!,
                    //     onTap: () => _navigateToRegistration(context, 'blood_bank'),
                    //   ),
                    // ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sponsor Footer
              const SponsorFooter(
                labelKey: 'accompanied_by',
                logoHeight: 50,
                logoSpacing: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),

            const SizedBox(width: 20),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(BuildContext context, String accountType) {
    // Determine registration mode (email or google). Google skips verification.
    final String registrationMode = extra?['registration_mode'] == 'google' ? 'google' : 'email';
    final bool isGoogle = registrationMode == 'google';
    final String verificationMode = isGoogle ? 'none' : 'email';
    final Map<String, dynamic> passExtra = {
      'verification_mode': verificationMode,
      'registration_mode': registrationMode,
      if (isGoogle) ...{
        'google_email': extra?['google_email'],
        'google_display_name': extra?['google_display_name'],
        'google_photo_url': extra?['google_photo_url'],
        'google_id_token': extra?['google_id_token'],
        'google_user': extra?['google_user'],
      }
    };
    
    switch (accountType) {
      case 'personal':
        context.push('/personal-registration', extra: passExtra);
        break;
      case 'hospital':
        context.push('/hospital-registration', extra: passExtra);
        break;
      case 'blood_bank':
        context.push('/blood-bank-registration', extra: passExtra);
        break;
    }
  }
}
