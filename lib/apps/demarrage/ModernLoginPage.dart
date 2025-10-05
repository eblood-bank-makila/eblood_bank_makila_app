import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get_storage/get_storage.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/ModernInputWidget.dart';
import '../widgets/ModernSpinnerWidget.dart';
import '../../utilisateurs/ui/pages/authentification/AuthentificationCtrl.dart';
import '../../utilisateurs/ui/pages/otp_code/OtpCodePage.dart';
import '../../utilisateurs/ui/pages/motdepasse/ReinitialiserMotDePassePage.dart';
import '../../utilisateurs/business/interactors/UtilisateurInteractor.dart';

class ModernLoginPage extends ConsumerStatefulWidget {
  const ModernLoginPage({super.key});

  @override
  ConsumerState<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends ConsumerState<ModernLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadSavedCredentials() {
    final savedUsername = _storage.read('remember_username');
    final savedPassword = _storage.read('remember_password');
    final rememberMe = _storage.read('remember_me') ?? false;

    if (rememberMe && savedUsername != null && savedPassword != null) {
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  void _saveCredentials() {
    if (_rememberMe) {
      _storage.write('remember_username', _usernameController.text.trim());
      _storage.write('remember_password', _passwordController.text);
      _storage.write('remember_me', true);
    } else {
      _storage.remove('remember_username');
      _storage.remove('remember_password');
      _storage.write('remember_me', false);
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save credentials if remember me is checked
        _saveCredentials();

        // Use the existing authentication controller
        final authCtrl = ref.read(authentificationCtrlProvider.notifier);
        final result = await authCtrl.authenticate(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        // Handle successful authentication - align with connect flow
        if (result != null && result.token.isNotEmpty && mounted) {
          if (result.token == 'mfa') {
            debugPrint('✅ Login successful, MFA required → navigating to OTP page');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OtpCodePage(),
              ),
            );
          } else {
            debugPrint('✅ Login successful without MFA → navigating to main app');
            context.go('/app/MainApp');
          }
        } else if (result == null && mounted) {
          debugPrint('❌ Login failed, showing error message');
          // Clear any stale tokens on failed login
          try {
            final authProvider = ref.read(utilisateurInteractorProvider);
            await authProvider.deconnexionUtilisateurUseCase.run();
          } catch (e) {
            debugPrint('Error clearing tokens: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Échec de l\'authentification - Vérifiez vos identifiants'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Error handling will be managed by the auth controller
        debugPrint('Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the loading state to prevent unnecessary rebuilds
    final isLoading = ref.watch(authentificationCtrlProvider.select((state) => state.isLoading));

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorPages.COLOR_PRINCIPAL,
              ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                                 MediaQuery.of(context).padding.top -
                                 MediaQuery.of(context).padding.bottom - 48,
                    ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    FadeInLeft(
                      child: IconButton(
                        onPressed: () => context.go('/welcome'),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Welcome text
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'welcome_back'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'login_subtitle'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Login form
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // App logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.water_drop,
                                  size: 40,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Username field
                              ModernUsernameInput(
                                controller: _usernameController,
                              ),

                              const SizedBox(height: 20),

                              // Password field
                              ModernPasswordInput(
                                controller: _passwordController,
                                onSubmitted: (_) => _handleLogin(),
                              ),

                              const SizedBox(height: 20),

                              // Remember Me checkbox
                              FadeInUp(
                                delay: const Duration(milliseconds: 600),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: ColorPages.COLOR_PRINCIPAL,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _rememberMe = !_rememberMe;
                                          });
                                        },
                                        child: Text(
                                          'remember_me'.tr,
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to forgot password page using Navigator.push for better stability
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ReinitialiserMotDePassePage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'forgot_password'.tr,
                                    style: GoogleFonts.ubuntu(
                                      color: ColorPages.COLOR_PRINCIPAL,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isLoading
                                      ? const ModernButtonSpinner(
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : Text(
                                          'login'.tr,
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'login_no_account'.tr,
                                    style: GoogleFonts.ubuntu(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.go('/register');
                                    },
                                    child: Text(
                                      'register'.tr,
                                      style: GoogleFonts.ubuntu(
                                        color: ColorPages.COLOR_PRINCIPAL,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
                  ),
                ),
              ),

              // Modern loading overlay
              ModernLoadingOverlay(
                isVisible: isLoading,
                message: 'login_in_progress'.tr,
                spinnerType: SpinnerType.bloodDrop,
                spinnerColor: ColorPages.COLOR_PRINCIPAL,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
