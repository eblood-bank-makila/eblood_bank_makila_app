import 'dart:convert';

enum BloodRequestStatus {
  pendingDelivery,
  inProgressDelivery,
  delivered,
  completed,
}

extension BloodRequestStatusExtension on BloodRequestStatus {
  String get value {
    switch (this) {
      case BloodRequestStatus.pendingDelivery:
        return 'pending_delivery';
      case BloodRequestStatus.inProgressDelivery:
        return 'in_progress_delivery';
      case BloodRequestStatus.delivered:
        return 'delivered';
      case BloodRequestStatus.completed:
        return 'completed';
    }
  }

  String get displayName {
    switch (this) {
      case BloodRequestStatus.pendingDelivery:
        return 'En attente de livraison';
      case BloodRequestStatus.inProgressDelivery:
        return 'Livraison en cours';
      case BloodRequestStatus.delivered:
        return 'Livré';
      case BloodRequestStatus.completed:
        return 'Utilisé';
    }
  }

  static BloodRequestStatus fromString(String status) {
    print("🔍 Parsing status: '$status'");

    switch (status.toLowerCase().trim()) {
      case 'pending_delivery':
      case 'pending':
      case 'en attente':
      case 'en attente de livraison':
      case 'waiting':
        print("✅ Mapped to: pendingDelivery");
        return BloodRequestStatus.pendingDelivery;
      case 'in_progress_delivery':
      case 'in-progress':
      case 'in_progress':  // Added missing underscore version
      case 'inprogress':
      case 'en cours':
      case 'en cours de livraison':  // Added full French label
      case 'livraison en cours':
      case 'processing':
        print("✅ Mapped to: inProgressDelivery");
        return BloodRequestStatus.inProgressDelivery;
      case 'delivered':
      case 'livré':
      case 'livrée':
      case 'success':
      case 'successed':
        print("✅ Mapped to: delivered");
        return BloodRequestStatus.delivered;
      case 'completed':
      case 'used':
      case 'utilisé':
      case 'utilisée':
        print("✅ Mapped to: completed");
        return BloodRequestStatus.completed;
      default:
        print("⚠️ Unknown status '$status', defaulting to: pendingDelivery");
        return BloodRequestStatus.pendingDelivery;
    }
  }
}

class BloodRequestModel {
  final String id;
  final String requestId;
  final String hospitalId;
  final String hospitalName;
  final String bloodType;
  final int quantity;
  final BloodRequestStatus status;
  final DateTime requestDate;
  final DateTime? deliveryDate;
  final String? deliveryAddress;
  final String? notes;
  final double? totalAmount;
  final String? paymentStatus;
  final List<BloodBagRequestModel> bloodBags;
  final String? deliveryCoolboxId;
  final String? actionData;

  BloodRequestModel({
    required this.id,
    required this.requestId,
    required this.hospitalId,
    required this.hospitalName,
    required this.bloodType,
    required this.quantity,
    required this.status,
    required this.requestDate,
    this.deliveryDate,
    this.deliveryAddress,
    this.notes,
    this.totalAmount,
    this.paymentStatus,
    this.bloodBags = const [],
    this.deliveryCoolboxId,
    this.actionData,
  });

