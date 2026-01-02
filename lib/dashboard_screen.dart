import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_and_authenthication/auth_service.dart';
import 'login_and_authenthication/welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role; // staff, manager, owner

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();

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
    setState(() => tipIndex = (tipIndex + 1) % tips.length);
  }

  // 🔎 Helper to safely parse Firestore numeric fields
  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  // 🔎 Balance card (budget from Firestore)
  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('budget')
          .snapshots(),
      builder: (context, budgetSnap) {
        double budget = 200.0; // fallback
        if (budgetSnap.hasData && budgetSnap.data!.exists) {
          budget = _parseAmount(budgetSnap.data!['amount']);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, snapshot) {
            double totalSpent = 0.0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalSpent += _parseAmount(data['amount']);
              }
            }
            double remaining = budget - totalSpent;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    widget.role == "owner"
                        ? "Owner Financial Overview"
                        : "Available Balance",
                    style: const TextStyle(color: Colors.grey),
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
      },
    );
  }

  // 🔎 Chart sections helper with category-based colors
  List<PieChartSectionData> _buildChartSections(QuerySnapshot snapshot) {
    final Map<String, double> categoryTotals = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = (data['category'] ?? 'Other').toString();
      final amount = _parseAmount(data['amount']);
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    // ✅ Define fixed colors per category
    final Map<String, Color> categoryColors = {
      "Food": Colors.green,
      "Transport": Colors.blue,
      "Utilities": Colors.orange,
      "Entertainment": Colors.purple,
      "Shopping": Colors.pink,
      "Other": Colors.grey,
    };

    return categoryTotals.entries.map((entry) {
      final sectionColor = categoryColors[entry.key] ?? Colors.teal; // fallback
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

  // 🔎 Expenses list (manager approve/reject)
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
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final approved = data['approved'] ?? false;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.pink),
                title: Text(data['remark'] ?? 'No Remark'),
                subtitle: Text(data['date']?.toString() ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RM ${_parseAmount(data['amount']).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (widget.role == "manager" && !approved) ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('expenses')
                              .doc(doc.id)
                              .update({'approved': true});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('expenses')
                              .doc(doc.id)
                              .update({'approved': false});
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔎 Owner summary
  Widget _buildOwnerSummary() {
    if (widget.role != "owner") return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        double weeklyTotal = 0.0;
        double monthlyTotal = 0.0;
        final now = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] is Timestamp)
              ? (data['date'] as Timestamp).toDate()
              : DateTime.tryParse(data['date']?.toString() ?? '') ?? now;
          final amount = _parseAmount(data['amount']);

          if (date.isAfter(now.subtract(const Duration(days: 7)))) {
            weeklyTotal += amount;
          }
          if (date.month == now.month && date.year == now.year) {
            monthlyTotal += amount;
          }
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Weekly Total: RM ${weeklyTotal.toStringAsFixed(2)}"),
              Text("Monthly Total: RM ${monthlyTotal.toStringAsFixed(2)}"),
            ],
          ),
        );
      },
    );
  }

  // 🔎 Add expense (staff only)
  void _addExpense() {
    if (widget.role != "staff") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don’t have permission to add expenses"),
        ),
      );
      return;
    }

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
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(labelText: "Remark"),
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number, // ✅ enforce numeric input
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: "Category"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('expenses').add({
                'remark': remarkCtrl.text,
                'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                'category': categoryCtrl.text,
                'date': FieldValue.serverTimestamp(), // ✅ timestamp
                'approved': false,
                'userId': _auth.getUid(), // ✅ track who added
              });
              Navigator.pop(context);
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

            // Balance card
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

            // Expenses list (with manager approve/reject)
            Expanded(child: _buildExpenseList()),

            // Owner summary (only visible for owner)
            _buildOwnerSummary(),

            // Bottom navigation + Add Expense button
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
                  GestureDetector(
                    onTap: _addExpense,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.pink,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
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
