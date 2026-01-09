import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login_and_authenthication/auth_service.dart';
import 'analystic_dashboard/analystic_screen.dart';
import 'settings/profile_screen.dart';
import 'budgets/budget_list_screen.dart';
import '../screens/expense_main_screen.dart'; 
import '../screens/bottom_navigation.dart'; 
import 'chat_screen.dart'; 
import '../screens/add_expense.dart'; // Import untuk FAB navigate ke sini

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  final ScrollController _dashboardScrollController = ScrollController();
  
  final Color themePink = const Color(0xFFE91E63);
  bool _isFabVisible = true; // State untuk kawal sorok/tunjuk FAB

  final tips = [
    "Prepare a Budget and Abide by it",
    "Track your daily expenses to avoid overspending",
    "Save at least 10% of your income monthly",
    "Plan purchases ahead to reduce impulse buying",
  ];
  int tipIndex = 0;

  @override
  void initState() {
    super.initState();
    // Logik Scroll Listener untuk kawal visibiliti FAB
    _dashboardScrollController.addListener(() {
      if (_dashboardScrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_dashboardScrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _dashboardScrollController.dispose();
    super.dispose();
  }

  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Supaya kandungan body nampak di belakang notch bar

      // --- FAB PUTIH DI TENAH (HIDE ON SCROLL) ---
      floatingActionButton: AnimatedScale(
        scale: _isFabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 8,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
          child: Icon(Icons.add, color: themePink, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- SHARED NAVIGATION ---
      bottomNavigationBar: SharedNavigation(
        scrollController: _dashboardScrollController,
        isFabVisible: _isFabVisible,
      ),
      
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'), 
            fit: BoxFit.cover
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            controller: _dashboardScrollController, // Sambungkan controller
            child: Column(
              children: [
                _buildCustomAppBar(),
                const SizedBox(height: 15),
                _buildBalanceCard(), 
                _buildPieChart(),
                _buildTips(),
                _buildAiTile(), 
                _buildExpenseList(), 
                const SizedBox(height: 130), // Ruang bawah untuk Nav Bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text("Dashboard • ${widget.role}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          IconButton(
            onPressed: () => _auth.logout(), 
            icon: const Icon(Icons.logout, color: Colors.white)
          ),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return _card(const SizedBox(height: 100, child: Center(child: Text("No data to display"))));
        
        final Map<String, double> totals = {};
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;
          String cat = data['category'] ?? 'Other';
          totals[cat] = (totals[cat] ?? 0) + _parseAmount(data['amount']);
        }

        final List<Color> pinkShades = [
          const Color(0xFFF06292), const Color(0xFFE91E63), 
          const Color(0xFFC2185B), const Color(0xFFF48FB1), 
          const Color(0xFF880E4F)
        ];

        return _card(
          Column(
            children: [
              const Text("Spending Breakdown", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: totals.entries.toList().asMap().entries.map((entry) {
                      return PieChartSectionData(
                        value: entry.value.value,
                        title: '${entry.value.key}\n${entry.value.value.toStringAsFixed(0)}',
                        radius: 60,
                        color: pinkShades[entry.key % pinkShades.length],
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
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
            const Icon(Icons.refresh, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(expenses: currentExpenses))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 30),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ask AI Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Analyze your spending with AI", style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildExpenseList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseMainScreen())),
                child: const Text("View All", style: TextStyle(color: Colors.white, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).limit(5).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snap.data!.docs.length,
              itemBuilder: (_, i) {
                final data = snap.data!.docs[i].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), 
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: themePink.withOpacity(0.1), child: Icon(Icons.receipt_long_rounded, color: themePink)),
                    title: Text(data['remark'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['category'] ?? 'General'),
                    trailing: Text("- RM ${_parseAmount(data['amount']).toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: child,
    );
  }
}