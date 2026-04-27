// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blood_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BloodRequestModel _$BloodRequestModelFromJson(Map<String, dynamic> json) {
  return _BloodRequestModel.fromJson(json);
}

/// @nodoc
mixin _$BloodRequestModel {
  @JsonKey(name: '_id', readValue: _readId)
  String get id => throw _privateConstructorUsedError;
  String get identifier => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'health_structure_requesting_id',
      readValue: _readHealthStructureRequestingId)
  String? get healthStructureRequestingId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
  String? get sysOrganizationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'request_type')
  String get requestType => throw _privateConstructorUsedError;
  @JsonKey(name: 'urgency_level')
  String get urgencyLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_blood_group')
  String get patientBloodGroup => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_rh_factor')
  String get patientRhFactor => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_components')
  List<BloodRequestComponent> get requestedComponents =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_delivery_time')
  String? get requestedDeliveryTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'clinical_indication')
  String? get clinicalIndication => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_by')
  String? get requestedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_contact')
  DeliveryContact? get deliveryContact => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_history')
  List<StatusHistory>? get statusHistory => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'soft_deleted')
  bool get softDeleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'onafriq_transaction_ref')
  String? get onafriqTransactionRef => throw _privateConstructorUsedError;
  @JsonKey(name: 'failure_reason')
  String? get failureReason => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_number')
  String? get phoneNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'eblood_fee')
  double? get ebloodFee => throw _privateConstructorUsedError;
  @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
  String? get refCurrencyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'transactional_eblood_fee')
  double? get transactionalEbloodFee => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'transactional_currency_id',
      readValue: _readTransactionalCurrencyId)
  String? get transactionalCurrencyId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BloodRequestModelCopyWith<BloodRequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodRequestModelCopyWith<$Res> {
  factory $BloodRequestModelCopyWith(
          BloodRequestModel value, $Res Function(BloodRequestModel) then) =
      _$BloodRequestModelCopyWithImpl<$Res, BloodRequestModel>;
  @useResult
  $Res call(
      {@JsonKey(name: '_id', readValue: _readId) String id,
      String identifier,
      @JsonKey(
          name: 'health_structure_requesting_id',
          readValue: _readHealthStructureRequestingId)
      String? healthStructureRequestingId,
      @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
      String? sysOrganizationId,
      @JsonKey(name: 'request_type') String requestType,
      @JsonKey(name: 'urgency_level') String urgencyLevel,
      @JsonKey(name: 'patient_blood_group') String patientBloodGroup,
      @JsonKey(name: 'patient_rh_factor') String patientRhFactor,
      @JsonKey(name: 'requested_components')
      List<BloodRequestComponent> requestedComponents,
      @JsonKey(name: 'requested_delivery_time') String? requestedDeliveryTime,
      @JsonKey(name: 'clinical_indication') String? clinicalIndication,
      @JsonKey(name: 'requested_by') String? requestedBy,
      @JsonKey(name: 'delivery_contact') DeliveryContact? deliveryContact,
      String status,
      @JsonKey(name: 'status_history') List<StatusHistory>? statusHistory,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'soft_deleted') bool softDeleted,
      @JsonKey(name: 'onafriq_transaction_ref') String? onafriqTransactionRef,
      @JsonKey(name: 'failure_reason') String? failureReason,
      @JsonKey(name: 'phone_number') String? phoneNumber,
      @JsonKey(name: 'eblood_fee') double? ebloodFee,
      @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
      String? refCurrencyId,
      @JsonKey(name: 'transactional_eblood_fee') double? transactionalEbloodFee,
      @JsonKey(
          name: 'transactional_currency_id',
          readValue: _readTransactionalCurrencyId)
      String? transactionalCurrencyId});

  $DeliveryContactCopyWith<$Res>? get deliveryContact;
}

