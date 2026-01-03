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

  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _nextTip() {
    setState(() => tipIndex = (tipIndex + 1) % tips.length);
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

  // --- FUNGSI UPDATE BUDGET ---
  void _showUpdateBudgetDialog(double currentBudget) {
    if (widget.role == "staff") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only Owners/Managers can update budget")),
      );
      return;
    }
    final budgetCtrl = TextEditingController(text: currentBudget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Monthly Budget"),
             content: TextField(
          controller: budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Budget Amount (RM)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('settings')
                  .doc('budget')
                  .set({'amount': double.tryParse(budgetCtrl.text) ?? 0.0});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI ADD EXPENSE ---
  void _addExpense() {
    if (widget.role != "staff" && widget.role != "manager" && widget.role != "owner") return;
    
    final remarkCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: "Remark")),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (remarkCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('expenses').add({
                  'remark': remarkCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'category': categoryCtrl.text,
                  'date': FieldValue.serverTimestamp(),
                  'approved': widget.role == "owner" || widget.role == "manager",
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard • ${widget.role}'),
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.pink))],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: _buildBodyContent(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: _addExpense,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
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

  Widget _buildBodyContent() {
    if (_selectedIndex == 1) return const AnalyticsScreen();
    if (_selectedIndex == 3) return const BudgetListScreen();
    if (_selectedIndex == 4) return const ProfileScreen();

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
      stream: FirebaseFirestore.instance.collection('settings').doc('budget').snapshots(),
      builder: (context, budgetSnap) {
        double budget = 0.0;
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
            return GestureDetector(
              onTap: () => _showUpdateBudgetDialog(budget),
              child: _card(
                Column(
                  children: [
                    Text(widget.role == "owner" ? "Owner Financial Overview" : "Available Balance"),
                    const SizedBox(height: 8),
                    Text("RM ${remaining.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("Total Spent: RM ${spent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.pink)),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return _card(const Text("No expense data"));
        final Map<String, double> totals = {};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          totals[data['category'] ?? 'Other'] = (totals[data['category']] ?? 0) + _parseAmount(data['amount']);
        }
        return _card(
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(sections: totals.entries.map((e) => PieChartSectionData(value: e.value, title: e.key, color: Colors.pinkAccent, radius: 50)).toList())),
          ),
        );
      },
    );
  }

  Widget _buildTips() {
    return _card(
      GestureDetector(
        onTap: _nextTip,
        child: Row(children: [const Icon(Icons.lightbulb, color: Colors.pink), const SizedBox(width: 8), Expanded(child: Text(tips[tipIndex]))]),
      ),
    );
  }

  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final docs = snap.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.pink),
                title: Text(data['remark'] ?? 'No remark'),
                trailing: Text("RM ${_parseAmount(data['amount']).toStringAsFixed(2)}"),
              ),
            );
          },
        );
      },
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
          Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.pink : Colors.grey)),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}