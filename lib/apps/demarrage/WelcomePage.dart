import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/services/FirebaseAuthService.dart';
import 'package:eblood_bank_mak_app/apps/services/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:get/get.dart';
import '../widgets/LanguageSelector.dart';
import '../components/SponsorFooter.dart';
import '../services/AuthApi.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => context.go('/debug/first-launch'),
      //   backgroundColor: Colors.white.withValues(alpha: 0.2),
      //   child: const Icon(Icons.bug_report, color: Colors.white),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.red.shade50,
              Colors.red.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // Add some top spacing for the language selector
                              const SizedBox(height: 60),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // FadeInDown(
                          //   duration: const Duration(milliseconds: 800),
                          //   child: Container(
                          //     width: 60,
                          //     height: 60,
                          //     decoration: BoxDecoration(
                          //       shape: BoxShape.circle,
                          //       color: ColorPages.COLOR_BLANCHE.withOpacity(0.1),
                          //       border: Border.all(
                          //         color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                          //         width: 2,
                          //       ),
                          //     ),
                          //     child: Center(
                          //       child: Image.asset(
                          //         'assets/icons/cnts.png',
                          //         width: 45,
                          //         height: 45,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 20),
                          // Container(
                          //   height: 60,
                          //   width: 4,
                          //   decoration: BoxDecoration(
                          //     color: ColorPages.COLOR_PRINCIPAL,
                          //     borderRadius: BorderRadius.circular(5),
                          //   ),
                          // ),
                          // const SizedBox(width: 20),
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                                border: Border.all(
                                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/image4.png',
                                  width: 90,
                                  height: 90,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'welcome'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 400),
                        child: Text(
                          'welcome_message'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  Column(
                    children: [
                      // Email login button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: _buildLoginButton(
                          context: context,
                          icon: Icons.mail_outline,
                          text: 'sign_in_with_email'.tr,
                          color: ColorPages.COLOR_PRINCIPAL,
                          textColor: Colors.white,
                          onPressed: () {
                            context.go('/login');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Divider
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Social login buttons
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: _buildSocialLoginButton(
                          context: context,
                          icon: Ionicons.logo_google,
                          text: 'sign_in_with_google'.tr,
                          color: Colors.white,
                          textColor: Colors.grey.shade700,
                          borderColor: Colors.grey.shade300,
                          onPressed: () async {
                            await _handleGoogleSignIn(context, ref);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FadeInUp(
                      //   duration: const Duration(milliseconds: 600),
                      //   delay: const Duration(milliseconds: 900),
                      //   child: _buildSocialLoginButton(
                      //     context: context,
                      //     icon: Ionicons.phone_portrait_outline,
                      //     text: 'sign_in_with_phone_number'.tr,
                      //     color: ColorPages.COLOR_PRINCIPAL,
                      //     textColor: Colors.white,
                      //     onPressed: () {
                      //       _showComingSoonDialog(context, 'PhoneNumber');
                      //     },
                      //   ),
                      // ),
                      // const SizedBox(height: 12),

                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1000),
                        child: _buildVisitorButton(context),
                      ),
                      const SizedBox(height: 16),
                      
                      // Search Blood button - leads to blood search flow
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1100),
                        child: _buildSearchBloodButton(context),
                      ),
                    ],
                  ),
                  
                  // Register link
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 1200),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Vous n\'avez pas de compte ? ',
                          style: GoogleFonts.ubuntu(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/register');
                          },
                          child: Text(
                            'S\'inscrire ici',
                            style: GoogleFonts.ubuntu(
                              color: ColorPages.COLOR_PRINCIPAL,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sponsor Footer
                const SizedBox(height: 16),
                const SponsorFooter(
                  labelKey: 'accompanied_by',
                  logoHeight: 45,
                  logoSpacing: 12,
                ),
                const SizedBox(height: 20), // Add padding at the bottom
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Language selector positioned on top
              Positioned(
                top: 16,
                right: 24,
                child: FadeInRight(
                  duration: const Duration(milliseconds: 600),
                  child: CompactLanguageSelector(
                    iconColor: ColorPages.COLOR_PRINCIPAL,
                    showBottomSheet: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: borderColor != null ? 0 : 1,
          shadowColor: color.withOpacity(0.2),
          side: borderColor != null ? BorderSide(color: borderColor, width: 1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Attempt visitor login based on device link
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              final result = await AuthApi.instance.visitorLoginCheck();
              if (context.mounted) Navigator.of(context).pop();

              final next = (result['nextAction'] ?? '').toString();
              if (next == 'login') {
                if (context.mounted) context.go('/app/MainApp');
              } else if (next == 'select_entity') {
                if (context.mounted) context.push('/visitor/select-entity');
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message']?.toString() ?? 'Unable to continue as visitor'), backgroundColor: Colors.red),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.eye_outline,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'continue_as_visitor'.tr,
                style: GoogleFonts.ubuntu(
                  color: ColorPages.COLOR_PRINCIPAL,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBloodButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.red.shade600,
            Colors.red.shade400,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/blood-search');
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.search_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'search_blood'.tr.isEmpty ? 'Search Blood' : 'search_blood'.tr,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Sign in with Firebase
      final authService = ref.read(firebaseAuthServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      // Get Firebase ID token
      final idToken = await authService.getIdToken();
      if (idToken == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
          _showErrorDialog(context, 'error'.tr, 'Failed to get authentication token');
        }
        return;
      }

      // Call backend Google login endpoint
      final authApi = AuthService();
      final result = await authApi.googleLogin({
        'google_id_token': idToken,
        'email': userCredential.user?.email,
      });

      if (context.mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        // Handle auto-login response - same as OTP validation success
        await authApi.handleAutoLoginAfterRegistration(result);

        // Navigate to main app
        if (context.mounted) context.go('/app/MainApp');
      } else {
        // Handle login failure
        final message = result['message'] ?? 'Login failed';
        final statusCode = result['statusCode'] ?? 500;

        // Email already registered with different method (409 CONFLICT)
        if (statusCode == 409) {
          // Sign out from Firebase since they can't use Google login
          await authService.signOut();
          if (context.mounted) {
            _showErrorDialog(context, 'login_error'.tr, message);
          }
        }
        // User not found - redirect to registration
        else if (statusCode == 404 || message.toLowerCase().contains('not found')) {
          if (context.mounted) {
            context.push('/account-type-selection', extra: {
              'registration_mode': 'google',
              'google_email': userCredential.user?.email,
              'google_display_name': userCredential.user?.displayName,
              'google_photo_url': userCredential.user?.photoURL,
              'google_id_token': idToken,
              'google_user': {
                'email': userCredential.user?.email,
                'displayName': userCredential.user?.displayName,
                'photoURL': userCredential.user?.photoURL,
                'uid': userCredential.user?.uid,
              }
            });
          }
        } else {
          // Other errors
          if (context.mounted) {
            _showErrorDialog(context, 'login_error'.tr, message);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'connection_error'.tr, 'connection_error_message'.tr);
      }
    }
  }

  void _showComingSoonDialog(BuildContext context, String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'coming_soon'.tr,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'coming_soon_message'.tr.replaceAll('@platform', platform),
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'ok'.tr,
              style: GoogleFonts.ubuntu(
                color: ColorPages.COLOR_PRINCIPAL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.ubuntu(
                color: ColorPages.COLOR_PRINCIPAL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
