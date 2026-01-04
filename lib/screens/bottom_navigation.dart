import 'package:flutter/material.dart';
import '../dashboard_screen.dart';
import '../analystic_dashboard/analystic_screen.dart';
import '../budgets/budget_list_screen.dart';
import '../settings/profile_screen.dart';

class SharedNavigation extends StatelessWidget {
  const SharedNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final Color themePink = const Color(0xFFE91E63);

    return BottomAppBar(
      color: themePink,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home / Dashboard
            _navItem(context, Icons.home_rounded, "Home", () {
              // Guna popUntil untuk balik ke skrin pertama (Dashboard)
              Navigator.popUntil(context, (route) => route.isFirst);
            }),

            // Stats / Analytics
            _navItem(context, Icons.bar_chart_rounded, "Stats", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            }),

            const SizedBox(width: 40), // Ruang untuk FloatingActionButton

            // Budgets
            _navItem(context, Icons.account_balance_wallet_rounded, "Budgets", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetListScreen()),
              );
            }),

            // Profile
            _navItem(context, Icons.person_rounded, "Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}