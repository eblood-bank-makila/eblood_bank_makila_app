import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/motdepasse/OtpCodePasswordPage.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/motdepasse/ReinitialiserMotDePasseCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ReinitialiserMotDePassePage extends ConsumerStatefulWidget {
  const ReinitialiserMotDePassePage({super.key});

  @override
  ConsumerState createState() => _ReinitialiserMotDePassePageState();
}

class _ReinitialiserMotDePassePageState extends ConsumerState<ReinitialiserMotDePassePage> {
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Keep the provider alive to prevent auto-disposal
    ref.read(reinitialiserMotDePasseCtrlProvider.notifier);

    // Add debugging to track screen lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔐 ReinitialiserMotDePassePage: Screen initialized and displayed');
    });
  }

  @override
  void dispose() {
    debugPrint('🔐 ReinitialiserMotDePassePage: Screen being disposed');
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the controller state to prevent auto-disposal
    ref.watch(reinitialiserMotDePasseCtrlProvider);

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: [
            _buildBody(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // Illustration
              _buildIllustration(),
              
              const SizedBox(height: 32),
              
              // Title and description
              _buildTitleSection(),
              
              const SizedBox(height: 32),
              
              // Email field
              _buildEmailField(),
              
              const SizedBox(height: 40),
              
              // Submit button
              _buildSubmitButton(),
              
              const SizedBox(height: 24),
              
              // Back to login
              _buildBackToLogin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 100),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Only allow navigation back if not loading
              if (!_isLoading) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Iconsax.arrow_left_2,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Mot de passe oublié',
              style: GoogleFonts.ubuntu(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(
            Iconsax.key,
            size: 60,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récupérer votre compte',
            style: GoogleFonts.ubuntu(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Entrez votre adresse email et nous vous enverrons un code de vérification pour réinitialiser votre mot de passe.',
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adresse email / Nom d\'utilisateur',
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse email';
              }
              // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              //   return 'Veuillez entrer une adresse email valide';
              // }
              if (value.length < 4) {
                return 'Email ou nom d\'utilisateur trop court';
              }
              if ( value.length > 30) {
                return 'Email ou nom d\'utilisateur trop long';
              }
              return null;
            },
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'exemple@email.com',
              hintStyle: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Iconsax.sms,
                color: Colors.grey.shade600,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handlePasswordReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? AppSpinner.ring(size: 24, showMessage: false)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.send_1,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Envoyer le code',
                      style: GoogleFonts.ubuntu(
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

  Widget _buildBackToLogin() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Center(
        child: TextButton(
          onPressed: () {
            // Only allow navigation back if not loading
            if (!_isLoading) {
              Navigator.pop(context);
            }
          },
          child: RichText(
            text: TextSpan(
              text: 'Vous vous souvenez de votre mot de passe? ',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              children: [
                TextSpan(
                  text: 'Se connecter',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpinner.pulse(size: 60, showMessage: false),
              const SizedBox(height: 20),
              Text(
                'Envoi du code...',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ctrl = ref.read(reinitialiserMotDePasseCtrlProvider.notifier);
      debugPrint('🔐 ReinitialiserMotDePassePage: Sending request to server...');
      final result = await ctrl.reinitialiser(_emailController.text);
      debugPrint('🔐 ReinitialiserMotDePassePage: Server response received: ${result?.token}');

      if (result?.token != null && result!.token.isNotEmpty) {
        // Reset loading state before navigation
        if (mounted) {
          debugPrint('🔐 ReinitialiserMotDePassePage: Success - Resetting loading state');
          setState(() {
            _isLoading = false;
          });

          // Small delay to ensure both local and controller states are updated
          await Future.delayed(const Duration(milliseconds: 200));

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OtpCodePasswordPage(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Échec de l\'envoi du code de vérification');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Une erreur est survenue');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
