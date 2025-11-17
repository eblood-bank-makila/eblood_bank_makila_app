import 'package:eblood_bank_mak_app/apps/config/route/GoRouter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'translations/AppTranslations.dart';
import 'services/LanguageService.dart';

import 'package:eblood_bank_mak_app/core/widgets/network_status_widget.dart';

// Fallback delegate for unsupported locales (like Lingala)
class FallbackLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Use French as fallback for unsupported locales
    return DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(FallbackLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // Use default Cupertino localizations
    return DefaultCupertinoLocalizations();
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class MonApplication extends ConsumerWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return GetMaterialApp.router(
      title: 'E-Blood Bank Makila',

      // Wrap app to close keyboard when tapping outside inputs
      builder: (context, child) {
        final base = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child ?? const SizedBox.shrink(),
        );
        return NetworkStatusWidget(
          child: base,
          offlineMessage: 'backend_unavailable'.tr,
          preserveSpace: true,
          absorbPointerWhenOffline: false,
        );
      },

      // Internationalization configuration
      translations: AppTranslations(),
      locale: Get.find<LanguageService>().currentLocale,
      fallbackLocale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('ln', 'CD'),
        Locale('ar', 'SA'),
        Locale('ru', 'RU'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],

      // Theme configuration
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.ubuntuTextTheme(),
        fontFamily: GoogleFonts.ubuntu().fontFamily,
        useMaterial3: true,
      ),

      // Router configuration
      debugShowCheckedModeBanner: false,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,

      // Initialize services
      initialBinding: BindingsBuilder(() {
        Get.put(LanguageService());
      }),
    );
  }
}
