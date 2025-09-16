import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/services/FirebaseAuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/debug/first-launch'),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Bienvenue !',
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
                          'Connectez-vous pour accéder à votre\ncompte E-Blood Bank Makila',
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
                ),
                
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Username login button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: _buildLoginButton(
                          context: context,
                          icon: Icons.person_outline,
                          text: 'Se connecter avec nom d\'utilisateur',
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
                          text: 'Continuer avec Google',
                          color: Colors.white,
                          textColor: Colors.grey.shade700,
                          borderColor: Colors.grey.shade300,
                          onPressed: () async {
                            await _handleGoogleSignIn(context, ref);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 900),
                        child: _buildSocialLoginButton(
                          context: context,
                          icon: Ionicons.logo_facebook,
                          text: 'Continuer avec Facebook',
                          color: const Color(0xFF1877F2),
                          textColor: Colors.white,
                          onPressed: () {
                            _showComingSoonDialog(context, 'Facebook');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1000),
                        child: _buildSocialLoginButton(
                          context: context,
                          icon: Ionicons.logo_twitter,
                          text: 'Continuer avec Twitter',
                          color: const Color(0xFF1DA1F2),
                          textColor: Colors.white,
                          onPressed: () {
                            _showComingSoonDialog(context, 'Twitter');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Register link
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 1100),
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
              ],
            ),
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

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential != null && context.mounted) {
        // Successfully signed in, navigate to main app
        context.go('/app/MainApp');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Erreur de connexion',
          'Une erreur est survenue lors de la connexion avec Google. Veuillez réessayer.');
      }
    }
  }

  void _showComingSoonDialog(BuildContext context, String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bientôt disponible',
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'La connexion avec $platform sera bientôt disponible.',
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
