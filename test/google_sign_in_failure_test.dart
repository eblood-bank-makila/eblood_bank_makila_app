// Google sign-in used to swallow every exception and return null, which the
// callers treated as "user cancelled" — so a build whose signing certificate
// is not registered on the Firebase project failed in complete silence and
// never reached the backend.
//
// These tests lock in the classification that makes such a failure reportable.

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/services/FirebaseAuthService.dart';

void main() {
  group('GoogleSignInFailure.isConfigurationError', () {
    test('flags ApiException: 10 (DEVELOPER_ERROR) from the Play build', () {
      // What google_sign_in actually throws on Android when the running APK's
      // SHA-1 + package name match no OAuth client — the Play App Signing key
      // is the one that signs a Play Store install.
      final failure = GoogleSignInFailure(
        'Google sign-in is not configured for this build of the app.',
        code: 'sign_in_failed',
        cause: 'PlatformException(sign_in_failed, '
            'com.google.android.gms.common.api.ApiException: 10: , null, null)',
      );

      expect(failure.isConfigurationError, isTrue);
    });

    test('flags a disabled Google provider in Firebase Authentication', () {
      final failure = GoogleSignInFailure(
        'Google sign-in is disabled for this project.',
        code: 'operation-not-allowed',
      );

      expect(failure.isConfigurationError, isTrue);
    });

    test('does not flag a transient network error as misconfiguration', () {
      final failure = GoogleSignInFailure(
        'No internet connection.',
        code: 'network_error',
        cause: 'PlatformException(network_error, 7: , null, null)',
      );

      expect(failure.isConfigurationError, isFalse);
    });

    test('carries the code and message needed for a support report', () {
      final failure = GoogleSignInFailure('boom', code: 'sign_in_failed');

      expect(failure.message, 'boom');
      expect(failure.code, 'sign_in_failed');
      expect(failure.toString(), contains('sign_in_failed'));
    });
  });
}
