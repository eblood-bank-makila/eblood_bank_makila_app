import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../business/models/payout_number_model.dart';

/// Mobile-money operators a payout number can be tagged with. The values are
/// the backend `operator_hint` strings; the labels are display-only.
const List<String> payoutOperatorValues = <String>[
  'mpesa',
  'orange_money',
  'airtel_money',
  'afrimoney',
  'other',
];

/// Display label for an `operator_hint` value; `other` is translated, the
/// brand names are not.
String payoutOperatorLabel(String value) {
  switch (value) {
    case 'mpesa':
      return 'M-Pesa';
    case 'orange_money':
      return 'Orange Money';
    case 'airtel_money':
      return 'Airtel Money';
    case 'afrimoney':
      return 'AfriMoney';
    default:
      return 'other'.tr;
  }
}

final RegExp _phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

/// Pure validation for the payout-number form. Returns the translation key
/// of the first failing rule (`enter_valid_phone`, `enter_valid_daily_cap`,
/// `enter_valid_priority`) or null when everything is acceptable.
String? validatePayoutForm({
  required String phone,
  required String cap,
  required String priority,
}) {
  if (!_phoneRe.hasMatch(phone.trim())) return 'enter_valid_phone';
  final capValue = double.tryParse(cap.trim().replaceAll(',', '.'));
  if (capValue == null || capValue <= 0) return 'enter_valid_daily_cap';
  final priorityValue = int.tryParse(priority.trim());
  if (priorityValue == null || priorityValue < 1) return 'enter_valid_priority';
  return null;
}

/// Add / edit bottom sheet for one cash-out (payout) number.
///
/// Show it with `showModalBottomSheet(isScrollControlled: true)`. [onSubmit]
/// receives the backend payload and returns the provider result; the sheet
/// only closes (popping `true`) when that result is `true`, otherwise it stays
/// open and shows [readError]'s message (if provided) under the form so the
/// user can fix the input — a page-level snackbar is hidden behind the sheet.
class PayoutNumberSheet extends StatefulWidget {
  final PayoutNumberModel? initial;
  final Future<bool> Function(Map<String, dynamic> payload) onSubmit;
  final String? Function()? readError;

  const PayoutNumberSheet({
    super.key,
    this.initial,
    required this.onSubmit,
    this.readError,
  });

  @override
  State<PayoutNumberSheet> createState() => _PayoutNumberSheetState();
}

class _PayoutNumberSheetState extends State<PayoutNumberSheet> {
  late final TextEditingController _phoneController;
  late final TextEditingController _holderController;
  late final TextEditingController _capController;
  late final TextEditingController _priorityController;
  late String _operator;

  /// Translation key of the current validation failure (drives the inline
  /// `errorText` of the matching field), or null.
  String? _errorKey;

  /// Backend/provider failure message from the last rejected submit, or null.
  String? _submitError;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _phoneController = TextEditingController(text: initial?.phoneNumber ?? '');
    _holderController = TextEditingController(text: initial?.holderName ?? '');
    _capController = TextEditingController(
      text: initial == null ? '' : _formatCap(initial.maxAmountPerDay),
    );
    _priorityController = TextEditingController(text: '${initial?.priority ?? 1}');
    final hint = initial?.operatorHint;
    _operator = (hint != null && payoutOperatorValues.contains(hint)) ? hint : payoutOperatorValues.first;
  }

  static String _formatCap(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  void dispose() {
    _phoneController.dispose();
    _holderController.dispose();
    _capController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error = validatePayoutForm(
      phone: _phoneController.text,
      cap: _capController.text,
      priority: _priorityController.text,
    );
    if (error != null) {
      setState(() {
        _errorKey = error;
        _submitError = null;
      });
      return;
    }
    final payload = <String, dynamic>{
      'phone_number': _phoneController.text.trim(),
      'holder_name': _holderController.text.trim(),
      'operator_hint': _operator,
      'max_amount_per_day': double.parse(_capController.text.trim().replaceAll(',', '.')),
      'priority': int.parse(_priorityController.text.trim()),
    };
    setState(() {
      _errorKey = null;
      _submitError = null;
      _submitting = true;
    });
    final ok = await widget.onSubmit(payload);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _submitError = widget.readError?.call() ?? 'error'.tr;
    });
  }

  String? _fieldError(String key) => _errorKey == key ? key.tr : null;

  InputDecoration _decoration(String label, {IconData? icon, String? errorText}) => InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: icon == null ? null : Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Iconsax.money_send, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (_isEdit ? 'edit_payout_number' : 'add_payout_number').tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                'phone_number'.tr,
                icon: Icons.phone,
                errorText: _fieldError('enter_valid_phone'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _holderController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('holder_name'.tr, icon: Icons.person_outline),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _operator,
              decoration: _decoration('operator'.tr),
              items: payoutOperatorValues
                  .map((v) => DropdownMenuItem<String>(value: v, child: Text(payoutOperatorLabel(v))))
                  .toList(),
              onChanged: _submitting ? null : (v) => setState(() => _operator = v ?? _operator),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _capController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration(
                      'daily_cap'.tr,
                      errorText: _fieldError('enter_valid_daily_cap'),
                    ).copyWith(prefixText: 'USD '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priorityController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration(
                      'priority'.tr,
                      errorText: _fieldError('enter_valid_priority'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.info_circle, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'payout_number_validation_note'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                style: GoogleFonts.ubuntu(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cancel'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('save'.tr, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
