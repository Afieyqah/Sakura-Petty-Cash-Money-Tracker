import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'monthly_report_screen.dart';
import 'history_screen.dart';

// Category colors
final Map<String, Color> categoryColorMap = {
  "Food": const Color(0xFFBFA2DB),
  "Fuel": const Color(0xFFFFB37B),
  "Stationery": const Color(0xFFF3E5AB),
  "Transport": const Color(0xFFF7C6C7),
  "Misc": const Color(0xFFFFF3A0),
};

const double initialPettyCash = 200.0;

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // ---------------- Parse date from Firestore string ----------------
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
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
            double totalThisMonth = 0;
            double totalLastMonth = 0;
            Map<int, double> monthlyTotals = {};
            Map<int, Map<String, double>> monthlyCategoryData = {};

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount =
                  double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
              final category = data['category'] ?? 'Misc';
              final date = _parseDate(data['date'] ?? '01/01/${now.year}');

              // Monthly totals for current year only
              if (date.year == now.year) {
                monthlyTotals[date.month] =
                    (monthlyTotals[date.month] ?? 0) + amount;

                monthlyCategoryData[date.month] ??= {};
                monthlyCategoryData[date.month]![category] =
                    (monthlyCategoryData[date.month]![category] ?? 0) + amount;
              }

              if (date.month == now.month && date.year == now.year)
                totalThisMonth += amount;
              if (date.month == lastMonth && date.year == lastMonthYear)
                totalLastMonth += amount;
            }

            // Ensure all 12 months exist for trend chart
            Map<int, double> yearlyTotals = Map.fromIterable(
              List.generate(12, (index) => index + 1),
              key: (month) => month,
              value: (month) => monthlyTotals[month] ?? 0.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _thisMonthOverview(
                    thisMonthTotal: totalThisMonth,
                    lastMonthTotal: totalLastMonth,
                    initialPettyCash: initialPettyCash,
                    context: context,
                  ),
                  const SizedBox(height: 20),
                  _monthlyTrendPanel(yearlyTotals, context),
                  const SizedBox(height: 20),
                  _categoryBreakdownPanel(monthlyCategoryData, now),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- This Month Overview ----------------
  Widget _thisMonthOverview({
    required double thisMonthTotal,
    required double lastMonthTotal,
    required double initialPettyCash,
    required BuildContext context,
  }) {
    final remaining = initialPettyCash - thisMonthTotal;
    final percentageChange = lastMonthTotal == 0
        ? 0
        : ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
    final isPositive = percentageChange >= 0;

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
                      "Total Expenses",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "RM ${thisMonthTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${percentageChange.abs().toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "from last month",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 60, width: 1, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Remaining",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "RM ${remaining.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Petty Cash",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MonthlyReportScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Full Report"),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Monthly Trend Panel ----------------
  Widget _monthlyTrendPanel(Map<int, double> data, BuildContext context) {
    const monthAbbr = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    double maxY = data.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b) * 1.2
        : 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Monthly Expenses Trend",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                child: const Text("History"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: data.entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: Colors.pink,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          (value >= 1 && value <= 12)
                          ? Text(monthAbbr[value.toInt() - 1])
                          : const Text(""),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Category Breakdown Panel ----------------
  Widget _categoryBreakdownPanel(
    Map<int, Map<String, double>> monthlyCategoryData,
    DateTime now,
  ) {
    final data = monthlyCategoryData[now.month] ?? {};
    double total = data.values.fold(0, (sum, val) => sum + val);
    final sortedData = data.entries.toList();

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
            "Category Breakdown (This Month)",
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
                      sections: sortedData
                          .map(
                            (e) => PieChartSectionData(
                              value: e.value,
                              color: categoryColorMap[e.key] ?? Colors.grey,
                              title: '',
                              radius: 50,
                            ),
                          )
                          .toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedData.map((e) {
                    final percent = total == 0 ? 0 : (e.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: categoryColorMap[e.key] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${e.key} (${percent.toStringAsFixed(1)}%)",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
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
}