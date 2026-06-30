/// Auth Service Implementation
/// Integrates with existing authentication system

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/services/service_interfaces.dart';

class AuthServiceImpl implements IAuthService {
  final GetStorage _storage = GetStorage();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// Safely read a secure-storage key, tolerating an invalidated Keystore key.
  Future<String?> _readSecure(String key) async {
    try {
      return await _secure.read(key: key);
    } on PlatformException {
      try {
        await _secure.delete(key: key);
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      // The login + OTP + visitor flows persist the session token under
      // `auth_token` (real logins / visitors) — keep the legacy keys as a
      // best-effort fallback. GetStorage is the fast path; secure storage is
      // the durable source that survives a kill / GetStorage wipe.
      final fast = _storage.read('auth_token') ??
          _storage.read('visitor_token') ??
          _storage.read('token_otp') ??
          _storage.read('access_token');
      if (fast != null && fast.toString().isNotEmpty) {
        return fast.toString();
      }
      return await _readSecure('auth_token');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getUserProfileType() async {
    try {
      // `account_type` is derived + persisted by every login flow
      // (login / OTP validate / profile fetch / visitor). Read it locally —
      // no network round trip needed.
      final accountType = (_storage.read('account_type') ?? '').toString();
      if (accountType.isNotEmpty) return accountType.toLowerCase();

      // Legacy fallback key.
      final legacy = _storage.read('user_profile_type');
      if (legacy != null && legacy.toString().isNotEmpty) {
        return legacy.toString().toLowerCase();
      }
      return null;
    } catch (e) {
      print('AuthService.getUserProfileType error: $e');
      return null;
    }
  }

  @override
  Future<bool> isVisitor() async {
    try {
      final profileType = (await getUserProfileType() ?? '').toLowerCase();
      if (profileType == 'visitor') return true;
      return _storage.read('is_visitor') == true;
    } catch (e) {
      return false;
    }
  }
}
