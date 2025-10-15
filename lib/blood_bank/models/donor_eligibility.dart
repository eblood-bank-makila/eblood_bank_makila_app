import 'package:flutter/foundation.dart';

class DonorDeferral {
  final String? reason;
  final String? type;
  final DateTime? endDate;

  const DonorDeferral({
    this.reason,
    this.type,
    this.endDate,
  });

  factory DonorDeferral.fromJson(Map<String, dynamic> json) {
    DateTime? parsedEndDate;
    final dynamic rawEndDate = json['end_date'] ?? json['endDate'];
    if (rawEndDate is String && rawEndDate.isNotEmpty) {
      try {
        parsedEndDate = DateTime.parse(rawEndDate);
      } catch (e, stackTrace) {
        debugPrint('Failed to parse deferral end_date: $rawEndDate -> $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return DonorDeferral(
      reason: json['reason']?.toString(),
      type: json['type']?.toString(),
      endDate: parsedEndDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'type': type,
      'end_date': endDate?.toIso8601String(),
    };
  }
}

class DonorEligibility {
  final String donorId;
  final bool isEligible;
  final List<String> reasons;
  final List<DonorDeferral> deferrals;
  final DateTime? nextEligibleDate;
  final List<String> recommendations;

  const DonorEligibility({
    required this.donorId,
    required this.isEligible,
    required this.reasons,
    required this.deferrals,
    required this.nextEligibleDate,
    required this.recommendations,
  });

  factory DonorEligibility.fromJson(Map<String, dynamic> json) {
    final dynamic rawReasons = json['reasons'];
    final dynamic rawRecommendations = json['recommendations'];
    final dynamic rawDeferrals = json['deferrals'];

    final List<String> parsedReasons = rawReasons is List
        ? rawReasons.map((reason) => reason.toString()).toList()
        : const [];

    final List<String> parsedRecommendations = rawRecommendations is List
        ? rawRecommendations.map((item) => item.toString()).toList()
        : const [];

    final List<DonorDeferral> parsedDeferrals = rawDeferrals is List
        ? rawDeferrals
            .whereType<Map<String, dynamic>>()
            .map(DonorDeferral.fromJson)
            .toList()
        : const [];

    DateTime? parsedNextEligible;
    final dynamic rawNextEligible =
        json['next_eligible_date'] ?? json['nextEligibleDate'];
    if (rawNextEligible is String && rawNextEligible.isNotEmpty) {
      try {
        parsedNextEligible = DateTime.parse(rawNextEligible);
      } catch (e, stackTrace) {
        debugPrint('Failed to parse next_eligible_date: $rawNextEligible -> $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return DonorEligibility(
      donorId: json['donor_id']?.toString() ?? json['donorId']?.toString() ?? '',
      isEligible: json['is_eligible'] == true || json['isEligible'] == true,
      reasons: parsedReasons,
      deferrals: parsedDeferrals,
      nextEligibleDate: parsedNextEligible,
      recommendations: parsedRecommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donor_id': donorId,
      'is_eligible': isEligible,
      'reasons': reasons,
      'deferrals': deferrals.map((deferral) => deferral.toJson()).toList(),
      'next_eligible_date': nextEligibleDate?.toIso8601String(),
      'recommendations': recommendations,
    };
  }
}
