/// Blood Search Flow - Domain Entities
/// Clean architecture domain layer for the blood search journey

import 'package:flutter/foundation.dart';

/// Represents the current step in the blood search flow
enum SearchFlowStep {
  welcome,
  citySelection,
  bloodTypeInput,
  searchResults,
  hospitalIdentification,
  visitorRegistration,
  otpVerification,
  payment,
  addressView,
  deliveryTracking,
}

/// Payment option selected by user
enum PaymentOption {
  viewAddress,
  delivery,
}

/// Hospital identification method
enum HospitalIdentificationMethod {
  qrScan,
  galleryImport,
  manualCode,
  deepLink,
}

/// Represents a city/location selection
@immutable
class SelectedCity {
  final String id;
  final String name;
  final String? regionId;
  final String? regionName;
  final String? countryId;
  final String? countryName;
  final String? path;

  const SelectedCity({
    required this.id,
    required this.name,
    this.regionId,
    this.regionName,
    this.countryId,
    this.countryName,
    this.path,
  });

  /// Returns full location path as string
  String get fullPath {
    final parts = <String>[];
    if (countryName != null) parts.add(countryName!);
    if (regionName != null) parts.add(regionName!);
    parts.add(name);
    return parts.join(' > ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedCity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents identified hospital data
@immutable
class IdentifiedHospital {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final HospitalIdentificationMethod method;

  const IdentifiedHospital({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    required this.method,
  });

  factory IdentifiedHospital.fromJson(Map<String, dynamic> json, HospitalIdentificationMethod method) {
    return IdentifiedHospital(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? json['hospital_code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['hospital_name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString() ?? json['phone_number']?.toString(),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      method: method,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'address': address,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'method': method.name,
  };
}

/// Blood search result item
@immutable
class BloodSearchResult {
  final String id;
  final String bloodBankId;
  final String bloodBankName;
  final String bloodType;
  final String rhFactor;
  final int stockCount;
  final String? distance;
  final double? latitude;
  final double? longitude;
  
  // Additional fields for UI display
  final String? hospitalName;
  final String? address;
  final double? distanceKm;
  final bool isAvailable;
  
  // Pricing info
  final double price;
  final String currency;
  final String? currencySymbol;
  
  // Blood bag info
  final String? bloodProductType;
  final String? status;
  final String? batchNumber;
  final String? expireDate;
  final int? daysUntilExpiry;
  final String? bloodBagCondition;
  final String? description;

  const BloodSearchResult({
    required this.id,
    required this.bloodBankId,
    required this.bloodBankName,
    required this.bloodType,
    required this.rhFactor,
    required this.stockCount,
    this.distance,
    this.latitude,
    this.longitude,
    this.hospitalName,
    this.address,
    this.distanceKm,
    this.isAvailable = true,
    this.price = 0.0,
    this.currency = 'USD',
    this.currencySymbol,
    this.bloodProductType,
    this.status,
    this.batchNumber,
    this.expireDate,
    this.daysUntilExpiry,
    this.bloodBagCondition,
    this.description,
  });

  factory BloodSearchResult.fromJson(Map<String, dynamic> json) {
    // Parse blood bank info - matches DatumRecherchePocheModel structure
    final bloodBank = json['blood_bank_info'] ?? json['blood_bank'] ?? json['bloodBank'] ?? {};
    final bloodInfo = json['blood_bag_info'] ?? json['bloodBagInfo'] ?? {};
    final bloodTypeInfo = bloodInfo['blood_type_info'] ?? bloodInfo['bloodTypeInfo'] ?? {};
    final townInfo = bloodBank['town_info'] ?? bloodBank['townInfo'] ?? {};
    
    // Get blood bank name from blood_bank_info field
    final bloodBankName = bloodBank['blood_bank_name']?.toString() ?? 
                          bloodBank['bloodBankName']?.toString() ?? 
                          bloodBank['name']?.toString() ?? '';
    
    // Parse blood type and rh factor
    final bloodTypeName = bloodTypeInfo['blood_type_name']?.toString() ?? 
                          bloodTypeInfo['bloodTypeName']?.toString() ?? '';
    final rhFactor = bloodTypeInfo['rh_factor']?.toString() ?? 
                     bloodTypeInfo['rhFactor']?.toString() ??
                     json['rhesus_factor']?.toString() ?? '';
    
    // Parse distance as double
    double? parsedDistanceKm;
    final distanceStr = json['distance']?.toString();
    if (distanceStr != null) {
      parsedDistanceKm = double.tryParse(distanceStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    
    // Parse coordinates
    double? lat;
    double? lng;
    if (bloodBank['latitude'] != null) {
      lat = double.tryParse(bloodBank['latitude'].toString());
    }
    if (bloodBank['longitude'] != null) {
      lng = double.tryParse(bloodBank['longitude'].toString());
    }
    
    // Build address from town info
    String? fullAddress;
    if (townInfo.isNotEmpty) {
      final townName = townInfo['town_name']?.toString() ?? townInfo['townName']?.toString() ?? '';
      final provinceName = townInfo['province_name']?.toString() ?? townInfo['provinceName']?.toString() ?? '';
      final countryName = townInfo['country_name']?.toString() ?? townInfo['countryName']?.toString() ?? '';
      final parts = [townName, provinceName, countryName].where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) fullAddress = parts.join(', ');
    }
    
    return BloodSearchResult(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? bloodBank['_id']?.toString() ?? '',
      bloodBankId: bloodBank['_id']?.toString() ?? bloodBank['id']?.toString() ?? '',
      bloodBankName: bloodBankName,
      bloodType: bloodTypeName,
      rhFactor: rhFactor,
      stockCount: json['blood_stock_count'] ?? json['bloodStockCount'] ?? 1,
      distance: json['distance']?.toString(),
      latitude: lat,
      longitude: lng,
      hospitalName: bloodBankName,
      address: fullAddress ?? bloodBank['address']?.toString() ?? json['address']?.toString(),
      distanceKm: parsedDistanceKm,
      isAvailable: (json['status'] ?? 'available') == 'available' && 
                   (json['blood_stock_count'] ?? json['bloodStockCount'] ?? 1) > 0,
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency']?.toString() ?? 'USD',
      currencySymbol: json['currency_symbol']?.toString() ?? json['currencySymbol']?.toString(),
      bloodProductType: json['blood_product_type']?.toString() ?? json['bloodProductType']?.toString(),
      status: json['status']?.toString(),
      batchNumber: json['batch_number']?.toString() ?? json['batchNumber']?.toString(),
      expireDate: json['expire_date']?.toString() ?? json['expireDate']?.toString(),
      daysUntilExpiry: json['days_until_expiry'] ?? json['daysUntilExpiry'],
      bloodBagCondition: json['blood_bag_condition']?.toString() ?? json['bloodBagCondition']?.toString(),
      description: json['description']?.toString(),
    );
  }
  
  /// Returns formatted blood type with Rh factor (e.g., "A+", "O-")
  String get fullBloodType {
    if (rhFactor.isNotEmpty) {
      return '$bloodType$rhFactor';
    }
    return bloodType;
  }
  
  /// Returns formatted price string
  String get formattedPrice {
    final symbol = currencySymbol ?? currency;
    return '$symbol ${price.toStringAsFixed(2)}';
  }
}

/// Payment result
@immutable
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final PaymentOption option;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    required this.option,
  });
}

/// Delivery tracking info
@immutable  
class DeliveryTrackingInfo {
  final String trackingId;
  final String status;
  final String? driverName;
  final String? driverPhone;
  final double? driverLatitude;
  final double? driverLongitude;
  final String? estimatedArrival;
  
  // Timeline timestamps
  final DateTime? orderTime;
  final DateTime? confirmedTime;
  final DateTime? pickedUpTime;
  final DateTime? deliveredTime;

  const DeliveryTrackingInfo({
    required this.trackingId,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.driverLatitude,
    this.driverLongitude,
    this.estimatedArrival,
    this.orderTime,
    this.confirmedTime,
    this.pickedUpTime,
    this.deliveredTime,
  });

  factory DeliveryTrackingInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryTrackingInfo(
      trackingId: json['tracking_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      driverName: json['driver_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      driverLatitude: json['driver_latitude'] is num ? (json['driver_latitude'] as num).toDouble() : null,
      driverLongitude: json['driver_longitude'] is num ? (json['driver_longitude'] as num).toDouble() : null,
      estimatedArrival: json['estimated_arrival']?.toString(),
      orderTime: json['order_time'] != null ? DateTime.tryParse(json['order_time'].toString()) : null,
      confirmedTime: json['confirmed_time'] != null ? DateTime.tryParse(json['confirmed_time'].toString()) : null,
      pickedUpTime: json['picked_up_time'] != null ? DateTime.tryParse(json['picked_up_time'].toString()) : null,
      deliveredTime: json['delivered_time'] != null ? DateTime.tryParse(json['delivered_time'].toString()) : null,
    );
  }
}

/// Complete search flow state
@immutable
class SearchFlowState {
  final SearchFlowStep currentStep;
  final bool isLoading;
  final String? errorMessage;
  
  // Flow data
  final bool qrScannedFirst;
  final SelectedCity? selectedCity;
  final String? selectedBloodType;
  final List<BloodSearchResult> searchResults;
  final PaymentOption? selectedPaymentOption;
  final IdentifiedHospital? identifiedHospital;
  
  // Visitor registration
  final String? visitorPhoneNumber;
  final bool otpSent;
  final bool otpVerified;
  final String? visitorToken;
  
  // Payment & post-payment
  final PaymentResult? paymentResult;
  final String? unlockedAddress;
  final DeliveryTrackingInfo? deliveryTracking;

  const SearchFlowState({
    this.currentStep = SearchFlowStep.welcome,
    this.isLoading = false,
    this.errorMessage,
    this.qrScannedFirst = false,
    this.selectedCity,
    this.selectedBloodType,
    this.searchResults = const [],
    this.selectedPaymentOption,
    this.identifiedHospital,
    this.visitorPhoneNumber,
    this.otpSent = false,
    this.otpVerified = false,
    this.visitorToken,
    this.paymentResult,
    this.unlockedAddress,
    this.deliveryTracking,
  });

  SearchFlowState copyWith({
    SearchFlowStep? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? qrScannedFirst,
    SelectedCity? selectedCity,
    String? selectedBloodType,
    List<BloodSearchResult>? searchResults,
    PaymentOption? selectedPaymentOption,
    IdentifiedHospital? identifiedHospital,
    String? visitorPhoneNumber,
    bool? otpSent,
    bool? otpVerified,
    String? visitorToken,
    PaymentResult? paymentResult,
    String? unlockedAddress,
    DeliveryTrackingInfo? deliveryTracking,
  }) {
    return SearchFlowState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      qrScannedFirst: qrScannedFirst ?? this.qrScannedFirst,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedBloodType: selectedBloodType ?? this.selectedBloodType,
      searchResults: searchResults ?? this.searchResults,
      selectedPaymentOption: selectedPaymentOption ?? this.selectedPaymentOption,
      identifiedHospital: identifiedHospital ?? this.identifiedHospital,
      visitorPhoneNumber: visitorPhoneNumber ?? this.visitorPhoneNumber,
      otpSent: otpSent ?? this.otpSent,
      otpVerified: otpVerified ?? this.otpVerified,
      visitorToken: visitorToken ?? this.visitorToken,
      paymentResult: paymentResult ?? this.paymentResult,
      unlockedAddress: unlockedAddress ?? this.unlockedAddress,
      deliveryTracking: deliveryTracking ?? this.deliveryTracking,
    );
  }

  /// Check if user has completed hospital identification
  bool get hasHospitalIdentified => identifiedHospital != null;

  /// Check if visitor is registered and verified
  bool get isVisitorVerified => otpVerified && visitorToken != null;

  /// Check if payment was successful
  bool get paymentSuccessful => paymentResult?.success == true;
  
  /// Get the searched blood type with Rh factor formatted for display
  String? get searchedBloodType => selectedBloodType;
}
