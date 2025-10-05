import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/CustomButton.dart';

class RegistrationSuccessPage extends StatelessWidget {
  final String phoneNumber;
  final String email;
  final String? token;

  const RegistrationSuccessPage({
    super.key,
    required this.phoneNumber,
    required this.email,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success animation - using local asset instead of network to avoid 403 error
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Lottie.asset(
                  'assets/animations/success_animation.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Heading - translated
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'registration_successful'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description - translated
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'account_created_successfully'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // User information
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Ionicons.call_outline, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'phone_label'.tr + ': ',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              phoneNumber,
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Ionicons.mail_outline, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'email'.tr + ': ',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Continue button - translated
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: CustomButton(
                  text: 'continue_to_login'.tr,
                  onPressed: () {
                    // Navigate to login page using GoRouter
                    context.go('/welcome'); // Using go_router to navigate to welcome page
                  },
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}