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

// ============================================================================
// PENDING DELIVERY REQUEST MODEL (Yango-style)
// ============================================================================

/// Represents a pending delivery request that delivery persons can accept
class PendingDeliveryRequest {
  final String id;
  final String bloodBankId;
  final String bloodBankName;
  final String bloodBankAddress;
  final double? bloodBankLat;
  final double? bloodBankLng;
  final String hospitalId;
  final String hospitalName;
  final String hospitalAddress;
  final double? hospitalLat;
  final double? hospitalLng;
  final String priority;
  final DateTime broadcastedAt;
  final DateTime timeoutAt;
  final double? distanceKm;
  final int? estimatedMinutes;
  final List<BloodBagInfo> bloodBags;

  PendingDeliveryRequest({
    required this.id,
    required this.bloodBankId,
    required this.bloodBankName,
    required this.bloodBankAddress,
    this.bloodBankLat,
    this.bloodBankLng,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalAddress,
    this.hospitalLat,
    this.hospitalLng,
    required this.priority,
    required this.broadcastedAt,
    required this.timeoutAt,
    this.distanceKm,
    this.estimatedMinutes,
    this.bloodBags = const [],
  });

  factory PendingDeliveryRequest.fromJson(Map<String, dynamic> json) {
    return PendingDeliveryRequest(
      id: json['_id'] ?? json['id'] ?? '',
      bloodBankId: json['blood_bank']?['id'] ?? json['source_blood_bank_id'] ?? '',
      bloodBankName: json['blood_bank']?['name'] ?? '',
      bloodBankAddress: json['blood_bank']?['address'] ?? '',
      bloodBankLat: json['blood_bank']?['location']?['lat']?.toDouble(),
      bloodBankLng: json['blood_bank']?['location']?['lng']?.toDouble(),
      hospitalId: json['hospital']?['id'] ?? json['destination_hospital_id'] ?? '',
      hospitalName: json['hospital']?['name'] ?? '',
      hospitalAddress: json['hospital']?['address'] ?? '',
      hospitalLat: json['hospital']?['location']?['lat']?.toDouble(),
      hospitalLng: json['hospital']?['location']?['lng']?.toDouble(),
      priority: json['priority'] ?? 'normal',
      broadcastedAt: json['assignment_broadcasted_at'] != null
          ? DateTime.parse(json['assignment_broadcasted_at'])
          : DateTime.now(),
      timeoutAt: json['assignment_timeout_at'] != null
          ? DateTime.parse(json['assignment_timeout_at'])
          : DateTime.now().add(const Duration(minutes: 5)),
      distanceKm: json['distance_km']?.toDouble(),
      estimatedMinutes: json['estimated_minutes'],
      bloodBags: (json['blood_bags'] as List<dynamic>?)
              ?.map((e) => BloodBagInfo.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool get isExpired => DateTime.now().isAfter(timeoutAt);
  bool get isEmergency => priority == 'emergency';

  Duration get remainingTime {
    final remaining = timeoutAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get remainingTimeFormatted {
    final remaining = remainingTime;
    if (remaining == Duration.zero) return 'Expiré';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Blood bag information for delivery
class BloodBagInfo {
  final String id;
  final String bloodType;
  final String rhesus;
  final int quantity;
  final String? component;
  final int? volume;

  BloodBagInfo({
    required this.id,
    required this.bloodType,
    required this.rhesus,
    required this.quantity,
    this.component,
    this.volume,
  });

  factory BloodBagInfo.fromJson(Map<String, dynamic> json) {
    return BloodBagInfo(
      id: json['id'] ?? '',
      bloodType: json['blood_type'] ?? json['bloodType'] ?? '',
      rhesus: json['rhesus'] ?? '',
      quantity: json['quantity'] ?? 1,
      component: json['component'],
      volume: json['volume'],
    );
  }

  String get fullBloodType => '$bloodType$rhesus';
}

// ============================================================================
// ACTIVE DELIVERY MODEL (For tracking ongoing delivery)
// ============================================================================

/// Represents an active delivery being tracked
class ActiveDelivery {
  final String id;
  final String deliveryPhase;
  final String assignmentStatus;
  final BloodBankDetails bloodBank;
  final HospitalDetails hospital;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAt;
  final double? estimatedArrivalMinutes;
  final LocationInfo? currentLocation;

  ActiveDelivery({
    required this.id,
    required this.deliveryPhase,
    required this.assignmentStatus,
    required this.bloodBank,
    required this.hospital,
    this.acceptedAt,
    this.pickedUpAt,
    this.arrivedAt,
    this.estimatedArrivalMinutes,
    this.currentLocation,
  });

  factory ActiveDelivery.fromJson(Map<String, dynamic> json) {
    return ActiveDelivery(
      id: json['_id'] ?? json['id'] ?? '',
      deliveryPhase: json['delivery_phase'] ?? 'awaiting_assignment',
      assignmentStatus: json['assignment_status'] ?? 'pending',
      bloodBank: BloodBankDetails.fromJson(json['blood_bank'] ?? {}),
      hospital: HospitalDetails.fromJson(json['hospital'] ?? {}),
      acceptedAt: json['assignment_accepted_at'] != null
          ? DateTime.parse(json['assignment_accepted_at'])
          : null,
      pickedUpAt: json['picked_up_from_blood_bank_at'] != null
          ? DateTime.parse(json['picked_up_from_blood_bank_at'])
          : null,
      arrivedAt: json['arrived_at_hospital_at'] != null
          ? DateTime.parse(json['arrived_at_hospital_at'])
          : null,
      estimatedArrivalMinutes: json['estimated_arrival_minutes']?.toDouble(),
      currentLocation: json['delivery_person_current_location'] != null
          ? LocationInfo.fromJson(json['delivery_person_current_location'])
          : null,
    );
  }

  bool get isEnRouteToBloodBank => deliveryPhase == 'en_route_to_blood_bank';
  bool get isAtBloodBank => deliveryPhase == 'at_blood_bank';
  bool get isPickedUp => deliveryPhase == 'picked_up_from_blood_bank';
  bool get isEnRouteToHospital => deliveryPhase == 'en_route_to_hospital';
  bool get isAtHospital => deliveryPhase == 'at_hospital';
  bool get isDelivered => deliveryPhase == 'delivered_and_confirmed';
}

class BloodBankDetails {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final LocationInfo? location;

  BloodBankDetails({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.location,
  });

  factory BloodBankDetails.fromJson(Map<String, dynamic> json) {
    return BloodBankDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'],
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'])
          : null,
    );
  }
}

class HospitalDetails {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final LocationInfo? location;

  HospitalDetails({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.location,
  });

  factory HospitalDetails.fromJson(Map<String, dynamic> json) {
    return HospitalDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'],
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'])
          : null,
    );
  }
}

class LocationInfo {
  final double lat;
  final double lng;
  final DateTime? timestamp;
  final double? accuracy;

  LocationInfo({
    required this.lat,
    required this.lng,
    this.timestamp,
    this.accuracy,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      accuracy: json['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (accuracy != null) 'accuracy': accuracy,
    };
  }
}

/// Model for incoming delivery (hospital view)
class IncomingDelivery {
  final String id;
  final String bloodRequestId;
  final String bloodBankId;
  final String bloodBankName;
  final String bloodBankAddress;
  final String status;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final List<BloodBagInfo> bloodBags;
  final String? estimatedArrival;
  final LocationInfo? currentLocation;
  final DateTime createdAt;

  IncomingDelivery({
    required this.id,
    required this.bloodRequestId,
    required this.bloodBankId,
    required this.bloodBankName,
    required this.bloodBankAddress,
    required this.status,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    required this.bloodBags,
    this.estimatedArrival,
    this.currentLocation,
    required this.createdAt,
  });

  factory IncomingDelivery.fromJson(Map<String, dynamic> json) {
    return IncomingDelivery(
      id: json['id'] ?? json['_id'] ?? '',
      bloodRequestId: json['blood_request_id'] ?? '',
      bloodBankId: json['blood_bank_id'] ?? '',
      bloodBankName: json['blood_bank_name'] ?? '',
      bloodBankAddress: json['blood_bank_address'] ?? '',
      status: json['status'] ?? json['delivery_phase'] ?? '',
      deliveryPersonId: json['delivery_person_id'],
      deliveryPersonName: json['delivery_person_name'],
      deliveryPersonPhone: json['delivery_person_phone'],
      bloodBags: (json['blood_bags'] as List<dynamic>?)
              ?.map((e) => BloodBagInfo.fromJson(e))
              .toList() ??
          [],
      estimatedArrival: json['estimated_arrival'],
      currentLocation: json['current_location'] != null
          ? LocationInfo.fromJson(json['current_location'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isAtHospital => status == 'at_hospital';
  bool get isEnRoute => status == 'en_route_to_hospital';
  bool get isPickedUp => status == 'picked_up_from_blood_bank';
}
