import 'dart:convert';

enum BloodRequestStatus {
  pendingDelivery,
  inProgressDelivery,
  delivered,
}

extension BloodRequestStatusExtension on BloodRequestStatus {
  String get value {
    switch (this) {
      case BloodRequestStatus.pendingDelivery:
        return 'pending-delivery';
      case BloodRequestStatus.inProgressDelivery:
        return 'inprogress-delivery';
      case BloodRequestStatus.delivered:
        return 'delivered';
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
    }
  }

  static BloodRequestStatus fromString(String status) {
    print("🔍 Parsing status: '$status'");

    switch (status.toLowerCase().trim()) {
      case 'pending-delivery':
      case 'pending':
      case 'en attente':
      case 'en attente de livraison':
      case 'waiting':
        print("✅ Mapped to: pendingDelivery");
        return BloodRequestStatus.pendingDelivery;
      case 'inprogress-delivery':
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
      case 'completed':
      case 'livré':
      case 'livrée':
      case 'success':
      case 'successed':
        print("✅ Mapped to: delivered");
        return BloodRequestStatus.delivered;
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
    this.actionData,
  });

  static BloodRequestStatus _determineStatus(Map<String, dynamic> json) {
    print("🔍 Determining status from JSON:");
    print("  - Delivery Status: ${json['delivery_status']}");
    print("  - Delivery Status Label: ${json['delivery_status_lbl']}");
    print("  - Blood Request Status: ${json['blood_request_status']}");

    // Priority logic for status determination:
    // 1. If delivery_status exists and is not 'none', use it
    // 2. Otherwise, use blood_request_status
    // 3. Fall back to generic status field

    String? deliveryStatus = json['delivery_status']?.toString().toLowerCase().trim();
    String? bloodRequestStatus = json['blood_request_status']?.toString().toLowerCase().trim();
    String? genericStatus = json['status']?.toString().toLowerCase().trim();

    print("  - Processed delivery_status: '$deliveryStatus'");
    print("  - Processed blood_request_status: '$bloodRequestStatus'");

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

    // Fall back to generic status
    if (genericStatus != null && genericStatus.isNotEmpty) {
      print("  - Using generic status: '$genericStatus'");
      return BloodRequestStatusExtension.fromString(genericStatus);
    }

    print("  - No valid status found, defaulting to pendingDelivery");
    return BloodRequestStatus.pendingDelivery;
  }

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    // Debug print to check blood request data
    print("🩸 Blood Request Debug:");
    print("  - ID: ${json['_id']}");
    print("  - Identifier: ${json['identifier']}");
    print("  - Delivery Status: ${json['delivery_status']}");
    print("  - Delivery Status Label: ${json['delivery_status_lbl']}");
    print("  - Blood Request Status: ${json['blood_request_status']}");
    print("  - Total Amount: ${json['total_amount']}");

    // Extract blood type from requested_items if available
    String extractedBloodType = '';
    int totalQuantity = 0;
    List<BloodBagRequestModel> bloodBags = [];

    if (json['requested_items'] != null && json['requested_items'] is List) {
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
            extractedBloodType = '$typeName$rhesusName';
          }

          // Create blood bag model
          bloodBags.add(BloodBagRequestModel.fromRequestedItem(item));
        }
      }
    }

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

    return BloodRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      requestId: json['identifier'] ?? json['request_id'] ?? json['requestId'] ?? '',
      hospitalId: json['hospital_id'] ?? json['hospitalId'] ?? '',
      hospitalName: json['hospital_name'] ?? json['hospitalName'] ?? 'Hôpital',
      bloodType: extractedBloodType.isNotEmpty ? extractedBloodType : (json['blood_type'] ?? json['bloodType'] ?? ''),
      quantity: totalQuantity > 0 ? totalQuantity : (json['quantity'] ?? 0),
      status: _determineStatus(json),
      requestDate: DateTime.tryParse(json['createdAt'] ?? json['request_date'] ?? json['requestDate'] ?? '') ?? DateTime.now(),
      deliveryDate: json['delivery_date'] != null || json['deliveryDate'] != null
          ? DateTime.tryParse(json['delivery_date'] ?? json['deliveryDate'])
          : null,
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'],
      notes: json['notes'],
      totalAmount: json['total_amount']?.toDouble() ?? json['totalAmount']?.toDouble(),
      paymentStatus: json['payment_status'] ?? json['paymentStatus'],
      bloodBags: bloodBags,
      actionData: extractedActionData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'hospital_id': hospitalId,
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

  BloodBagRequestModel({
    required this.id,
    required this.bloodBagId,
    required this.bloodType,
    required this.bankName,
    this.price,
    this.expiryDate,
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
