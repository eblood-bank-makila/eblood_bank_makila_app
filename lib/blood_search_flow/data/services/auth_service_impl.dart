/// Auth Service Implementation
/// Integrates with existing authentication system

import 'package:get_storage/get_storage.dart';
import '../../domain/services/service_interfaces.dart';
import '../../../apps/services/AuthApi.dart';

class AuthServiceImpl implements IAuthService {
  final GetStorage _storage = GetStorage();

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Check for existing tokens
      final token = _storage.read('token_otp') ?? 
                    _storage.read('visitor_token') ??
                    _storage.read('access_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return _storage.read('token_otp') ?? 
             _storage.read('visitor_token') ??
             _storage.read('access_token');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getUserProfileType() async {
    try {
      // Check stored profile type
      final profileType = _storage.read('user_profile_type');
      if (profileType != null) return profileType;

      // Try to fetch from API
      final userProfile = await AuthApi.instance.getUserProfile();
      if (userProfile != null) {
        // DatumCodeOtpModele has profilTypeFlag and profilTypeName fields
        final type = userProfile.profilTypeFlag ?? 
                     userProfile.profilTypeName ??
                     userProfile.uAccountType;
        if (type.isNotEmpty) {
          await _storage.write('user_profile_type', type);
        }
        return type;
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
      final profileType = await getUserProfileType();
      return profileType == 'visitor' || 
             profileType == 'VISITOR' ||
             _storage.read('is_visitor') == true;
    } catch (e) {
      return false;
    }
  }
}
