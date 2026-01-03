import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_and_authenthication/auth_service.dart';
import 'login_and_authenthication/welcome_screen.dart';
// Import screen lain untuk navigasi
import 'settings/profile_screen.dart';
import 'budgets/budget_list_screen.dart';
import 'budgets/budget_chart_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  int _selectedIndex = 0; // Untuk mengawal tab mana yang aktif

  final tips = [
    "Prepare a Budget and Abide by it",
    "Track your daily expenses to avoid overspending",
    "Save at least 10% of your income monthly",
    "Plan purchases ahead to reduce impulse buying",
  ];
  int tipIndex = 0;

  // Fungsi navigasi tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // --- WIDGET HELPER ---
  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  // Isi kandungan utama Dashboard (Graf + Balance + Tips)
  Widget _buildHomeContent() {
    return SingleChildScrollView( // Tambah scroll supaya tidak overflow
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildBalanceCard(),
          const SizedBox(height: 12),
          _buildPieChartSection(),
          const SizedBox(height: 12),
          _buildTipsSection(),
          const SizedBox(height: 12),
          // Senarai perbelanjaan diletakkan di sini jika dalam tab Home
          SizedBox(
            height: 400, // Beri ketinggian tetap untuk list dalam scrollview
            child: _buildExpenseList(),
          ),
          _buildOwnerSummary(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Senarai skrin untuk setiap tab
    final List<Widget> _pages = [
      _buildHomeContent(),     // Tab 0: Home
      const BudgetChartScreen(), // Tab 1: Stats
      const SizedBox(),         // Tab 2: Dummy untuk butang tengah (+)
      const BudgetListScreen(),  // Tab 3: Records
      const ProfileScreen(),     // Tab 4: Profile (INI YANG ANDA MAHU)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard • ${widget.role}'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.pink)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _pages[_selectedIndex], // Paparkan skrin ikut index
      ),
      // Gunakan butang terapung (FAB) untuk butang "+" di tengah
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: _addExpense,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.home, "Home", 0),
            _buildNavIcon(Icons.analytics_outlined, "Stats", 1),
            const SizedBox(width: 40), // Ruang kosong untuk butang FAB tengah
            _buildNavIcon(Icons.list_alt, "Records", 3),
            _buildNavIcon(Icons.person, "Profile", 4),
          ],
        ),
      ),
    );
  }

  // Widget untuk membina ikon navigasi bawah
  Widget _buildNavIcon(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.pink : Colors.grey, size: 28),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.pink : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- KOD ASAL ANDA (DIKEKALKAN) ---
  Widget _buildBalanceCard() {
     return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('budget').snapshots(),
      builder: (context, budgetSnap) {
        double budget = 200.0;
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
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(widget.role == "owner" ? "Owner Financial Overview" : "Available Balance", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('RM ${remaining.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Total Spent: RM ${totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.pink, fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPieChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox(height: 160, child: Center(child: Text("No chart data")));
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
    );
  }

  List<PieChartSectionData> _buildChartSections(QuerySnapshot snapshot) {
    final Map<String, double> categoryTotals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = (data['category'] ?? 'Other').toString();
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + _parseAmount(data['amount']);
    }
    final Map<String, Color> categoryColors = {
      "Food": Colors.green, "Transport": Colors.blue, "Utilities": Colors.orange,
      "Entertainment": Colors.purple, "Shopping": Colors.pink, "Other": Colors.grey,
    };
    return categoryTotals.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value, title: entry.key, color: categoryColors[entry.key] ?? Colors.teal,
        radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildTipsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => setState(() => tipIndex = (tipIndex + 1) % tips.length),
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
    );
  }

  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No expenses found."));
        return ListView.builder(
          shrinkWrap: true, // Benarkan list duduk dalam column
          physics: const NeverScrollableScrollPhysics(), // Scroll dikawal oleh parent
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.payments, color: Colors.pink),
                title: Text(data['remark'] ?? 'No Remark'),
                trailing: Text('RM ${_parseAmount(data['amount']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOwnerSummary() {
    if (widget.role != "owner") return const SizedBox.shrink();
    return Container(); // Tambah logik summary anda di sini
  }

  void _addExpense() {
    // Logik dialog add expense anda...
    print("Add expense dialog triggered");
  }
}