/// @nodoc
class _$BloodRequestModelCopyWithImpl<$Res, $Val extends BloodRequestModel>
    implements $BloodRequestModelCopyWith<$Res> {
  _$BloodRequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? healthStructureRequestingId = freezed,
    Object? sysOrganizationId = freezed,
    Object? requestType = null,
    Object? urgencyLevel = null,
    Object? patientBloodGroup = null,
    Object? patientRhFactor = null,
    Object? requestedComponents = null,
    Object? requestedDeliveryTime = freezed,
    Object? clinicalIndication = freezed,
    Object? requestedBy = freezed,
    Object? deliveryContact = freezed,
    Object? status = null,
    Object? statusHistory = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? softDeleted = null,
    Object? onafriqTransactionRef = freezed,
    Object? failureReason = freezed,
    Object? phoneNumber = freezed,
    Object? ebloodFee = freezed,
    Object? refCurrencyId = freezed,
    Object? transactionalEbloodFee = freezed,
    Object? transactionalCurrencyId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      healthStructureRequestingId: freezed == healthStructureRequestingId
          ? _value.healthStructureRequestingId
          : healthStructureRequestingId // ignore: cast_nullable_to_non_nullable
              as String?,
      sysOrganizationId: freezed == sysOrganizationId
          ? _value.sysOrganizationId
          : sysOrganizationId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestType: null == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String,
      urgencyLevel: null == urgencyLevel
          ? _value.urgencyLevel
          : urgencyLevel // ignore: cast_nullable_to_non_nullable
              as String,
      patientBloodGroup: null == patientBloodGroup
          ? _value.patientBloodGroup
          : patientBloodGroup // ignore: cast_nullable_to_non_nullable
              as String,
      patientRhFactor: null == patientRhFactor
          ? _value.patientRhFactor
          : patientRhFactor // ignore: cast_nullable_to_non_nullable
              as String,
      requestedComponents: null == requestedComponents
          ? _value.requestedComponents
          : requestedComponents // ignore: cast_nullable_to_non_nullable
              as List<BloodRequestComponent>,
      requestedDeliveryTime: freezed == requestedDeliveryTime
          ? _value.requestedDeliveryTime
          : requestedDeliveryTime // ignore: cast_nullable_to_non_nullable
              as String?,
      clinicalIndication: freezed == clinicalIndication
          ? _value.clinicalIndication
          : clinicalIndication // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedBy: freezed == requestedBy
          ? _value.requestedBy
          : requestedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryContact: freezed == deliveryContact
          ? _value.deliveryContact
          : deliveryContact // ignore: cast_nullable_to_non_nullable
              as DeliveryContact?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusHistory: freezed == statusHistory
          ? _value.statusHistory
          : statusHistory // ignore: cast_nullable_to_non_nullable
              as List<StatusHistory>?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      softDeleted: null == softDeleted
          ? _value.softDeleted
          : softDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      onafriqTransactionRef: freezed == onafriqTransactionRef
          ? _value.onafriqTransactionRef
          : onafriqTransactionRef // ignore: cast_nullable_to_non_nullable
              as String?,
      failureReason: freezed == failureReason
          ? _value.failureReason
          : failureReason // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      ebloodFee: freezed == ebloodFee
          ? _value.ebloodFee
          : ebloodFee // ignore: cast_nullable_to_non_nullable
              as double?,
      refCurrencyId: freezed == refCurrencyId
          ? _value.refCurrencyId
          : refCurrencyId // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionalEbloodFee: freezed == transactionalEbloodFee
          ? _value.transactionalEbloodFee
          : transactionalEbloodFee // ignore: cast_nullable_to_non_nullable
              as double?,
      transactionalCurrencyId: freezed == transactionalCurrencyId
          ? _value.transactionalCurrencyId
          : transactionalCurrencyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DeliveryContactCopyWith<$Res>? get deliveryContact {
    if (_value.deliveryContact == null) {
      return null;
    }

    return $DeliveryContactCopyWith<$Res>(_value.deliveryContact!, (value) {
      return _then(_value.copyWith(deliveryContact: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BloodRequestModelImplCopyWith<$Res>
    implements $BloodRequestModelCopyWith<$Res> {
  factory _$$BloodRequestModelImplCopyWith(_$BloodRequestModelImpl value,
          $Res Function(_$BloodRequestModelImpl) then) =
      __$$BloodRequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: '_id', readValue: _readId) String id,
      String identifier,
      @JsonKey(
          name: 'health_structure_requesting_id',
          readValue: _readHealthStructureRequestingId)
      String? healthStructureRequestingId,
      @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
      String? sysOrganizationId,
      @JsonKey(name: 'request_type') String requestType,
      @JsonKey(name: 'urgency_level') String urgencyLevel,
      @JsonKey(name: 'patient_blood_group') String patientBloodGroup,
      @JsonKey(name: 'patient_rh_factor') String patientRhFactor,
      @JsonKey(name: 'requested_components')
      List<BloodRequestComponent> requestedComponents,
      @JsonKey(name: 'requested_delivery_time') String? requestedDeliveryTime,
      @JsonKey(name: 'clinical_indication') String? clinicalIndication,
      @JsonKey(name: 'requested_by') String? requestedBy,
      @JsonKey(name: 'delivery_contact') DeliveryContact? deliveryContact,
      String status,
      @JsonKey(name: 'status_history') List<StatusHistory>? statusHistory,
      String? notes,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'soft_deleted') bool softDeleted,
      @JsonKey(name: 'onafriq_transaction_ref') String? onafriqTransactionRef,
      @JsonKey(name: 'failure_reason') String? failureReason,
      @JsonKey(name: 'phone_number') String? phoneNumber,
      @JsonKey(name: 'eblood_fee') double? ebloodFee,
      @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
      String? refCurrencyId,
      @JsonKey(name: 'transactional_eblood_fee') double? transactionalEbloodFee,
      @JsonKey(
          name: 'transactional_currency_id',
          readValue: _readTransactionalCurrencyId)
      String? transactionalCurrencyId});

  @override
  $DeliveryContactCopyWith<$Res>? get deliveryContact;
}

/// @nodoc
class __$$BloodRequestModelImplCopyWithImpl<$Res>
    extends _$BloodRequestModelCopyWithImpl<$Res, _$BloodRequestModelImpl>
    implements _$$BloodRequestModelImplCopyWith<$Res> {
  __$$BloodRequestModelImplCopyWithImpl(_$BloodRequestModelImpl _value,
      $Res Function(_$BloodRequestModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? identifier = null,
    Object? healthStructureRequestingId = freezed,
    Object? sysOrganizationId = freezed,
    Object? requestType = null,
    Object? urgencyLevel = null,
    Object? patientBloodGroup = null,
    Object? patientRhFactor = null,
    Object? requestedComponents = null,
    Object? requestedDeliveryTime = freezed,
    Object? clinicalIndication = freezed,
    Object? requestedBy = freezed,
    Object? deliveryContact = freezed,
    Object? status = null,
    Object? statusHistory = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? softDeleted = null,
    Object? onafriqTransactionRef = freezed,
    Object? failureReason = freezed,
    Object? phoneNumber = freezed,
    Object? ebloodFee = freezed,
    Object? refCurrencyId = freezed,
    Object? transactionalEbloodFee = freezed,
    Object? transactionalCurrencyId = freezed,
  }) {
    return _then(_$BloodRequestModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      healthStructureRequestingId: freezed == healthStructureRequestingId
          ? _value.healthStructureRequestingId
          : healthStructureRequestingId // ignore: cast_nullable_to_non_nullable
              as String?,
      sysOrganizationId: freezed == sysOrganizationId
          ? _value.sysOrganizationId
          : sysOrganizationId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestType: null == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as String,
      urgencyLevel: null == urgencyLevel
          ? _value.urgencyLevel
          : urgencyLevel // ignore: cast_nullable_to_non_nullable
              as String,
      patientBloodGroup: null == patientBloodGroup
          ? _value.patientBloodGroup
          : patientBloodGroup // ignore: cast_nullable_to_non_nullable
              as String,
      patientRhFactor: null == patientRhFactor
          ? _value.patientRhFactor
          : patientRhFactor // ignore: cast_nullable_to_non_nullable
              as String,
      requestedComponents: null == requestedComponents
          ? _value._requestedComponents
          : requestedComponents // ignore: cast_nullable_to_non_nullable
              as List<BloodRequestComponent>,
      requestedDeliveryTime: freezed == requestedDeliveryTime
          ? _value.requestedDeliveryTime
          : requestedDeliveryTime // ignore: cast_nullable_to_non_nullable
              as String?,
      clinicalIndication: freezed == clinicalIndication
          ? _value.clinicalIndication
          : clinicalIndication // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedBy: freezed == requestedBy
          ? _value.requestedBy
          : requestedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryContact: freezed == deliveryContact
          ? _value.deliveryContact
          : deliveryContact // ignore: cast_nullable_to_non_nullable
              as DeliveryContact?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusHistory: freezed == statusHistory
          ? _value._statusHistory
          : statusHistory // ignore: cast_nullable_to_non_nullable
              as List<StatusHistory>?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      softDeleted: null == softDeleted
          ? _value.softDeleted
          : softDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      onafriqTransactionRef: freezed == onafriqTransactionRef
          ? _value.onafriqTransactionRef
          : onafriqTransactionRef // ignore: cast_nullable_to_non_nullable
              as String?,
      failureReason: freezed == failureReason
          ? _value.failureReason
          : failureReason // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      ebloodFee: freezed == ebloodFee
          ? _value.ebloodFee
          : ebloodFee // ignore: cast_nullable_to_non_nullable
              as double?,
      refCurrencyId: freezed == refCurrencyId
          ? _value.refCurrencyId
          : refCurrencyId // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionalEbloodFee: freezed == transactionalEbloodFee
          ? _value.transactionalEbloodFee
          : transactionalEbloodFee // ignore: cast_nullable_to_non_nullable
              as double?,
      transactionalCurrencyId: freezed == transactionalCurrencyId
          ? _value.transactionalCurrencyId
          : transactionalCurrencyId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodRequestModelImpl implements _BloodRequestModel {
  const _$BloodRequestModelImpl(
      {@JsonKey(name: '_id', readValue: _readId) required this.id,
      required this.identifier,
      @JsonKey(
          name: 'health_structure_requesting_id',
          readValue: _readHealthStructureRequestingId)
      this.healthStructureRequestingId,
      @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
      this.sysOrganizationId,
      @JsonKey(name: 'request_type') required this.requestType,
      @JsonKey(name: 'urgency_level') required this.urgencyLevel,
      @JsonKey(name: 'patient_blood_group') required this.patientBloodGroup,
      @JsonKey(name: 'patient_rh_factor') required this.patientRhFactor,
      @JsonKey(name: 'requested_components')
      final List<BloodRequestComponent> requestedComponents = const [],
      @JsonKey(name: 'requested_delivery_time') this.requestedDeliveryTime,
      @JsonKey(name: 'clinical_indication') this.clinicalIndication,
      @JsonKey(name: 'requested_by') this.requestedBy,
      @JsonKey(name: 'delivery_contact') this.deliveryContact,
      required this.status,
      @JsonKey(name: 'status_history') final List<StatusHistory>? statusHistory,
      this.notes,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'soft_deleted') this.softDeleted = false,
      @JsonKey(name: 'onafriq_transaction_ref') this.onafriqTransactionRef,
      @JsonKey(name: 'failure_reason') this.failureReason,
      @JsonKey(name: 'phone_number') this.phoneNumber,
      @JsonKey(name: 'eblood_fee') this.ebloodFee,
      @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
      this.refCurrencyId,
      @JsonKey(name: 'transactional_eblood_fee') this.transactionalEbloodFee,
      @JsonKey(
          name: 'transactional_currency_id',
          readValue: _readTransactionalCurrencyId)
      this.transactionalCurrencyId})
      : _requestedComponents = requestedComponents,
        _statusHistory = statusHistory;

  factory _$BloodRequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodRequestModelImplFromJson(json);

  @override
  @JsonKey(name: '_id', readValue: _readId)
  final String id;
  @override
  final String identifier;
  @override
  @JsonKey(
      name: 'health_structure_requesting_id',
      readValue: _readHealthStructureRequestingId)
  final String? healthStructureRequestingId;
  @override
  @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
  final String? sysOrganizationId;
  @override
  @JsonKey(name: 'request_type')
  final String requestType;
  @override
  @JsonKey(name: 'urgency_level')
  final String urgencyLevel;
  @override
  @JsonKey(name: 'patient_blood_group')
  final String patientBloodGroup;
  @override
  @JsonKey(name: 'patient_rh_factor')
  final String patientRhFactor;
  final List<BloodRequestComponent> _requestedComponents;
  @override
  @JsonKey(name: 'requested_components')
  List<BloodRequestComponent> get requestedComponents {
    if (_requestedComponents is EqualUnmodifiableListView)
      return _requestedComponents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requestedComponents);
  }

  @override
  @JsonKey(name: 'requested_delivery_time')
  final String? requestedDeliveryTime;
  @override
  @JsonKey(name: 'clinical_indication')
  final String? clinicalIndication;
  @override
  @JsonKey(name: 'requested_by')
  final String? requestedBy;
  @override
  @JsonKey(name: 'delivery_contact')
  final DeliveryContact? deliveryContact;
  @override
  final String status;
  final List<StatusHistory>? _statusHistory;
  @override
  @JsonKey(name: 'status_history')
  List<StatusHistory>? get statusHistory {
    final value = _statusHistory;
    if (value == null) return null;
    if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @override
  @JsonKey(name: 'soft_deleted')
  final bool softDeleted;
  @override
  @JsonKey(name: 'onafriq_transaction_ref')
  final String? onafriqTransactionRef;
  @override
  @JsonKey(name: 'failure_reason')
  final String? failureReason;
  @override
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @override
  @JsonKey(name: 'eblood_fee')
  final double? ebloodFee;
  @override
  @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
  final String? refCurrencyId;
  @override
  @JsonKey(name: 'transactional_eblood_fee')
  final double? transactionalEbloodFee;
  @override
  @JsonKey(
      name: 'transactional_currency_id',
      readValue: _readTransactionalCurrencyId)
  final String? transactionalCurrencyId;

  @override
  String toString() {
    return 'BloodRequestModel(id: $id, identifier: $identifier, healthStructureRequestingId: $healthStructureRequestingId, sysOrganizationId: $sysOrganizationId, requestType: $requestType, urgencyLevel: $urgencyLevel, patientBloodGroup: $patientBloodGroup, patientRhFactor: $patientRhFactor, requestedComponents: $requestedComponents, requestedDeliveryTime: $requestedDeliveryTime, clinicalIndication: $clinicalIndication, requestedBy: $requestedBy, deliveryContact: $deliveryContact, status: $status, statusHistory: $statusHistory, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, softDeleted: $softDeleted, onafriqTransactionRef: $onafriqTransactionRef, failureReason: $failureReason, phoneNumber: $phoneNumber, ebloodFee: $ebloodFee, refCurrencyId: $refCurrencyId, transactionalEbloodFee: $transactionalEbloodFee, transactionalCurrencyId: $transactionalCurrencyId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodRequestModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.healthStructureRequestingId,
                    healthStructureRequestingId) ||
                other.healthStructureRequestingId ==
                    healthStructureRequestingId) &&
            (identical(other.sysOrganizationId, sysOrganizationId) ||
                other.sysOrganizationId == sysOrganizationId) &&
            (identical(other.requestType, requestType) ||
                other.requestType == requestType) &&
            (identical(other.urgencyLevel, urgencyLevel) ||
                other.urgencyLevel == urgencyLevel) &&
            (identical(other.patientBloodGroup, patientBloodGroup) ||
                other.patientBloodGroup == patientBloodGroup) &&
            (identical(other.patientRhFactor, patientRhFactor) ||
                other.patientRhFactor == patientRhFactor) &&
            const DeepCollectionEquality()
                .equals(other._requestedComponents, _requestedComponents) &&
            (identical(other.requestedDeliveryTime, requestedDeliveryTime) ||
                other.requestedDeliveryTime == requestedDeliveryTime) &&
            (identical(other.clinicalIndication, clinicalIndication) ||
                other.clinicalIndication == clinicalIndication) &&
            (identical(other.requestedBy, requestedBy) ||
                other.requestedBy == requestedBy) &&
            (identical(other.deliveryContact, deliveryContact) ||
                other.deliveryContact == deliveryContact) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._statusHistory, _statusHistory) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.softDeleted, softDeleted) ||
                other.softDeleted == softDeleted) &&
            (identical(other.onafriqTransactionRef, onafriqTransactionRef) ||
                other.onafriqTransactionRef == onafriqTransactionRef) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.ebloodFee, ebloodFee) ||
                other.ebloodFee == ebloodFee) &&
            (identical(other.refCurrencyId, refCurrencyId) ||
                other.refCurrencyId == refCurrencyId) &&
            (identical(other.transactionalEbloodFee, transactionalEbloodFee) ||
                other.transactionalEbloodFee == transactionalEbloodFee) &&
            (identical(
                    other.transactionalCurrencyId, transactionalCurrencyId) ||
                other.transactionalCurrencyId == transactionalCurrencyId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        identifier,
        healthStructureRequestingId,
        sysOrganizationId,
        requestType,
        urgencyLevel,
        patientBloodGroup,
        patientRhFactor,
        const DeepCollectionEquality().hash(_requestedComponents),
        requestedDeliveryTime,
        clinicalIndication,
        requestedBy,
        deliveryContact,
        status,
        const DeepCollectionEquality().hash(_statusHistory),
        notes,
        createdAt,
        updatedAt,
        softDeleted,
        onafriqTransactionRef,
        failureReason,
        phoneNumber,
        ebloodFee,
        refCurrencyId,
        transactionalEbloodFee,
        transactionalCurrencyId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodRequestModelImplCopyWith<_$BloodRequestModelImpl> get copyWith =>
      __$$BloodRequestModelImplCopyWithImpl<_$BloodRequestModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodRequestModelImplToJson(
      this,
    );
  }
}

