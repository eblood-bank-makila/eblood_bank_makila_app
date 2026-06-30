import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ModernSpinnerWidget.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/otp_code/OtpCodeCtrl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OtpCodePage extends ConsumerStatefulWidget {
  const OtpCodePage({super.key});

  @override
  ConsumerState createState() => _OtpCodePageState();
}

class _OtpCodePageState extends ConsumerState<OtpCodePage> {

  // Individual controllers for each OTP digit
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Initialize token reading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var ctrl = ref.read(otpCodeCtrlProvider.notifier);
      ctrl.readLocalCodeToken();
      // Auto-focus first field
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get otpCode => _controllers.map((controller) => controller.text).join();

  void _onOtpDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    if (otpCode.length == 6) {
      // Auto-submit when all fields are filled
      _handleOtpSubmission();
    }
  }

  void _handleOtpSubmission() async {
    if (otpCode.length == 6) {
      final ctrl = ref.read(otpCodeCtrlProvider.notifier);
      final result = await ctrl.otp(otpCode);

      if (mounted) {
        if (result['success'] == true) {
          // OTP verification successful — navigate to the main container.
          // AccountTypeBasedNavigation will immediately pick the correct UI
          // (customer/bloodBank/hospital) using the stored user_profiles flags.
          debugPrint('🧭 OTP success — navigating to /rbac-loading');
          context.go('/rbac-loading');
        } else {
          // Show server error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Code OTP invalide'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          // Clear all fields on error
          _clearAllFields();
        }
      }
    }
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // ignore: unused_element
  String _computePostLoginRoute() {
    final storage = GetStorage();
    final dynamic profiles = storage.read('user_profiles');
    if (profiles is List && profiles.isNotEmpty) {
      // Extract ALL profiles regardless of 'enabled' status
      // The 'enabled' field will be used later to disable actions, not to hide profiles
      final allProfiles = profiles
          .whereType<Map>()
          .toList();

      // Collect unique flags from all profiles
      final profilFlags = allProfiles
          .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();

      debugPrint('🔍 Computing post-login route:');
      debugPrint('   Total profiles: ${profiles.length}');
      debugPrint('   All profiles: ${allProfiles.length}');
      debugPrint('   Flags: $profilFlags');

      // Exclusivity: blood bank and health structure cannot be combined with others
      if (profilFlags.contains('mobile_app_blood_bank_profil')) {
        debugPrint('   ✅ Route: /app/BloodBankMainApp');
        return '/app/BloodBankMainApp';
      }
      if (profilFlags.contains('mobile_app_health_structure_profil')) {
        debugPrint('   ✅ Route: /app/MainApp (hospital)');
        return '/app/MainApp'; // existing hospital main app
      }

      // Consumer space: simple user, blood donor, and optional delivery
      if (profilFlags.contains('mobile_app_simple_user_profil') ||
          profilFlags.contains('mobile_app_blood_donor_profil') ||
          profilFlags.contains('mobile_app_delivery_person_profil')) {
        debugPrint('   ✅ Route: /app/ConsumerMainApp');
        return '/app/ConsumerMainApp';
      }
    }
    // Default
    debugPrint('   ✅ Route: /app/ConsumerMainApp (default)');
    return '/app/ConsumerMainApp';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpCodeCtrlProvider.select((state) => state.isLoading));

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
              _buildModernOtpBody(context),
              ModernLoadingOverlay(
                isVisible: isLoading,
                message: 'otp_verification_in_progress'.tr,
                spinnerType: SpinnerType.pulse,
                spinnerColor: ColorPages.COLOR_PRINCIPAL,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernOtpBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
                     MediaQuery.of(context).padding.top -
                     MediaQuery.of(context).padding.bottom - 48,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Back button
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Enhanced Blood drop icon with pulse animation
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 50,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Title
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'otp_verification'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Enhanced Subtitle (i18n + dynamic target)
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _buildOtpSubtitle(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Timer indicator
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code valide pendant 5 minutes',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Enhanced OTP Input Fields Card
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      blurRadius: 50,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Security badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sécurisé',
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: ColorPages.COLOR_PRINCIPAL,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OTP Input Fields
                    _buildOtpInputFields(),

                    const SizedBox(height: 32),

                    // Verify Button
                    _buildVerifyButton(),

                    const SizedBox(height: 24),

                    // Resend Code
                    _buildResendCodeButton(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Flexible(
            child: Container(
              width: 45,
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: _controllers[index].text.isNotEmpty
                  ? ColorPages.COLOR_PRINCIPAL
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _controllers[index].text.isNotEmpty
                ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05)
                : Colors.grey.shade50,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              _onOtpDigitChanged(value, index);
              setState(() {}); // Rebuild to update border colors
            },
          ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final isComplete = otpCode.length == 6;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isComplete ? _handleOtpSubmission : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete
              ? ColorPages.COLOR_PRINCIPAL
              : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isComplete ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 20,
              color: isComplete ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'verify'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isComplete ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendCodeButton() {
    return TextButton(
      onPressed: _resendCode,
      child: RichText(
        text: TextSpan(
          text: 'didnt_receive_code'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          children: [
            TextSpan(
              text: 'resend'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: ColorPages.COLOR_PRINCIPAL,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resendCode() async {
    final ctrl = ref.read(otpCodeCtrlProvider.notifier);

    final result = await ctrl.renvoicode('');
    if (mounted && result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('code_resent_email'.tr),
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          duration: const Duration(seconds: 3),
        ),
      );
      _clearAllFields();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('failed_resend_code'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _buildOtpSubtitle() {
    final storage = GetStorage();
    final String mfaType = (storage.read('pending_mfa_type') as String?) ?? 'email';
    if (mfaType == 'phone') {
      final phone = (storage.read('pending_login_phone') as String?) ?? '';
      if (phone.isNotEmpty) {
        return 'verification_code_sent_to_phone'.trParams({'phone': phone});
      }
      return 'verify_phone'.tr;
    } else {
      final email = (storage.read('pending_login_email') as String?) ?? '';
      if (email.isNotEmpty) {
        return 'verification_code_sent_to'.trParams({'email': email});
      }
      return 'please_enter_six_digits'.tr;
    }
  }
}
