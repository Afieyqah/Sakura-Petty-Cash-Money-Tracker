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
  final Color themePink = const Color(0xFFE91E63); // Warna pink seragam

  final tips = [
    "Prepare a Budget and Abide by it",
    "Track your daily expenses to avoid overspending",
    "Save at least 10% of your income monthly",
    "Plan purchases ahead to reduce impulse buying",
  ];
  int tipIndex = 0;

  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  void _addExpense() {
    final remarkCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: "Remark")),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount (RM)"), keyboardType: TextInputType.number),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themePink, foregroundColor: Colors.white),
            onPressed: () async {
              if (remarkCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('expenses').add({
                  'remark': remarkCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'category': categoryCtrl.text,
                  'date': FieldValue.serverTimestamp(),
                  'approved': widget.role == "owner" || widget.role == "manager",
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add Now"),
          ),
        ],
      ),
    );
  }

  void _showUpdateBudgetDialog(double currentBudget) {
    if (widget.role == "staff") return;
    final budgetCtrl = TextEditingController(text: currentBudget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Monthly Budget"),
        content: TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Budget Amount (RM)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('settings').doc('budget').set({'amount': double.tryParse(budgetCtrl.text) ?? 0.0});
            if (mounted) Navigator.pop(context);
          }, child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const AnalyticsScreen(),
      const SizedBox(), 
      const BudgetListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        // Banner warna pink seragam
        backgroundColor: themePink,
        elevation: 4,
        centerTitle: true,
        title: Text('Dashboard • ${widget.role}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [IconButton(onPressed: () => _auth.logout(), icon: const Icon(Icons.logout, color: Colors.white))],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: pages[_selectedIndex],
      ),
      // Butang Tambah Bulat Sempurna
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: themePink,
          elevation: 8,
          onPressed: _addExpense,
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: themePink, // Warna navigation sama dengan banner
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_rounded, "Home", 0),
              _navIcon(Icons.bar_chart_rounded, "Stats", 1),
              const SizedBox(width: 40),
              _navIcon(Icons.account_balance_wallet_rounded, "Budgets", 3),
              _navIcon(Icons.person_rounded, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          _buildBalanceCard(),
          _buildPieChart(),
          _buildTips(),
          _buildExpenseList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('budget').snapshots(),
      builder: (context, budgetSnap) {
        double budget = 0;
        if (budgetSnap.hasData && budgetSnap.data!.exists) budget = _parseAmount(budgetSnap.data!['amount']);
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, snap) {
            double spent = 0;
            if (snap.hasData) {
              for (var d in snap.data!.docs) spent += _parseAmount((d.data() as Map)['amount']);
            }
            final remaining = budget - spent;
            return GestureDetector(
              onTap: () => _showUpdateBudgetDialog(budget),
              child: _card(
                Column(
                  children: [
                    const Text("Available Balance", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text("RM ${remaining.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: remaining < 0 ? Colors.red : Colors.black87)),
                    const SizedBox(height: 5),
                    Text("Total Spent: RM ${spent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  ],
                ),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return _card(const Center(child: Text("No data to display")));
        final Map<String, double> totals = {};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          totals[data['category'] ?? 'Other'] = (totals[data['category']] ?? 0) + _parseAmount(data['amount']);
        }

        // Nuansa Pink Berbeza
        final List<Color> pinkShades = [
          const Color(0xFFF06292), // Light Pink
          const Color(0xFFE91E63), // Pink
          const Color(0xFFC2185B), // Dark Pink
          const Color(0xFFF48FB1), // Soft Pink
          const Color(0xFF880E4F), // Deep Pink
        ];

        return _card(
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              centerSpaceRadius: 40,
              sections: totals.entries.toList().asMap().entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value.value,
                  title: entry.value.key,
                  radius: 60,
                  color: pinkShades[entry.key % pinkShades.length],
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            )),
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
            const Icon(Icons.tips_and_updates_rounded, color: Colors.orangeAccent, size: 30),
            const SizedBox(width: 15),
            Expanded(child: Text(tips[tipIndex], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(left: 25, top: 15), child: Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snap.data!.docs.length,
              itemBuilder: (_, i) {
                final data = snap.data!.docs[i].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.receipt_long_rounded, color: Colors.white)),
                    title: Text(data['remark'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['category'] ?? 'General'),
                    trailing: Text("- RM ${_parseAmount(data['amount']).toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _navIcon(IconData icon, String label, int index) {
    bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.white : Colors.white70, size: 28),
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }
}