abstract class _BloodRequestModel implements BloodRequestModel {
  const factory _BloodRequestModel(
      {@JsonKey(name: '_id', readValue: _readId) required final String id,
      required final String identifier,
      @JsonKey(
          name: 'health_structure_requesting_id',
          readValue: _readHealthStructureRequestingId)
      final String? healthStructureRequestingId,
      @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
      final String? sysOrganizationId,
      @JsonKey(name: 'request_type') required final String requestType,
      @JsonKey(name: 'urgency_level') required final String urgencyLevel,
      @JsonKey(name: 'patient_blood_group')
      required final String patientBloodGroup,
      @JsonKey(name: 'patient_rh_factor') required final String patientRhFactor,
      @JsonKey(name: 'requested_components')
      final List<BloodRequestComponent> requestedComponents,
      @JsonKey(name: 'requested_delivery_time')
      final String? requestedDeliveryTime,
      @JsonKey(name: 'clinical_indication') final String? clinicalIndication,
      @JsonKey(name: 'requested_by') final String? requestedBy,
      @JsonKey(name: 'delivery_contact') final DeliveryContact? deliveryContact,
      required final String status,
      @JsonKey(name: 'status_history') final List<StatusHistory>? statusHistory,
      final String? notes,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') required final String updatedAt,
      @JsonKey(name: 'soft_deleted') final bool softDeleted,
      @JsonKey(name: 'onafriq_transaction_ref')
      final String? onafriqTransactionRef,
      @JsonKey(name: 'failure_reason') final String? failureReason,
      @JsonKey(name: 'phone_number') final String? phoneNumber,
      @JsonKey(name: 'eblood_fee') final double? ebloodFee,
      @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
      final String? refCurrencyId,
      @JsonKey(name: 'transactional_eblood_fee')
      final double? transactionalEbloodFee,
      @JsonKey(
          name: 'transactional_currency_id',
          readValue: _readTransactionalCurrencyId)
      final String? transactionalCurrencyId}) = _$BloodRequestModelImpl;

