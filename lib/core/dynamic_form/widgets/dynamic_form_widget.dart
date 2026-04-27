import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../models/dynamic_form_field.dart';

/// A reusable widget that renders a list of [DynamicFormField] into form controls.
///
/// Mirrors Angular's `GlobalCreationFormComponent`.
class DynamicFormWidget extends StatefulWidget {
  final List<DynamicFormField> fields;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? submitLabel;

  const DynamicFormWidget({
    super.key,
    required this.fields,
    required this.isSubmitting,
    required this.onSubmit,
    this.submitLabel,
  });

  @override
  State<DynamicFormWidget> createState() => DynamicFormWidgetState();
}

class DynamicFormWidgetState extends State<DynamicFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final field in widget.fields) {
      if (_isTextInput(field.fieldType) && !field.isHiddenPreFilled) {
        final ctrl = TextEditingController(
          text: field.value?.toString() ?? field.defaultValue?.toString() ?? '',
        );
        _controllers[field.name] = ctrl;
      }
    }
  }

  @override
  void didUpdateWidget(covariant DynamicFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool _isTextInput(DynamicFieldType t) {
    return t == DynamicFieldType.text ||
        t == DynamicFieldType.email ||
        t == DynamicFieldType.phone ||
        t == DynamicFieldType.password ||
        t == DynamicFieldType.number ||
        t == DynamicFieldType.longText;
  }

  /// Validate and sync controller values into field.value, returns true if valid.
  bool validate() {
    // Sync controller text into field values.
    for (final field in widget.fields) {
      if (field.isHiddenPreFilled) continue;
      final ctrl = _controllers[field.name];
      if (ctrl != null) {
        final text = ctrl.text.trim();
        if (field.fieldType == DynamicFieldType.number) {
          field.value = num.tryParse(text);
        } else {
          field.value = text.isEmpty ? null : text;
        }
      }
    }
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final visibleFields = widget.fields.where((f) => !f.isHiddenPreFilled).toList();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          for (final field in visibleFields) ...[
            _buildField(field),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isSubmitting
                  ? null
                  : () {
                      if (validate()) widget.onSubmit();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.submitLabel ?? 'save'.tr,
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(DynamicFormField field) {
    switch (field.fieldType) {
      case DynamicFieldType.text:
      case DynamicFieldType.email:
      case DynamicFieldType.phone:
      case DynamicFieldType.password:
      case DynamicFieldType.number:
      case DynamicFieldType.longText:
        return _buildTextFormField(field);
      case DynamicFieldType.date:
        return _buildDateField(field);
      case DynamicFieldType.checkbox:
        return _buildCheckbox(field);
      case DynamicFieldType.radio:
        return _buildRadio(field);
      case DynamicFieldType.select:
      case DynamicFieldType.enumField:
        return _buildDropdown(field);
      case DynamicFieldType.cascade:
        return _buildDropdown(field); // simplified cascade
      case DynamicFieldType.file:
        return const SizedBox.shrink(); // file upload not handled here
      case DynamicFieldType.htmlEditor:
        return _buildTextFormField(field); // fallback to text
    }
  }

  Widget _buildTextFormField(DynamicFormField field) {
    final ctrl = _controllers[field.name]!;
    return TextFormField(
      controller: ctrl,
      obscureText: field.fieldType == DynamicFieldType.password,
      keyboardType: _keyboardType(field.fieldType),
      maxLines: field.fieldType == DynamicFieldType.longText ? 4 : 1,
      decoration: InputDecoration(
        labelText: field.label,
        labelStyle: GoogleFonts.ubuntu(),
        suffixText: field.isOptional ? '(${'optional'.tr})' : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: GoogleFonts.ubuntu(),
      validator: (v) {
        if (!field.isRequired && field.isOptional) return null;
        if (field.isRequired && (v == null || v.trim().isEmpty)) {
          return 'required_field'.tr;
        }
        if (field.minLength != null && v != null && v.trim().length < field.minLength!) {
          return '${'min_length'.tr}: ${field.minLength}';
        }
        if (field.maxLength != null && v != null && v.trim().length > field.maxLength!) {
          return '${'max_length'.tr}: ${field.maxLength}';
        }
        return null;
      },
    );
  }

  TextInputType _keyboardType(DynamicFieldType t) {
    switch (t) {
      case DynamicFieldType.email:
        return TextInputType.emailAddress;
      case DynamicFieldType.phone:
        return TextInputType.phone;
      case DynamicFieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  Widget _buildDateField(DynamicFormField field) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          initialDate: field.value is DateTime ? field.value : DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: ColorPages.COLOR_PRINCIPAL),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => field.value = DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: GoogleFonts.ubuntu(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          suffixIcon: const Icon(Iconsax.calendar_1, size: 20),
        ),
        child: Text(
          field.value?.toString() ?? '',
          style: GoogleFonts.ubuntu(),
        ),
      ),
    );
  }

  Widget _buildCheckbox(DynamicFormField field) {
    return SwitchListTile(
      value: field.value == true,
      title: Text(field.label, style: GoogleFonts.ubuntu()),
      activeColor: ColorPages.COLOR_PRINCIPAL,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => field.value = v),
    );
  }

  Widget _buildRadio(DynamicFormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(field.label, style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade700)),
        ),
        ...field.options.map((opt) => RadioListTile<String>(
              value: opt.id,
              groupValue: field.value?.toString(),
              title: Text(opt.displayValue, style: GoogleFonts.ubuntu()),
              activeColor: ColorPages.COLOR_PRINCIPAL,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => field.value = v),
            )),
      ],
    );
  }

  Widget _buildDropdown(DynamicFormField field) {
    final currentId = field.value?.toString();
    final validIds = field.options.map((o) => o.id).toSet();
    final effectiveValue = validIds.contains(currentId) ? currentId : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: field.label,
        labelStyle: GoogleFonts.ubuntu(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: GoogleFonts.ubuntu(color: Colors.black87, fontSize: 14),
      items: field.options
          .map((o) => DropdownMenuItem<String>(
                value: o.id,
                child: Text(o.displayValue, style: GoogleFonts.ubuntu()),
              ))
          .toList(),
      onChanged: (v) => setState(() => field.value = v),
      validator: (v) {
        if (field.isRequired && (v == null || v.isEmpty)) {
          return 'required_field'.tr;
        }
        return null;
      },
    );
  }
}
