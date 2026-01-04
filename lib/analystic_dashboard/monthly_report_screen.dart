import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:selab_project/analystic_dashboard/ai_financial_report.dart';
import 'package:selab_project/analystic_dashboard/history_screen.dart';
import '../screens/bottom_navigation.dart'; // Import SharedNavigation anda
import '../screens/add_expense.dart';       // Import skrin tambah

// ---------------- Category colors ----------------
final List<String> _categories = [
  "Food",
  "Fuel",
  "Stationery",
  "Transport",
  "Misc",
];
final List<Color> categoryColors = [
  const Color(0xFFBFA2DB),
  const Color(0xFFFFB37B),
  const Color(0xFFF3E5AB),
  const Color(0xFFF7C6C7),
  const Color(0xFFFFF3A0),
];

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  // --- PEMBETULAN: Fungsi untuk handle Timestamp Firestore & String ---
  DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is String) {
      try {
        final parts = raw.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final Color themePink = const Color(0xFFE91E63);

    return Scaffold(
      extendBody: true, // Supaya background nampak di belakang Nav Bar
      appBar: AppBar(
        title: const Text("Monthly Report", style: TextStyle(color: Colors.white)),
        backgroundColor: themePink,
      ),
      
      // --- INTEGRASI NAVIGATION BAR ---
      bottomNavigationBar: const SharedNavigation(),
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: themePink,
          elevation: 8,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
            );
          },
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/cherry_blossom_bg.jpg', fit: BoxFit.cover),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              double thisMonthTotal = 0;
              double lastMonthTotal = 0;
              Map<String, double> categoryTotals = {};
              Map<int, double> weeklyTotals = {1: 0, 2: 0, 3: 0, 4: 0};

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
                final category = data['category'] ?? 'Misc';
                
                // Guna raw data (boleh jadi Timestamp atau String)
                final date = _parseDate(data['date']);

                if (date.month == now.month && date.year == now.year) {
                  thisMonthTotal += amount;
                  categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

                  int week = ((date.day - 1) / 7).floor() + 1;
                  if (week > 4) week = 4;
                  weeklyTotals[week] = (weeklyTotals[week] ?? 0) + amount;
                }

                if (date.month == lastMonth && date.year == lastMonthYear) {
                  lastMonthTotal += amount;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _totalSpentPanel(context, thisMonthTotal, lastMonthTotal),
                    const SizedBox(height: 20),
                    _categoryBreakdownPanel(categoryTotals),
                    const SizedBox(height: 20),
                    _weeklyBreakdownPanel(weeklyTotals),
                    const SizedBox(height: 20),
                    _aiInsightPanel(context),
                    const SizedBox(height: 120), // Ruang untuk Nav Bar
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Widget Panels (Dikekalkan & Dibaiki Styling) ----------------

  Widget _totalSpentPanel(BuildContext context, double current, double last) {
    final percent = last == 0 ? 0.0 : ((current - last) / last * 100);
    final isPositive = percent >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Spent This Month", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      "RM ${current.toStringAsFixed(2)}",
                      style: const TextStyle(color: Color(0xFFE91E63), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, 
                       color: isPositive ? Colors.red : Colors.green, size: 16),
                  Text("${percent.abs().toStringAsFixed(1)}%", 
                       style: TextStyle(color: isPositive ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  const Text("vs last month", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              icon: const Icon(Icons.history),
              label: const Text("History"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdownPanel(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: List.generate(entries.length, (i) {
                  return PieChartSectionData(
                    value: entries[i].value,
                    color: categoryColors[i % categoryColors.length],
                    title: '',
                    radius: 50,
                  );
                }),
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyBreakdownPanel(Map<int, double> weekly) {
    final maxY = (weekly.values.isEmpty) ? 10.0 : weekly.values.reduce(max) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Weekly Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: weekly.entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(toY: e.value, color: const Color(0xFFE91E63), width: 18, borderRadius: BorderRadius.circular(6))
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text("W${v.toInt()}"))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInsightPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Financial Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Get a smart summary of your spending habits and personalized tips."),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiFinancialReportScreen())),
              child: const Text("Generate AI Report"),
            ),
          ),
        ],
      ),
    );
  }
}