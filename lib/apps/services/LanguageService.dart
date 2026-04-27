import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Language service for managing app language preferences
class LanguageService extends GetxService {
  static LanguageService get to => Get.find();
  
  final GetStorage _storage = GetStorage();
  static const String _languageKey = 'app_language';
  
  // Observable language code
  final _currentLanguage = 'fr_FR'.obs;
  
  // Available languages (French, English, Spanish, Lingala, Russian)
  final List<Map<String, String>> availableLanguages = [
    {
      'code': 'fr_FR',
      'name': 'Français',
      'flag': '🇫🇷',
      'nativeName': 'Français',
    },
    {
      'code': 'en_US',
      'name': 'English',
      'flag': '🇺🇸',
      'nativeName': 'English',
    },
    {
      'code': 'es_ES',
      'name': 'Español',
      'flag': '🇪🇸',
      'nativeName': 'Español',
    },
    {
      'code': 'ln_CD',
      'name': 'Lingala',
      'flag': '🇨🇩',
      'nativeName': 'Lingála',
    },
    {
      'code': 'ru_RU',
      'name': 'Русский',
      'flag': '🇷🇺',
      'nativeName': 'Русский',
    },
  ];
  
  // Getters
  String get currentLanguage => _currentLanguage.value;
  String get languageCode => _currentLanguage.value.split('_')[0];
  String get countryCode => _currentLanguage.value.split('_')[1];
  Locale get currentLocale => Locale(languageCode, countryCode);
  
  // Get current language info
  Map<String, String> get currentLanguageInfo {
    return availableLanguages.firstWhere(
      (lang) => lang['code'] == currentLanguage,
      orElse: () => availableLanguages.first,
    );
  }
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadSavedLanguage();
  }
  
  /// Load saved language from storage
  Future<void> _loadSavedLanguage() async {
    try {
      final savedLanguage = _storage.read(_languageKey);
      if (savedLanguage != null && _isValidLanguage(savedLanguage)) {
        _currentLanguage.value = savedLanguage;
        await _updateLocale();
      } else {
        // Set default language based on system locale
        await _setDefaultLanguage();
      }
    } catch (e) {
      print('Error loading saved language: $e');
      await _setDefaultLanguage();
    }
  }
  
  /// Set default language to French
  Future<void> _setDefaultLanguage() async {
    try {
      // Always default to French as the primary language
      _currentLanguage.value = 'fr_FR';
      await _updateLocale();
      await _saveLanguage();
    } catch (e) {
      print('Error setting default language: $e');
      _currentLanguage.value = 'fr_FR';
      await _updateLocale();
    }
  }
  
  /// Check if language code is valid
  bool _isValidLanguage(String languageCode) {
    return availableLanguages.any((lang) => lang['code'] == languageCode);
  }
  
  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    if (!_isValidLanguage(languageCode)) {
      print('Invalid language code: $languageCode');
      return;
    }
    
    try {
      _currentLanguage.value = languageCode;
      await _saveLanguage();
      await _updateLocale();
      
      // Force app update
      Get.forceAppUpdate();
    } catch (e) {
      print('Error changing language: $e');
    }
  }
  
  /// Save language to storage
  Future<void> _saveLanguage() async {
    try {
      await _storage.write(_languageKey, _currentLanguage.value);
    } catch (e) {
      print('Error saving language: $e');
    }
  }
  
  /// Update app locale
  Future<void> _updateLocale() async {
    try {
      final locale = currentLocale;
      Get.updateLocale(locale);
    } catch (e) {
      print('Error updating locale: $e');
    }
  }
  
  /// Toggle between French and English (for quick switching)
  Future<void> toggleLanguage() async {
    final newLanguage = currentLanguage == 'fr_FR' ? 'en_US' : 'fr_FR';
    await changeLanguage(newLanguage);
  }
  
  /// Set French language
  Future<void> setFrench() async {
    await changeLanguage('fr_FR');
  }
  
  /// Set English language
  Future<void> setEnglish() async {
    await changeLanguage('en_US');
  }
  
  /// Set Spanish language
  Future<void> setSpanish() async {
    await changeLanguage('es_ES');
  }
  
  /// Get language name by code
  String getLanguageName(String languageCode) {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => availableLanguages.first,
    );
    return language['name'] ?? 'Unknown';
  }
  
  /// Get language flag by code
  String getLanguageFlag(String languageCode) {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => availableLanguages.first,
    );
    return language['flag'] ?? '🏳️';
  }
  
  /// Check if current language is RTL (no RTL languages currently supported)
  bool get isRTL => false;

  /// Get text direction based on current language
  TextDirection get textDirection => TextDirection.ltr;
}
