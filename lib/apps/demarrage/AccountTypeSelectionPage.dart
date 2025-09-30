import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import '../config/theme/ColorPages.dart';

class AccountTypeSelectionPage extends StatelessWidget {
  final Map<String, dynamic>? extra;
  
  const AccountTypeSelectionPage({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'select_account_type'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
                        icon: Ionicons.person_outline,
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
                        icon: Ionicons.medical_outline,
                        title: 'hospital_account'.tr,
                        description: 'hospital_account_description'.tr,
                        color: Colors.blue[600]!,
                        onTap: () => _navigateToRegistration(context, 'hospital'),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Blood Bank Account
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                      child: _buildAccountTypeCard(
                        context: context,
                        icon: Ionicons.water_outline,
                        title: 'blood_bank_account'.tr,
                        description: 'blood_bank_account_description'.tr,
                        color: Colors.red[600]!,
                        onTap: () => _navigateToRegistration(context, 'blood_bank'),
                      ),
                    ),
                  ],
                ),
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
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
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
                      color: Colors.black87,
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
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(BuildContext context, String accountType) {
    // Get the verification mode from extra parameters
    final String verificationMode = extra?['verification_mode'] ?? 'email';
    
    switch (accountType) {
      case 'personal':
        context.push('/personal-registration', extra: {'verification_mode': verificationMode});
        break;
      case 'hospital':
        context.push('/hospital-registration', extra: {'verification_mode': verificationMode});
        break;
      case 'blood_bank':
        context.push('/blood-bank-registration', extra: {'verification_mode': verificationMode});
        break;
    }
  }
}
