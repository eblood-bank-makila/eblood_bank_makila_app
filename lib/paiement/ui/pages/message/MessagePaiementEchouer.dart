import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OpsErrorScreen extends StatelessWidget {
  final message;
  final title;
  final VoidCallback onClosing;
  final VoidCallback goBack;
  final bool can_show_go_back_btn;
  final bool hidde_all_btn;
  final String? ref;
  final List<String>? errorMessages;


  const OpsErrorScreen({
      super.key,
      required this.message,
      required this.onClosing,
      required this.goBack,
      this.can_show_go_back_btn = false,
      this.title,
      required this.hidde_all_btn,
      this.ref,
      this.errorMessages,
    });

  @override
  Widget build(BuildContext context) {
    // Set status bar style to dark (black icons/text) for light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade100,
            Colors.red.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60.0),

          // Icon Badge
          FadeInDown(
            from: 60,
            duration: const Duration(milliseconds: 900),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30.0),

          // Title
          FadeInUp(
            from: 70,
            duration: const Duration(milliseconds: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                title ?? 'operation_failed'.tr,
                style: const TextStyle(
                  color: ColorPages.COLOR_PRINCIPAL,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Message
          FadeInUp(
            from: 85,
            duration: const Duration(milliseconds: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Info Card
          if (ref != null || (errorMessages != null && errorMessages!.isNotEmpty)) ...[
            const SizedBox(height: 24),
            FadeInUp(
              from: 90,
              duration: const Duration(milliseconds: 1000),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ref != null) ...[
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'reference'.tr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ref!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'copy'.tr,
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: ref!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('reference_copied'.tr)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    if (errorMessages != null && errorMessages!.isNotEmpty) ...[
                      if (ref != null) const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'details'.tr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...errorMessages!.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: ColorPages.COLOR_PRINCIPAL,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Button
          if (hidde_all_btn == false)
            FadeInUp(
              from: 90,
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: ColorPages.COLOR_PRINCIPAL,
                  child: MaterialButton(
                    onPressed: () {
                      try {
                        debugPrint('🔘 Close button pressed (Error screen)');
                        Future.delayed(const Duration(milliseconds: 100), () {
                          onClosing();
                        });
                      } catch (e) {
                        debugPrint('❌ Error: $e');
                      }
                    },
                    minWidth: double.infinity,
                    height: 54,
                    child: Text(
                      'close'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40.0),
        ],
      ),
    );
  }
}

