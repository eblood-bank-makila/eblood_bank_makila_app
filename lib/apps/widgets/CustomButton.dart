import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final bool outlined;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.icon,
    this.outlined = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = backgroundColor ?? theme.primaryColor;
    final buttonTextColor = textColor ?? (outlined ? primaryColor : Colors.white);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: outlined ? _buildOutlinedButton(primaryColor, buttonTextColor) : _buildElevatedButton(primaryColor, buttonTextColor),
    );
  }

  Widget _buildElevatedButton(Color primaryColor, Color buttonTextColor) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: buttonTextColor,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[500],
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _buildButtonContent(buttonTextColor),
    );
  }

  Widget _buildOutlinedButton(Color primaryColor, Color buttonTextColor) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonTextColor,
        disabledForegroundColor: Colors.grey[500],
        side: BorderSide(
          color: isLoading ? Colors.grey[300]! : primaryColor,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _buildButtonContent(buttonTextColor),
    );
  }

  Widget _buildButtonContent(Color buttonTextColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            outlined ? Colors.grey[500]! : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: buttonTextColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.ubuntu(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: buttonTextColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.ubuntu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: buttonTextColor,
      ),
    );
  }
}
