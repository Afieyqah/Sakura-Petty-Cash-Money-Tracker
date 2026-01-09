import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'monthly_report_screen.dart';
import 'history_screen.dart';
import '../screens/add_expense.dart'; 
import '../screens/bottom_navigation.dart'; 

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;
  final Color primaryPink = const Color(0xFFE91E63);

  // Map warna untuk kategori
  final Map<String, Color> categoryColorMap = {
    "food": const Color(0xFFFF1744),
    "fuel": const Color(0xFFF06292),
    "stationery": const Color(0xFFEC407A),
    "transport": const Color(0xFFC2185B),
    "misc": const Color(0xFFF48FB1),
  };

  // Helper untuk parse tarikh dari pelbagai format
  DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    try {
      final parts = raw.toString().split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return DateTime.now();
    }
  }

  // Helper untuk parse amount (elak ralat String/Double)
  double _parseNum(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. WAJIB: extendBody supaya background nampak di belakang Nav Bar
      extendBody: true, 
      extendBodyBehindAppBar: true,

      // 2. FIXED FAB: Letak di sini supaya tidak "motionless"
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 8,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add, size: 35, color: Color(0xFFE91E63)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 3. NAV BAR
      bottomNavigationBar: const SharedNavigation(),

      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/images/cherry_blossom_bg.jpg', fit: BoxFit.cover),
          ),
          // Overlay putih nipis supaya text senang dibaca
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.3))),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
            builder: (context, accountSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                builder: (context, expenseSnapshot) {
                  if (!accountSnapshot.hasData || !expenseSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pink));
                  }

                  // Logik pengiraan real-time
                  double totalAccountBalance = 0;
                  for (var doc in accountSnapshot.data!.docs) {
                    totalAccountBalance += _parseNum(doc['balance']);
                  }

                  final now = DateTime.now();
                  double totalThisMonth = 0;
                  double totalLastMonth = 0;
                  Map<String, double> categoryData = {};
                  Map<int, double> yearlyTotals = {for (var i = 1; i <= 12; i++) i: 0.0};

                  for (var doc in expenseSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = _parseNum(data['amount']);
                    final category = (data['category'] ?? 'misc').toString().toLowerCase().trim();
                    final date = _parseDate(data['date']);

                    if (date.year == now.year) {
                      yearlyTotals[date.month] = (yearlyTotals[date.month] ?? 0) + amount;
                    }

                    if (date.month == now.month && date.year == now.year) {
                      totalThisMonth += amount;
                      categoryData[category] = (categoryData[category] ?? 0) + amount;
                    }
                    
                    int lastM = now.month == 1 ? 12 : now.month - 1;
                    int lastY = now.month == 1 ? now.year - 1 : now.year;
                    if (date.month == lastM && date.year == lastY) {
                      totalLastMonth += amount;
                    }
                  }

                  double realTimeRemaining = totalAccountBalance - totalThisMonth;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.only(top: 80, bottom: 20),
                          child: const Center(
                            child: Text("Analytics",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
                          ),
                        ),
                      ),
                      SliverPadding(
                        // Padding bawah 120 supaya chart tidak ditutup oleh Nav Bar
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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

  // --- WIDGET COMPONENTS ---

  Widget _buildTotalExpenseCard(double current, double last, double remaining) {
    double diff = last == 0 ? 0 : ((current - last) / last) * 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol("Monthly Spent", "RM ${current.toStringAsFixed(2)}", primaryPink),
              _buildStatCol("Available", "RM ${remaining.toStringAsFixed(2)}", Colors.black87),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${diff >= 0 ? '↑' : '↓'} ${diff.abs().toStringAsFixed(1)}% vs last month",
                style: TextStyle(color: diff >= 0 ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen())),
                child: Text("View Report >", style: TextStyle(color: primaryPink)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, double> categories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Spending by Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: categories.isEmpty 
              ? const Center(child: Text("No data this month"))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: categories.entries.map((e) {
                      return PieChartSectionData(
                        color: categoryColorMap[e.key] ?? Colors.grey.shade300,
                        value: e.value,
                        title: e.key[0].toUpperCase(),
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(Map<int, double> trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text("Yearly Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: trend.values.isEmpty ? 100 : trend.values.reduce((a, b) => a > b ? a : b) * 1.2,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                        return Text(months[v.toInt()-1], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: trend.entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(toY: e.value, color: primaryPink, width: 12, borderRadius: BorderRadius.circular(4))],
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
      Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: col)),
    ]);
  }
}