  static BloodRequestStatus _determineStatus(Map<String, dynamic> json) {
    print("🔍 Determining status from JSON:");
    print("  - Status: ${json['status']}");
    print("  - Delivery Status: ${json['delivery_status']}");
    print("  - Blood Request Status: ${json['blood_request_status']}");

    // Priority logic for status determination:
    // 1. Check delivery_status first (if exists and meaningful)
    // 2. Check blood_request_status
    // 3. Check generic status field
    // 4. Map backend status values to our internal status enum

    String? deliveryStatus = json['delivery_status']?.toString().toLowerCase().trim();
    String? bloodRequestStatus = json['blood_request_status']?.toString().toLowerCase().trim();
    String? genericStatus = json['status']?.toString().toLowerCase().trim();

    print("  - Processed delivery_status: '$deliveryStatus'");
    print("  - Processed blood_request_status: '$bloodRequestStatus'");
    print("  - Processed status: '$genericStatus'");

    // Use delivery_status if it's meaningful (not null, empty, or 'none')
    if (deliveryStatus != null && deliveryStatus.isNotEmpty && deliveryStatus != 'none') {
      print("  - Using delivery_status: '$deliveryStatus'");
      return BloodRequestStatusExtension.fromString(deliveryStatus);
    }

    // Use blood_request_status if delivery_status is not available
    if (bloodRequestStatus != null && bloodRequestStatus.isNotEmpty) {
      print("  - Using blood_request_status: '$bloodRequestStatus'");
      return BloodRequestStatusExtension.fromString(bloodRequestStatus);
    }

    // Map backend status to delivery status
    // Backend statuses: pending, approved, processing, completed, cancelled, rejected
    if (genericStatus != null && genericStatus.isNotEmpty) {
      print("  - Using generic status: '$genericStatus'");

      // Map backend status to our delivery status
      switch (genericStatus) {
        case 'pending':
        case 'requested':
        case 'approved':
          return BloodRequestStatus.pendingDelivery;
        case 'processing':
        case 'in_progress':
        case 'preparing':
          return BloodRequestStatus.inProgressDelivery;
        case 'delivered':
        case 'shipped':
          return BloodRequestStatus.delivered;
        case 'completed':
        case 'used':
        case 'transfused':
          return BloodRequestStatus.completed;
        default:
          return BloodRequestStatusExtension.fromString(genericStatus);
      }
    }

    print("  - No valid status found, defaulting to pendingDelivery");
    return BloodRequestStatus.pendingDelivery;
  }

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    // Debug print to check blood request data
    print("🩸 Blood Request Debug:");
    print("  - ID: ${json['id'] ?? json['_id']}");
    print("  - Status: ${json['status']}");
    print("  - Urgency Level: ${json['urgency_level']}");

    // Extract blood type and quantity from ops_blood_bags_requested (new hospital endpoint format)
    String extractedBloodType = '';
    int totalQuantity = 0;
    List<BloodBagRequestModel> bloodBags = [];

    if (json['ops_blood_bags_requested'] != null && json['ops_blood_bags_requested'] is List) {
      final bagRequests = json['ops_blood_bags_requested'] as List;
      print("  - Found ${bagRequests.length} blood bag requests");

      for (var bagRequest in bagRequests) {
        totalQuantity += 1; // Each bag request is 1 unit

        // Extract blood type from stock_blood_bag
        Map<String, dynamic> stockBag = {};
        if (bagRequest['stock_blood_bag'] != null) {
          stockBag = Map<String, dynamic>.from(bagRequest['stock_blood_bag']);
          final rhesusFactor = stockBag['rhesus_factor']?.toString() ?? '';
          if (extractedBloodType.isEmpty && rhesusFactor.isNotEmpty) {
            extractedBloodType = rhesusFactor;
            print("  - Extracted blood type from stock_blood_bag: $extractedBloodType");
          }
        }

        // Build blood bag model entry
        final bagId = bagRequest['id']?.toString() ?? bagRequest['_id']?.toString() ?? '';
        final bloodBagId = stockBag['id']?.toString() ?? stockBag['_id']?.toString() ?? bagRequest['blood_bag_id']?.toString() ?? '';
        final isUsed = bagRequest['is_used'] == true;
        final price = (bagRequest['price'] is num) ? (bagRequest['price'] as num).toDouble() : null;
        final expiry = stockBag['expiry_date']?.toString();

        bloodBags.add(BloodBagRequestModel(
          id: bagId,
          bloodBagId: bloodBagId,
          bloodType: extractedBloodType.isNotEmpty ? extractedBloodType : (stockBag['rhesus_factor']?.toString() ?? ''),
          bankName: 'Banque de sang',
          price: price,
          expiryDate: expiry != null ? DateTime.tryParse(expiry) : null,
          isUsed: isUsed,
        ));
      }
    }

    // Fallback: Extract from patient info (old format)
    if (extractedBloodType.isEmpty && json['patient_blood_group'] != null && json['patient_rh_factor'] != null) {
      extractedBloodType = '${json['patient_blood_group']}${json['patient_rh_factor']}';
      print("  - Extracted blood type from patient: $extractedBloodType");
    }

    // Fallback: Extract quantity from requested_components (old format)
    if (totalQuantity == 0 && json['requested_components'] != null && json['requested_components'] is List) {
      final components = json['requested_components'] as List;
      for (var component in components) {
        totalQuantity += (component['quantity'] as int? ?? 0);
        print("  - Component: ${component['component_type']}, Quantity: ${component['quantity']}");
      }
    }

