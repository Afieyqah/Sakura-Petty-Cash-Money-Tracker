import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login_and_authenthication/auth_service.dart';
import 'login_and_authenthication/welcome_screen.dart';

import 'analystic_dashboard/analystic_screen.dart';
import 'settings/profile_screen.dart';
import 'budgets/budget_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  int _selectedIndex = 0;

  final tips = [
    "Prepare a Budget and Abide by it",
    "Track your daily expenses to avoid overspending",
    "Save at least 10% of your income monthly",
    "Plan purchases ahead to reduce impulse buying",
  ];
  int tipIndex = 0;

  // ---------------- Helpers ----------------
  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  // ---------------- Pages ----------------
  late final List<Widget> _pages = [
    _buildHomeContent(), // 0 Home
    const AnalyticsScreen(), // 1 Stats (RESTORED)
    const SizedBox(), // 2 FAB placeholder
    const BudgetListScreen(), // 3 Records
    const ProfileScreen(), // 4 Profile
  ];

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard • ${widget.role}'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: _addExpense,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.home, "Home", 0),
            _navIcon(Icons.analytics_outlined, "Stats", 1),
            const SizedBox(width: 40),
            _navIcon(Icons.list_alt, "Records", 3),
            _navIcon(Icons.person, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, int index) {
    final active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.pink : Colors.grey, size: 28),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.pink : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Home Content ----------------
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildBalanceCard(),
          const SizedBox(height: 12),
          _buildPieChart(),
          const SizedBox(height: 12),
          _buildTips(),
          const SizedBox(height: 12),
          _buildExpenseList(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('budget')
          .snapshots(),
      builder: (context, budgetSnap) {
        double budget = 0;
        if (budgetSnap.hasData && budgetSnap.data!.exists) {
          budget = _parseAmount(budgetSnap.data!['amount']);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, snap) {
            double spent = 0;
            if (snap.hasData) {
              for (var d in snap.data!.docs) {
                spent += _parseAmount((d.data() as Map)['amount']);
              }
            }
            final remaining = budget - spent;

            return _card(
              Column(
                children: [
                  Text(
                    widget.role == "owner"
                        ? "Owner Financial Overview"
                        : "Available Balance",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RM ${remaining.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Total Spent: RM ${spent.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.pink),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _card(const Text("No expense data"));
        }

        final Map<String, double> totals = {};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          totals[data['category'] ?? 'Other'] =
              (totals[data['category']] ?? 0) + _parseAmount(data['amount']);
        }

        return _card(
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 30,
                sections: totals.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value,
                    title: e.key,
                    radius: 55,
                    color: Colors.pinkAccent,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTips() {
    return _card(
      GestureDetector(
        onTap: () => setState(() => tipIndex = (tipIndex + 1) % tips.length),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.pink),
            const SizedBox(width: 8),
            Expanded(child: Text(tips[tipIndex])),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No expenses yet"));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final data = snap.data!.docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.pink),
                title: Text(data['remark'] ?? 'No remark'),
                trailing: Text(
                  "RM ${_parseAmount(data['amount']).toStringAsFixed(2)}",
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  void _addExpense() {
    // hook your add-expense dialog here
  }
}
