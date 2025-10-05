import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/CustomButton.dart';
import '../widgets/PinInputField.dart';
import '../services/AuthService.dart';
import '../models/UserInfoValidation.dart';
import '../constants/api_constants.dart';
import 'RegistrationSuccessPage.dart';
import 'package:http/http.dart' as http;

/// Sequential email verification screen for Health Structure registration.
/// You must verify each distinct email (structure, contact, admin). Duplicates are verified once.
class HealthStructureEmailVerificationPage extends StatefulWidget {
  final List<String> emails; // unique, ordered
  final Map<String, dynamic> registrationPayload; // payload to POST after all verified

  const HealthStructureEmailVerificationPage({
    super.key,
    required this.emails,
    required this.registrationPayload,
  });

  @override
  State<HealthStructureEmailVerificationPage> createState() => _HealthStructureEmailVerificationPageState();
}

class _HealthStructureEmailVerificationPageState extends State<HealthStructureEmailVerificationPage> {
  final AuthService _authService = AuthService();

  // Per-email state containers
  late List<_EmailVerificationItem> _items;
  bool _submittingFinal = false;

  @override
  void initState() {
    super.initState();
    _items = widget.emails.map((e) => _EmailVerificationItem(email: e)).toList();
  }

  bool get _allVerified => _items.every((i) => i.verified);

  Future<void> _startVerification(_EmailVerificationItem item) async {
    if (item.loading || item.verified) return;
    setState(() => item.loading = true);
    try {
      final validation = UserInfoValidation(
        email: item.email,
        phoneNumber: '',
        validationType: 'email',
      );
      final result = await _authService.validateUserInfo(validation);
      if (result['success'] == true) {
        item.validationKey = result['data']?['validation_key'];
        item.codeRequested = true;
        item.error = null;
        item.startTimer(_onTimerTick);
      } else {
        item.error = result['message'] ?? 'verification_failed'.tr;
      }
    } catch (e) {
      item.error = e.toString();
    } finally {
      setState(() => item.loading = false);
    }
  }

  Future<void> _verifyCode(_EmailVerificationItem item) async {
    if (item.loading || item.verified || item.codeController.text.length < 6) {
      setState(() => item.error = 'please_enter_six_digits'.tr);
      return;
    }
    setState(() {
      item.loading = true;
      item.error = null;
    });
    try {
      if (item.validationKey == null) {
        item.error = 'missing_validation_key'.tr;
      } else {
        final verification = UserValidationCodeVerification(
          email: item.email,
          phoneNumber: '',
          validationType: 'email',
          validationCode: item.codeController.text,
          validationKey: item.validationKey!,
        );
        final result = await _authService.verifyValidationCode(verification);
        if (result['success'] == true) {
          item.verified = true;
          item.error = null;
          item.cancelTimer();
        } else {
          item.error = result['message'] ?? 'check_otp_code'.tr;
        }
      }
    } catch (e) {
      item.error = e.toString();
    } finally {
      setState(() => item.loading = false);
    }
  }

  Future<void> _resend(_EmailVerificationItem item) async {
    if (!item.canResend || item.loading) return;
    // Re-initiate verification
    await _startVerification(item);
  }

  void _onTimerTick() {
    if (!mounted) return;
    setState(() {}); // rebuild to update countdown or resend availability
  }

  Future<void> _submitFinalRegistration() async {
    if (!_allVerified || _submittingFinal) return;
    setState(() => _submittingFinal = true);
    try {
      final url = ApiConstants.HEALTH_STRUCTURE_REGISTER;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'accept-language': Get.locale?.languageCode ?? 'en'
        },
        body: jsonEncode(widget.registrationPayload),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RegistrationSuccessPage(
                phoneNumber: widget.registrationPayload['contact_person']?['phone'] ?? '',
                email: widget.registrationPayload['email'] ?? '',
                token: '',
              ),
            ),
          );
        }
      } else {
        String message = 'registration_failed'.tr;
        try {
          final body = jsonDecode(response.body);
          message = body['message'] ?? message;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingFinal = false);
    }
  }

  @override
  void dispose() {
    for (var i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('verify_emails'.tr, style: GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('verify_each_email_before_submission'.tr, style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) => _buildEmailCard(_items[idx], idx + 1),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _submittingFinal ? 'submitting'.tr : 'submit_registration'.tr,
                onPressed: _allVerified && !_submittingFinal ? _submitFinalRegistration : null,
                isLoading: _submittingFinal,
                backgroundColor: _allVerified ? ColorPages.COLOR_PRINCIPAL : Colors.grey,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCard(_EmailVerificationItem item, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.verified ? Colors.green : Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.verified ? Ionicons.checkmark_circle : Ionicons.mail_outline, color: item.verified ? Colors.green : ColorPages.COLOR_PRINCIPAL),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.email,
                  style: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              if (!item.verified && !item.codeRequested)
                TextButton(
                  onPressed: () => _startVerification(item),
                  child: item.loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('verify'.tr),
                ),
              if (item.verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('verified'.tr, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                )
            ],
          ),
          if (item.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (item.codeRequested && !item.verified) ...[
            const SizedBox(height: 10),
            PinInputField(
              controller: item.codeController,
              length: 6,
              onComplete: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: item.loading ? null : () => _verifyCode(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    foregroundColor: Colors.white,
                  ),
                  child: item.loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('confirm'.tr),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: item.canResend ? () => _resend(item) : null,
                  child: Text(item.canResend ? 'resend'.tr : item.formattedCountdown,
                      style: TextStyle(color: item.canResend ? ColorPages.COLOR_PRINCIPAL : Colors.grey)),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class _EmailVerificationItem {
  final String email;
  bool loading = false;
  bool codeRequested = false;
  bool verified = false;
  String? error;
  String? validationKey;
  final TextEditingController codeController = TextEditingController();

  // Timer
  Timer? _timer;
  int _countdown = 60;
  bool canResend = false;

  _EmailVerificationItem({required this.email});

  void startTimer(VoidCallback notify) {
    canResend = false;
    _countdown = 60;
    _timer?.cancel();
    notify();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        _countdown--;
        notify();
      } else {
        canResend = true;
        notify();
        _timer?.cancel();
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  String get formattedCountdown {
    final m = (_countdown ~/ 60).toString().padLeft(2, '0');
    final s = (_countdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void dispose() {
    codeController.dispose();
    _timer?.cancel();
  }
}
