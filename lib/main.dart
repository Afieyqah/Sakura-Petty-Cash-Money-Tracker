import 'package:flutter/material.dart';
import 'screens/expense_main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Automatically generated in Step 1

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SakuraApp());
}
class SakuraApp extends StatelessWidget {
  const SakuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExpenseMainScreen(),
    );
  }
}
