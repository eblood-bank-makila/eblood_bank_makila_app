import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../apps/config/theme/ColorPages.dart';

class PhoneNumberBottomSheet extends StatefulWidget {
  final Function(String phoneNumber) onPhoneNumberSubmitted;

  const PhoneNumberBottomSheet({
    Key? key,
    required this.onPhoneNumberSubmitted,
  }) : super(key: key);

  @override
  State<PhoneNumberBottomSheet> createState() => _PhoneNumberBottomSheetState();
}

class _PhoneNumberBottomSheetState extends State<PhoneNumberBottomSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    
    // Remove any spaces or special characters
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid DRC mobile number (9 digits after country code)
    if (cleanNumber.length < 9) {
      return 'Numéro de téléphone trop court';
    }
    
    if (cleanNumber.length > 12) {
      return 'Numéro de téléphone trop long';
    }
    
    // Check if it starts with valid DRC mobile prefixes
    List<String> validPrefixes = ['81', '82', '83', '84', '85', '89', '90', '91', '92', '93', '94', '95', '96', '97', '98', '99'];
    bool hasValidPrefix = false;
    
    for (String prefix in validPrefixes) {
      if (cleanNumber.startsWith(prefix) || cleanNumber.startsWith('243$prefix')) {
        hasValidPrefix = true;
        break;
      }
    }
    
    if (!hasValidPrefix) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present
    if (!cleanNumber.startsWith('243')) {
      cleanNumber = '243$cleanNumber';
    }
    
    return cleanNumber;
  }

  void _submitPhoneNumber() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String formattedNumber = _formatPhoneNumber(_phoneController.text);

      // Simulate a small delay for better UX
      Future.delayed(const Duration(milliseconds: 500), () {
        // Only call the callback - the parent will handle closing the bottom sheet
        widget.onPhoneNumberSubmitted(formattedNumber);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Numéro de téléphone Mobile Money',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Entrez votre numéro de téléphone pour effectuer le paiement via Mobile Money',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: _validatePhoneNumber,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: 'Ex: 243991234567 ou 991234567',
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assurez-vous que votre compte Mobile Money a suffisamment de fonds',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'CONFIRMER LE PAIEMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                
                // Cancel button
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
