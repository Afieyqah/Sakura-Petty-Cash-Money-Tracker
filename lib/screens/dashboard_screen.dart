import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  double balance = 156.50;

  final expenses = [
    {
      'title': 'Marker',
      'amount': 6.30,
      'date': 'October 20, 2025',
      'icon': Icons.edit,
    },
    {
      'title': 'Fuel',
      'amount': 20.00,
      'date': 'October 20, 2025',
      'icon': Icons.local_gas_station,
    },
    {
      'title': 'Banner printing',
      'amount': 12.00,
      'date': 'October 2, 2025',
      'icon': Icons.print,
    },
  ];

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

  List<PieChartSectionData> _buildChartSections() {
    return [
      PieChartSectionData(value: 6.3, color: Colors.green, title: 'Marker'),
      PieChartSectionData(value: 20.0, color: Colors.blue, title: 'Fuel'),
      PieChartSectionData(value: 12.0, color: Colors.purple, title: 'Banner'),
    ];
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
            // Balance + chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                      'RM${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(sections: _buildChartSections()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tip of the day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _nextTip, // tap to cycle tips
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expenses.length,
                itemBuilder: (context, i) {
                  final e = expenses[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(e['icon'] as IconData, color: Colors.pink),
                      title: Text(e['title'] as String),
                      subtitle: Text(e['date'] as String),
                      trailing: Text(
                        'RM ${(e['amount'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom nav (updated)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ), // ⬆️ taller bar
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
                    radius: 28, // ⬆️ bigger add button
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
