import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import '../screens/expense_main_screen.dart';



// --- AUTHENTICATION & DASHBOARD ---

import 'login_and_authenthication/splash_screen.dart';

import 'dashboard_screen.dart';



// --- BUDGET MODULES ---

import 'budgets/budget_list_screen.dart';

import 'budgets/add_budget_screen.dart';

import 'budgets/view_budget_screen.dart';

import 'budgets/budget_chart_screen.dart';



// --- ACCOUNT & ALERTS ---

import 'account_dashboard/account_dashboard.dart';

import 'alerts/alerts_screen.dart';



// --- SETTINGS & PROFILE ---

import 'settings/profile_screen.dart';

import 'settings/edit_profile_screen.dart';

import 'settings/security_screen.dart';

import 'settings/setting_screen.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SakuraApp());

}



class SakuraApp extends StatelessWidget {

  const SakuraApp({super.key});



  @override

  Widget build(BuildContext context) {

    final theme = ThemeData(

      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),

      useMaterial3: true,

      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(

        backgroundColor: Colors.white,

        centerTitle: true,

        iconTheme: IconThemeData(color: Colors.pink),

      ),

    );



    return MaterialApp(

      title: 'Youth 24+ Petty Cash Tracker',

      theme: theme,

      debugShowCheckedModeBanner: false,

      home: const SplashScreen(),

      routes: {

        '/dashboard': (_) => const DashboardScreen(role: 'user'),

        '/expense-main': (context) => const ExpenseMainScreen(),

        '/budget_list': (_) => const BudgetListScreen(),

        '/add-budget': (_) => const AddBudgetScreen(),

        '/view_budget': (_) => const ViewBudgetScreen(),

        '/budget_chart': (_) => const BudgetChartScreen(),

        '/alerts': (_) => const AlertsScreen(),

        '/accounts': (_) => const AccountDashboard(),

        '/profile': (_) => const ProfileScreen(),

        '/edit_profile': (_) => const EditProfileScreen(),

        '/security': (_) => const SecurityScreen(),

        '/settings': (_) => const SettingsScreen(),

      }, // Added missing bracket

    ); // Added missing bracket

  }

}