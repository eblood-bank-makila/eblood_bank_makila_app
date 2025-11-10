// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BloodRequestModelImpl _$$BloodRequestModelImplFromJson(
        Map<String, dynamic> json) =>
    _$BloodRequestModelImpl(
      id: json['_id'] as String,
      identifier: json['identifier'] as String,
      healthStructureRequestingId:
          json['health_structure_requesting_id'] as String?,
      sysOrganizationId: json['sys_organization_id'] as String?,
      requestType: json['request_type'] as String,
      urgencyLevel: json['urgency_level'] as String,
      patientBloodGroup: json['patient_blood_group'] as String,
      patientRhFactor: json['patient_rh_factor'] as String,
      requestedComponents: (json['requested_components'] as List<dynamic>?)
              ?.map((e) =>
                  BloodRequestComponent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      requestedDeliveryTime: json['requested_delivery_time'] as String?,
      clinicalIndication: json['clinical_indication'] as String?,
      requestedBy: json['requested_by'] as String?,
      deliveryContact: json['delivery_contact'] == null
          ? null
          : DeliveryContact.fromJson(
              json['delivery_contact'] as Map<String, dynamic>),
      status: json['status'] as String,
      statusHistory: (json['status_history'] as List<dynamic>?)
          ?.map((e) => StatusHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      softDeleted: json['soft_deleted'] as bool? ?? false,
      onafriqTransactionRef: json['onafriq_transaction_ref'] as String?,
      failureReason: json['failure_reason'] as String?,
      phoneNumber: json['phone_number'] as String?,
      ebloodFee: (json['eblood_fee'] as num?)?.toDouble(),
      refCurrencyId: json['ref_currency_id'] as String?,
      transactionalEbloodFee:
          (json['transactional_eblood_fee'] as num?)?.toDouble(),
      transactionalCurrencyId: json['transactional_currency_id'] as String?,
    );

Map<String, dynamic> _$$BloodRequestModelImplToJson(
        _$BloodRequestModelImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'identifier': instance.identifier,
      'health_structure_requesting_id': instance.healthStructureRequestingId,
      'sys_organization_id': instance.sysOrganizationId,
      'request_type': instance.requestType,
      'urgency_level': instance.urgencyLevel,
      'patient_blood_group': instance.patientBloodGroup,
      'patient_rh_factor': instance.patientRhFactor,
      'requested_components': instance.requestedComponents,
      'requested_delivery_time': instance.requestedDeliveryTime,
      'clinical_indication': instance.clinicalIndication,
      'requested_by': instance.requestedBy,
      'delivery_contact': instance.deliveryContact,
      'status': instance.status,
      'status_history': instance.statusHistory,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'soft_deleted': instance.softDeleted,
      'onafriq_transaction_ref': instance.onafriqTransactionRef,
      'failure_reason': instance.failureReason,
      'phone_number': instance.phoneNumber,
      'eblood_fee': instance.ebloodFee,
      'ref_currency_id': instance.refCurrencyId,
      'transactional_eblood_fee': instance.transactionalEbloodFee,
      'transactional_currency_id': instance.transactionalCurrencyId,
    };

_$BloodRequestComponentImpl _$$BloodRequestComponentImplFromJson(
        Map<String, dynamic> json) =>
    _$BloodRequestComponentImpl(
      bloodProductType: json['blood_product_type'] as String,
      quantity: (json['quantity'] as num).toInt(),
      volume: json['volume'] as String?,
      bloodBagId: json['blood_bag_id'] as String?,
      bloodBankId: json['blood_bank_id'] as String?,
    );

Map<String, dynamic> _$$BloodRequestComponentImplToJson(
        _$BloodRequestComponentImpl instance) =>
    <String, dynamic>{
      'blood_product_type': instance.bloodProductType,
      'quantity': instance.quantity,
      'volume': instance.volume,
      'blood_bag_id': instance.bloodBagId,
      'blood_bank_id': instance.bloodBankId,
    };

_$DeliveryContactImpl _$$DeliveryContactImplFromJson(
        Map<String, dynamic> json) =>
    _$DeliveryContactImpl(
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$$DeliveryContactImplToJson(
        _$DeliveryContactImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
    };

_$StatusHistoryImpl _$$StatusHistoryImplFromJson(Map<String, dynamic> json) =>
    _$StatusHistoryImpl(
      status: json['status'] as String,
      timestamp: json['timestamp'] as String,
      changedBy: json['changed_by'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$StatusHistoryImplToJson(_$StatusHistoryImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'changed_by': instance.changedBy,
      'notes': instance.notes,
    };

_$BloodRequestsResponseImpl _$$BloodRequestsResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$BloodRequestsResponseImpl(
      data: (json['data'] as List<dynamic>)
          .map((e) => BloodRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$$BloodRequestsResponseImplToJson(
        _$BloodRequestsResponseImpl instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
