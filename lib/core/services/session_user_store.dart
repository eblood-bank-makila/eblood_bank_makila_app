import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Compact, durable record of the currently logged-in user used to render the
/// "logged-in" UI (e.g. the bottom user bar on the blood-search / QR page).
///
/// Stored in [FlutterSecureStorage] so it survives an app kill or a hot
/// restart even if the faster [GetStorage] cache (`user_data`) is missing or
/// has been wiped. Only the minimal display fields are kept here — never the
/// raw token (that lives under its own `auth_token` secure key).
class SessionUser {
  final String displayName;
  final String accountType;

  const SessionUser({
    required this.displayName,
    required this.accountType,
  });

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'account_type': accountType,
      };

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        displayName: (json['display_name'] ?? '').toString(),
        accountType: (json['account_type'] ?? '').toString(),
      );
}

/// Durable, secure-storage backed cache for the logged-in user's display info.
class SessionUserStore {
  SessionUserStore._();

  static const String _key = 'session_user';
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  /// Persist the display name + account type. No-op when the name is empty.
  static Future<void> save({
    required String displayName,
    required String accountType,
  }) async {
    try {
      final name = displayName.trim();
      if (name.isEmpty) return;
      final record = SessionUser(
        displayName: name,
        accountType: accountType.trim().toLowerCase(),
      );
      await _secure.write(key: _key, value: jsonEncode(record.toJson()));
    } catch (_) {
      // Persisting the session record is best-effort; never break the caller.
    }
  }

  /// Derive a display name from a backend `user` map and persist it.
  static Future<void> saveFromUserData({
    Map? userData,
    required String accountType,
  }) async {
    if (userData == null) return;
    final name = deriveDisplayName(userData, accountType);
    if (name.isEmpty) return;
    await save(displayName: name, accountType: accountType);
  }

  /// Read the durable session record. Returns null when absent.
  static Future<SessionUser?> read() async {
    try {
      final raw = await _secure.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return SessionUser.fromJson(decoded.cast<String, dynamic>());
      }
      return null;
    } on PlatformException {
      // Keystore key invalidated (OS update / reinstall) — drop the entry.
      try {
        await _secure.delete(key: _key);
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Remove the durable session record (call on logout).
  static Future<void> clear() async {
    try {
      await _secure.delete(key: _key);
    } catch (_) {}
  }

  /// Build a human-friendly display name from a backend `user` map.
  ///
  /// Mirrors the precedence used by the blood-search welcome bar:
  /// entity name (for hospital / blood bank) → full name → username →
  /// phone → email. Returns an empty string when nothing usable is present.
  static String deriveDisplayName(Map userData, String accountType) {
    final type = accountType.trim().toLowerCase();
    final firstName = (userData['first_name'] ?? '').toString().trim();
    final lastName = (userData['last_name'] ?? '').toString().trim();
    final username = (userData['username'] ?? '').toString().trim();
    final phone = (userData['phone_number'] ?? '').toString().trim();
    final email = (userData['email_address'] ?? '').toString().trim();

    // For hospital / blood bank, prefer the entity name.
    final entity = userData['user_entity'];
    if (entity is Map && (type == 'hospital' || type == 'blood_bank')) {
      final entityName =
          (entity['entity_name'] ?? entity['name'] ?? '').toString().trim();
      if (entityName.isNotEmpty) return entityName;
    }

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    if (username.isNotEmpty) return username;
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email;
    return '';
  }
}
