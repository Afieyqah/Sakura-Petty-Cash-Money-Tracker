import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'monthly_report_screen.dart';
import 'history_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;
  final Color primaryPink = const Color(0xFFE91E63);

  // --- TEMA ALL PINK (Dikutip dari rona Sakura) ---
  final Map<String, Color> categoryColorMap = {
    "food": const Color(0xFFFF1744),       // Deep Pink
    "fuel": const Color(0xFFF06292),       // Light Pink
    "stationery": const Color(0xFFEC407A), // Medium Pink
    "transport": const Color(0xFFC2185B),  // Dark Pink
    "misc": const Color(0xFFF48FB1),       // Soft Pink
  };

  DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    try {
      final parts = raw.toString().split('/'); // Format DD/MM/YYYY
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/cherry_blossom_bg.jpg', fit: BoxFit.cover),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
            builder: (context, accountSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                builder: (context, expenseSnapshot) {
                  if (!accountSnapshot.hasData || !expenseSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pink));
                  }

                  // 1. KIRA TOTAL BAKI AKAUN (REAL-TIME)
                  double totalAccountBalance = 0;
                  for (var doc in accountSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalAccountBalance += (data['balance'] is num) 
                        ? (data['balance'] as num).toDouble() 
                        : double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
                  }

                  // 2. PROSES DATA EXPENSES (FIXED LOGIC)
                  final now = DateTime.now();
                  double totalThisMonth = 0;
                  double totalLastMonth = 0;
                  Map<String, double> categoryData = {};
                  Map<int, double> yearlyTotals = {for (var i = 1; i <= 12; i++) i: 0.0};

                  for (var doc in expenseSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] is num) 
                        ? (data['amount'] as num).toDouble() 
                        : double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
                    
                    final category = (data['category'] ?? 'misc').toString().toLowerCase().trim();
                    final date = _parseDate(data['date']);

                    // Kira trend tahunan (Tahun Semasa)
                    if (date.year == now.year) {
                      yearlyTotals[date.month] = (yearlyTotals[date.month] ?? 0) + amount;
                    }

                    // Kira Bulan Ini
                    if (date.month == now.month && date.year == now.year) {
                      totalThisMonth += amount;
                      categoryData[category] = (categoryData[category] ?? 0) + amount;
                    }
                    
                    // Kira Bulan Lepas
                    int lastM = now.month == 1 ? 12 : now.month - 1;
                    int lastY = now.month == 1 ? now.year - 1 : now.year;
                    if (date.month == lastM && date.year == lastY) {
                      totalLastMonth += amount;
                    }
                  }

                  // 3. REMAINING = BAKI DASHBOARD - EXPENSES BULAN INI
                  double realTimeRemaining = totalAccountBalance - totalThisMonth;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.only(top: 60, bottom: 20),
                          child: const Center(
                            child: Text("Analytics",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildTotalExpenseCard(totalThisMonth, totalLastMonth, realTimeRemaining),
                            const SizedBox(height: 16),
                            _buildPieChartCard(categoryData),
                            const SizedBox(height: 16),
                            _buildTrendCard(yearlyTotals),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- CARD 1: OVERVIEW ---
  Widget _buildTotalExpenseCard(double current, double last, double remaining) {
    double diff = last == 0 ? 0 : ((current - last) / last) * 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol("Total Expenses", "RM ${current.toStringAsFixed(2)}", primaryPink),
              _buildStatCol("Remaining", "RM ${remaining.toStringAsFixed(2)}", Colors.black87),
            ],
          ),
          const Divider(height: 30, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${diff >= 0 ? '↑' : '↓'} ${diff.abs().toStringAsFixed(1)}% vs last month",
                style: TextStyle(color: diff >= 0 ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("Full Report", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- CARD 2: PIE CHART (ALL PINK) ---
  Widget _buildPieChartCard(Map<String, double> categories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Category Distribution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      setState(() => touchedIndex = -1);
                      return;
                    }
                    setState(() => touchedIndex = response.touchedSection!.touchedSectionIndex);
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: categories.entries.map((e) {
                  final index = categories.keys.toList().indexOf(e.key);
                  final isTouched = index == touchedIndex;
                  return PieChartSectionData(
                    color: categoryColorMap[e.key] ?? Colors.pink.shade100,
                    value: e.value,
                    radius: isTouched ? 70 : 60,
                    title: isTouched ? '${e.key}\nRM${e.value.toStringAsFixed(0)}' : '',
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const Text("Tap segments for details", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  // --- CARD 3: TREND (PINK BARS) ---
  Widget _buildTrendCard(Map<int, double> trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                child: Text("History", style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: (trend.values.isEmpty || trend.values.reduce((a, b) => a > b ? a : b) == 0) ? 100 : trend.values.reduce((a, b) => a > b ? a : b) * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.pink.withOpacity(0.05), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 35, 
                      getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey))
                    )
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                        if (v < 1 || v > 12) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[v.toInt()-1], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: trend.entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value, 
                      color: primaryPink, 
                      width: 14, 
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(show: true, toY: 0, color: Colors.pink.withOpacity(0.05))
                    )
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String val, Color col) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col)),
    ]);
  }
}