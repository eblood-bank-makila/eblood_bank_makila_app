import 'dart:convert';

class QrCodeActionModel {
  final String requestedAction;
  final String actionData;

  QrCodeActionModel({
    required this.requestedAction,
    required this.actionData,
  });

  Map<String, dynamic> toJson() {
    return {
      'requested_action': requestedAction,
      'action_data': actionData,
    };
  }

  factory QrCodeActionModel.fromJson(Map<String, dynamic> json) {
    return QrCodeActionModel(
      requestedAction: json['requested_action'] ?? '',
      actionData: json['action_data'] ?? '',
    );
  }

  String toJsonString() => json.encode(toJson());

  @override
  String toString() {
    return 'QrCodeActionModel(requestedAction: $requestedAction, actionData: $actionData)';
  }
}

class QrCodeActionResponseModel {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  QrCodeActionResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory QrCodeActionResponseModel.fromJson(Map<String, dynamic> json) {
    return QrCodeActionResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'QrCodeActionResponseModel(success: $success, message: $message, data: $data)';
  }
}

// Keep the old names for backward compatibility
typedef DeliveryValidationModel = QrCodeActionModel;
typedef DeliveryValidationResponseModel = QrCodeActionResponseModel;
