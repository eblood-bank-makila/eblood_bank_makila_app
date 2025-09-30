import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/AppConfig.dart';
import 'package:eblood_bank_mak_app/apps/services/ApiTestService.dart';
import 'package:eblood_bank_mak_app/core/utils/api_initializer.dart';
import 'package:eblood_bank_mak_app/commande/business/interactor/CommandeInteractor.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/GestionStockInteractor.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/framework/banque/BanqueListeServiceLocalImpl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/framework/banque/BanqueListeServiceNetworkImpl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/framework/favoris/FavorisServiceNetworkImpl.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/framework/poche/PocheListeServiceNetworkImpl.dart';
import 'package:eblood_bank_mak_app/paiement/businness/interactors/PaiementInteractor.dart';
import 'package:eblood_bank_mak_app/paiement/ui/framework/PaiementNetworkServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/framework/UtilisateurLocalServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/framework/UtilisateurNetworkServiceImpl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'apps/MonApplication.dart';
import 'apps/services/LanguageService.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'commande/ui/framework/panier/PanierServiceNetworkImpl.dart';
import 'gestionStocks/ui/framework/recherche/RechercheListeServiceNetworkImpl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize GetX services
  final languageService = Get.put(LanguageService());
  await languageService.onInit();

  // Debug: Check first launch status
  final storage = GetStorage();
  final hasBeenLaunched = storage.read('app_has_been_launched');
  print('🚀 MAIN: app_has_been_launched = $hasBeenLaunched');
  print('🚀 MAIN: This should be null on first launch, true on subsequent launches');

  // Initialize Firebase with proper options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase is already initialized, continue
      print('Firebase already initialized');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark
        .copyWith(statusBarColor: ColorPages.COLOR_TRANSPARENT),
  );

  // Initialize AppConfig first
  await dotenv.load(fileName: ".env");
  await AppConfig.initialize();

  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDir.path, "sembast.db");
  DatabaseFactory dbFactory = databaseFactoryIo;
  Database db = await dbFactory.openDatabase(dbPath);

  // Use AppConfig instead of direct dotenv access
  var baseUrl = AppConfig.instance.baseUrl;

  // Debug logging to check what URLs are being loaded
  print("🌐 BASE_URL from AppConfig: '${AppConfig.instance.baseUrl}'");
  print("🌐 BASE_API_URL from AppConfig: '${AppConfig.instance.baseApiUrl}'");
  print("🔑 API_CONSUMER set: ${AppConfig.instance.apiConsumer.isNotEmpty ? 'Yes' : 'No'}");
  print("🔧 AppConfig summary: ${AppConfig.instance.getConfigSummary()}");
  
  // Initialize the centralized Dio client
  try {
    // Initialize the centralized Dio client
    await ApiInitializer.initialize();
    
    // Keeping the original test for backward compatibility
    final apiTestService = ApiTestService();
    await apiTestService.testLocationApi();
  } catch (e) {
    print("⚠️ API Test failed: $e");
  }

  // Module utilisateur service implementations
  var utilisateurNetworkImpl = UtilisateurNetworkServiceImpl(baseUrl);
  var utilisateurLocalImpl = UtilisateurLocalServiceImpl(db);
  var userInteractor =
      Utilisateurinteractor.build(utilisateurNetworkImpl, utilisateurLocalImpl);
  // Module utilisateur service implementations

  // Module gestion_stock
  var BanqueListeNetworkImpl = BanqueListeNetworkServiceImpl(baseUrl);
  var BanqueListeLocalImpl = BanqueListeServiceLocalImpl(db);
  var PocheListeNetworkImpl = PocheListeNetworkServiceImpl(baseUrl);
  var FavorisNetworkImpl = FavorisNetworkServiceImpl(baseUrl);
  var RechercheNetworkImpl = RechercheListeNetworkServiceImpl(baseUrl);

  var banquelisteInteractor = Gestionstockinteractor.build(
      BanqueListeNetworkImpl,
      BanqueListeLocalImpl,
      utilisateurLocalImpl,
      PocheListeNetworkImpl,
      FavorisNetworkImpl,
      RechercheNetworkImpl);
  // Module gestion_stock

  // Module commande
  var commandeNetworkImpl = PanierServiceNetworkImpl(baseUrl);
  var panierInteractor =
      Commandeinteractor.build(commandeNetworkImpl, utilisateurLocalImpl);
  // Module commande

  // Module paiement
  var paiementNetworkImpl = PaiementServiceNetworkImpl(baseUrl);
  var paiementInteractor =
      Paiementinteractor.build(paiementNetworkImpl, utilisateurLocalImpl);
  // module paiement

  runApp(ProviderScope(
    child: MonApplication(),
    overrides: [
      utilisateurInteractorProvider.overrideWithValue(userInteractor),
      gestionstockInteractorProvider.overrideWithValue(banquelisteInteractor),
      commandeInteractorProvider.overrideWithValue(panierInteractor),
      paiementInteractorProvider.overrideWithValue(paiementInteractor)
    ],
  ));
}
