/// Visitor Phone OTP Page
/// Phone verification for visitor registration

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../providers/search_flow_provider.dart';
import '../../data/services/visitor_registration_service_impl.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

class VisitorPhoneOtpPage extends ConsumerStatefulWidget {
  const VisitorPhoneOtpPage({super.key});

  @override
  ConsumerState<VisitorPhoneOtpPage> createState() =>
      _VisitorPhoneOtpPageState();
}

class _VisitorPhoneOtpPageState extends ConsumerState<VisitorPhoneOtpPage>
    with CodeAutoFill {
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  late PageController _pageController;
  final VisitorRegistrationServiceImpl _visitorService =
      VisitorRegistrationServiceImpl();

  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerifying = false; // Prevent duplicate verification calls
  bool _verificationComplete = false; // Prevent any state changes after success
  bool _disposed = false; // Track if dispose was called
  String? _errorMessage;
  int _resendCountdown = 0;
  String _formattedPhone = '';
  String? _appSignature;

  /// Whether the SMS retriever is actually listening right now. The
  /// "waiting for SMS" chip is driven by this, so it can never claim to be
  /// listening after the listener has stopped.
  bool _isListeningForSms = false;

  /// Stops the SMS listener once the code the backend sent has expired.
  Timer? _smsListenTimer;

  /// Fallback window when send-phone-otp doesn't report otp_expiry_minutes.
  static const int _fallbackListenMinutes = 10;

  /// Android's SMS Retriever API stops delivering after 5 minutes — a platform
  /// limit we can't extend. The code may stay valid longer (the backend says
  /// 10), but auto-read is dead past this, so the chip must not outlive it or
  /// it would claim to be listening when nothing is.
  static const int _smsRetrieverMaxMinutes = 5;

  @override
  void initState() {
    super.initState();
    // Create fresh controllers on every mount to avoid reusing disposed ones
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
    _pageController = PageController();
    _disposed = false;
    _getAppSignature();
    // Safety check in case user navigates directly to OTP page
    // Primary check happens before navigation in hospital_identify_page
    _checkIfAlreadyVerified();
  }

  /// Safety check if phone is already verified (fallback)
  /// Primary verification check happens before navigating to this page
  Future<void> _checkIfAlreadyVerified() async {
    try {
      print('🔍 [OTP Page] Checking if phone already verified...');
      final isVerified = await _visitorService.hasVisitorPhoneNumber();
      print('📱 [OTP Page] Local verification status: $isVerified');
      
      if (isVerified) {
        print('✅ [OTP Page] Phone verified locally, fetching backend data...');
        // Fetch fresh visitor data from backend to get updated can_pay_on_delivery status
        final result = await _visitorService.checkVisitorLogin();
        print('🔄 [OTP Page] Backend result: ${result != null}');
        
        if (result != null) {
          print('📦 [OTP Page] Result success: ${result['success']}, needs_verification: ${result['needs_phone_verification']}');
          
          final needsVerification = result['needs_phone_verification'] == true;
          
          if (result['success'] == true && !needsVerification) {
            print('✅ [OTP Page] Backend confirms verification, navigating to payment');
            
            // Navigate AFTER the current frame finishes layout to avoid
            // disposing controllers while PageView is still inflating children.
            if (mounted && !_disposed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_disposed) {
                  print('⏭️ [OTP Page] Navigating to payment page...');
                  context.pushReplacement('/blood-search/payment');
                }
              });
            }
          } else {
            print('⚠️ [OTP Page] Backend requires verification, showing OTP input');
          }
        } else {
          print('❌ [OTP Page] No result from backend, showing OTP input');
        }
      } else {
        print('📝 [OTP Page] Phone not verified locally, showing OTP input');
      }
    } catch (e) {
      print('❌ [OTP Page] Error checking verification: $e');
      // Continue to normal flow if check fails
    }
  }

  Future<void> _getAppSignature() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      print('📱 App Signature for SMS: $_appSignature');
    } catch (e) {
      print('⚠️ Could not get app signature: $e');
    }
  }

  /// Listen for the OTP SMS for as long as auto-read can actually work:
  /// min(backend's otp_expiry_minutes, SMS Retriever's 5-minute ceiling).
  /// Past either bound there is nothing left to auto-read, so keeping the
  /// listener (and its spinner) alive would only mislead the user.
  void _startListeningForSms(int? expiryMinutes) {
    final codeLifetime = (expiryMinutes != null && expiryMinutes > 0)
        ? expiryMinutes
        : _fallbackListenMinutes;
    final minutes = codeLifetime > _smsRetrieverMaxMinutes
        ? _smsRetrieverMaxMinutes
        : codeLifetime;

    listenForCode();
    _smsListenTimer?.cancel();
    _smsListenTimer = Timer(Duration(minutes: minutes), () {
      print('⏱️ SMS listen window ($minutes min) elapsed — stopping listener');
      _stopListeningForSms();
    });

    if (mounted && !_disposed) {
      setState(() => _isListeningForSms = true);
    }
    print('👂 Started listening for SMS OTP (window: $minutes min)...');
  }

  /// Tear down the SMS listener and its timer, and drop the waiting chip.
  /// Safe to call repeatedly and after dispose.
  void _stopListeningForSms() {
    _smsListenTimer?.cancel();
    _smsListenTimer = null;
    cancel(); // sms_autofill: stop listening
    if (mounted && !_disposed && _isListeningForSms) {
      setState(() => _isListeningForSms = false);
    } else {
      _isListeningForSms = false;
    }
  }

  @override
  void codeUpdated() {
    // This is called when SMS is received and OTP is extracted
    // Skip if disposed, verification is already in progress or complete
    if (_disposed || _isVerifying || _verificationComplete) return;

    if (code != null && code!.length == 6) {
      print('📨 Auto-received OTP: $code');
      if (mounted && !_disposed) {
        setState(() {
          try {
            _otpController.text = code!;
          } catch (_) {
            // Controller may have been disposed in a race
          }
        });
        // Auto-verify after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted &&
              !_disposed &&
              _otpController.text.length == 6 &&
              !_isVerifying &&
              !_verificationComplete) {
            _verifyOtp();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true; // Mark as disposed first
    _smsListenTimer?.cancel(); // Don't fire setState after dispose
    _smsListenTimer = null;
    cancel(); // Stop listening for SMS
    SmsAutoFill().unregisterListener();
    // Only dispose controllers if not already disposed
    try {
      _phoneController.dispose();
    } catch (_) {}
    try {
      _otpController.dispose();
    } catch (_) {}
    try {
      _pageController.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If verification is complete, show a loading/transitioning state
    if (_verificationComplete) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Redirecting...',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: _isOtpSent
            ? ('verify_phone'.tr.isEmpty ? 'Verify Phone' : 'verify_phone'.tr)
            : ('enter_phone'.tr.isEmpty ? 'Enter Phone' : 'enter_phone'.tr),
        onBack: () {
          if (_isOtpSent) {
            // Stop listening for SMS and reset verification state
            _stopListeningForSms();
            setState(() {
              _isOtpSent = false;
              _isVerifying = false;
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
        children: [_buildPhoneInputPage(), _buildOtpVerificationPage()],
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
              'enter_your_phone'.tr.isEmpty
                  ? 'Enter your phone number'
                  : 'enter_your_phone'.tr,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('🇨🇩', style: const TextStyle(fontSize: 20)),
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
                Container(width: 1, height: 30, color: Colors.grey.shade300),
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
                      hintStyle: GoogleFonts.ubuntu(
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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

          // Auto-read indicator — only while the SMS listener is actually
          // running. It stops when the code expires, on verify, or on back.
          if (_isListeningForSms) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'waiting_for_sms'.tr.isEmpty
                          ? 'Waiting for SMS...'
                          : 'waiting_for_sms'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // OTP input — only build PinCodeTextField when the OTP page is
          // actually active. PageView eagerly inflates both children, so
          // building PinCodeTextField before _isOtpSent causes a race if the
          // widget gets disposed during layout (e.g. pushReplacement in
          // _checkIfAlreadyVerified).
          if (_isOtpSent && !_disposed)
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
                // Only verify if not already verifying or complete
                if (!_disposed && !_isVerifying && !_verificationComplete) {
                  _verifyOtp();
                }
              },
              onChanged: (value) {
                if (!_disposed && mounted) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
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
                      'resend_code'.tr.isEmpty
                          ? 'Resend Code'
                          : 'resend_code'.tr,
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

      // Set app signature for SMS auto-read before sending OTP
      if (_appSignature != null) {
        ref.read(searchFlowProvider.notifier).setAppSignature(_appSignature);
      }

      await ref.read(searchFlowProvider.notifier).registerVisitor(fullPhone);

      if (!mounted) return;

      setState(() {
        _isOtpSent = true;
        _formattedPhone = phone;
      });

      // Listen for the SMS only for as long as the backend says the code
      // lives (otp_expiry_minutes), so the listener can't outlive the code.
      _startListeningForSms(ref.read(searchFlowProvider).otpExpiryMinutes);

      _startResendCountdown();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    // Prevent duplicate verification calls or calls after success
    if (_isVerifying || _isLoading || _verificationComplete) {
      print('⚠️ Verification already in progress or complete, skipping');
      return;
    }

    // Sanitize OTP: trim whitespace and keep only digits
    final rawOtp = _otpController.text.trim();
    final otp = rawOtp.replaceAll(RegExp(r'[^0-9]'), '');
    
    print('🔐 Raw OTP: "$rawOtp", Sanitized OTP: "$otp"');

    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'code_too_short'.tr.isEmpty
            ? 'Please enter the complete 6-digit code'
            : 'code_too_short'.tr;
      });
      return;
    }
    
    // Ensure we're using exactly 6 digits
    final otpToVerify = otp.substring(0, 6);
    
    print('📤 Verifying OTP: "$otpToVerify" (length: ${otpToVerify.length})');

    setState(() {
      _isVerifying = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Stop listening for SMS since we're verifying
      _stopListeningForSms();

      await ref.read(searchFlowProvider.notifier).verifyOtp(otpToVerify);

      if (!mounted) return;

      // Check state after verification
      final state = ref.read(searchFlowProvider);
      if (state.otpVerified) {
        // Mark verification as complete to prevent any further actions
        _verificationComplete = true;

        // Save the verified phone number locally
        final fullPhone = '+243$_formattedPhone';
        await _visitorService.saveVisitorPhone(fullPhone);
        print('✅ Phone number saved: $fullPhone');

        if (mounted) {
          // Navigate to payment page (confirm step in blood search flow)
          // Use pushReplacement to remove this page from the stack
          context.pushReplacement('/blood-search/payment');
        }
      } else {
        if (mounted) {
          setState(() {
            _isVerifying = false; // Allow retry on failure
            _errorMessage =
                state.errorMessage ??
                ('invalid_otp'.tr.isEmpty
                    ? 'Invalid verification code. Please try again.'
                    : 'invalid_otp'.tr);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false; // Allow retry on error
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted && !_verificationComplete) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resendOtp() {
    // Reset verification state when resending
    setState(() {
      _isVerifying = false;
      _otpController.clear();
      _errorMessage = null;
    });
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
