import 'package:get/get.dart';

/// Helper class for translating blood-related keys
class BloodTranslations {
  /// Translate blood component key to localized name
  static String getBloodComponentName(String componentKey) {
    switch (componentKey.toLowerCase()) {
      case 'whole_blood':
        return 'whole_blood'.tr;
      case 'red_cells':
        return 'red_cells'.tr;
      case 'plasma':
        return 'plasma'.tr;
      case 'platelets':
        return 'platelets'.tr;
      default:
        return componentKey;
    }
  }

  /// Translate blood type key to localized name
  static String getBloodTypeName(String bloodTypeKey) {
    switch (bloodTypeKey.toUpperCase()) {
      case 'A+':
      case 'A_POSITIVE':
        return 'blood_type_a_positive'.tr;
      case 'A-':
      case 'A_NEGATIVE':
        return 'blood_type_a_negative'.tr;
      case 'B+':
      case 'B_POSITIVE':
        return 'blood_type_b_positive'.tr;
      case 'B-':
      case 'B_NEGATIVE':
        return 'blood_type_b_negative'.tr;
      case 'AB+':
      case 'AB_POSITIVE':
        return 'blood_type_ab_positive'.tr;
      case 'AB-':
      case 'AB_NEGATIVE':
        return 'blood_type_ab_negative'.tr;
      case 'O+':
      case 'O_POSITIVE':
        return 'blood_type_o_positive'.tr;
      case 'O-':
      case 'O_NEGATIVE':
        return 'blood_type_o_negative'.tr;
      default:
        return bloodTypeKey;
    }
  }

  /// Get month name from month number (1-12)
  static String getMonthName(int month) {
    const monthKeys = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december'
    ];
    if (month >= 1 && month <= 12) {
      return monthKeys[month - 1].tr;
    }
    return month.toString();
  }

  /// Get period label for charts
  static String getPeriodLabel(String period) {
    switch (period.toLowerCase()) {
      case 'week':
        return 'day'.tr;
      case 'month':
        return 'day'.tr;
      case 'quarter':
        return 'week'.tr;
      case 'year':
        return 'month'.tr;
      default:
        return 'period'.tr;
    }
  }

  /// Get stock level label
  static String getStockLevelLabel(int quantity) {
    if (quantity >= 30) {
      return 'normal'.tr;
    } else if (quantity >= 15) {
      return 'low'.tr;
    } else {
      return 'critical'.tr;
    }
  }

  /// Format time ago
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      return 'minutes_ago'.trParams({'minutes': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return 'hours_ago'.trParams({'hours': difference.inHours.toString()});
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr;
    } else if (difference.inDays < 7) {
      return 'days_ago'.trParams({'days': difference.inDays.toString()});
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

