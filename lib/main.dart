import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/firebase_options.dart';
import 'package:sendra/screens/login_page.dart';
import 'package:sendra/services/exchange_rate_service.dart';
import 'package:sendra/providers/app_providers.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

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
      theme: STheme.light,
      darkTheme: STheme.dark,
      themeMode: themeProvider.mode,
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
