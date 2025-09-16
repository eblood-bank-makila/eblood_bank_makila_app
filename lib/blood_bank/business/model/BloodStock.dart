class BloodStock {
  final String id;
  final String bloodType;
  final int quantity;
  final DateTime expirationDate;
  final DateTime collectionDate;
  final String donorId;
  final String batchNumber;
  final BloodStockStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BloodStock({
    required this.id,
    required this.bloodType,
    required this.quantity,
    required this.expirationDate,
    required this.collectionDate,
    required this.donorId,
    required this.batchNumber,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BloodStock.fromJson(Map<String, dynamic> json) {
    return BloodStock(
      id: json['id'] ?? '',
      bloodType: json['bloodType'] ?? '',
      quantity: json['quantity'] ?? 0,
      expirationDate: DateTime.parse(json['expirationDate']),
      collectionDate: DateTime.parse(json['collectionDate']),
      donorId: json['donorId'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      status: BloodStockStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BloodStockStatus.available,
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloodType': bloodType,
      'quantity': quantity,
      'expirationDate': expirationDate.toIso8601String(),
      'collectionDate': collectionDate.toIso8601String(),
      'donorId': donorId,
      'batchNumber': batchNumber,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BloodStock copyWith({
    String? id,
    String? bloodType,
    int? quantity,
    DateTime? expirationDate,
    DateTime? collectionDate,
    String? donorId,
    String? batchNumber,
    BloodStockStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodStock(
      id: id ?? this.id,
      bloodType: bloodType ?? this.bloodType,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      collectionDate: collectionDate ?? this.collectionDate,
      donorId: donorId ?? this.donorId,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
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
    return status == BloodStockStatus.available && !isExpired && quantity > 0;
  }

  int get daysUntilExpiration {
    return expirationDate.difference(DateTime.now()).inDays;
  }

  String get stockLevel {
    if (quantity >= 10) return 'Normal';
    if (quantity >= 5) return 'Faible';
    return 'Critique';
  }

  @override
  String toString() {
    return 'BloodStock(id: $id, bloodType: $bloodType, quantity: $quantity, status: $status)';
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

class BloodBankStats {
  final int totalStock;
  final int activeRequests;
  final int completedDeliveries;
  final int criticalStock;
  final int expiringSoon;
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
    return BloodBankStats(
      totalStock: json['totalStock'] ?? 0,
      activeRequests: json['activeRequests'] ?? 0,
      completedDeliveries: json['completedDeliveries'] ?? 0,
      criticalStock: json['criticalStock'] ?? 0,
      expiringSoon: json['expiringSoon'] ?? 0,
      stockByType: Map<String, int>.from(json['stockByType'] ?? {}),
      requestsByStatus: Map<String, int>.from(json['requestsByStatus'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStock': totalStock,
      'activeRequests': activeRequests,
      'completedDeliveries': completedDeliveries,
      'criticalStock': criticalStock,
      'expiringSoon': expiringSoon,
      'stockByType': stockByType,
      'requestsByStatus': requestsByStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
