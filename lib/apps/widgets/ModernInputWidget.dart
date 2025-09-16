import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme/ColorPages.dart';

enum ModernInputType {
  text,
  email,
  password,
  phone,
  number,
  multiline,
}

class ModernInputWidget extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ModernInputType inputType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool showCharacterCount;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final bool floatingLabel;
  final bool dense;

  const ModernInputWidget({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputType = ModernInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.initialValue,
    this.showCharacterCount = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.floatingLabel = true,
    this.dense = false,
  });

  @override
  State<ModernInputWidget> createState() => _ModernInputWidgetState();
}

class _ModernInputWidgetState extends State<ModernInputWidget>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  TextInputType _getKeyboardType() {
    switch (widget.inputType) {
      case ModernInputType.email:
        return TextInputType.emailAddress;
      case ModernInputType.phone:
        return TextInputType.phone;
      case ModernInputType.number:
        return TextInputType.number;
      case ModernInputType.multiline:
        return TextInputType.multiline;
      case ModernInputType.password:
      case ModernInputType.text:
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.inputType) {
      case ModernInputType.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];
      case ModernInputType.number:
        return [
          FilteringTextInputFormatter.digitsOnly,
        ];
      default:
        return [];
    }
  }

  Widget? _buildSuffixIcon() {
    if (widget.inputType == ModernInputType.password) {
      return IconButton(
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            key: ValueKey(_isPasswordVisible),
            color: _isFocused 
                ? (widget.focusedBorderColor ?? ColorPages.COLOR_PRINCIPAL)
                : Colors.grey.shade600,
          ),
        ),
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.fillColor ?? Colors.grey.shade50;
    final borderColor = widget.borderColor ?? Colors.grey.shade300;
    final focusedBorderColor = widget.focusedBorderColor ?? ColorPages.COLOR_PRINCIPAL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: _handleFocusChange,
          child: AnimatedBuilder(
            animation: _focusAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: focusedBorderColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  initialValue: widget.initialValue,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  obscureText: widget.inputType == ModernInputType.password && !_isPasswordVisible,
                  keyboardType: _getKeyboardType(),
                  inputFormatters: _getInputFormatters(),
                  maxLines: widget.inputType == ModernInputType.password ? 1 : widget.maxLines,
                  maxLength: widget.maxLength,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: widget.validator,
                  style: widget.textStyle ?? GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: widget.enabled ? Colors.black87 : Colors.grey.shade600,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hintText,
                    helperText: widget.helperText,
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused 
                                ? focusedBorderColor
                                : Colors.grey.shade600,
                          )
                        : null,
                    suffixIcon: _buildSuffixIcon(),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: widget.contentPadding ?? 
                        EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: widget.dense ? 12 : 16,
                        ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: focusedBorderColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    labelStyle: widget.labelStyle ?? GoogleFonts.ubuntu(
                      color: _isFocused 
                          ? focusedBorderColor
                          : Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    hintStyle: GoogleFonts.ubuntu(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    helperStyle: GoogleFonts.ubuntu(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    counterStyle: GoogleFonts.ubuntu(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    floatingLabelBehavior: widget.floatingLabel 
                        ? FloatingLabelBehavior.auto
                        : FloatingLabelBehavior.never,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showCharacterCount && widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Specialized input widgets for common use cases
class ModernUsernameInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const ModernUsernameInput({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernInputWidget(
      label: 'Nom d\'utilisateur',
      hintText: 'Entrez votre nom d\'utilisateur',
      prefixIcon: Icons.person_outline,
      inputType: ModernInputType.text,
      controller: controller,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre nom d\'utilisateur';
        }
        if (value.length < 3) {
          return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
        }
        return null;
      },
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.next,
    );
  }
}

class ModernPasswordInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final String? label;
  final String? hintText;

  const ModernPasswordInput({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.label,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return ModernInputWidget(
      label: label ?? 'Mot de passe',
      hintText: hintText ?? 'Entrez votre mot de passe',
      prefixIcon: Icons.lock_outline,
      inputType: ModernInputType.password,
      controller: controller,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre mot de passe';
        }
        if (value.length < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        return null;
      },
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.done,
    );
  }
}

class ModernEmailInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const ModernEmailInput({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernInputWidget(
      label: 'Adresse e-mail',
      hintText: 'exemple@email.com',
      prefixIcon: Icons.email_outlined,
      inputType: ModernInputType.email,
      controller: controller,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre adresse e-mail';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Veuillez entrer une adresse e-mail valide';
        }
        return null;
      },
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.next,
    );
  }
}

class ModernPhoneInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;

  const ModernPhoneInput({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernInputWidget(
      label: 'Numéro de téléphone',
      hintText: '+243 XXX XXX XXX',
      prefixIcon: Icons.phone_outlined,
      inputType: ModernInputType.phone,
      controller: controller,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre numéro de téléphone';
        }
        if (value.length < 9) {
          return 'Veuillez entrer un numéro de téléphone valide';
        }
        return null;
      },
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: TextInputAction.next,
    );
  }
}
