import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A text widget that automatically rebuilds when the app's language changes
class LanguageAwareText extends StatefulWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Map<String, String>? params;
  
  const LanguageAwareText(
    this.translationKey, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.params,
  }) : super(key: key);

  @override
  State<LanguageAwareText> createState() => _LanguageAwareTextState();
}

class _LanguageAwareTextState extends State<LanguageAwareText> {
  String? _currentLocale;
  
  @override
  void initState() {
    super.initState();
    _currentLocale = Get.locale?.toString();
    
    // We'll use didChangeDependencies to detect locale changes
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if locale changed and trigger a rebuild if needed
    final newLocale = Get.locale?.toString();
    if (newLocale != _currentLocale) {
      _currentLocale = newLocale;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use lowercase for translation key for consistency
    String translationKey = widget.translationKey.toLowerCase();
    
    // Apply translation parameters if provided
    String translatedText = translationKey.tr;
    
    if (widget.params != null) {
      widget.params!.forEach((key, value) {
        translatedText = translatedText.replaceAll('@$key', value);
      });
    }
    
    return Text(
      translatedText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}