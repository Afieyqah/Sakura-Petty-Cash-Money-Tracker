import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_and_authenthication/splash_screen.dart';
import 'dashboard_screen.dart'; // 👈 import your dashboard

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PettyCashApp());
}

class PettyCashApp extends StatelessWidget {
  const PettyCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      title: 'Youth 24+ Petty Cash Tracker',
      theme: theme,
      debugShowCheckedModeBanner: false,
      // 👇 Start with SplashScreen, then navigate to Dashboard
      home: const SplashScreen(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        // you can add other screens here like '/welcome': (_) => const WelcomeScreen(),
      },
    );
  }
}
