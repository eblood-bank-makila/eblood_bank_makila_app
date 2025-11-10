import 'dart:math';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/BottomNavBarWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanquePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/authentification/AuthentificationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfileCtrl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;


import '../../../../apps/config/utils/AppFullContentSpin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthentificationEmpreintePage extends ConsumerStatefulWidget {
  const AuthentificationEmpreintePage({super.key});

  @override
  ConsumerState createState() => _AuthentificationEmpreintePageState();
}

class _AuthentificationEmpreintePageState
    extends ConsumerState<AuthentificationEmpreintePage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _activity_id_running = false;
  String authorized = '';
  bool isAuthenticating = false;
  late BuildContext _ctx;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        isAuthenticating = true;
        authorized = 'Authentification';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Accéder à l\'application par votre empreinte',

        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      if (mounted) {
        setState(() {
          isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        isAuthenticating = false;
        authorized = 'Error - ${e.message}';
      });
      String message =
          "Veuillez activer la sécurité dans vos paramètres, ou relancer l'application si c'est déjà fait";
      if (e.code == auth_error.notEnrolled) {
        // Aucune biométrie enregistrée
        if (kDebugMode) {
          print('Error - notEnrolled - ${e.message}');
        }
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        // Bloqué
        if (kDebugMode) {
          print('Error - lockedOut/permanentlyLockedOut - ${e.message}');
        }
      } else {
        if (kDebugMode) {
          print('Error - others - ${e.message}');
        }
      }

      // Affichage du SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 9000),
          backgroundColor: ColorPages.COLOR_NOIR,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    if (authenticated) {
      // Navigate to the new page directly
      Navigator.of(_ctx).pushReplacement(
        CupertinoPageRoute(
          builder: (BuildContext context) => HospitalBottomNavBarWidget(),
          fullscreenDialog: true,
        ),
      );
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: const Text("L'authentification ne semble pas réussir"),
      //     duration: const Duration(milliseconds: 9000),
      //     backgroundColor: ColorPages.COLOR_NOIR,
      //   ),
      // );
    }
    // if (authenticated) {
    //   Future.delayed(const Duration(milliseconds: 300), () {
    //     Navigator.of(_ctx).pushAndRemoveUntil(
    //         CupertinoPageRoute(
    //             builder: (BuildContext context) => Banquepage(),
    //             fullscreenDialog: true),
    //         (Route<dynamic> route) => false);
    //   });
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: const Text("L'authentification ne semble pas réussir"),
    //       duration: const Duration(milliseconds: 9000),
    //       backgroundColor: ColorPages.COLOR_BLANCHE,
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    return Scaffold(
      backgroundColor: ColorPages.COLOR_BLANCHE,
      body: AppFullcontentSpin(
        activity_is_running: _activity_id_running,
        message: '',
        child: Container(
          constraints: const BoxConstraints.expand(),
          padding: const EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 32.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: [
                        Container(
                            margin: const EdgeInsets.symmetric(vertical: 15.0),
                            height: 120.0,
                            width: 120.0,
                            child: const Center(
                              child: CircleAvatar(
                                radius: 30.0,
                                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                backgroundImage: AssetImage('assets/images/logo.png'),
                              ),
                            )),
                      ],
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          const Text(
                            "Vérrouillage",
                            style: TextStyle(
                                color: ColorPages.COLOR_PRINCIPAL,
                                fontSize: 22.0,
                                fontWeight: FontWeight.w700),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 22.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      if (kDebugMode) {
                                        print("resent...");
                                      }
                                    },
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: const TextSpan(
                                        text:
                                            'Pour limiter les accès inappropriés à vos données, le déverrouillage est requis avant de continuer.',
                                        style: TextStyle(
                                          color: ColorPages.COLOR_NOIR,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text:
                                                  ' \n appuyez sur déverouiller ici',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    ColorPages.COLOR_PRINCIPAL,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 25.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _activity_id_running == false
                                ? OutlinedButton.icon(
                                    icon: const Icon(
                                      Iconsax.lock,
                                      color: ColorPages.COLOR_PRINCIPAL,
                                      size: 18.0,
                                    ),
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all(
                                            const StadiumBorder()),
                                        side: MaterialStateProperty.all(
                                            const BorderSide(
                                                color:
                                                    ColorPages.COLOR_PRINCIPAL,
                                                width: 1.0,
                                                style: BorderStyle.solid))),
                                    onPressed: () {
                                      _authenticate();
                                    },
                                    label: const Text(
                                      'Déverrouillez ici',
                                      style: TextStyle(
                                          color: ColorPages.COLOR_PRINCIPAL,
                                          fontSize: 19.0),
                                    ),
                                  )
                                : const CircularProgressIndicator(
                                    strokeWidth: 1.0,
                                    backgroundColor: Colors.white,
                                  ),
                          ),

                          const SizedBox(
                            height: 50.0,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 30.0),
                            child: Text(
                              'Utilisez le mode de déverrouillage configuré dans votre téléphone.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: ColorPages.COLOR_NOIR, fontSize: 17.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 22.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    height: 30.0,
                                    width: 30.0,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.0,
                                          color: const Color.fromARGB(
                                              255, 219, 219, 219),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0)),
                                    child: Center(
                                        child: SvgPicture.string(
                                      ''' <svg   viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg"><title/><path d="M64,24A12,12,0,1,1,76,12,12,12,0,0,1,64,24ZM64,4a8,8,0,1,0,8,8A8,8,0,0,0,64,4Z"/><path d="M64,128a12,12,0,1,1,12-12A12,12,0,0,1,64,128Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,64,108Z"/><path d="M64,58.67a12,12,0,1,1,12-12A12,12,0,0,1,64,58.67Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,64,38.67Z"/><path d="M64,93.33a12,12,0,1,1,12-12A12,12,0,0,1,64,93.33Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,64,73.33Z"/><path d="M29,24A12,12,0,1,1,41,12,12,12,0,0,1,29,24ZM29,4a8,8,0,1,0,8,8A8,8,0,0,0,29,4Z"/><path d="M29,58.67a12,12,0,1,1,12-12A12,12,0,0,1,29,58.67Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,29,38.67Z"/><path d="M29,93.33a12,12,0,1,1,12-12A12,12,0,0,1,29,93.33Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,29,73.33Z"/><path d="M99,24a12,12,0,1,1,12-12A12,12,0,0,1,99,24ZM99,4a8,8,0,1,0,8,8A8,8,0,0,0,99,4Z"/><path d="M99,58.67a12,12,0,1,1,12-12A12,12,0,0,1,99,58.67Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,99,38.67Z"/><path d="M99,93.33a12,12,0,1,1,12-12A12,12,0,0,1,99,93.33Zm0-20a8,8,0,1,0,8,8A8,8,0,0,0,99,73.33Z"/>
                                                      </svg>
                                                      ''',
                                      color: const Color.fromARGB(
                                          255, 219, 219, 219),
                                      fit: BoxFit.cover,
                                      height: 17.0,
                                      width: 17.0,
                                    ))),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Container(
                                    height: 30.0,
                                    width: 30.0,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.0,
                                          color: const Color.fromARGB(
                                              255, 219, 219, 219),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0)),
                                    child: const Center(
                                        child: Icon(
                                      Ionicons.finger_print_outline,
                                      size: 18.0,
                                      color: Color.fromARGB(255, 219, 219, 219),
                                    ))),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Container(
                                    height: 30.0,
                                    width: 30.0,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.0,
                                          color: const Color.fromARGB(
                                              255, 219, 219, 219),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0)),
                                    child: Center(
                                        child: SvgPicture.string(
                                      '''<svg fill="none" height="15" viewBox="0 0 15 15" width="15" xmlns="http://www.w3.org/2000/svg"><path clip-rule="evenodd" d="M2.5 1C1.67157 1 1 1.67157 1 2.5V5H0V2.5C0 1.11929 1.11929 0 2.5 0H5V1H2.5ZM12.5 1H10V0H12.5C13.8807 0 15 1.11929 15 2.5V5H14V2.5C14 1.67157 13.3284 1 12.5 1ZM5 6H4V5H5V6ZM11 6H10V5H11V6ZM4.9 8.7C6.2 10.4333 8.8 10.4333 10.1 8.7L10.9 9.3C9.2 11.5667 5.8 11.5667 4.1 9.3L4.9 8.7ZM0 12.5V10H1V12.5C1 13.3284 1.67157 14 2.5 14H5V15H2.5C1.11929 15 0 13.8807 0 12.5ZM15 10V12.5C15 13.8807 13.8807 15 12.5 15H10V14H12.5C13.3284 14 14 13.3284 14 12.5V10H15Z" fill="black" fill-rule="evenodd"/>
                                                </svg>
                                                      ''',
                                      color: const Color.fromARGB(
                                          255, 219, 219, 219),
                                      fit: BoxFit.cover,
                                      height: 17.0,
                                      width: 17.0,
                                    ))),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Container(
                                    height: 30.0,
                                    width: 30.0,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 1.0,
                                          color: const Color.fromARGB(
                                              255, 219, 219, 219),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15.0)),
                                    child: const Center(
                                        child: Icon(
                                      Ionicons.ellipsis_horizontal_outline,
                                      color: Color.fromARGB(255, 219, 219, 219),
                                    ))),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(vertical:8.0,horizontal: 22.0),
                          //   child: Text('Entrez votre pin afin de déverrouiller l\'application; si vous l\'avez oublié appuyez sur renvoyer mon pin.',
                          //     textAlign: TextAlign.center,
                          //     style: TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 17.0

                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _activity_id_running == false
                        ? OutlinedButton.icon(
                            icon: const Icon(
                              Ionicons.power_outline,
                              color: ColorPages.COLOR_PRINCIPAL,
                              size: 19.0,
                            ),
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                    const StadiumBorder()),
                                side: MaterialStateProperty.all(
                                    const BorderSide(
                                        color: ColorPages.COLOR_PRINCIPAL,
                                        width: 1.0,
                                        style: BorderStyle.solid))),
                            //  style: OutlinedButton.styleFrom(
                            //     side: BorderSide(
                            //       width: 1.0, color: Colors.orange),
                            //   ),
                            onPressed: () => BoiteDeconnexion(context),
                            label: const Text(
                              'Déconnexion',
                              style:
                                  TextStyle(color: ColorPages.COLOR_PRINCIPAL),
                            ),
                          )
                        : const CircularProgressIndicator(
                            strokeWidth: 1.0,
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                          ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.copyright,
                          size: 14, color: ColorPages.COLOR_PRINCIPAL),
                      const SizedBox(
                        width: 5.0,
                      ),
                      RichText(
                        text: const TextSpan(
                            text: "E-Blood Bank",
                            style: TextStyle(
                              color: ColorPages.COLOR_PRINCIPAL,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            children: <InlineSpan>[
                              TextSpan(
                                  text: " Makila",
                                  style: TextStyle(
                                      color: ColorPages.COLOR_PRINCIPAL,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logoutFromApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous confirmer la déconnexion ?'),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme le dialogue
                Future.delayed(const Duration(milliseconds: 400), () {
                  confirmLogout();
                });
              },
              icon: const Icon(
                Icons.check,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
              style: ButtonStyle(
                shape: MaterialStateProperty.all(const StadiumBorder()),
                side: MaterialStateProperty.all(const BorderSide(
                  color: ColorPages.COLOR_BLANCHE,
                  width: 1.0,
                  style: BorderStyle.solid,
                )),
              ),
              label: const Text(
                'Oui',
                style: TextStyle(color: ColorPages.COLOR_BLANCHE),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(), // Ferme le dialogue
              style: ButtonStyle(
                shape: MaterialStateProperty.all(const StadiumBorder()),
                side: MaterialStateProperty.all(const BorderSide(
                  color: ColorPages.COLOR_BLANCHE,
                  width: 1.0,
                  style: BorderStyle.solid,
                )),
              ),
              icon: const Icon(
                Ionicons.close,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
              label: const Text(
                'Non',
                style: TextStyle(color: ColorPages.COLOR_BLANCHE),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> BoiteDeconnexion(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          backgroundColor: Colors.white,
          content: Text(
            "Êtes-vous sûr de vouloir vous déconnecter ?",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 110.0, // Width of the button
                    height: 40.0, // Height of the button
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_BLANCHE, // Background color
                      border: Border.all(
                        color: ColorPages.COLOR_PRINCIPAL, // Border color
                        width: 1.0, // Border thickness
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, false); // Close with false
                      },
                      child: Text(
                        "Annuler", // Cancel text
                        style: TextStyle(
                          color: ColorPages.COLOR_PRINCIPAL, // Text color
                          fontSize: 14, // Font size
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 120.0, // Width of the button
                    height: 40.0, // Height of the button
                    color: ColorPages.COLOR_PRINCIPAL, // Background color
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(
                            context, true); // Ferme la boîte de dialogue
                      },
                      child: Text(
                        "Déconnexion", // Delete text
                        style: TextStyle(
                          color: ColorPages.COLOR_BLANCHE, // Text color
                          fontSize: 14, // Font size
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      setState(() {
        _isLoading = true; // Démarre le chargement
      });

      var dis = ref.read(profileCtrlProvider.notifier);
      var rep = await dis.disconnect();
      setState(() {
        _isLoading = false; // Arrête le chargement
      });
      if (rep) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => AuthentificationPage()));
      }
    }
  }

  bool activity_is_running = false;
  String activity_is_running_message = 'en cours...';

  confirmLogout() async {
    // Simulation d'une déconnexion réussie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Déconnexion réussie"),
        duration: const Duration(seconds: 2),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
      ),
    );

    // Remplacez la navigation par défaut
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthentificationPage()),
      (Route<dynamic> route) => false,
    );
  }

  deleteAllLocalStorage() async {
    try {
      // Simulation de la suppression des données locales
      activity_is_running = false;
      setState(() {});

      // Navigation vers Banquepage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Banquepage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      activity_is_running = false;
      setState(() {});
      // En cas d'erreur, naviguer vers Banquepage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Banquepage()),
        (Route<dynamic> route) => false,
      );
    }
  }
}
