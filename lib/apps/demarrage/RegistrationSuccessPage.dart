import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
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
              
              // Success animation
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_s4tubvxb.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Heading
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Registration Successful!',
                  style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Your account has been created successfully. You can now log in to access all features.',
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
                            'Phone: ',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            phoneNumber,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                            'Email: ',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Continue button
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: CustomButton(
                  text: 'Continue to Login',
                  onPressed: () {
                    // Navigate to login page
                    Get.offAllNamed('/welcome');
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