import 'BloodEnums.dart';

class BloodStock {
  final String id;
  final String bloodType;
  final double volume; // Changed from int quantity to double volume
  final BloodProductType productType;
  final BloodBagStatus status;
  final BloodBagConditionStatus bagCondition;
  final DateTime expirationDate;
  final DateTime collectionDate;
  final String donorId;
  final String batchNumber;
  final String? description; // Changed from notes to description
  final DateTime createdAt;
  final DateTime updatedAt;

  BloodStock({
    required this.id,
    required this.bloodType,
    required this.volume,
    required this.productType,
    required this.status,
    required this.bagCondition,
    required this.expirationDate,
    required this.collectionDate,
    required this.donorId,
    required this.batchNumber,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BloodStock.fromJson(Map<String, dynamic> json) {
    // Helper function to handle volume string parsing (e.g. "450.0ml" to 450.0)
    double parseVolume(dynamic volumeValue) {
      if (volumeValue == null) return 0.0;
      
      if (volumeValue is num) {
        return volumeValue.toDouble();
      } else if (volumeValue is String) {
        // Extract numeric part from string like "450.0ml"
        String numericPart = volumeValue.replaceAll(RegExp(r'[^0-9.]'), '');
        try {
          return double.parse(numericPart);
        } catch (e) {
          print('⚠️ Error parsing volume: $e for value: $volumeValue');
          return 0.0;
        }
      }
      return 0.0;
    }
    
    // Handle different date formats or null dates
    DateTime parseDate(dynamic dateValue, {DateTime? defaultValue}) {
      if (dateValue == null) {
        return defaultValue ?? DateTime.now();
      }
      
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is Map && dateValue.containsKey('seconds')) {
          // Handle Firestore timestamp format if used
          int seconds = dateValue['seconds'] as int;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        print('⚠️ Error parsing date: $e for value: $dateValue');
      }
      
      return defaultValue ?? DateTime.now();
    }
    
    // Support both camelCase and snake_case field names from API
    final String id = json['id'] ?? '';
    
    // Blood type could be in different formats
    final String bloodType = 
        json['bloodType'] ?? 
        json['blood_type'] ?? 
        json['rhesus_factor'] ?? 
        '';
    
    // Volume parsing with support for string format "450.0ml"
    final double volume = parseVolume(json['volume']);
    
    // Product type with fallback
    final productType = BloodProductType.fromString(
        json['productType'] ?? 
        json['blood_product_type'] ?? 
        'whole_blood');
    
    // Status with fallback to available if not provided
    final status = BloodBagStatus.fromString(
        json['status'] ?? 
        (json['is_discarded'] == true ? 'bad_quality' : 'available'));
    
    // Bag condition with support for different field names
    final bagCondition = BloodBagConditionStatus.fromString(
        json['bagCondition'] ?? 
        json['blood_bag_condition'] ?? 
        'good');
    
    // Dates with proper handling of null or different formats
    final DateTime now = DateTime.now();
    final expirationDate = parseDate(
        json['expirationDate'] ?? json['expire_date'],
        defaultValue: now.add(const Duration(days: 35))); // Default 35 days if missing
    
    final collectionDate = parseDate(
        json['collectionDate'] ?? json['collected_on_date'],
        defaultValue: now); // Default to now if missing
    
    // Created and updated with defaults
    final createdAt = parseDate(
        json['createdAt'] ?? json['created_at'],
        defaultValue: now);
    
    final updatedAt = parseDate(
        json['updatedAt'] ?? json['updated_at'],
        defaultValue: now);
    
    return BloodStock(
      id: id,
      bloodType: bloodType,
      volume: volume,
      productType: productType,
      status: status,
      bagCondition: bagCondition,
      expirationDate: expirationDate,
      collectionDate: collectionDate,
      donorId: json['donorId'] ?? json['donor_id'] ?? '',
      batchNumber: json['batchNumber'] ?? json['batch_number'] ?? '',
      description: json['description'] ?? json['description_str'] ?? json['notes'], // Support for all format variations
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloodType': bloodType,
      'volume': volume,
      'productType': productType.value,
      'status': status.value,
      'bagCondition': bagCondition.value,
      'expirationDate': expirationDate.toIso8601String(),
      'collectionDate': collectionDate.toIso8601String(),
      'donorId': donorId,
      'batchNumber': batchNumber,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BloodStock copyWith({
    String? id,
    String? bloodType,
    double? volume,
    BloodProductType? productType,
    BloodBagStatus? status,
    BloodBagConditionStatus? bagCondition,
    DateTime? expirationDate,
    DateTime? collectionDate,
    String? donorId,
    String? batchNumber,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodStock(
      id: id ?? this.id,
      bloodType: bloodType ?? this.bloodType,
      volume: volume ?? this.volume,
      productType: productType ?? this.productType,
      status: status ?? this.status,
      bagCondition: bagCondition ?? this.bagCondition,
      expirationDate: expirationDate ?? this.expirationDate,
      collectionDate: collectionDate ?? this.collectionDate,
      donorId: donorId ?? this.donorId,
      batchNumber: batchNumber ?? this.batchNumber,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isExpiringSoon {
    final daysUntilExpiration = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7;
  }

  bool get isExpired {
    return DateTime.now().isAfter(expirationDate);
  }

  bool get isAvailable {
    return status == BloodBagStatus.available && !isExpired && volume > 0;
  }

  int get daysUntilExpiration {
    return expirationDate.difference(DateTime.now()).inDays;
  }

  String get stockLevel {
    if (volume >= 450) return 'Normal'; // Typically a blood bag is ~450-500ml
    if (volume >= 250) return 'Faible';
    return 'Critique';
  }

  @override
  String toString() {
    return 'BloodStock(id: $id, bloodType: $bloodType, volume: $volume, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodStock && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum BloodStockStatus {
  available,
  reserved,
  used,
  expired,
  quarantine,
}

class BloodRequest {
  final String id;
  final String hospitalId;
  final String hospitalName;
  final String bloodType;
  final int quantity;
  final BloodRequestPriority priority;
  final BloodRequestStatus status;
  final String? reason;
  final String? notes;
  final DateTime requestDate;
  final DateTime? approvedDate;
  final DateTime? completedDate;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  BloodRequest({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.bloodType,
    required this.quantity,
    required this.priority,
    required this.status,
    this.reason,
    this.notes,
    required this.requestDate,
    this.approvedDate,
    this.completedDate,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] ?? '',
      hospitalId: json['hospitalId'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      bloodType: json['bloodType'] ?? '',
      quantity: json['quantity'] ?? 0,
      priority: BloodRequestPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => BloodRequestPriority.normal,
      ),
      status: BloodRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BloodRequestStatus.pending,
      ),
      reason: json['reason'],
      notes: json['notes'],
      requestDate: DateTime.parse(json['requestDate']),
      approvedDate: json['approvedDate'] != null ? DateTime.parse(json['approvedDate']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      approvedBy: json['approvedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'bloodType': bloodType,
      'quantity': quantity,
      'priority': priority.name,
      'status': status.name,
      'reason': reason,
      'notes': notes,
      'requestDate': requestDate.toIso8601String(),
      'approvedDate': approvedDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BloodRequest copyWith({
    String? id,
    String? hospitalId,
    String? hospitalName,
    String? bloodType,
    int? quantity,
    BloodRequestPriority? priority,
    BloodRequestStatus? status,
    String? reason,
    String? notes,
    DateTime? requestDate,
    DateTime? approvedDate,
    DateTime? completedDate,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      bloodType: bloodType ?? this.bloodType,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      requestDate: requestDate ?? this.requestDate,
      approvedDate: approvedDate ?? this.approvedDate,
      completedDate: completedDate ?? this.completedDate,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUrgent => priority == BloodRequestPriority.urgent;
  bool get isPending => status == BloodRequestStatus.pending;
  bool get isApproved => status == BloodRequestStatus.approved;
  bool get isCompleted => status == BloodRequestStatus.completed;

  @override
  String toString() {
    return 'BloodRequest(id: $id, hospitalName: $hospitalName, bloodType: $bloodType, quantity: $quantity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum BloodRequestPriority {
  normal,
  urgent,
  emergency,
}

enum BloodRequestStatus {
  pending,
  approved,
  rejected,
  completed,
  cancelled,
}

// Add a StatsValue class to hold both value and trend information
class StatsValue {
  final int value;
  final String trend;

  StatsValue({
    required this.value,
    this.trend = "0%",
  });

  factory StatsValue.fromJson(dynamic data) {
    // Handle both direct int value and nested object with value/trend
    if (data is int) {
      return StatsValue(value: data);
    }
    
    if (data is Map<String, dynamic>) {
      return StatsValue(
        value: data['value'] is int ? data['value'] : int.tryParse(data['value'].toString()) ?? 0,
        trend: data['trend']?.toString() ?? "0%",
      );
    }
    
    return StatsValue(value: 0);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'trend': trend,
    };
  }
}

class BloodBankStats {
  final StatsValue totalStock;
  final StatsValue activeRequests;
  final StatsValue completedDeliveries;
  final StatsValue criticalStock;
  final StatsValue expiringSoon;
  final Map<String, int> stockByType;
  final Map<String, int> requestsByStatus;
  final DateTime lastUpdated;

  BloodBankStats({
    required this.totalStock,
    required this.activeRequests,
    required this.completedDeliveries,
    required this.criticalStock,
    required this.expiringSoon,
    required this.stockByType,
    required this.requestsByStatus,
    required this.lastUpdated,
  });

  factory BloodBankStats.fromJson(Map<String, dynamic> json) {
    try {
      // For debugging
      print('📊 BloodBankStats.fromJson: ${json.toString()}');
      
      // Check if we have a nested 'data' field - sometimes the response has a data field
      final dataToUse = json.containsKey('data') && json['data'] is Map 
          ? json['data'] as Map<String, dynamic> 
          : json;
      
      print('📊 BloodBankStats.fromJson - using data: ${dataToUse.toString()}');
      
      // Handle both snake_case (backend API) and camelCase (frontend) field names
      final Map<String, dynamic> stockByTypeData = {};
      
      // Safely extract blood_type_stats
      if (dataToUse.containsKey('blood_type_stats') && dataToUse['blood_type_stats'] is Map) {
        final Map<String, dynamic> rawStockData = Map<String, dynamic>.from(dataToUse['blood_type_stats']);
        rawStockData.forEach((key, value) {
          stockByTypeData[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
      } else if (dataToUse.containsKey('stockByType') && dataToUse['stockByType'] is Map) {
        final Map<String, dynamic> rawStockData = Map<String, dynamic>.from(dataToUse['stockByType']);
        rawStockData.forEach((key, value) {
          stockByTypeData[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
      }
      
      // Create empty requestsByStatus map if not provided
      Map<String, int> requestsByStatusData = {};
      if (dataToUse.containsKey('requestsByStatus')) {
        if (dataToUse['requestsByStatus'] is Map) {
          final Map<String, dynamic> rawData = Map<String, dynamic>.from(dataToUse['requestsByStatus'] as Map);
          rawData.forEach((key, value) {
            requestsByStatusData[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
          });
        }
      }
      
      // Process total stock data (support both simple int and object with value/trend)
      final totalStockData = dataToUse['total_stock'] ?? dataToUse['totalStock'];
      final pendingRequestsData = dataToUse['pending_requests'] ?? dataToUse['activeRequests'];
      final criticalStockData = dataToUse['critical_stock'] ?? dataToUse['criticalStock'];
      final expiringStockData = dataToUse['expiring_stock'] ?? dataToUse['expiringSoon'];
      final completedDeliveriesData = dataToUse['completedDeliveries'];
      
      return BloodBankStats(
        totalStock: StatsValue.fromJson(totalStockData),
        activeRequests: StatsValue.fromJson(pendingRequestsData),
        completedDeliveries: StatsValue.fromJson(completedDeliveriesData ?? 0),
        criticalStock: StatsValue.fromJson(criticalStockData),
        expiringSoon: StatsValue.fromJson(expiringStockData),
        stockByType: stockByTypeData.map((key, value) => MapEntry(key, value as int)),
        requestsByStatus: requestsByStatusData,
        lastUpdated: dataToUse['lastUpdated'] != null 
          ? DateTime.parse(dataToUse['lastUpdated'])
          : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error in BloodBankStats.fromJson: $e');
      // Return default object with zeros instead of crashing
      return BloodBankStats(
        totalStock: StatsValue(value: 0),
        activeRequests: StatsValue(value: 0),
        completedDeliveries: StatsValue(value: 0),
        criticalStock: StatsValue(value: 0),
        expiringSoon: StatsValue(value: 0),
        stockByType: {},
        requestsByStatus: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStock': totalStock.toJson(),
      'activeRequests': activeRequests.toJson(),
      'completedDeliveries': completedDeliveries.toJson(),
      'criticalStock': criticalStock.toJson(),
      'expiringSoon': expiringSoon.toJson(),
      'stockByType': stockByType,
      'requestsByStatus': requestsByStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
