import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/firebase_options.dart';
import 'package:sendra/screens/login_page.dart';

void main() async {
  // 1. Ensure bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Firebase with the generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    // Optionally: show a "Service Unavailable" screen here
  }

  // 3. UI Overlay settings
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SColors.navy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 4. Lock orientation and THEN run the app
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
      theme: STheme
          .dark, // Ensure STheme.dark doesn't conflict with SystemUiOverlayStyle
      home: const LoginPage(),
    );
  }
}
