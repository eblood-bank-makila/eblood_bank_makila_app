import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Google sign-in attempt that failed for a real reason (as opposed to the
/// user simply backing out of the account picker).
///
/// Sign-in used to swallow every exception and return `null`, which made a
/// genuine failure indistinguishable from a cancel: the caller closed its
/// spinner and returned, so the screen just sat there with no message. That
/// hid the most common production cause — the signing certificate of the
/// installed build not being registered on the Firebase/Google project, which
/// surfaces as `ApiException: 10` (DEVELOPER_ERROR) and never reaches the
/// backend at all.
class GoogleSignInFailure implements Exception {
  GoogleSignInFailure(this.message, {this.code, this.cause});

  /// Human-readable, already localised enough to show in a dialog.
  final String message;

  /// Underlying platform error code, when there was one (e.g. `sign_in_failed`).
  final String? code;

  final Object? cause;

  /// True when the platform reported a configuration problem rather than a
  /// transient one — the build's SHA-1 is not registered for this package
  /// name, or the Google provider is disabled in Firebase Authentication.
  bool get isConfigurationError {
    final haystack = '${code ?? ''} ${cause ?? ''}';
    return haystack.contains('ApiException: 10') ||
        haystack.contains('DEVELOPER_ERROR') ||
        haystack.contains('operation-not-allowed');
  }

  @override
  String toString() =>
      'GoogleSignInFailure(code: $code, message: $message, cause: $cause)';
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with Google.
  ///
  /// Returns `null` **only** when the user dismissed the account picker.
  /// Every other outcome throws [GoogleSignInFailure] so the caller can show
  /// the reason instead of failing silently.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in — not an error, nothing to report.
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e, stackTrace) {
      // `sign_in_failed ... ApiException: 10` is DEVELOPER_ERROR: Google could
      // not match this build's signing certificate + package name to an OAuth
      // client. On a Play Store build the running APK is signed with the *Play
      // App Signing* key, not the upload key, so that key's SHA-1 has to be
      // registered too.
      debugPrint('Google sign-in PlatformException: ${e.code} ${e.message}');
      debugPrint('$stackTrace');
      throw GoogleSignInFailure(
        _describe(e.code, e.message),
        code: e.code,
        cause: e,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Google sign-in FirebaseAuthException: ${e.code} ${e.message}');
      debugPrint('$stackTrace');
      throw GoogleSignInFailure(
        _describe(e.code, e.message),
        code: e.code,
        cause: e,
      );
    } catch (e, stackTrace) {
      debugPrint('Google sign-in error: $e');
      debugPrint('$stackTrace');
      throw GoogleSignInFailure(e.toString(), cause: e);
    }
  }

  /// Maps a platform error code to something a user can act on, keeping the
  /// raw code visible so a support report identifies the cause immediately.
  String _describe(String code, String? message) {
    final detail = '${message ?? ''} $code';
    if (detail.contains('ApiException: 10') ||
        detail.contains('DEVELOPER_ERROR')) {
      return "Google sign-in is not configured for this build of the app "
          "(DEVELOPER_ERROR). The app's signing certificate is not registered "
          "on the Firebase project. Please report this to support.";
    }
    if (code == 'operation-not-allowed') {
      return 'Google sign-in is disabled for this project. '
          'Please report this to support.';
    }
    if (code == 'network_error' ||
        code == 'network-request-failed' ||
        detail.contains('7:')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (code == 'account-exists-with-different-credential') {
      return 'This email is already registered with a different sign-in method.';
    }
    return message?.isNotEmpty == true
        ? '$message ($code)'
        : 'Google sign-in failed ($code).';
  }

  // Sign in with Facebook (placeholder for future implementation)
  Future<UserCredential?> signInWithFacebook() async {
    // TODO: Implement Facebook sign-in with Firebase Auth
    // This would require adding facebook_auth plugin and configuring Facebook app
    throw UnimplementedError('Facebook sign-in not yet implemented');
  }

  // Sign in with Twitter (placeholder for future implementation)
  Future<UserCredential?> signInWithTwitter() async {
    // TODO: Implement Twitter sign-in with Firebase Auth
    // This would require configuring Twitter OAuth in Firebase Console
    throw UnimplementedError('Twitter sign-in not yet implemented');
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user photo URL
  String? get userPhotoURL => currentUser?.photoURL;

  // Get current user's ID token (for backend Google verification)
  Future<String?> getIdToken() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      return await user.getIdToken(true);
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }
}

// Provider for FirebaseAuthService
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.read(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// Provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final authService = ref.read(firebaseAuthServiceProvider);
  return authService.isSignedIn;
});
