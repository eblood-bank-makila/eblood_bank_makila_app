import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme/ColorPages.dart';

class PinInputField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final void Function(String)? onComplete;
  
  const PinInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: length,
        textAlign: TextAlign.center,
        style: GoogleFonts.ubuntu(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          hintText: "• • • • • •",
          hintStyle: GoogleFonts.ubuntu(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade300,
          ),
        ),
        onChanged: (value) {
          if (value.length == length && onComplete != null) {
            onComplete!(value);
          }
        },
      ),
    );
  }
}