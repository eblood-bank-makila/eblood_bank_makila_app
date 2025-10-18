import 'dart:convert';

/// Model for inventory summary from nearby blood banks API
class InventorySummary {
  final int totalBags;
  final List<String> availableBloodTypes;
  final List<String> productTypes;
  final List<String> volumes;

  InventorySummary({
    required this.totalBags,
    required this.availableBloodTypes,
    required this.productTypes,
    required this.volumes,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalBags: json['total_bags'] ?? 0,
      availableBloodTypes: (json['available_blood_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      productTypes: (json['product_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      volumes: (json['volumes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_bags': totalBags,
        'available_blood_types': availableBloodTypes,
        'product_types': productTypes,
        'volumes': volumes,
      };
}

/// Enhanced model for nearby blood banks with inventory information
class NearbyBloodBankModel {
  final String bloodBankId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? phone;
  final String? email;
  final InventorySummary inventorySummary;

  NearbyBloodBankModel({
    required this.bloodBankId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.phone,
    this.email,
    required this.inventorySummary,
  });

  factory NearbyBloodBankModel.fromJson(Map<String, dynamic> json) {
    return NearbyBloodBankModel(
      bloodBankId: json['blood_bank_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      phone: json['phone'],
      email: json['email'],
      inventorySummary: InventorySummary.fromJson(
          json['inventory_summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'blood_bank_id': bloodBankId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distance_km': distanceKm,
        'phone': phone,
        'email': email,
        'inventory_summary': inventorySummary.toJson(),
      };

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.toStringAsFixed(0)}km';
    }
  }

  /// Get blood types as comma-separated string
  String get bloodTypesString {
    return inventorySummary.availableBloodTypes.join(', ');
  }

  /// Get product types as comma-separated string
  String get productTypesString {
    return inventorySummary.productTypes
        .map((type) => _formatProductType(type))
        .join(', ');
  }

  /// Format product type for display
  String _formatProductType(String type) {
    switch (type.toLowerCase()) {
      case 'whole_blood':
        return 'Whole Blood';
      case 'plasma':
        return 'Plasma';
      case 'platelets':
        return 'Platelets';
      case 'red_blood_cells':
        return 'Red Blood Cells';
      default:
        return type;
    }
  }
}

/// Response model for nearby blood banks API
class NearbyBloodBanksResponse {
  final List<NearbyBloodBankModel> bloodBanks;
  final int total;
  final int page;
  final int limit;

  NearbyBloodBanksResponse({
    required this.bloodBanks,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory NearbyBloodBanksResponse.fromJson(Map<String, dynamic> json) {
    final bloodBankList = (json['blood_bank'] as List<dynamic>?)
            ?.map((e) => NearbyBloodBankModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return NearbyBloodBanksResponse(
      bloodBanks: bloodBankList,
      total: json['total'] ?? 0,
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
        'blood_bank': bloodBanks.map((e) => e.toJson()).toList(),
        'total': total,
        'page': page,
        'limit': limit,
      };
}

