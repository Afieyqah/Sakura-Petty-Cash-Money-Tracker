import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

// Your existing imports
import 'login_and_authenthication/auth_service.dart';
import 'analystic_dashboard/analystic_screen.dart';
import 'settings/profile_screen.dart';
import 'budgets/budget_list_screen.dart';
import '../screens/expense_main_screen.dart'; 

// Import your Chat Screen file
import 'chat_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  int _selectedIndex = 0;
  final Color themePink = const Color(0xFFE91E63);

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

  // --- AI TILE LOGIC ---
  Widget _buildAiTile() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> currentExpenses = [];
        if (snapshot.hasData) {
          currentExpenses = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'category': data['category'] ?? 'Misc',
              'amount': _parseAmount(data['amount']),
              'remark': data['remark'] ?? '',
            };
          }).toList();
        }

        return _card(
          InkWell(
            onTap: () {
              // Now navigating to ChatScreen and passing current data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(expenses: currentExpenses),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 30),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ask AI Assistant", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Analyze your spending patterns with AI", 
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    // Correctly define the pages list for navigation
    final List<Widget> pages = [
      _buildHomeContent(),
      const AnalyticsScreen(),
      const SizedBox(), // Placeholder for floating button space
      const BudgetListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: themePink,
        elevation: 4,
        centerTitle: true,
        title: Text('Dashboard • ${widget.role}', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [IconButton(onPressed: () => _auth.logout(), icon: const Icon(Icons.logout, color: Colors.white))],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: pages[_selectedIndex],
      ),
      floatingActionButton: SizedBox(
        height: 65, width: 65,
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
        color: themePink,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(Icons.home_rounded, "Home", 0),
              _navIcon(Icons.bar_chart_rounded, "Stats", 1),
              const SizedBox(width: 40), // Empty space for FAB
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
          _buildAiTile(), 
          _buildExpenseList(), 
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').where('userId', isEqualTo: user?.uid).snapshots(),
      builder: (context, accountSnap) {
        double totalNetWorth = 0;
        if (accountSnap.hasData) {
          for (var doc in accountSnap.data!.docs) {
            totalNetWorth += _parseAmount(doc['balance']);
          }
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expenseSnap) {
            double totalSpent = 0;
            if (expenseSnap.hasData) {
              for (var d in expenseSnap.data!.docs) {
                totalSpent += _parseAmount((d.data() as Map)['amount']);
              }
            }
            final remaining = totalNetWorth - totalSpent;
            return _card(
              Column(
                children: [
                  const Text("Available Balance", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text("RM ${remaining.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: remaining < 0 ? Colors.red : Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Net Worth: RM ${totalNetWorth.toStringAsFixed(2)}", style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(width: 15),
                      Text("Spent: RM ${totalSpent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return _card(const Center(child: Text("No data to display")));
        final Map<String, double> totals = {};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          totals[data['category'] ?? 'Other'] = (totals[data['category']] ?? 0) + _parseAmount(data['amount']);
        }
        final List<Color> pinkShades = [const Color(0xFFF06292), const Color(0xFFE91E63), const Color(0xFFC2185B), const Color(0xFFF48FB1), const Color(0xFF880E4F)];
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseMainScreen())),
                    child: const Text("View All", style: TextStyle(color: Colors.pink, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snap.data!.docs.length > 5 ? 5 : snap.data!.docs.length,
              itemBuilder: (_, i) {
                final data = snap.data!.docs[i].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
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