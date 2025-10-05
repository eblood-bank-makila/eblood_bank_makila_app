import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import '../config/theme/ColorPages.dart';
import '../services/AuthService.dart';
import '../widgets/CustomButton.dart';
import '../widgets/PinInputField.dart';
import './RegistrationSuccessPage.dart';
import '../models/UserInfoValidation.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final Map<String, dynamic>? userData; // Add userData for registration after OTP verification
  final String? validationKey; // Validation key received from the initial validation
  final String verificationType; // Type of verification: 'email' or 'phone'
  
  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.email,
    this.userData,
    this.validationKey,
    this.verificationType = 'email', // Default to email verification
  });
  
  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  
  // Timer for countdown
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _canResend = false;
    _countdown = 60;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }
  
  String get _formattedCountdown {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  void _verifyOTP() async {
    if (_otpController.text.length < 6) { // Update to expect 6 digits
      setState(() {
        _errorMessage = 'please_enter_six_digits'.tr;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // If we have userData, it means we're in the new registration flow using user validation
      if (widget.userData != null) {
        if (widget.validationKey == null) {
          setState(() {
            _errorMessage = 'missing_validation_key'.tr;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'something_wrong_try_again'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        
        final userValidation = UserValidationCodeVerification(
          email: widget.email,
          phoneNumber: widget.phoneNumber,
          validationType: widget.verificationType, // Use the verification type from the widget
          validationCode: _otpController.text,
          validationKey: widget.validationKey!, // Include the validation key received from initial validation
        );
        
        final verificationResult = await _authService.verifyValidationCode(userValidation);
        
        // Debug output to see what we're getting from the backend
        print("Verification result: $verificationResult");
        
        if (verificationResult['success'] == true) {
          // OTP verification successful, now proceed with the actual registration
          final registrationResult = await _authService.register(widget.userData!);
          
          // Debug output for registration result
          print("Registration result: $registrationResult");
          
          if (registrationResult['success'] == true) {
            // Registration successful, navigate to success page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RegistrationSuccessPage(
                  phoneNumber: widget.phoneNumber,
                  email: widget.email,
                  token: registrationResult['data']?['token'] ?? '',
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = registrationResult['message'];
              _isLoading = false;
            });
            
            // Show error in a snackbar for better visibility using ScaffoldMessenger
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  registrationResult['message'] ?? 'registration_failed_after_verification'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = verificationResult['message'];
            _isLoading = false;
          });
          
          // Show error in a snackbar for better visibility
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verificationResult['message'] ?? 'check_otp_code'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Use the old flow if userData is not provided
        final result = await _authService.verifyOTP(
          phoneNumber: widget.phoneNumber,
          otpCode: _otpController.text,
        );
        
        if (result['success']) {
          // Navigate to success page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationSuccessPage(
                phoneNumber: widget.phoneNumber,
                email: widget.email,
                token: result['token'],
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
          
          // Show error in a snackbar for better visibility
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'check_otp_code'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'verification_error_occurred'.tr;
        _isLoading = false;
      });
      
      // Show error in a snackbar for better visibility
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'verification_error_details'.trParams({'error': e.toString()}),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  void _resendOTP() async {
    if (!_canResend || _isResending) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    
    try {
      // For the new flow with validation key
      if (widget.userData != null && widget.validationKey != null) {
        // Create a new validation request with the same parameters but for resending
        final userValidation = UserInfoValidation(
          email: widget.email,
          phoneNumber: widget.phoneNumber,
          validationType: widget.verificationType, // Use the verification type from the widget
        );
        
        final result = await _authService.validateUserInfo(userValidation);
        
        if (result['success']) {
          // Store the new validation key if one is returned
          final String? newValidationKey = result['data']?['validation_key'];
          if (newValidationKey != null) {
            // We'd need to update the widget's validationKey, but it's final
            // So we'll just use the new one in the UI or reload the page
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'new_code_sent_email'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Reset timer
          _startTimer();
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      } else {
        // Legacy flow for phone verification
        final result = await _authService.resendOTP(widget.phoneNumber);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'code_resent_email'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Reset timer
          _startTimer();
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'failed_resend_code'.tr;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'failed_resend_code_details'.trParams({'error': e.toString()}),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.verificationType == 'phone' ? 'verify_phone'.tr : 'verify_email'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // OTP icon
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Ionicons.lock_closed_outline,
                    size: 60,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Heading
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'otp_verification'.tr,
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
                  widget.verificationType == 'phone'
                    ? 'verification_code_sent_to_phone'.trParams({'phone': widget.phoneNumber})
                    : 'verification_code_sent_to'.trParams({'email': widget.email}),
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // OTP Input
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    PinInputField(
                      controller: _otpController,
                      length: 6,
                      onComplete: (_) => _verifyOTP(),
                    ),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Timer and resend button
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'didnt_receive_code'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    _canResend
                        ? TextButton(
                            onPressed: _isResending ? null : _resendOTP,
                            child: Text(
                              _isResending ? 'sending'.tr : 'resend'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                          )
                        : Text(
                            _formattedCountdown,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Verify button
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
                child: CustomButton(
                  text: 'verify'.tr,
                  onPressed: _isLoading ? null : _verifyOTP,
                  isLoading: _isLoading,
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