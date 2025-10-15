import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/auth/account_not_allowed_screen.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/auth/device_not_allowed_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:ebloodbankauth/pages/auth/device_not_allowed_screen.dart';
// import 'package:ebloodbankauth/pages/auth/account_not_allowed_screen.dart';
// import 'package:ebloodbankauth/main.dart' as main;
import 'package:eblood_bank_mak_app/main.dart' as main;

class ErrorNavigationService {
  static final ErrorNavigationService _instance = ErrorNavigationService._internal();
  factory ErrorNavigationService() => _instance;
  ErrorNavigationService._internal();

  /// Navigate to device not allowed screen
  static Future<void> navigateToDeviceNotAllowed() async {
    debugPrint('ErrorNavigationService - Attempting to get navigator context');
    final context = main.navigatorKey.currentContext;
    debugPrint('ErrorNavigationService - Context available: ${context != null}');

    if (context != null) {
      debugPrint('ErrorNavigationService - Starting navigation to DeviceNotAllowedScreen using Navigator');
      try {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DeviceNotAllowedScreen(),
          ),
          (route) => false,
        );
        debugPrint('ErrorNavigationService - Navigation completed successfully');
      } catch (e) {
        debugPrint('ErrorNavigationService - Navigator failed: $e, trying GetX');
        _navigateWithGetX();
      }
    } else {
      debugPrint('ErrorNavigationService - Context is null, trying GetX navigation');
      _navigateWithGetX();
    }
  }

  /// Fallback navigation using GetX
  static void _navigateWithGetX() {
    try {
      debugPrint('ErrorNavigationService - Using GetX navigation');
      Get.offAll(() => const DeviceNotAllowedScreen());
      debugPrint('ErrorNavigationService - GetX navigation completed');
    } catch (e) {
      debugPrint('ErrorNavigationService - GetX navigation also failed: $e');
    }
  }

  /// Navigate to account not allowed screen
  static Future<void> navigateToAccountNotAllowed() async {
    debugPrint('ErrorNavigationService - Attempting to navigate to AccountNotAllowedScreen');
    final context = main.navigatorKey.currentContext;
    debugPrint('ErrorNavigationService - Context available: ${context != null}');

    if (context != null) {
      debugPrint('ErrorNavigationService - Starting navigation to AccountNotAllowedScreen using Navigator');
      try {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AccountNotAllowedScreen(),
          ),
          (route) => false,
        );
        debugPrint('ErrorNavigationService - Account navigation completed successfully');
      } catch (e) {
        debugPrint('ErrorNavigationService - Navigator failed: $e, trying GetX for account');
        _navigateToAccountWithGetX();
      }
    } else {
      debugPrint('ErrorNavigationService - Context is null, trying GetX navigation for account');
      _navigateToAccountWithGetX();
    }
  }

  /// Fallback navigation to account screen using GetX
  static void _navigateToAccountWithGetX() {
    try {
      debugPrint('ErrorNavigationService - Using GetX navigation for account');
      Get.offAll(() => const AccountNotAllowedScreen());
      debugPrint('ErrorNavigationService - GetX account navigation completed');
    } catch (e) {
      debugPrint('ErrorNavigationService - GetX account navigation also failed: $e');
    }
  }

  /// Navigate to login screen
  static Future<void> navigateToLogin() async {
    final context = main.navigatorKey.currentContext;
    if (context != null) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  /// Show error dialog
  static Future<void> showErrorDialog({
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) async {
    final context = main.navigatorKey.currentContext;
    if (context != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            if (actionText != null && onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction();
                },
                child: Text(
                  actionText,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }
  }
}
