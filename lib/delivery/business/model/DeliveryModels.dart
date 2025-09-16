class Delivery {
  final String id;
  final String requestId;
  final String hospitalName;
  final String hospitalAddress;
  final String bloodType;
  final int quantity;
  final DeliveryStatus status;
  final DeliveryPriority priority;
  final String deliveryPersonId;
  final String deliveryPersonName;
  final DateTime requestDate;
  final DateTime? assignedDate;
  final DateTime? pickupDate;
  final DateTime? deliveredDate;
  final String? notes;
  final String? deliveryNotes;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String? contactPerson;
  final DateTime createdAt;
  final DateTime updatedAt;

  Delivery({
    required this.id,
    required this.requestId,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.priority,
    required this.deliveryPersonId,
    required this.deliveryPersonName,
    required this.requestDate,
    this.assignedDate,
    this.pickupDate,
    this.deliveredDate,
    this.notes,
    this.deliveryNotes,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactPerson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      hospitalAddress: json['hospitalAddress'] ?? '',
      bloodType: json['bloodType'] ?? '',
      quantity: json['quantity'] ?? 0,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      priority: DeliveryPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => DeliveryPriority.normal,
      ),
      deliveryPersonId: json['deliveryPersonId'] ?? '',
      deliveryPersonName: json['deliveryPersonName'] ?? '',
      requestDate: json['requestDate'] != null 
          ? DateTime.parse(json['requestDate'])
          : DateTime.now(),
      assignedDate: json['assignedDate'] != null 
          ? DateTime.parse(json['assignedDate']) 
          : null,
      pickupDate: json['pickupDate'] != null 
          ? DateTime.parse(json['pickupDate']) 
          : null,
      deliveredDate: json['deliveredDate'] != null 
          ? DateTime.parse(json['deliveredDate']) 
          : null,
      notes: json['notes'],
      deliveryNotes: json['deliveryNotes'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      contactPhone: json['contactPhone'],
      contactPerson: json['contactPerson'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'bloodType': bloodType,
      'quantity': quantity,
      'status': status.name,
      'priority': priority.name,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'requestDate': requestDate.toIso8601String(),
      'assignedDate': assignedDate?.toIso8601String(),
      'pickupDate': pickupDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notes': notes,
      'deliveryNotes': deliveryNotes,
      'latitude': latitude,
      'longitude': longitude,
      'contactPhone': contactPhone,
      'contactPerson': contactPerson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Delivery copyWith({
    String? id,
    String? requestId,
    String? hospitalName,
    String? hospitalAddress,
    String? bloodType,
    int? quantity,
    DeliveryStatus? status,
    DeliveryPriority? priority,
    String? deliveryPersonId,
    String? deliveryPersonName,
    DateTime? requestDate,
    DateTime? assignedDate,
    DateTime? pickupDate,
    DateTime? deliveredDate,
    String? notes,
    String? deliveryNotes,
    double? latitude,
    double? longitude,
    String? contactPhone,
    String? contactPerson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      bloodType: bloodType ?? this.bloodType,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      deliveryPersonName: deliveryPersonName ?? this.deliveryPersonName,
      requestDate: requestDate ?? this.requestDate,
      assignedDate: assignedDate ?? this.assignedDate,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      notes: notes ?? this.notes,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactPhone: contactPhone ?? this.contactPhone,
      contactPerson: contactPerson ?? this.contactPerson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isInProgress => status == DeliveryStatus.inProgress;
  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isPending => status == DeliveryStatus.pending;
  bool get isUrgent => priority == DeliveryPriority.urgent;
  bool get isEmergency => priority == DeliveryPriority.emergency;

  String get statusLabel {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.assigned:
        return 'Assignée';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case DeliveryPriority.normal:
        return 'Normal';
      case DeliveryPriority.urgent:
        return 'Urgent';
      case DeliveryPriority.emergency:
        return 'Urgence';
    }
  }

  Duration? get deliveryDuration {
    if (pickupDate != null && deliveredDate != null) {
      return deliveredDate!.difference(pickupDate!);
    }
    return null;
  }

  String get estimatedDeliveryTime {
    if (pickupDate != null && status == DeliveryStatus.inProgress) {
      final elapsed = DateTime.now().difference(pickupDate!);
      final estimatedTotal = Duration(minutes: 30); // Base estimation
      final remaining = estimatedTotal - elapsed;
      
      if (remaining.isNegative) {
        return 'En retard';
      } else {
        return '${remaining.inMinutes} min restantes';
      }
    }
    return 'Non estimé';
  }

  @override
  String toString() {
    return 'Delivery(id: $id, hospitalName: $hospitalName, bloodType: $bloodType, quantity: $quantity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Delivery && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum DeliveryStatus {
  pending,
  assigned,
  inProgress,
  delivered,
  cancelled,
}

enum DeliveryPriority {
  normal,
  urgent,
  emergency,
}

class DeliveryStats {
  final int totalDeliveries;
  final int inProgressDeliveries;
  final int completedDeliveries;
  final int pendingDeliveries;
  final int cancelledDeliveries;
  final double averageDeliveryTime;
  final Map<String, int> deliveriesByStatus;
  final Map<String, int> deliveriesByPriority;
  final DateTime lastUpdated;

  DeliveryStats({
    required this.totalDeliveries,
    required this.inProgressDeliveries,
    required this.completedDeliveries,
    required this.pendingDeliveries,
    required this.cancelledDeliveries,
    required this.averageDeliveryTime,
    required this.deliveriesByStatus,
    required this.deliveriesByPriority,
    required this.lastUpdated,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      totalDeliveries: json['totalDeliveries'] ?? 0,
      inProgressDeliveries: json['inProgressDeliveries'] ?? 0,
      completedDeliveries: json['completedDeliveries'] ?? 0,
      pendingDeliveries: json['pendingDeliveries'] ?? 0,
      cancelledDeliveries: json['cancelledDeliveries'] ?? 0,
      averageDeliveryTime: (json['averageDeliveryTime'] ?? 0.0).toDouble(),
      deliveriesByStatus: Map<String, int>.from(json['deliveriesByStatus'] ?? {}),
      deliveriesByPriority: Map<String, int>.from(json['deliveriesByPriority'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeliveries': totalDeliveries,
      'inProgressDeliveries': inProgressDeliveries,
      'completedDeliveries': completedDeliveries,
      'pendingDeliveries': pendingDeliveries,
      'cancelledDeliveries': cancelledDeliveries,
      'averageDeliveryTime': averageDeliveryTime,
      'deliveriesByStatus': deliveriesByStatus,
      'deliveriesByPriority': deliveriesByPriority,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class DeliveryActivity {
  final String id;
  final String deliveryId;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DeliveryActivity({
    required this.id,
    required this.deliveryId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory DeliveryActivity.fromJson(Map<String, dynamic> json) {
    return DeliveryActivity(
      id: json['id'] ?? '',
      deliveryId: json['deliveryId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveryId': deliveryId,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
