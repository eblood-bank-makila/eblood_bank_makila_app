import 'package:get_storage/get_storage.dart';

/// Who is signed in, as GetStorage tells it: every login writes `user_data`
/// (with the user's `id`) and then `user_profiles`; every logout removes
/// `user_profiles`. Both keys are also rewritten mid-session for the same
/// user (AuthApi.getUserProfile), which is not a change of session.
class SessionIdentity {
  SessionIdentity([GetStorage? storage]) : _storage = storage ?? GetStorage() {
    _last = userId;
  }

  final GetStorage _storage;
  late String _last;

  /// The signed-in user's id; '' when signed out.
  String get userId {
    // One logout path removes the profiles before `user_data`.
    if (_storage.read('user_profiles') == null) return '';
    final data = _storage.read('user_data');
    return data is Map ? (data['id'] ?? data['_id'] ?? '').toString() : '';
  }

  /// Whether the signed-in user changed (another login, or a logout) since
  /// this was created or last answered true.
  bool changed() {
    final now = userId;
    if (now == _last) return false;
    _last = now;
    return true;
  }
}