  factory _BloodRequestModel.fromJson(Map<String, dynamic> json) =
      _$BloodRequestModelImpl.fromJson;

  @override
  @JsonKey(name: '_id', readValue: _readId)
  String get id;
  @override
  String get identifier;
  @override
  @JsonKey(
      name: 'health_structure_requesting_id',
      readValue: _readHealthStructureRequestingId)
  String? get healthStructureRequestingId;
  @override
  @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson)
  String? get sysOrganizationId;
  @override
  @JsonKey(name: 'request_type')
  String get requestType;
  @override
  @JsonKey(name: 'urgency_level')
  String get urgencyLevel;
  @override
  @JsonKey(name: 'patient_blood_group')
  String get patientBloodGroup;
  @override
  @JsonKey(name: 'patient_rh_factor')
  String get patientRhFactor;
  @override
  @JsonKey(name: 'requested_components')
  List<BloodRequestComponent> get requestedComponents;
  @override
  @JsonKey(name: 'requested_delivery_time')
  String? get requestedDeliveryTime;
  @override
  @JsonKey(name: 'clinical_indication')
  String? get clinicalIndication;
  @override
  @JsonKey(name: 'requested_by')
  String? get requestedBy;
  @override
  @JsonKey(name: 'delivery_contact')
  DeliveryContact? get deliveryContact;
  @override
  String get status;
  @override
  @JsonKey(name: 'status_history')
  List<StatusHistory>? get statusHistory;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override
  @JsonKey(name: 'soft_deleted')
  bool get softDeleted;
  @override
  @JsonKey(name: 'onafriq_transaction_ref')
  String? get onafriqTransactionRef;
  @override
  @JsonKey(name: 'failure_reason')
  String? get failureReason;
  @override
  @JsonKey(name: 'phone_number')
  String? get phoneNumber;
  @override
  @JsonKey(name: 'eblood_fee')
  double? get ebloodFee;
  @override
  @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId)
  String? get refCurrencyId;
  @override
  @JsonKey(name: 'transactional_eblood_fee')
  double? get transactionalEbloodFee;
  @override
  @JsonKey(
      name: 'transactional_currency_id',
      readValue: _readTransactionalCurrencyId)
  String? get transactionalCurrencyId;
  @override
  @JsonKey(ignore: true)
  _$$BloodRequestModelImplCopyWith<_$BloodRequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BloodRequestComponent _$BloodRequestComponentFromJson(
    Map<String, dynamic> json) {
  return _BloodRequestComponent.fromJson(json);
}

