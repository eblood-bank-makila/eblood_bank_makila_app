import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ModernSpinnerWidget.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/authentification/AuthentificationCtrl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/ReinitialiserMotDePassePage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthentificationPage extends ConsumerStatefulWidget {
  const AuthentificationPage({super.key});

  @override
  ConsumerState createState() => _AuthentificationPageState();
}

class _AuthentificationPageState extends ConsumerState<AuthentificationPage> {
  bool isPassword = true;
  bool isVisible = false;
  bool _hasInitialized = false;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController _utilisateur = TextEditingController();
  TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // action initiale de la page et appel d'un controleur
        var ctrl = ref.read(authentificationCtrlProvider.notifier);
        ctrl.readLocalToken();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [_body(context), _chargement(context)],
    ));
  }

  Widget _body(BuildContext context) {
    return Form(
      key: formkey,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image3.webp'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // Contenu de la page
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInUp(
                    key: const ValueKey('logo_animation'),
                    duration: const Duration(milliseconds: 500),
                    child: Image.asset('assets/images/image2.png', width: 100)),
                SizedBox(height: 20),
                SizedBox(height: 40),
                FadeInUp(
                  key: const ValueKey('username_field_animation'),
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      controller: _utilisateur,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          color: ColorPages.COLOR_BLANCHE,
                        ),
                        hintText: 'Nom d\'utilisateur',
                        hintStyle:
                            TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom d\'utilisateur*';
                        }

                        return null; // Si tout est bon, retourner null
                      },
                    ),
                  ),
                ),
                // Close the removed FadeInUp
                SizedBox(height: 20),
                FadeInUp(
                  key: const ValueKey('password_field_animation'),
                  duration: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      controller: _password,
                      obscureText: isPassword,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: ColorPages.COLOR_BLANCHE,
                          ),
                          onPressed: () {
                            isPassword = !isPassword;
                            setState(() {});
                          },
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: ColorPages.COLOR_BLANCHE,
                        ),
                        hintText: 'Mot de passe',
                        hintStyle:
                            TextStyle(color: Colors.white54, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe*';
                        }
                        if (value.length < 3) {
                          return 'Le mot de passe doit contenir au moins 8 caractères*';
                        }
                        return null; // Si tout est bon, retourner null
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                FadeInUp(
                  key: const ValueKey('forgot_password_animation'),
                  duration: const Duration(milliseconds: 800),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ReinitialiserMotDePassePage()));
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                FadeInUp(
                  key: const ValueKey('login_button_animation'),
                  duration: const Duration(milliseconds: 900),
                  child: Container(
                    width: 300,
                    height: 50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(

                        onPressed: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          if (!formkey.currentState!.validate()) {
                            return;
                          }
                          var ctrl = ref.read(authentificationCtrlProvider.notifier);
                          var resultat = await ctrl.authenticate(_utilisateur.text, _password.text);
                          print('Résultat de l\'API: $resultat');

                          if (resultat != null && resultat.token.isNotEmpty) {
                            print('✅ Login successful, redirecting to OTP page');
                            if (mounted) {
                              context.go('/auth/OtpCodePage');
                            }
                          } else {
                            print('❌ Login failed, showing error message');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Échec de l\'authentification - Vérifiez vos identifiants')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPages.COLOR_PRINCIPAL,
                          elevation: 0,
                          side: BorderSide(
                            color: ColorPages.COLOR_PRINCIPAL,
                            // Couleur du bord
                            width: 2.0, // Épaisseur du bord
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.input,
                              color: ColorPages.COLOR_BLANCHE,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'S\'identifier',
                              style: TextStyle(color: ColorPages.COLOR_BLANCHE),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // FadeInUp(
                //   duration: const Duration(milliseconds: 500),
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(horizontal: 30.0),
                //     child: Material(
                //       elevation: 0,
                //       borderRadius: BorderRadius.circular(10),
                //       color: ColorPages.COLOR_PRINCIPAL,
                //       child: MaterialButton(
                //         onPressed: () {
                //           Navigator.of(context)
                //               .pushReplacementNamed('/dashboard');
                //         },
                //         minWidth: double.infinity,
                //         height: 40,
                //         child: const Text(
                //           "Connexion",
                //           style: TextStyle(color: Colors0.white, fontSize: 19),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargement(BuildContext context) {
    // Use select to only watch the isLoading property to prevent unnecessary rebuilds
    final isLoading = ref.watch(authentificationCtrlProvider.select((state) => state.isLoading));
    return ModernLoadingOverlay(
      isVisible: isLoading,
      message: 'Connexion en cours...',
      spinnerType: SpinnerType.bloodDrop,
      spinnerColor: ColorPages.COLOR_PRINCIPAL,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
    );
  }
}
