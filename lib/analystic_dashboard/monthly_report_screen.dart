import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:selab_project/analystic_dashboard/ai_financial_report.dart';
import 'package:selab_project/analystic_dashboard/history_screen.dart';

// ---------------- Category colors ----------------
final List<String> _categories = [
  "Food",
  "Fuel",
  "Stationery",
  "Transport",
  "Misc",
];
final List<Color> categoryColors = [
  Color(0xFFBFA2DB),
  Color(0xFFFFB37B),
  Color(0xFFF3E5AB),
  Color(0xFFF7C6C7),
  Color(0xFFFFF3A0),
];

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  DateTime _parseDate(String raw) {
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

  // ---------------- Build the Screen ----------------
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Report")),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // ---------------- Process Firestore Data ----------------
            double thisMonthTotal = 0;
            double lastMonthTotal = 0;
            Map<String, double> categoryTotals = {};
            Map<int, double> weeklyTotals = {1: 0, 2: 0, 3: 0, 4: 0};

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount =
                  double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
              final category = data['category'] ?? 'Misc';
              final date = _parseDate(data['date'] ?? '01/01/${now.year}');

              // This month
              if (date.month == now.month && date.year == now.year) {
                thisMonthTotal += amount;

                categoryTotals[category] =
                    (categoryTotals[category] ?? 0) + amount;

                // Weekly totals
                int week = ((date.day - 1) / 7).floor() + 1;
                if (week > 4) week = 4;
                weeklyTotals[week] = (weeklyTotals[week] ?? 0) + amount;
              }

              // Last month
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- Total Spent Panel ----------------
  Widget _totalSpentPanel(BuildContext context, double current, double last) {
    final percent = last == 0 ? 0 : ((current - last) / last * 100);
    final isPositive = percent >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
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
                    const Text(
                      "Total Spent This Month",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "RM ${current.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.pink,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  Text(
                    "${percent.abs().toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "vs last month",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: const Text("History"),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Category Breakdown ----------------
  Widget _categoryBreakdownPanel(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Breakdown",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
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
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  children: entries.map((e) {
                    final percent = total == 0 ? 0 : e.value / total * 100;
                    return Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                categoryColors[entries.indexOf(e) %
                                    categoryColors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text("${e.key} (${percent.toStringAsFixed(1)}%)"),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Weekly Breakdown ----------------
  Widget _weeklyBreakdownPanel(Map<int, double> weekly) {
    final maxY = weekly.isNotEmpty ? weekly.values.reduce(max) * 1.2 : 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Breakdown Trend",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: weekly.entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: Colors.pink,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text("W${v.toInt()}"),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- AI Insight Panel ----------------
  Widget _aiInsightPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Insight Report",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tap Generate Report to get a smart summary of your spending habits, "
            "category highlights, and personalized tips to help you save more this month.",
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiFinancialReportScreen(),
                ),
              );
            },
            child: const Text("Generate Report"),
          ),
        ],
      ),
    );
  }
}
