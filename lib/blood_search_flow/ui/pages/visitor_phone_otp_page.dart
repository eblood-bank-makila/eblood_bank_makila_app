/// Visitor Phone OTP Page
/// Phone verification for visitor registration

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../providers/search_flow_provider.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

class VisitorPhoneOtpPage extends ConsumerStatefulWidget {
  const VisitorPhoneOtpPage({super.key});

  @override
  ConsumerState<VisitorPhoneOtpPage> createState() => _VisitorPhoneOtpPageState();
}

class _VisitorPhoneOtpPageState extends ConsumerState<VisitorPhoneOtpPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final PageController _pageController = PageController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  String _formattedPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: _isOtpSent 
            ? ('verify_phone'.tr.isEmpty ? 'Verify Phone' : 'verify_phone'.tr)
            : ('enter_phone'.tr.isEmpty ? 'Enter Phone' : 'enter_phone'.tr),
        onBack: () {
          if (_isOtpSent) {
            setState(() {
              _isOtpSent = false;
              _otpController.clear();
              _errorMessage = null;
            });
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            context.pop();
          }
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPhoneInputPage(),
          _buildOtpVerificationPage(),
        ],
      ),
    );
  }

  Widget _buildPhoneInputPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.call,
                size: 56,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // Title
          Center(
            child: Text(
              'enter_your_phone'.tr.isEmpty ? 'Enter your phone number' : 'enter_your_phone'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'we_will_send_code'.tr.isEmpty
                  ? 'We\'ll send you a verification code'
                  : 'we_will_send_code'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Phone input
          Text(
            'phone_number'.tr.isEmpty ? 'Phone Number' : 'phone_number'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Country code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '🇨🇩',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+243',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                ),
                // Phone input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      hintText: '812345678',
                      hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'send_code'.tr.isEmpty ? 'Send Code' : 'send_code'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Privacy note
          Center(
            child: Text(
              'privacy_note'.tr.isEmpty
                  ? 'Your phone number will only be used for verification'
                  : 'privacy_note'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.message_text,
                size: 56,
                color: Colors.green.shade600,
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // Title
          Center(
            child: Text(
              'enter_verification_code'.tr.isEmpty 
                  ? 'Enter verification code' 
                  : 'enter_verification_code'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'code_sent_to'.tr.isEmpty
                  ? 'Code sent to +243$_formattedPhone'
                  : '${'code_sent_to'.tr} +243$_formattedPhone',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // OTP input
          PinCodeTextField(
            appContext: context,
            controller: _otpController,
            length: 6,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.grey.shade50,
              selectedFillColor: Colors.white,
              activeColor: ColorPages.COLOR_PRINCIPAL,
              inactiveColor: Colors.grey.shade300,
              selectedColor: ColorPages.COLOR_PRINCIPAL,
            ),
            textStyle: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            enableActiveFill: true,
            onCompleted: (value) {
              _verifyOtp();
            },
            onChanged: (value) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Resend option
          Center(
            child: _resendCountdown > 0
                ? Text(
                    'resend_in'.tr.isEmpty
                        ? 'Resend code in $_resendCountdown seconds'
                        : '${'resend_in'.tr} $_resendCountdown',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  )
                : TextButton(
                    onPressed: _resendOtp,
                    child: Text(
                      'resend_code'.tr.isEmpty ? 'Resend Code' : 'resend_code'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 32),

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'verify'.tr.isEmpty ? 'Verify' : 'verify'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    
    if (phone.length < 9) {
      setState(() {
        _errorMessage = 'invalid_phone'.tr.isEmpty
            ? 'Please enter a valid phone number'
            : 'invalid_phone'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullPhone = '+243$phone';
      await ref.read(searchFlowProvider.notifier).registerVisitor(fullPhone);
      
      setState(() {
        _isOtpSent = true;
        _formattedPhone = phone;
        _startResendCountdown();
      });
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'enter_complete_code'.tr.isEmpty
            ? 'Please enter the complete 6-digit code'
            : 'enter_complete_code'.tr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(searchFlowProvider.notifier).verifyOtp(otp);
      
      // Check state after verification
      final state = ref.read(searchFlowProvider);
      if (state.otpVerified) {
        if (mounted) {
          context.push('/blood-search/payment');
        }
      } else {
        setState(() {
          _errorMessage = state.errorMessage ?? ('invalid_otp'.tr.isEmpty
              ? 'Invalid verification code. Please try again.'
              : 'invalid_otp'.tr);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resendOtp() {
    _sendOtp();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countDown();
  }

  void _countDown() async {
    while (_resendCountdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
      }
    }
  }
}
