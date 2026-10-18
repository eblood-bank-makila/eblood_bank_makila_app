/// The blood-search / QR welcome page is where every signed-in user lands.
/// Its user bar had an "Accueil" button to the dashboard, but the floating
/// "Mon activité" button sat right on top of it (prod, 2026-10-18, hospital
/// account): with any recent activity there was no visible way back to the
/// dashboard. Accounts with a dashboard now get an unobstructed
/// "Tableau de bord" button; visitors keep the page exactly as it was.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/providers/recent_activity_provider.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/providers/search_flow_provider.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/ui/pages/blood_search_welcome_page.dart';
import 'package:eblood_bank_mak_app/core/rbac/data/rbac_repository.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_state.dart';

class _TempPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

/// Recent activity without the network: one bought address when [hasActivity].
class _Activity extends RecentActivityNotifier {
  _Activity(bool hasActivity) {
    if (hasActivity) {
      state = const RecentActivityState(todayAddressRequests: [
        TodayAddressRequestItem(
          id: 'pi_1',
          identifier: 'REQ-1',
          status: 'succeeded',
          totalAmount: 1,
          totalAmountMerged: 1,
        ),
      ]);
    }
  }

  @override
  Future<void> fetchRecentActivity({int? autoOpenTab}) async {}
}

class _Rbac extends RbacNotifier {
  _Rbac({required bool loaded}) : super(RbacRepository()) {
    state = RbacState(isLoaded: loaded);
  }
}

final _dashboard = find.byKey(BloodSearchWelcomePage.dashboardButtonKey);
final _activity = find.byKey(BloodSearchWelcomePage.activityButtonKey);

Future<void> _signIn(String accountType) async {
  final storage = GetStorage();
  await storage.write('auth_token', 'jwt.$accountType');
  await storage.write('account_type', accountType);
  await storage.write('user_data', {'first_name': 'kinshasa', 'last_name': ''});
}

Future<void> _pumpWelcome(
  WidgetTester t, {
  required bool hasActivity,
  bool rbacLoaded = true,
}) async {
  // A 360 × 780 dp phone, like the user's.
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3.0;
  addTearDown(t.view.reset);

  final router = GoRouter(
    initialLocation: '/blood-search',
    routes: [
      GoRoute(path: '/blood-search', builder: (_, __) => const BloodSearchWelcomePage()),
      GoRoute(path: '/app/MainApp', builder: (_, __) => const Text('DASHBOARD')),
      GoRoute(path: '/rbac-loading', builder: (_, __) => const Text('RBAC LOADING')),
    ],
  );

  await t.pumpWidget(ProviderScope(
    overrides: [
      recentActivityProvider.overrideWith((ref) => _Activity(hasActivity)),
      canAccessProtectedRoutesProvider.overrideWith((ref) async => true),
      rbacProvider.overrideWith((ref) => _Rbac(loaded: rbacLoaded)),
    ],
    child: GetMaterialApp.router(
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    ),
  ));
  // _loadUserInfo is async; the hero animation runs 1.2 s.
  await t.pump();
  await t.pump(const Duration(seconds: 2));
}

/// Register the SDK's Roboto under every family GoogleFonts.ubuntu asks for
/// (`Ubuntu_regular`, `Ubuntu_500`, …): close to Ubuntu's metrics, so the
/// overflow checks reflect a phone rather than the test font's em boxes.
Future<void> _loadUbuntuStandIn() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  final font = File('$root/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf');
  if (root == null || !font.existsSync()) return;
  final bytes = ByteData.view(font.readAsBytesSync().buffer);
  // Ubuntu ships 300 / 400 / 500 / 700; GoogleFonts names them <family>_<variant>.
  for (final family in ['Ubuntu_300', 'Ubuntu_regular', 'Ubuntu_500', 'Ubuntu_700']) {
    await (FontLoader(family)..addFont(Future.value(bytes))).load();
  }
}

/// The page styles its text with GoogleFonts.ubuntu, which a test host can
/// neither fetch nor find bundled. google_fonts reports that as an uncaught
/// async error unrelated to the layout under test: drop exactly that one,
/// let everything else (failed expectations included) fail the test.
void _welcomeTest(String description, Future<void> Function(WidgetTester t) body) {
  testWidgets(description, (t) async {
    final done = Completer<void>();
    runZonedGuarded(() async {
      await body(t);
      if (!done.isCompleted) done.complete();
    }, (error, stack) {
      if ('$error'.contains('GoogleFonts.config.allowRuntimeFetching is false')) return;
      if (!done.isCompleted) done.completeError(error, stack);
    });
    await done.future;
  });
}

Widget? _floatingButton(WidgetTester t) =>
    t.widget<Scaffold>(find.byType(Scaffold).first).floatingActionButton;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // No network in tests: never try to fetch Ubuntu (see _welcomeTest), and
    // measure text with a real font instead of the test font's full-em boxes.
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadUbuntuStandIn();
    tempDir = await Directory.systemTemp.createTemp('eblood_welcome_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await GetStorage().erase();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  for (final accountType in ['hospital', 'blood_bank', 'cnts', 'customer']) {
    _welcomeTest('$accountType: dashboard button is visible and not covered by "Mon activité"', (t) async {
      await _signIn(accountType);
      await _pumpWelcome(t, hasActivity: true);

      expect(_dashboard, findsOneWidget);
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(_activity, findsOneWidget);
      expect(_floatingButton(t), isNull, reason: 'the activity button no longer floats over the bar');
      expect(t.getRect(_dashboard).overlaps(t.getRect(_activity)), isFalse);
      // Hit-testable: nothing on top of it.
      expect(t.hitTestOnBinding(t.getCenter(_dashboard)).path.any(
            (entry) => entry.target is RenderObject && _isWithin(t, entry.target as RenderObject, _dashboard),
          ), isTrue);
    });
  }

  _welcomeTest('dashboard button opens the dashboard', (t) async {
    await _signIn('hospital');
    await _pumpWelcome(t, hasActivity: true);

    await t.tap(_dashboard);
    await t.pumpAndSettle();
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  _welcomeTest('without loaded RBAC it goes through the loading screen', (t) async {
    await _signIn('hospital');
    await _pumpWelcome(t, hasActivity: false, rbacLoaded: false);

    await t.tap(_dashboard);
    await t.pumpAndSettle();
    expect(find.text('RBAC LOADING'), findsOneWidget);
  });

  _welcomeTest('visitor: unchanged — floating activity button and "Accueil"', (t) async {
    await _signIn('visitor');
    await _pumpWelcome(t, hasActivity: true);

    expect(_dashboard, findsNothing);
    expect(find.text('Accueil'), findsOneWidget);
    expect(_floatingButton(t), isNotNull);
    expect(_activity, findsOneWidget);
  });
}

/// Whether [target] is (inside) the render object of [finder]'s widget.
bool _isWithin(WidgetTester t, RenderObject target, Finder finder) {
  final root = t.renderObject(finder);
  RenderObject? node = target;
  while (node != null) {
    if (identical(node, root)) return true;
    node = node.parent;
  }
  return false;
}