    // Fallback: Extract from requested_items (oldest format)
    if (totalQuantity == 0 && json['requested_items'] != null && json['requested_items'] is List) {
      final requestedItems = json['requested_items'] as List;
      for (var item in requestedItems) {
        totalQuantity += (item['quantity'] as int? ?? 0);

        // Extract blood type info
        if (item['blood_bag_info'] != null) {
          final bloodBagInfo = item['blood_bag_info'];
          final bloodTypeInfo = bloodBagInfo['blood_type_info'];
          final bloodRhesusInfo = bloodBagInfo['blood_rhesus_info'];

          if (bloodTypeInfo != null && bloodRhesusInfo != null) {
            final typeName = bloodTypeInfo['blood_type_name'] ?? '';
            final rhesusName = bloodRhesusInfo['blood_rheusus_name'] ?? '';
            if (extractedBloodType.isEmpty) {
              extractedBloodType = '$typeName$rhesusName';
            }
          }

          // Create blood bag model
          bloodBags.add(BloodBagRequestModel.fromRequestedItem(item));
        }
      }
    }

    print("  - Total quantity: $totalQuantity");
    print("  - Blood type: $extractedBloodType");

    // Extract action_data from delivery_items if available
    String? extractedActionData = json['action_data'];
    if (extractedActionData == null || extractedActionData.isEmpty) {
      // Try to get action_data from delivery_items array
      if (json['delivery_items'] != null && json['delivery_items'] is List) {
        final deliveryItems = json['delivery_items'] as List;
        print("📦 Found ${deliveryItems.length} delivery items");

        // Look for the first delivery item with valid action_data
        for (var deliveryItem in deliveryItems) {
          if (deliveryItem != null && deliveryItem['action_data'] != null && deliveryItem['action_data'].toString().isNotEmpty) {
            extractedActionData = deliveryItem['action_data'].toString();
            print("📍 Extracted action_data from delivery_items: $extractedActionData");
            break;
          }
        }
      }
    }

    print("📍 Final action_data: $extractedActionData");

    // Extract hospital name from health_structure_requesting (new hospital endpoint format)
    String hospitalName = 'Hôpital';
    String hospitalId = '';

    if (json['health_structure_requesting'] != null) {
      final structureInfo = json['health_structure_requesting'];
      hospitalName = structureInfo['name'] ?? hospitalName;
      hospitalId = structureInfo['id']?.toString() ?? '';
      print("  - Extracted hospital from health_structure_requesting: $hospitalName (ID: $hospitalId)");
    } else if (json['health_structure_requesting_info'] != null) {
      // Fallback: old format
      final structureInfo = json['health_structure_requesting_info'];
      hospitalName = structureInfo['name'] ?? structureInfo['structure_name'] ?? hospitalName;
      print("  - Extracted hospital name: $hospitalName");
    } else if (json['hospital_name'] != null) {
      hospitalName = json['hospital_name'];
    } else if (json['hospitalName'] != null) {
      hospitalName = json['hospitalName'];
    }

    // Extract hospital ID if not already set
    if (hospitalId.isEmpty) {
      if (json['health_structure_requesting_id'] != null) {
        hospitalId = json['health_structure_requesting_id'].toString();
      } else if (json['hospital_id'] != null) {
        hospitalId = json['hospital_id'].toString();
      } else if (json['hospitalId'] != null) {
        hospitalId = json['hospitalId'].toString();
      }

    }

    // Parse dates
    DateTime requestDate = DateTime.now();

    // Extract delivery coolbox id if present (unconditional)
    String? deliveryCoolboxId =
        json['delivery_coolbox_id']?.toString() ?? json['coolbox_id']?.toString();

