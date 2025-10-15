import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/services/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:ebloodbankauth/constants/colors.dart';
// import 'package:ebloodbankauth/services/auth_service.dart';
// import 'package:ebloodbankauth/common/dio_client.dart';

class DeviceNotAllowedScreen extends StatefulWidget {
  const DeviceNotAllowedScreen({super.key});

  @override
  State<DeviceNotAllowedScreen> createState() => _DeviceNotAllowedScreenState();
}

class _DeviceNotAllowedScreenState extends State<DeviceNotAllowedScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Map<String, String> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await _authService.getDeviceNotAllowedInfo();
    setState(() {
      _deviceInfo = info;
    });
  }

  Future<void> _requestDeviceActivation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Check if token is available
      debugPrint('Device activation - Token available: ${_deviceInfo['token'] != null}');
      debugPrint('Device activation - Token value: ${_deviceInfo['token']}');

      if (_deviceInfo['token'] == null || _deviceInfo['token']!.isEmpty) {
        _showErrorDialog('No activation token available. Please try logging in again.');
        return;
      }

      // Make API call to request device activation
      final response = await getWithDio(
        '/auth/initiate-device-activation',
        headers: {
          'Authorization': 'Bearer ${_deviceInfo['token']}',
        },
      );

      if (response.success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(response.message ?? 'Failed to request activation');
      }
    } catch (e) {
      _showErrorDialog('Network error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Request Sent',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your device activation request has been sent. You will be notified once approved.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: ColorPages.COLOR_PRINCIPAL),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: ColorPages.COLOR_PRINCIPAL),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToLogin() async {
    await _authService.clearDeviceAccountErrorInfo();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              FadeInDown(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    children: [
                      // Error Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      const Text(
                        'Device Not Allowed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      const Text(
                        'This device is not authorized to access your account',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Message
              if (_deviceInfo['message']?.isNotEmpty == true)
                FadeInUp(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Text(
                      _deviceInfo['message']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Action Buttons
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    // Request Activation Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestDeviceActivation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPages.COLOR_PRINCIPAL,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mail_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Request Device Activation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Support Contact
                    if (_deviceInfo['support_email']?.isNotEmpty == true)
                      Text(
                        'Need immediate assistance? Contact support at ${_deviceInfo['support_email']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Go to Login Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _goToLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Go to Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
