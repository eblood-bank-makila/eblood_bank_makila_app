import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../services/LanguageService.dart';
import '../config/theme/ColorPages.dart';

/// Language selector widget for selecting app language
class LanguageSelector extends StatelessWidget {
  final bool showAsDropdown;
  final bool showLabel;
  final Color? backgroundColor;
  final Color? textColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final bool showBottomSheet;

  const LanguageSelector({
    super.key,
    this.showAsDropdown = false,
    this.showLabel = true,
    this.backgroundColor,
    this.textColor,
    this.iconSize,
    this.padding,
    this.compact = false,
    this.showBottomSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    if (showAsDropdown) {
      return _buildDropdownSelector(languageService);
    } else {
      return _buildButtonSelector(languageService, context);
    }
  }

  Widget _buildButtonSelector(LanguageService languageService, BuildContext context) {
    return Obx(() {
      final currentLang = languageService.currentLanguageInfo;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showBottomSheet ? () => _showLanguageBottomSheet(context) : languageService.toggleLanguage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (textColor ?? Colors.white).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLang['flag'] ?? '🏳️',
                style: TextStyle(fontSize: iconSize ?? 16),
              ),
              if (showLabel && !compact) ...[
                const SizedBox(width: 8),
                Text(
                  currentLang['name'] ?? 'Unknown',
                  style: GoogleFonts.ubuntu(
                    color: textColor ?? Colors.white,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (showBottomSheet) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor ?? Colors.white,
                  size: iconSize ?? 16,
                ),
              ],
            ],
          ),
        ),
      ),
      );
    });
  }

  Widget _buildDropdownSelector(LanguageService languageService) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: languageService.currentLanguage,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: textColor ?? Colors.black87,
            ),
            dropdownColor: backgroundColor ?? Colors.white,
            items: languageService.availableLanguages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang['code'],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    if (showLabel) Text(lang['name']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                languageService.changeLanguage(newValue);
              }
            },
          ),
        ),
      );
    });
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    // Check if we have a valid context and GetX is properly initialized
    if (!Get.isRegistered<LanguageService>()) {
      print('LanguageService not registered');
      return;
    }

    // Use Flutter's native showModalBottomSheet as it's more reliable
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => _buildLanguageBottomSheet(languageService, bottomSheetContext),
    );
  }

  Widget _buildLanguageBottomSheet(LanguageService languageService, BuildContext context) {
    return
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'select_language'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'choose_preferred_language'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // Language options
            Obx(() {
              return Column(
                children: languageService.availableLanguages.map((lang) {
                  final isSelected = languageService.currentLanguage == lang['code'];

                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        ),
                        child: Center(
                          child: Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        lang['name']!,
                        style: GoogleFonts.ubuntu(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        lang['nativeName']!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: ColorPages.COLOR_PRINCIPAL,
                            )
                          : null,
                      selected: isSelected,
                      selectedTileColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.05),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await languageService.changeLanguage(lang['code']!);
                        navigator.pop();

                        // Show success message using ScaffoldMessenger (more reliable than Get.snackbar)
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'language_changed'.tr,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      );
  }
}

/// Compact language selector for use in app bars
class CompactLanguageSelector extends StatelessWidget {
  final Color? iconColor;
  final bool showBottomSheet;
  
  const CompactLanguageSelector({
    super.key,
    this.iconColor,
    this.showBottomSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    return LanguageSelector(
      compact: true,
      showLabel: false,
      textColor: iconColor,
      iconSize: 18.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      showBottomSheet: showBottomSheet,
    );
  }
}

/// Language toggle button for quick switching between two languages
class LanguageToggleButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  
  const LanguageToggleButton({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    
    return Obx(() {
      final currentLang = languageService.currentLanguageInfo;
      
      return GestureDetector(
        onTap: languageService.toggleLanguage,
        child: Container(
          width: size ?? 40,
          height: size ?? 40,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: (textColor ?? Colors.white).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              currentLang['flag'] ?? '🏳️',
              style: TextStyle(fontSize: (size ?? 40) * 0.4),
            ),
          ),
        ),
      );
    });
  }
}
