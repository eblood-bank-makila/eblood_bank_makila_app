import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OpsErrorScreen extends StatelessWidget {
  final message;
  final title;
  final VoidCallback onClosing;
  final VoidCallback goBack;
  final bool can_show_go_back_btn;
  final bool hidde_all_btn;

  const OpsErrorScreen(
      {super.key,
        required this.message,
        required this.onClosing,
        required this.goBack,
        this.can_show_go_back_btn = false,
        this.title = "Echec de l'opération !",
        required this.hidde_all_btn});

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
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 60.0,
                        width: 60.0,
                        child: SvgPicture.string(
                          '''<svg fill="currentColor" xmlns="http://www.w3.org/2000/svg" height="1em" viewBox="0 0 512 512"><path d="M367.2 412.5L99.5 144.8C77.1 176.1 64 214.5 64 256c0 106 86 192 192 192c41.5 0 79.9-13.1 111.2-35.5zm45.3-45.3C434.9 335.9 448 297.5 448 256c0-106-86-192-192-192c-41.5 0-79.9 13.1-111.2 35.5L412.5 367.2zM0 256a256 256 0 1 1 512 0A256 256 0 1 1 0 256z"/>
                          </svg>
                        ''',
                          color: Colors.red,
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
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "$title",
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w800),
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
                  from: 80,
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "$message",
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
          if (hidde_all_btn == false)
            const SizedBox(
              height: 25.0,
            ),
          if (hidde_all_btn == false)
            FadeInDown(
              from: 90,
              delay: const Duration(milliseconds: 800),
              duration: const Duration(milliseconds: 1000),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (can_show_go_back_btn == true)
                    const SizedBox(
                      width: 20.0,
                    ),
                  if (can_show_go_back_btn == true)
                    Flexible(
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.circular(10),
                        color: ColorPages.COLOR_PRINCIPAL,
                        child: MaterialButton(
                          onPressed: () {
                            // Add a small delay to prevent Navigator lock issues
                            Future.delayed(const Duration(milliseconds: 100), () {
                              goBack();
                            });
                          },
                          minWidth: double.infinity,
                          height: 50,
                          child: const Text(
                            "Retour",
                            style: TextStyle(color: Colors.white, fontSize: 19),
                          ),
                        ),
                      ),
                    ),
                  if (can_show_go_back_btn == true)
                    const SizedBox(
                      width: 20.0,
                    ),
                  if (hidde_all_btn == false)
                    Flexible(
                      child: Material(
                        elevation: 0,
                        borderRadius: BorderRadius.circular(10),
                        color: ColorPages.COLOR_PRINCIPAL,
                        child: MaterialButton(
                          onPressed: () {
                            // Ensure proper error handling for the callback
                            try {
                              debugPrint('🔘 Fermer button pressed (Error screen) - executing onClosing callback');
                              // Add a small delay to prevent Navigator lock issues
                              Future.delayed(const Duration(milliseconds: 100), () {
                                onClosing();
                                debugPrint('✅ onClosing callback executed successfully (Error screen)');
                              });
                            } catch (e) {
                              debugPrint('❌ Error in Fermer button onPressed (Error screen): $e');
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
                  if (hidde_all_btn == false)
                    const SizedBox(
                      width: 20.0,
                    ),
                ],
              ),
            ),
          if (hidde_all_btn == false)
            const SizedBox(
              height: 30.0,
            ),
        ],
      ),
    );
  }
}

