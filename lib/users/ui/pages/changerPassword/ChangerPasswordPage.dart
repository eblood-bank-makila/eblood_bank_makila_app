import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/ModernLoginPage.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/changerPassword/ChangerPasswordCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ChangerPasswordPage extends ConsumerStatefulWidget {
  const ChangerPasswordPage({super.key});

  @override
  ConsumerState createState() => _ChangerPasswordPageState();
}

class _ChangerPasswordPageState extends ConsumerState<ChangerPasswordPage> {
  bool isPassword = true;
  bool isPassword1 = true;
  bool isPassword2 = true;
  bool isVisible = false;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController _ancien = TextEditingController();
  TextEditingController _password1 = TextEditingController();
  TextEditingController _password2 = TextEditingController();


  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // action initiale de la page et appel d'un controleur
      var ctrl = ref.read(changerPasswordCtrlProvider.notifier);
      ctrl.readLocalCodeToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(changerPasswordCtrlProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildHeader(context),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildContent(context),
                      if (state.isLoading) _buildLoadingOverlay(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Lock Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Iconsax.lock,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier le mot de passe',
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sécurisez votre compte',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Form(
      key: formkey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/image2.png',
                    width: 50,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Pour votre sécurité, veuillez saisir votre ancien mot de passe puis définir un nouveau mot de passe.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Current Password Field
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildPasswordField(
                controller: _ancien,
                hintText: 'Ancien mot de passe',
                icon: Iconsax.lock,
                isObscure: isPassword,
                onToggleVisibility: () {
                  setState(() {
                    isPassword = !isPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez votre ancien mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Le mot de passe doit contenir au moins 8 caractères';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // New Password Field
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildPasswordField(
                controller: _password1,
                hintText: 'Nouveau mot de passe',
                icon: Iconsax.lock_1,
                isObscure: isPassword1,
                onToggleVisibility: () {
                  setState(() {
                    isPassword1 = !isPassword1;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez votre nouveau mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Le mot de passe doit contenir au moins 8 caractères';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Password Field
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildPasswordField(
                controller: _password2,
                hintText: 'Confirmer le nouveau mot de passe',
                icon: Iconsax.verify,
                isObscure: isPassword2,
                onToggleVisibility: () {
                  setState(() {
                    isPassword2 = !isPassword2;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmez votre nouveau mot de passe';
                  }
                  if (value != _password1.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handlePasswordChange,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.tick_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Modifier le mot de passe',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.ubuntu(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              isObscure ? Iconsax.eye_slash : Iconsax.eye,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _handlePasswordChange() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (!formkey.currentState!.validate()) {
      return;
    }

    var ctrl = ref.read(changerPasswordCtrlProvider.notifier);
    var resultat = await ctrl.changer(
      _ancien.text,
      _password1.text,
      _password2.text,
    );

    if (resultat?.success == true) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Mot de passe modifié avec succès',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ModernLoginPage()),
        );
      }
    } else {
      // Clear fields and show error
      _ancien.clear();
      _password1.clear();
      _password2.clear();

      if (mounted) {
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
                    'Échec du changement de mot de passe',
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
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Image.asset(
                  'assets/images/image2.png',
                  width: 30,
                ),
              ),
              const SizedBox(height: 16),
              AppSpinner.pulse(
                size: 40,
                showMessage: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Modification en cours...',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
