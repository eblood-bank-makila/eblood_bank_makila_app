import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ──────────────────────────────────────────────────
// EWallet setting validation status (per setting: email / phone / auto_cash_out)
// ──────────────────────────────────────────────────

/// Validation lifecycle of one wallet setting submitted by the BB/CNTS and validated
/// by the MAIN profile: not_set -> pending_validation -> rejected | validated.
class EWalletSettingStatus {
  final String status;
  final String? pendingValue;
  final String? rejectionReason;

  const EWalletSettingStatus({
    this.status = 'not_set',
    this.pendingValue,
    this.rejectionReason,
  });

  factory EWalletSettingStatus.fromJson(Map? json) {
    if (json == null) return const EWalletSettingStatus();
    return EWalletSettingStatus(
      status: (json['status'] ?? 'not_set').toString(),
      pendingValue: json['pending_value']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  bool get isNotSet => status == 'not_set';
  bool get isPending => status == 'pending_validation';
  bool get isRejected => status == 'rejected';
  bool get isValidated => status == 'validated';
}

// ──────────────────────────────────────────────────
// EWallet Model
// ──────────────────────────────────────────────────

class EWalletModel {
  final String id;
  final String identifier;
  final String ewalletNumber;
  final String ewalletPlaceholderName;
  final double ewalletAmount;
  final String currencySymbol;
  final String currencyCode;
  final String currencyName;
  final String authEmail;
  final String authPhoneNumber;
  final String withdrawalPhoneNumber;
  final String lockedUseStatus;
  final String walletType;
  final String walletFlag;
  final bool isDefault;
  final bool isActivated;
  final bool autoCashOut;
  final DateTime? createdAt;
  // Per-setting validation status (from the my-wallets `settings_status` payload).
  final EWalletSettingStatus emailStatus;
  final EWalletSettingStatus phoneStatus;
  final EWalletSettingStatus autoCashOutStatus;
  final EWalletSettingStatus withdrawalPhoneStatus;

  EWalletModel({
    required this.id,
    required this.identifier,
    required this.ewalletNumber,
    required this.ewalletPlaceholderName,
    required this.ewalletAmount,
    required this.currencySymbol,
    required this.currencyCode,
    required this.currencyName,
    required this.authEmail,
    required this.authPhoneNumber,
    this.withdrawalPhoneNumber = '',
    required this.lockedUseStatus,
    required this.walletType,
    required this.walletFlag,
    required this.isDefault,
    required this.isActivated,
    this.autoCashOut = false,
    this.createdAt,
    this.emailStatus = const EWalletSettingStatus(),
    this.phoneStatus = const EWalletSettingStatus(),
    this.autoCashOutStatus = const EWalletSettingStatus(),
    this.withdrawalPhoneStatus = const EWalletSettingStatus(),
  });

  factory EWalletModel.fromBackendJson(Map<String, dynamic> json) {
    dynamic getValue(String key, [Map<String, dynamic>? source]) {
      final data = source ?? json;
      final field = data[key];
      if (field is Map<String, dynamic>) {
        if (field.containsKey('real_value') || field.containsKey('display_value')) {
          return field['real_value'] ?? field['display_value'];
        }
      }
      return field;
    }

    // Currency
    String currencySymbol = '\$';
    String currencyCode = 'USD';
    String currencyName = 'US Dollar';

    final refCurrency = json['ref_currency'];
    if (refCurrency is Map<String, dynamic> && refCurrency.isNotEmpty) {
      final sym = refCurrency['symbol'];
      if (sym is Map<String, dynamic>) {
        currencySymbol = (sym['real_value'] ?? sym['display_value'] ?? '\$').toString();
      } else if (sym != null) {
        currencySymbol = sym.toString();
      }

      final code = refCurrency['code'];
      if (code is Map<String, dynamic>) {
        currencyCode = (code['real_value'] ?? code['display_value'] ?? 'USD').toString().toUpperCase();
      } else if (code != null) {
        currencyCode = code.toString().toUpperCase();
      }

      final name = refCurrency['name'];
      if (name is Map<String, dynamic>) {
        currencyName = (name['real_value'] ?? name['display_value'] ?? 'US Dollar').toString();
      } else if (name != null) {
        currencyName = name.toString();
      }
    }

    // Amount
    double amount = 0.0;
    final amountField = json['ewallet_amount'];
    if (amountField is Map<String, dynamic>) {
      final v = amountField['real_value'] ?? amountField['display_value'];
      if (v is num) amount = v.toDouble();
      else if (v is String) amount = double.tryParse(v) ?? 0.0;
    } else if (amountField is num) {
      amount = amountField.toDouble();
    } else if (amountField is String) {
      amount = double.tryParse(amountField) ?? 0.0;
    }

    // is_default
    bool isDefault = false;
    final isDefaultField = json['is_default'];
    if (isDefaultField is Map<String, dynamic>) {
      isDefault = (isDefaultField['real_value'] ?? isDefaultField['display_value']) == true;
    } else if (isDefaultField is bool) {
      isDefault = isDefaultField;
    }

    // is_activated
    bool isActivated = false;
    final isActivatedField = json['is_activated'];
    if (isActivatedField is Map<String, dynamic>) {
      isActivated = (isActivatedField['real_value'] ?? isActivatedField['display_value']) == true;
    } else if (isActivatedField is bool) {
      isActivated = isActivatedField;
    }

    // auto_cash_out (the "automatic reception" settings toggle)
    bool autoCashOut = false;
    final autoCashOutField = json['auto_cash_out'];
    if (autoCashOutField is Map<String, dynamic>) {
      autoCashOut = (autoCashOutField['real_value'] ?? autoCashOutField['display_value']) == true;
    } else if (autoCashOutField is bool) {
      autoCashOut = autoCashOutField;
    }

    // Per-setting validation status (attached by GET /ewallet/my-wallets).
    final settingsStatus = json['settings_status'];
    EWalletSettingStatus statusFor(String key) => settingsStatus is Map
        ? EWalletSettingStatus.fromJson(settingsStatus[key] as Map?)
        : const EWalletSettingStatus();

    DateTime? createdAt;
    final cAt = getValue('created_at');
    if (cAt is String && cAt.isNotEmpty) createdAt = DateTime.tryParse(cAt);

    return EWalletModel(
      id: (getValue('id') ?? '').toString(),
      identifier: (getValue('identifier') ?? '').toString(),
      ewalletNumber: (getValue('ewallet_number') ?? '').toString(),
      ewalletPlaceholderName: (getValue('ewallet_placeholder_name') ?? '').toString(),
      ewalletAmount: amount,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
      currencyName: currencyName,
      authEmail: (getValue('auth_email') ?? '').toString(),
      authPhoneNumber: (getValue('auth_phone_number') ?? '').toString(),
      withdrawalPhoneNumber: (getValue('withdrawal_phone_number') ?? '').toString(),
      lockedUseStatus: (getValue('locked_use_status') ?? 'active').toString(),
      walletType: (getValue('lokotro_wallet_type') ?? 'basic').toString(),
      walletFlag: (getValue('lokotro_wallet_flag') ?? 'customer').toString(),
      isDefault: isDefault,
      isActivated: isActivated,
      autoCashOut: autoCashOut,
      createdAt: createdAt,
      emailStatus: statusFor('auth_email'),
      phoneStatus: statusFor('auth_phone_number'),
      autoCashOutStatus: statusFor('auto_cash_out'),
      withdrawalPhoneStatus: statusFor('withdrawal_phone_number'),
    );
  }

  String get maskedWalletNumber {
    if (ewalletNumber.length > 4) {
      final lastFour = ewalletNumber.substring(ewalletNumber.length - 4);
      return '**** **** **** $lastFour';
    }
    return ewalletNumber;
  }

  String get formattedBalance => '$currencySymbol${ewalletAmount.toStringAsFixed(2)}';

  bool get isActive => lockedUseStatus == 'active' && isActivated;

  String get holderName =>
      ewalletPlaceholderName.isNotEmpty ? ewalletPlaceholderName : 'E-Blood Wallet';
}

// ──────────────────────────────────────────────────
// EWallet History Model
// ──────────────────────────────────────────────────

enum EWalletMovementType { debit, credit, transferIn, transferOut, none }

enum EWalletOperationOrigin {
  none,
  ewalletReload,
  transferIn,
  transferOut,
  deposit,
  ewalletCashOut,
  ewalletCashIn,
  ewalletWithdrawal,
  ewalletWithdrawalSharingFee,
  payment,
  paymentHoldReleased,
  paymentHoldRefunded,
}

class StatusColor {
  final Color textColor;
  final Color backgroundColor;

  StatusColor({required this.textColor, required this.backgroundColor});

  factory StatusColor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StatusColor(textColor: Colors.grey, backgroundColor: Colors.grey.shade100);
    }
    return StatusColor(
      textColor: _parseColor(json['textColor']),
      backgroundColor: _parseColor(json['backgroundColor']),
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class EWalletHistoryModel {
  final String id;
  final String identifier;
  final String status;
  final String statusLabel;
  final StatusColor statusColor;
  final EWalletMovementType movementType;
  final String movementTypeLabel;
  final StatusColor movementTypeColor;
  final EWalletOperationOrigin operationOrigin;
  final String operationOriginLabel;
  final StatusColor operationOriginColor;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String walletId;
  final String walletNumber;
  final String currencySymbol;
  final String currencyCode;
  final String? userName;
  final DateTime? createdAt;

  EWalletHistoryModel({
    required this.id,
    required this.identifier,
    required this.status,
    this.statusLabel = '',
    StatusColor? statusColor,
    required this.movementType,
    this.movementTypeLabel = '',
    StatusColor? movementTypeColor,
    required this.operationOrigin,
    this.operationOriginLabel = '',
    StatusColor? operationOriginColor,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.walletId,
    this.walletNumber = '',
    required this.currencySymbol,
    required this.currencyCode,
    this.userName,
    this.createdAt,
  })  : statusColor = statusColor ?? StatusColor(textColor: Colors.grey, backgroundColor: Colors.grey.shade100),
        movementTypeColor = movementTypeColor ?? StatusColor(textColor: Colors.grey, backgroundColor: Colors.grey.shade100),
        operationOriginColor = operationOriginColor ?? StatusColor(textColor: Colors.grey, backgroundColor: Colors.grey.shade100);

  bool get isCredit =>
      movementType == EWalletMovementType.credit ||
      movementType == EWalletMovementType.transferIn;

  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign$currencySymbol${amount.toStringAsFixed(2)}';
  }

  String get title {
    if (operationOriginLabel.isNotEmpty) return operationOriginLabel;
    if (movementTypeLabel.isNotEmpty) return movementTypeLabel;
    return isCredit ? 'Credit' : 'Debit';
  }

  IconData get icon {
    switch (operationOrigin) {
      case EWalletOperationOrigin.ewalletWithdrawal:
      case EWalletOperationOrigin.ewalletCashOut:
        return Iconsax.money_send;
      case EWalletOperationOrigin.ewalletReload:
      case EWalletOperationOrigin.ewalletCashIn:
      case EWalletOperationOrigin.deposit:
        return Iconsax.money_recive;
      case EWalletOperationOrigin.transferIn:
        return Iconsax.receive_square;
      case EWalletOperationOrigin.transferOut:
        return Iconsax.send_square;
      case EWalletOperationOrigin.payment:
      case EWalletOperationOrigin.paymentHoldReleased:
        return Iconsax.card;
      default:
        return isCredit ? Iconsax.money_recive : Iconsax.money_send;
    }
  }

  factory EWalletHistoryModel.fromBackendJson(Map<String, dynamic> json) {
    dynamic getValue(String key, [Map<String, dynamic>? source]) {
      final data = source ?? json;
      final field = data[key];
      if (field is Map<String, dynamic>) {
        if (field.containsKey('real_value') || field.containsKey('display_value')) {
          return field['real_value'] ?? field['display_value'];
        }
      }
      return field;
    }

    String getLabel(String key) {
      final field = json[key];
      if (field is Map<String, dynamic>) {
        return (field['display_value'] ?? '').toString();
      }
      return (field ?? '').toString();
    }

    StatusColor getStatusColor(String key) {
      final field = json[key];
      if (field is Map<String, dynamic> && field.containsKey('status_colors')) {
        return StatusColor.fromJson(field['status_colors'] as Map<String, dynamic>?);
      }
      return StatusColor(textColor: Colors.grey, backgroundColor: Colors.grey.shade100);
    }

    // Movement type
    final movementRaw = (getValue('movement_type') ?? '').toString().toLowerCase();
    EWalletMovementType movementType;
    switch (movementRaw) {
      case 'credit':
        movementType = EWalletMovementType.credit;
      case 'debit':
        movementType = EWalletMovementType.debit;
      case 'transfer_in':
        movementType = EWalletMovementType.transferIn;
      case 'transfer_out':
        movementType = EWalletMovementType.transferOut;
      default:
        movementType = EWalletMovementType.none;
    }

    // Operation origin
    final originRaw = (getValue('operation_origin_flag') ?? '').toString().toLowerCase();
    EWalletOperationOrigin operationOrigin;
    switch (originRaw) {
      case 'ewallet_reload':
        operationOrigin = EWalletOperationOrigin.ewalletReload;
      case 'transfer_in':
        operationOrigin = EWalletOperationOrigin.transferIn;
      case 'transfer_out':
        operationOrigin = EWalletOperationOrigin.transferOut;
      case 'ewallet_withdrawal':
        operationOrigin = EWalletOperationOrigin.ewalletWithdrawal;
      case 'ewallet_cash_out':
        operationOrigin = EWalletOperationOrigin.ewalletCashOut;
      case 'ewallet_cash_in':
        operationOrigin = EWalletOperationOrigin.ewalletCashIn;
      case 'deposit':
        operationOrigin = EWalletOperationOrigin.deposit;
      case 'payment':
        operationOrigin = EWalletOperationOrigin.payment;
      case 'payment_hold_released':
        operationOrigin = EWalletOperationOrigin.paymentHoldReleased;
      case 'payment_hold_refunded':
        operationOrigin = EWalletOperationOrigin.paymentHoldRefunded;
      default:
        operationOrigin = EWalletOperationOrigin.none;
    }

    // Amount
    double parseDouble(String key) {
      final v = getValue(key);
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    // Currency from ops_ewallet
    String currSym = '\$';
    String currCode = 'USD';
    final wallet = json['ops_ewallet'];
    if (wallet is Map<String, dynamic>) {
      final rc = wallet['ref_currency'];
      if (rc is Map<String, dynamic>) {
        final s = rc['symbol'];
        if (s is Map) {
          currSym = (s['real_value'] ?? s['display_value'] ?? '\$').toString();
        } else if (s != null) {
          currSym = s.toString();
        }
        final c = rc['code'];
        if (c is Map) {
          currCode = (c['real_value'] ?? c['display_value'] ?? 'USD').toString().toUpperCase();
        } else if (c != null) {
          currCode = c.toString().toUpperCase();
        }
      }
    }

    // User name
    String? userName;
    final sysUser = json['sys_user'];
    if (sysUser is Map<String, dynamic>) {
      final fn = getValue('first_name', sysUser);
      final ln = getValue('last_name', sysUser);
      if (fn != null || ln != null) {
        userName = '${fn ?? ''} ${ln ?? ''}'.trim();
      }
    }

    DateTime? createdAt;
    final cAt = getValue('created_at');
    if (cAt is String && cAt.isNotEmpty) createdAt = DateTime.tryParse(cAt);

    return EWalletHistoryModel(
      id: (getValue('id') ?? '').toString(),
      identifier: (getValue('identifier') ?? '').toString(),
      status: (getValue('status') ?? '').toString(),
      statusLabel: getLabel('status'),
      statusColor: getStatusColor('status'),
      movementType: movementType,
      movementTypeLabel: getLabel('movement_type'),
      movementTypeColor: getStatusColor('movement_type'),
      operationOrigin: operationOrigin,
      operationOriginLabel: getLabel('operation_origin_flag'),
      operationOriginColor: getStatusColor('operation_origin_flag'),
      amount: parseDouble('amount'),
      balanceBefore: parseDouble('balance_before'),
      balanceAfter: parseDouble('balance_after'),
      walletId: (getValue('ops_ewallet_id') ?? '').toString(),
      walletNumber: wallet is Map<String, dynamic>
          ? (getValue('ewallet_number', wallet) ?? '').toString()
          : '',
      currencySymbol: currSym,
      currencyCode: currCode,
      userName: userName,
      createdAt: createdAt,
    );
  }
}
