import 'package:flutter/material.dart';
// Import semua skrin yang berkaitan
import '../dashboard_screen.dart';
import '../analystic_dashboard/analystic_screen.dart';
import '../budgets/budget_list_screen.dart';
import '../settings/profile_screen.dart';

class SharedNavigation extends StatelessWidget {
  final ScrollController? scrollController; // Letak tanda ?
  final bool isFabVisible;

  const SharedNavigation({
    super.key,
    this.scrollController,           // Buang 'required'
    this.isFabVisible = true,        // Beri nilai default 'true'
  });
  
  // ... rest of your code

  // Fungsi pembantu untuk navigasi tanpa bertumpuk (Clean Navigation)
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themePink = Color(0xFFE91E63);

    return BottomAppBar(
      height: 70,
      color: themePink,
      shape: const CircularNotchedRectangle(), 
      notchMargin: 10.0, 
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home, "Home", () {
            _navigateTo(context, const DashboardScreen(role: 'manager')); // Sesuaikan role
          }),
          _navItem(context, Icons.bar_chart, "Stats", () {
            _navigateTo(context, const AnalyticsScreen());
          }),
          const SizedBox(width: 45), // Ruang untuk FAB di tengah
          _navItem(context, Icons.wallet, "Budgets", () {
            _navigateTo(context, const BudgetListScreen());
          }),
          _navItem(context, Icons.person, "Profile", () {
            _navigateTo(context, const ProfileScreen());
          }),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}