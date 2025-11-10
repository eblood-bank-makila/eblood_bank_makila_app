import '../config/AppConfig.dart';

/// API constants built dynamically from environment configuration (AppConfig)
/// This avoids hardcoding base URLs so different envs (.env) work seamlessly.
class ApiConstants {
  static String get _BASE_API_URL => AppConfig.instance.baseApiUrl; // e.g. http://host:port/api/v1

  // Auth endpoints (kept for backward compatibility if still used elsewhere)
  static String get LOGIN => '$_BASE_API_URL/auth/login';
  static String get REGISTER => '$_BASE_API_URL/auth/register';

  // User (personal) registration endpoints (new centralized variants)
  static String get USERS_REGISTER => '$_BASE_API_URL/eblood-connect/users/register';
  static String userSocialRegister(String provider) => '$_BASE_API_URL/eblood-connect/users/' + provider + '/register';
  static String get USERS_GOOGLE_REGISTER => userSocialRegister('google');
  // Future examples: USERS_FACEBOOK_REGISTER => userSocialRegister('facebook');

  // Health Structure endpoints
  static String get HEALTH_STRUCTURE_REGISTER => '$_BASE_API_URL/eblood/health-structures/register';
  static String get HEALTH_STRUCTURE_VERIFY => '$_BASE_API_URL/eblood/health-structures/verify';
  static String get HEALTH_STRUCTURE_COMPLETE_PROFILE => '$_BASE_API_URL/eblood/health-structures/complete-profile';
  static String healthStructureSocialRegister(String provider) => '$_BASE_API_URL/eblood/health-structures/' + provider + '/register';
  static String get HEALTH_STRUCTURE_GOOGLE_REGISTER => healthStructureSocialRegister('google');
}