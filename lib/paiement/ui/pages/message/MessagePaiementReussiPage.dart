import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OpsSuccessScreen extends StatefulWidget {
  final message;
  final title;
  final VoidCallback onClosing;
  final bool hidde_all_btn;

  const OpsSuccessScreen(
      {super.key,
      required this.message,
      required this.onClosing,
      this.title = "Opération Réussie !",
      required this.hidde_all_btn});

  @override
  State<OpsSuccessScreen> createState() => _OpsSuccessScreenState();
}

class _OpsSuccessScreenState extends State<OpsSuccessScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: [
          const SizedBox(
            height: 40.0,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
            child: Column(
              children: [
                FadeInDown(
                  from: 60,
                  // delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 60.0,
                        width: 60.0,
                        child: SvgPicture.string(
                          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
                            <path fill-rule="evenodd" d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12a4.49 4.49 0 01-1.549 3.397 4.491 4.491 0 01-1.307 3.497 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clip-rule="evenodd" />
                          </svg>

                        ''',
                          color: Color.fromRGBO(56, 142, 60, 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30.0,
                ),
                FadeInUp(
                  from: 70,
                  // delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "${widget.title}",
                          style: const TextStyle(
                              color: Color.fromRGBO(56, 142, 60, 1),
                              fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                FadeInUp(
                  from: 85,
                  // delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "${widget.message}",
                          style: const TextStyle(fontWeight: FontWeight.normal),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 25.0,
          ),
          if (widget.hidde_all_btn == false)
            FadeInUp(
              from: 90,
              // delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 1000),
              child: Row(
                children: [
                  if (widget.hidde_all_btn == false)
                    const SizedBox(
                      width: 20.0,
                    ),
                  if (widget.hidde_all_btn == false)
                    Flexible(
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.circular(10),
                        color: ColorPages.COLOR_PRINCIPAL,
                        child: MaterialButton(
                          onPressed: _isProcessing ? null : () {
                            // Prevent multiple taps
                            if (_isProcessing) return;

                            setState(() {
                              _isProcessing = true;
                            });

                            // Ensure the callback is not null and add proper error handling
                            try {
                              debugPrint('🔘 Fermer button pressed - executing onClosing callback');
                              // Add a small delay to prevent Navigator lock issues
                              Future.delayed(const Duration(milliseconds: 100), () {
                                widget.onClosing();
                                debugPrint('✅ onClosing callback executed successfully');
                              });
                            } catch (e) {
                              debugPrint('❌ Error in Fermer button onPressed: $e');
                              setState(() {
                                _isProcessing = false;
                              });
                            }
                          },
                          minWidth: double.infinity,
                          height: 50,
                          child: const Text(
                            "Fermer",
                            style: TextStyle(color: Colors.white, fontSize: 19),
                          ),
                        ),
                      ),
                    ),
                  if (widget.hidde_all_btn == false)
                    const SizedBox(
                      width: 20.0,
                    ),
                ],
              ),
            ),
          const SizedBox(
            height: 30.0,
          ),
        ],
      ),
    );
  }
}
