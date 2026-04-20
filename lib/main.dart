import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/firebase_options.dart';
import 'package:sendra/screens/login_page.dart';
import 'package:sendra/services/exchange_rate_service.dart';

void main() async {
  // 1. Ensure bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Start listening to live exchange rates from Firestore
    // AppRates fields will be updated automatically whenever
    // the Cloud Function writes new rates (every 30 min).
    ExchangeRateService.instance.init();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
    // App continues with AppRates fallback values if Firebase fails
  }

  // 4. UI overlay settings
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SColors.navy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 5. Lock orientation and run the app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const SendraApp());
  });
}

class SendraApp extends StatelessWidget {
  const SendraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sendra',
      debugShowCheckedModeBanner: false,
      theme: STheme.dark,
      home: const LoginPage(),
    );
  }
}
