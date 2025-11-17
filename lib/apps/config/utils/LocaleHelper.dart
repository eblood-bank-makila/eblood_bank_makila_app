import 'package:intl/intl.dart';

/// Helper class to handle locale-specific formatting with fallback support
/// for locales not supported by the intl package (like Lingala)
class LocaleHelper {
  /// List of locales supported by the intl package
  static const Set<String> _supportedIntlLocales = {
    'en', 'en_US', 'en-US',
    'fr', 'fr_FR', 'fr-FR',
    'es', 'es_ES', 'es-ES',
    'ar', 'ar_SA', 'ar-SA',
    'ru', 'ru_RU', 'ru-RU',
    'de', 'de_DE', 'de-DE',
    'it', 'it_IT', 'it-IT',
    'pt', 'pt_BR', 'pt-BR',
    'zh', 'zh_CN', 'zh-CN',
    'ja', 'ja_JP', 'ja-JP',
  };

  /// Map of unsupported locales to their fallback locales
  /// Lingala (ln_CD) falls back to French (fr_FR) since both are used in DRC
  static const Map<String, String> _localeFallbacks = {
    'ln': 'fr_FR',
    'ln_CD': 'fr_FR',
    'ln-CD': 'fr_FR',
  };

  /// Get a safe locale string for use with intl package
  /// Returns the original locale if supported, otherwise returns a fallback
  static String getSafeLocale(String? locale) {
    if (locale == null || locale.isEmpty) {
      return 'en_US'; // Default fallback
    }

    // Normalize locale format (replace - with _)
    final normalizedLocale = locale.replaceAll('-', '_');

    // Check if locale is supported
    if (_supportedIntlLocales.contains(normalizedLocale)) {
      return normalizedLocale;
    }

    // Check if we have a fallback for this locale
    if (_localeFallbacks.containsKey(normalizedLocale)) {
      return _localeFallbacks[normalizedLocale]!;
    }

    // Try just the language code (e.g., 'ln' from 'ln_CD')
    final languageCode = normalizedLocale.split('_').first;
    if (_localeFallbacks.containsKey(languageCode)) {
      return _localeFallbacks[languageCode]!;
    }

    // Check if just the language code is supported
    if (_supportedIntlLocales.contains(languageCode)) {
      return languageCode;
    }

    // Ultimate fallback to French (common in DRC)
    return 'fr_FR';
  }

  /// Create a safe DateFormat with fallback locale support
  static DateFormat createDateFormat(String pattern, String? locale) {
    final safeLocale = getSafeLocale(locale);
    try {
      return DateFormat(pattern, safeLocale);
    } catch (e) {
      // If still fails, use default locale
      return DateFormat(pattern);
    }
  }

  /// Create a safe NumberFormat with fallback locale support
  static NumberFormat createNumberFormat({
    String? locale,
    String? symbol,
    int? decimalDigits,
  }) {
    final safeLocale = getSafeLocale(locale);
    try {
      if (symbol != null || decimalDigits != null) {
        return NumberFormat.currency(
          locale: safeLocale,
          symbol: symbol ?? '',
          decimalDigits: decimalDigits ?? 2,
        );
      }
      return NumberFormat('#,##0.00', safeLocale);
    } catch (e) {
      // If still fails, use default locale
      return NumberFormat.currency(
        symbol: symbol ?? '',
        decimalDigits: decimalDigits ?? 2,
      );
    }
  }

  /// Format a date with safe locale handling
  static String formatDate(DateTime date, String pattern, String? locale) {
    final formatter = createDateFormat(pattern, locale);
    return formatter.format(date);
  }

  /// Format a number/currency with safe locale handling
  static String formatCurrency(
    num amount, {
    String? locale,
    String? symbol,
    int? decimalDigits,
  }) {
    final formatter = createNumberFormat(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Check if a locale is supported by intl package
  static bool isLocaleSupported(String? locale) {
    if (locale == null || locale.isEmpty) return false;
    final normalizedLocale = locale.replaceAll('-', '_');
    return _supportedIntlLocales.contains(normalizedLocale);
  }

  /// Get the fallback locale for an unsupported locale
  static String? getFallbackLocale(String? locale) {
    if (locale == null || locale.isEmpty) return null;
    final normalizedLocale = locale.replaceAll('-', '_');
    return _localeFallbacks[normalizedLocale];
  }
}

