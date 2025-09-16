import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/IntroSlidePage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/WelcomePage.dart';
import 'package:eblood_bank_mak_app/apps/demarrage/RegisterWelcomePage.dart';

void main() {
  group('Welcome System Tests', () {
    testWidgets('IntroSlidePage should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: IntroSlidePage(),
          ),
        ),
      );

      // Verify that the intro slide page renders
      expect(find.text('E-Blood Bank Makila'), findsOneWidget);
      expect(find.text('Connecter les banques de sang,\nhôpitaux et donneurs'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('WelcomePage should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WelcomePage(),
          ),
        ),
      );

      // Verify that the welcome page renders
      expect(find.text('Bienvenue !'), findsOneWidget);
      expect(find.text('Se connecter avec nom d\'utilisateur'), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Facebook'), findsOneWidget);
      expect(find.text('Continuer avec Twitter'), findsOneWidget);
      expect(find.text('S\'inscrire ici'), findsOneWidget);
    });

    testWidgets('RegisterWelcomePage should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterWelcomePage(),
          ),
        ),
      );

      // Verify that the register welcome page renders
      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('S\'inscrire avec nom d\'utilisateur'), findsOneWidget);
      expect(find.text('S\'inscrire avec Google'), findsOneWidget);
      expect(find.text('S\'inscrire avec Facebook'), findsOneWidget);
      expect(find.text('S\'inscrire avec Twitter'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('WelcomePage navigation should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WelcomePage(),
          ),
        ),
      );

      // Test social login buttons show coming soon dialog
      await tester.tap(find.text('Continuer avec Google'));
      await tester.pumpAndSettle();
      
      expect(find.text('Bientôt disponible'), findsOneWidget);
      expect(find.text('La connexion avec Google sera bientôt disponible.'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });
  });
}