    if (json['created_at'] != null) {
      requestDate = DateTime.tryParse(json['created_at']) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      requestDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else if (json['request_date'] != null) {
      requestDate = DateTime.tryParse(json['request_date']) ?? DateTime.now();
    }

    // Extract request identifier
    String requestId = '';
    if (json['payment_metadata'] != null && json['payment_metadata']['cart_identifier'] != null) {
      requestId = json['payment_metadata']['cart_identifier'];
    } else {
      requestId = json['identifier'] ?? json['request_id'] ?? json['requestId'] ?? '';
    }

    return BloodRequestModel(
      id: json['id'] ?? json['_id'] ?? '',
      requestId: requestId,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      bloodType: extractedBloodType.isNotEmpty ? extractedBloodType : (json['blood_type'] ?? json['bloodType'] ?? ''),
      quantity: totalQuantity > 0 ? totalQuantity : (json['quantity'] ?? 0),
      status: _determineStatus(json),
      requestDate: requestDate,
      deliveryDate: json['delivery_date'] != null || json['deliveryDate'] != null
          ? DateTime.tryParse(json['delivery_date'] ?? json['deliveryDate'])
          : null,
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'],
      notes: json['notes'] ?? json['clinical_indication'],
      totalAmount: json['total_amount']?.toDouble() ?? json['totalAmount']?.toDouble() ?? json['transactional_total_amount']?.toDouble(),
      paymentStatus: json['payment_status'] ?? json['paymentStatus'],
      bloodBags: bloodBags,
      deliveryCoolboxId: deliveryCoolboxId,
      actionData: extractedActionData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,

      'hospital_name': hospitalName,
      'blood_type': bloodType,
      'quantity': quantity,
      'status': status.value,
      'request_date': requestDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'delivery_address': deliveryAddress,
      'notes': notes,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'blood_bags': bloodBags.map((bag) => bag.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'BloodRequestModel(id: $id, requestId: $requestId, status: ${status.displayName}, quantity: $quantity)';
  }
}

class BloodBagRequestModel {
  final String id;
  final String bloodBagId;
  final String bloodType;
  final String bankName;
  final double? price;
  final DateTime? expiryDate;
  bool isUsed;

  BloodBagRequestModel({
    required this.id,
    required this.bloodBagId,
    required this.bloodType,
    required this.bankName,
    this.price,
    this.expiryDate,
    this.isUsed = false,
  });

  factory BloodBagRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodBagRequestModel(
      id: json['id'] ?? '',
      bloodBagId: json['blood_bag_id'] ?? json['bloodBagId'] ?? '',
      bloodType: json['blood_type'] ?? json['bloodType'] ?? '',
      bankName: json['bank_name'] ?? json['bankName'] ?? '',
      price: json['price']?.toDouble(),
      expiryDate: json['expiry_date'] != null || json['expiryDate'] != null
          ? DateTime.tryParse(json['expiry_date'] ?? json['expiryDate'])
          : null,
      isUsed: json['is_used'] == true,
    );
  }

  factory BloodBagRequestModel.fromRequestedItem(Map<String, dynamic> item) {
    final bloodBagInfo = item['blood_bag_info'] ?? {};
    final bloodTypeInfo = bloodBagInfo['blood_type_info'] ?? {};
    final bloodRhesusInfo = bloodBagInfo['blood_rhesus_info'] ?? {};

    // Extract blood type
    final typeName = bloodTypeInfo['blood_type_name'] ?? '';
    final rhesusName = bloodRhesusInfo['blood_rheusus_name'] ?? '';
    final bloodType = '$typeName$rhesusName';

    return BloodBagRequestModel(
      id: item['_id'] ?? '',
      bloodBagId: bloodBagInfo['_id'] ?? '',
      bloodType: bloodType,
      bankName: 'Banque de sang', // Default since not provided in this structure
      price: item['price']?.toDouble(),
      expiryDate: null, // Not provided in this structure
      isUsed: item['is_used'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blood_bag_id': bloodBagId,
      'blood_type': bloodType,
      'bank_name': bankName,
      'price': price,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_used': isUsed,
    };
  }
}

class BloodRequestResponseModel {
  final bool success;
  final String message;
  final List<BloodRequestModel> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  BloodRequestResponseModel({
    required this.success,
    required this.message,
    required this.data,
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalItems = 0,
  });

  factory BloodRequestResponseModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => BloodRequestModel.fromJson(item))
              .toList() ??
          [],
      currentPage: json['current_page'] ?? json['currentPage'] ?? 0,
      totalPages: json['total_pages'] ?? json['totalPages'] ?? 0,
      totalItems: json['total_items'] ?? json['totalItems'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
      'current_page': currentPage,
      'total_pages': totalPages,
      'total_items': totalItems,
    };
  }

  @override
  String toString() {
    return 'BloodRequestResponseModel(success: $success, items: ${data.length}, page: $currentPage/$totalPages)';
  }
}