/// @nodoc
mixin _$BloodRequestComponent {
  @JsonKey(name: 'blood_product_type')
  String get bloodProductType => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get volume => throw _privateConstructorUsedError;
  @JsonKey(name: 'blood_bag_id')
  String? get bloodBagId => throw _privateConstructorUsedError;
  @JsonKey(name: 'blood_bank_id')
  String? get bloodBankId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BloodRequestComponentCopyWith<BloodRequestComponent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodRequestComponentCopyWith<$Res> {
  factory $BloodRequestComponentCopyWith(BloodRequestComponent value,
          $Res Function(BloodRequestComponent) then) =
      _$BloodRequestComponentCopyWithImpl<$Res, BloodRequestComponent>;
  @useResult
  $Res call(
      {@JsonKey(name: 'blood_product_type') String bloodProductType,
      int quantity,
      String? volume,
      @JsonKey(name: 'blood_bag_id') String? bloodBagId,
      @JsonKey(name: 'blood_bank_id') String? bloodBankId});
}

/// @nodoc
class _$BloodRequestComponentCopyWithImpl<$Res,
        $Val extends BloodRequestComponent>
    implements $BloodRequestComponentCopyWith<$Res> {
  _$BloodRequestComponentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bloodProductType = null,
    Object? quantity = null,
    Object? volume = freezed,
    Object? bloodBagId = freezed,
    Object? bloodBankId = freezed,
  }) {
    return _then(_value.copyWith(
      bloodProductType: null == bloodProductType
          ? _value.bloodProductType
          : bloodProductType // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      volume: freezed == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodBagId: freezed == bloodBagId
          ? _value.bloodBagId
          : bloodBagId // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodBankId: freezed == bloodBankId
          ? _value.bloodBankId
          : bloodBankId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BloodRequestComponentImplCopyWith<$Res>
    implements $BloodRequestComponentCopyWith<$Res> {
  factory _$$BloodRequestComponentImplCopyWith(
          _$BloodRequestComponentImpl value,
          $Res Function(_$BloodRequestComponentImpl) then) =
      __$$BloodRequestComponentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'blood_product_type') String bloodProductType,
      int quantity,
      String? volume,
      @JsonKey(name: 'blood_bag_id') String? bloodBagId,
      @JsonKey(name: 'blood_bank_id') String? bloodBankId});
}

