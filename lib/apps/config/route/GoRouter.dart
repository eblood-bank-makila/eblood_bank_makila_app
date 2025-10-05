import 'package:eblood_bank_mak_app/apps/autres/AproposPage.dart';
import 'package:eblood_bank_mak_app/apps/config/route/Routes.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/ModernSplashPage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/IntroSlidePage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/WelcomePage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/ModernLoginPage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/RegisterWelcomePage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/AccountTypeSelectionPage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/PersonalRegistrationPage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/HealthStructureRegistrationPage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/BloodBankRegistrationPage.dart';
import 'package:eblood_bank_mak_app/apps/debug/FirstLaunchDebugScreen.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AccountTypeBasedNavigation.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ConsumerMainApp.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/widgets/BloodBankBottomNavWidget.dart';
import 'package:eblood_bank_mak_app/apps/widgets/DetailsPocheBanqueWidget.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/MessageCommadePage.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/banque/BanquePage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisPage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/poche/ListePocheBanquePage.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/authentification/AuthentificationPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/changerPassword/ChangerPasswordPage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/ReinitialiserMotDePassePage.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePage.dart';

import 'package:eblood_bank_mak_app/apps/services/FirebaseAuthService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../gestionStocks/business/model/banque/BanqueModele.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Use ref.read instead of ref.watch to prevent continuous rebuilds
  // The router will access these providers when needed, not watch them continuously
  final authProvider = ref.read(utilisateurInteractorProvider);
  final firebaseAuthService = ref.read(firebaseAuthServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      // Only perform expensive checks for specific routes to avoid rebuild loops
      final location = state.matchedLocation;

      // Always start with splash screen, let it handle navigation
      if (location == '/') {
        return '/splash';
      }

      // Only check authentication for app routes to avoid unnecessary async calls
      // But be more careful about when to redirect
      if (location.startsWith("/app") && location != '/app/MainApp') {
        try {
          var tokenOTP = await authProvider.recuperationTokenOtpUseCase.run();
          bool isFirebaseSignedIn = firebaseAuthService.isSignedIn;

          // Only redirect if we're sure the user is not authenticated
          if ((tokenOTP == null || tokenOTP.isEmpty) && !isFirebaseSignedIn) {
            debugPrint('🔒 GoRouter: Redirecting unauthenticated user from $location to /welcome');
            return '/welcome';
          }
        } catch (e) {
          debugPrint('🔒 GoRouter: Error checking auth for $location: $e');
          // Don't redirect on error, let the route handle it
        }
      }

      // No redirect needed for other routes
      return null;
    },
    routes: [
      // Modern Splash Screen (shows first for all users)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            const MaterialPage(child: ModernSplashPage()),
      ),

      // Intro slide route
      GoRoute(
        path: '/intro',
        pageBuilder: (context, state) =>
            const MaterialPage(child: IntroSlidePage()),
      ),

      // Welcome page route
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            const MaterialPage(child: WelcomePage()),
      ),

      // Modern Login page route
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const MaterialPage(child: ModernLoginPage()),
      ),

      // Register welcome page route
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            const MaterialPage(child: RegisterWelcomePage()),
      ),

      // Account type selection page route
      GoRoute(
        path: '/account-type-selection',
        pageBuilder: (context, state) =>
            const MaterialPage(child: AccountTypeSelectionPage()),
      ),

      // Personal registration page route
      GoRoute(
        path: '/personal-registration',
        pageBuilder: (context, state) =>
            const MaterialPage(child: PersonalRegistrationPage()),
      ),

      // Health Structure registration page route
      GoRoute(
        path: '/hospital-registration',
        pageBuilder: (context, state) =>
            const MaterialPage(child: HealthStructureRegistrationPage()),
      ),

      // Blood bank registration page route
      GoRoute(
        path: '/blood-bank-registration',
        pageBuilder: (context, state) =>
            const MaterialPage(child: BloodBankRegistrationPage()),
      ),

      // Health Structure verification page route
      GoRoute(
        path: '/verify-hospital',
        pageBuilder: (context, state) {
          // TODO: Create HealthStructureVerificationPage
          // For now, return to welcome page
          
          // Show a SnackBar after a short delay to ensure it's shown when the page is rendered
          Future.delayed(const Duration(milliseconds: 300), () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please verify your health structure with the code sent to your email.'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
          });
          
          return const MaterialPage(
            child: WelcomePage(),
          );
        },
      ),

      // Debug Screen for First Launch Testing
      GoRoute(
        path: '/debug/first-launch',
        pageBuilder: (context, state) =>
            const MaterialPage(child: FirstLaunchDebugScreen()),
      ),

      GoRoute(
          path: '/auth',
          pageBuilder: (context, state) =>
              const MaterialPage(child: ModernSplashPage()),
          routes: [
            GoRoute(
              path: 'AuthentificationPage',
              name: authentification,
              pageBuilder: (context, state) =>
                  const MaterialPage(child: AuthentificationPage()),
            ),
            GoRoute(
              path: 'ReinitialiserMotDePassePage',
              name: motDePasseOubiePage,
              pageBuilder: (context, state) =>
                  const MaterialPage(child: ReinitialiserMotDePassePage()),
            ),
          ]),
      GoRoute(
          path: '/app',
          name: appPage,
          pageBuilder: (context, state) => const MaterialPage(
                  child: Recherchepage(
                query: '',
              )),
          routes: [
            GoRoute(
              path: 'ModernSplash',
              name: splashPage2,
              pageBuilder: (context, state) =>
                  const MaterialPage(child: ModernSplashPage()),
            ),
            GoRoute(
              path: 'RecherchePage',
              name: recherchePage,
              pageBuilder: (context, stahente) => const MaterialPage(
                  child: Recherchepage(
                query: '',
              )),
            ),
            GoRoute(
              path: 'BanquePage',
              name: banquePage,
              pageBuilder: (context, state) =>
                  MaterialPage(child: Banquepage()),
            ),
            GoRoute(
              path: 'PanierPage',
              name: panierPage,
              pageBuilder: (context, state) =>
                  MaterialPage(child: PanierPage()),
            ),
            // Main app with account type-based navigation
            GoRoute(
              path: 'MainApp',
              name: bottomNavBarWidget,
              pageBuilder: (context, state) =>
                  const MaterialPage(child: AccountTypeBasedNavigation()),
            ),
            // Blood bank main app (exclusive profile)
            GoRoute(
              path: 'BloodBankMainApp',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: BloodBankBottomNavWidget()),
            ),
            // Consumer main app (simple user, blood donor, and optionally delivery)
            GoRoute(
              path: 'ConsumerMainApp',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: ConsumerMainApp()),
            ),
            GoRoute(
              path: 'ProfilePage',
              name: profilePage,
              pageBuilder: (context, state) =>
                  MaterialPage(child: ProfilePage()),
            ),

            GoRoute(
              path: 'DetailPocheBanquePage',
              name: 'detailPocheBanquePage',
              pageBuilder: (context, state) {
                final poche =
                    state.extra as PocheModel; // Récupérez l'objet PocheModel
                final banque =
                    state.extra as BanqueModele; // Récupérez l'objet PocheModel
                final banqueNom = poche.bloodBagInfo.bloodTypeInfo
                    .bloodTypeName; // Ou récupérez le nom de la banque d'une autre manière
                return MaterialPage(
                  child: DetailPocheBanqueWidget(
                    poche: poche,
                    banqueNom: banqueNom,
                    banque: banque, // Passez le nom de la banque ici
                  ),
                );
              },
            ),
            GoRoute(
              path: 'ListePocheBanquePage',
              name: listePocheBanquePage,
              pageBuilder: (context, state) {
                final banque =
                    state.extra as BanqueModele; // Récupérer l'objet banque

                return MaterialPage(
                  child: ListePocheBanquePage(
                    banqueId: banque.id, // Passez le nom de la banque
                    banque: banque,
                    banqueNom: banque.blood_bank_name, // Passez l'objet banque
                    localisation: banque.townInfo.townName,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'MessageCommandePage',
              name: messageCommandePage,
              pageBuilder: (context, snntate) =>
                  MaterialPage(child: MessageCommandePage()),
            ),
            GoRoute(
              path: 'FavorisPage',
              name: favorisPage,
              pageBuilder: (context, state) {
                return MaterialPage(child: FavorisPage());
              },
            ),
            // GoRoute(
            //   path: 'NotificationPage',
            //   name: notificationPage,
            //   pageBuilder: (context, state) =>
            //       MaterialPage(child: NotificationPage()),
            // ),
            GoRoute(
              path: 'AproposPage',
              name: aproposPage,
              pageBuilder: (context, state) =>
                  MaterialPage(child: AproposPage()),
            ),
            GoRoute(
              path: 'ChangerPasswordPage',
              name: changerPasswordPage,
              pageBuilder: (context, state) =>
                  MaterialPage(child: ChangerPasswordPage()),
            ),
          ]),
    ],
  );
});
