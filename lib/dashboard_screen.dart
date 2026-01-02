import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_and_authenthication/auth_service.dart';
import 'login_and_authenthication/welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  final double _initialBudget = 200.00;

  final tips = [
    "Prepare a Budget and Abide by it",
    "Track your daily expenses to avoid overspending",
    "Save at least 10% of your income monthly",
    "Plan purchases ahead to reduce impulse buying",
  ];
  int tipIndex = 0;

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _nextTip() {
    setState(() {
      tipIndex = (tipIndex + 1) % tips.length;
    });
  }

  // 🔎 Balance card using Firestore
  Widget _buildBalanceCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount =
                double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
            totalSpent += amount;
          }
        }
        double remaining = _initialBudget - totalSpent;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'RM ${remaining.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total Spent: RM ${totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.pink, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔎 Build chart sections dynamically from Firestore
  List<PieChartSectionData> _buildChartSections(QuerySnapshot snapshot) {
    final Map<String, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category']?.toString() ?? 'Other';
      final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;

      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    final colors = [
      Colors.pink,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    int colorIndex = 0;

    return categoryTotals.entries.map((entry) {
      final sectionColor = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: sectionColor,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // 🔎 Expenses list using Firestore
  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No expenses found."));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.pink),
                title: Text(data['remark'] ?? 'No Remark'),
                subtitle: Text(data['date'] ?? ''),
                trailing: Text(
                  'RM ${data['amount']?.toString() ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBalanceCard(),
            ),
            const SizedBox(height: 12),
            // Pie Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: Text("No chart data")),
                    );
                  }
                  return SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sections: _buildChartSections(snapshot.data!),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Tip of the day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _nextTip,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border.all(color: const Color(0xFFFFB6C1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.pink),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tips[tipIndex])),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Expenses list
            Expanded(child: _buildExpenseList()),
            // Bottom nav (larger)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.home, color: Colors.pink, size: 30),
                      Text("Home", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.analytics_outlined,
                        color: Colors.grey,
                        size: 30,
                      ),
                      Text("Stats", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.pink,
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.list_alt, color: Colors.grey, size: 30),
                      Text("Records", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person, color: Colors.grey, size: 30),
                      Text("Profile", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
