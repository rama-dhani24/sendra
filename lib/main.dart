import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sendra/core/theme.dart'; // provides SColors, STheme.light, STheme.dark
import 'package:sendra/firebase_options.dart';
import 'package:sendra/screens/login_page.dart';
import 'package:sendra/services/exchange_rate_service.dart';
import 'package:sendra/providers/app_providers.dart'; // provides ThemeProvider, LocaleProvider
import 'package:sendra/core/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    ExchangeRateService.instance.init();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SColors.navy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Init providers before runApp so first frame has correct values
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  await Future.wait([themeProvider.init(), localeProvider.init()]);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const SendraApp(),
    ),
  );
}

class SendraApp extends StatelessWidget {
  const SendraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Sendra',
      debugShowCheckedModeBanner: false,

      // Theme — dark / light / system
      theme: STheme.light,
      darkTheme: STheme.dark,
      themeMode: themeProvider.mode,

      // Locale
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const LoginPage(),
    );
  }
}