/// @nodoc
class __$$BloodRequestComponentImplCopyWithImpl<$Res>
    extends _$BloodRequestComponentCopyWithImpl<$Res,
        _$BloodRequestComponentImpl>
    implements _$$BloodRequestComponentImplCopyWith<$Res> {
  __$$BloodRequestComponentImplCopyWithImpl(_$BloodRequestComponentImpl _value,
      $Res Function(_$BloodRequestComponentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bloodProductType = null,
    Object? quantity = null,
    Object? volume = freezed,
    Object? bloodBagId = freezed,
    Object? bloodBankId = freezed,
  }) {
    return _then(_$BloodRequestComponentImpl(
      bloodProductType: null == bloodProductType
          ? _value.bloodProductType
          : bloodProductType // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      volume: freezed == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodBagId: freezed == bloodBagId
          ? _value.bloodBagId
          : bloodBagId // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodBankId: freezed == bloodBankId
          ? _value.bloodBankId
          : bloodBankId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodRequestComponentImpl implements _BloodRequestComponent {
  const _$BloodRequestComponentImpl(
      {@JsonKey(name: 'blood_product_type') required this.bloodProductType,
      required this.quantity,
      this.volume,
      @JsonKey(name: 'blood_bag_id') this.bloodBagId,
      @JsonKey(name: 'blood_bank_id') this.bloodBankId});

  factory _$BloodRequestComponentImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodRequestComponentImplFromJson(json);

  @override
  @JsonKey(name: 'blood_product_type')
  final String bloodProductType;
  @override
  final int quantity;
  @override
  final String? volume;
  @override
  @JsonKey(name: 'blood_bag_id')
  final String? bloodBagId;
  @override
  @JsonKey(name: 'blood_bank_id')
  final String? bloodBankId;

  @override
  String toString() {
    return 'BloodRequestComponent(bloodProductType: $bloodProductType, quantity: $quantity, volume: $volume, bloodBagId: $bloodBagId, bloodBankId: $bloodBankId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodRequestComponentImpl &&
            (identical(other.bloodProductType, bloodProductType) ||
                other.bloodProductType == bloodProductType) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.bloodBagId, bloodBagId) ||
                other.bloodBagId == bloodBagId) &&
            (identical(other.bloodBankId, bloodBankId) ||
                other.bloodBankId == bloodBankId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, bloodProductType, quantity, volume, bloodBagId, bloodBankId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodRequestComponentImplCopyWith<_$BloodRequestComponentImpl>
      get copyWith => __$$BloodRequestComponentImplCopyWithImpl<
          _$BloodRequestComponentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodRequestComponentImplToJson(
      this,
    );
  }
}

abstract class _BloodRequestComponent implements BloodRequestComponent {
  const factory _BloodRequestComponent(
          {@JsonKey(name: 'blood_product_type')
          required final String bloodProductType,
          required final int quantity,
          final String? volume,
          @JsonKey(name: 'blood_bag_id') final String? bloodBagId,
          @JsonKey(name: 'blood_bank_id') final String? bloodBankId}) =
      _$BloodRequestComponentImpl;

  factory _BloodRequestComponent.fromJson(Map<String, dynamic> json) =
      _$BloodRequestComponentImpl.fromJson;

  @override
  @JsonKey(name: 'blood_product_type')
  String get bloodProductType;
  @override
  int get quantity;
  @override
  String? get volume;
  @override
  @JsonKey(name: 'blood_bag_id')
  String? get bloodBagId;
  @override
  @JsonKey(name: 'blood_bank_id')
  String? get bloodBankId;
  @override
  @JsonKey(ignore: true)
  _$$BloodRequestComponentImplCopyWith<_$BloodRequestComponentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DeliveryContact _$DeliveryContactFromJson(Map<String, dynamic> json) {
  return _DeliveryContact.fromJson(json);
}

/// @nodoc
mixin _$DeliveryContact {
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DeliveryContactCopyWith<DeliveryContact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryContactCopyWith<$Res> {
  factory $DeliveryContactCopyWith(
          DeliveryContact value, $Res Function(DeliveryContact) then) =
      _$DeliveryContactCopyWithImpl<$Res, DeliveryContact>;
  @useResult
  $Res call({String name, String phone, String? email, String? address});
}

/// @nodoc
class _$DeliveryContactCopyWithImpl<$Res, $Val extends DeliveryContact>
    implements $DeliveryContactCopyWith<$Res> {
  _$DeliveryContactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? email = freezed,
    Object? address = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeliveryContactImplCopyWith<$Res>
    implements $DeliveryContactCopyWith<$Res> {
  factory _$$DeliveryContactImplCopyWith(_$DeliveryContactImpl value,
          $Res Function(_$DeliveryContactImpl) then) =
      __$$DeliveryContactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String phone, String? email, String? address});
}

/// @nodoc
class __$$DeliveryContactImplCopyWithImpl<$Res>
    extends _$DeliveryContactCopyWithImpl<$Res, _$DeliveryContactImpl>
    implements _$$DeliveryContactImplCopyWith<$Res> {
  __$$DeliveryContactImplCopyWithImpl(
      _$DeliveryContactImpl _value, $Res Function(_$DeliveryContactImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? email = freezed,
    Object? address = freezed,
  }) {
    return _then(_$DeliveryContactImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryContactImpl implements _DeliveryContact {
  const _$DeliveryContactImpl(
      {required this.name, required this.phone, this.email, this.address});

  factory _$DeliveryContactImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryContactImplFromJson(json);

  @override
  final String name;
  @override
  final String phone;
  @override
  final String? email;
  @override
  final String? address;

  @override
  String toString() {
    return 'DeliveryContact(name: $name, phone: $phone, email: $email, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryContactImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, phone, email, address);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryContactImplCopyWith<_$DeliveryContactImpl> get copyWith =>
      __$$DeliveryContactImplCopyWithImpl<_$DeliveryContactImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryContactImplToJson(
      this,
    );
  }
}

abstract class _DeliveryContact implements DeliveryContact {
  const factory _DeliveryContact(
      {required final String name,
      required final String phone,
      final String? email,
      final String? address}) = _$DeliveryContactImpl;

  factory _DeliveryContact.fromJson(Map<String, dynamic> json) =
      _$DeliveryContactImpl.fromJson;

  @override
  String get name;
  @override
  String get phone;
  @override
  String? get email;
  @override
  String? get address;
  @override
  @JsonKey(ignore: true)
  _$$DeliveryContactImplCopyWith<_$DeliveryContactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StatusHistory _$StatusHistoryFromJson(Map<String, dynamic> json) {
  return _StatusHistory.fromJson(json);
}

/// @nodoc
mixin _$StatusHistory {
  String get status => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  @JsonKey(name: 'changed_by')
  String? get changedBy => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StatusHistoryCopyWith<StatusHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatusHistoryCopyWith<$Res> {
  factory $StatusHistoryCopyWith(
          StatusHistory value, $Res Function(StatusHistory) then) =
      _$StatusHistoryCopyWithImpl<$Res, StatusHistory>;
  @useResult
  $Res call(
      {String status,
      String timestamp,
      @JsonKey(name: 'changed_by') String? changedBy,
      String? notes});
}

/// @nodoc
class _$StatusHistoryCopyWithImpl<$Res, $Val extends StatusHistory>
    implements $StatusHistoryCopyWith<$Res> {
  _$StatusHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? timestamp = null,
    Object? changedBy = freezed,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      changedBy: freezed == changedBy
          ? _value.changedBy
          : changedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StatusHistoryImplCopyWith<$Res>
    implements $StatusHistoryCopyWith<$Res> {
  factory _$$StatusHistoryImplCopyWith(
          _$StatusHistoryImpl value, $Res Function(_$StatusHistoryImpl) then) =
      __$$StatusHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      String timestamp,
      @JsonKey(name: 'changed_by') String? changedBy,
      String? notes});
}

/// @nodoc
class __$$StatusHistoryImplCopyWithImpl<$Res>
    extends _$StatusHistoryCopyWithImpl<$Res, _$StatusHistoryImpl>
    implements _$$StatusHistoryImplCopyWith<$Res> {
  __$$StatusHistoryImplCopyWithImpl(
      _$StatusHistoryImpl _value, $Res Function(_$StatusHistoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? timestamp = null,
    Object? changedBy = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$StatusHistoryImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      changedBy: freezed == changedBy
          ? _value.changedBy
          : changedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StatusHistoryImpl implements _StatusHistory {
  const _$StatusHistoryImpl(
      {required this.status,
      required this.timestamp,
      @JsonKey(name: 'changed_by') this.changedBy,
      this.notes});

  factory _$StatusHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatusHistoryImplFromJson(json);

  @override
  final String status;
  @override
  final String timestamp;
  @override
  @JsonKey(name: 'changed_by')
  final String? changedBy;
  @override
  final String? notes;

  @override
  String toString() {
    return 'StatusHistory(status: $status, timestamp: $timestamp, changedBy: $changedBy, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatusHistoryImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.changedBy, changedBy) ||
                other.changedBy == changedBy) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, timestamp, changedBy, notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StatusHistoryImplCopyWith<_$StatusHistoryImpl> get copyWith =>
      __$$StatusHistoryImplCopyWithImpl<_$StatusHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StatusHistoryImplToJson(
      this,
    );
  }
}

abstract class _StatusHistory implements StatusHistory {
  const factory _StatusHistory(
      {required final String status,
      required final String timestamp,
      @JsonKey(name: 'changed_by') final String? changedBy,
      final String? notes}) = _$StatusHistoryImpl;

  factory _StatusHistory.fromJson(Map<String, dynamic> json) =
      _$StatusHistoryImpl.fromJson;

  @override
  String get status;
  @override
  String get timestamp;
  @override
  @JsonKey(name: 'changed_by')
  String? get changedBy;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$StatusHistoryImplCopyWith<_$StatusHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BloodRequestsResponse _$BloodRequestsResponseFromJson(
    Map<String, dynamic> json) {
  return _BloodRequestsResponse.fromJson(json);
}

/// @nodoc
mixin _$BloodRequestsResponse {
  List<BloodRequestModel> get data => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BloodRequestsResponseCopyWith<BloodRequestsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodRequestsResponseCopyWith<$Res> {
  factory $BloodRequestsResponseCopyWith(BloodRequestsResponse value,
          $Res Function(BloodRequestsResponse) then) =
      _$BloodRequestsResponseCopyWithImpl<$Res, BloodRequestsResponse>;
  @useResult
  $Res call({List<BloodRequestModel> data, int total, int page, int limit});
}

/// @nodoc
class _$BloodRequestsResponseCopyWithImpl<$Res,
        $Val extends BloodRequestsResponse>
    implements $BloodRequestsResponseCopyWith<$Res> {
  _$BloodRequestsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<BloodRequestModel>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BloodRequestsResponseImplCopyWith<$Res>
    implements $BloodRequestsResponseCopyWith<$Res> {
  factory _$$BloodRequestsResponseImplCopyWith(
          _$BloodRequestsResponseImpl value,
          $Res Function(_$BloodRequestsResponseImpl) then) =
      __$$BloodRequestsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<BloodRequestModel> data, int total, int page, int limit});
}

/// @nodoc
class __$$BloodRequestsResponseImplCopyWithImpl<$Res>
    extends _$BloodRequestsResponseCopyWithImpl<$Res,
        _$BloodRequestsResponseImpl>
    implements _$$BloodRequestsResponseImplCopyWith<$Res> {
  __$$BloodRequestsResponseImplCopyWithImpl(_$BloodRequestsResponseImpl _value,
      $Res Function(_$BloodRequestsResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_$BloodRequestsResponseImpl(
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as List<BloodRequestModel>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodRequestsResponseImpl implements _BloodRequestsResponse {
  const _$BloodRequestsResponseImpl(
      {required final List<BloodRequestModel> data,
      required this.total,
      required this.page,
      required this.limit})
      : _data = data;

  factory _$BloodRequestsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodRequestsResponseImplFromJson(json);

  final List<BloodRequestModel> _data;
  @override
  List<BloodRequestModel> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;

  @override
  String toString() {
    return 'BloodRequestsResponse(data: $data, total: $total, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodRequestsResponseImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_data), total, page, limit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodRequestsResponseImplCopyWith<_$BloodRequestsResponseImpl>
      get copyWith => __$$BloodRequestsResponseImplCopyWithImpl<
          _$BloodRequestsResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodRequestsResponseImplToJson(
      this,
    );
  }
}

abstract class _BloodRequestsResponse implements BloodRequestsResponse {
  const factory _BloodRequestsResponse(
      {required final List<BloodRequestModel> data,
      required final int total,
      required final int page,
      required final int limit}) = _$BloodRequestsResponseImpl;

  factory _BloodRequestsResponse.fromJson(Map<String, dynamic> json) =
      _$BloodRequestsResponseImpl.fromJson;

  @override
  List<BloodRequestModel> get data;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;
  @override
  @JsonKey(ignore: true)
  _$$BloodRequestsResponseImplCopyWith<_$BloodRequestsResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
