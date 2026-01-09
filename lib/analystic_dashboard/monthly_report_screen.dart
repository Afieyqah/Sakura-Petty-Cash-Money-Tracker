import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:selab_project/analystic_dashboard/ai_financial_report.dart';
import 'package:selab_project/analystic_dashboard/history_screen.dart';
import '../screens/bottom_navigation.dart'; 
import '../screens/add_expense.dart';       

// ---------------- Category colors ----------------
final List<Color> categoryColors = [
  const Color(0xFFBFA2DB),
  const Color(0xFFFFB37B),
  const Color(0xFFF3E5AB),
  const Color(0xFFF7C6C7),
  const Color(0xFFFFF3A0),
];

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

  // Handle Timestamp Firestore & String
  DateTime _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        final parts = raw.split('/');
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
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
      // 1. PENTING: ExtendBody supaya background gambar penuh sampai bawah Nav Bar
      extendBody: true, 
      
      appBar: AppBar(
        title: const Text("Monthly Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themePink,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // 2. INTEGRASI NAVIGATION BAR (Gunakan fail SharedNavigation anda)
      bottomNavigationBar: const SharedNavigation(),
      
      // 3. FLOATING ACTION BUTTON (Diletakkan di centerDocked)
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: Icon(Icons.add, size: 35, color: themePink),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('assets/images/cherry_blossom_bg.jpg', fit: BoxFit.cover),
          ),
          // Overlay sedikit gelap supaya teks senang dibaca
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.05))),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No expenses found."));
              }

              double thisMonthTotal = 0;
              double lastMonthTotal = 0;
              Map<String, double> categoryTotals = {};
              Map<int, double> weeklyTotals = {1: 0, 2: 0, 3: 0, 4: 0};

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
                final category = data['category'] ?? 'Misc';
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _totalSpentPanel(context, thisMonthTotal, lastMonthTotal),
                    const SizedBox(height: 20),
                    _categoryBreakdownPanel(categoryTotals),
                    const SizedBox(height: 20),
                    _weeklyBreakdownPanel(weeklyTotals),
                    const SizedBox(height: 20),
                    _aiInsightPanel(context),
                    const SizedBox(height: 120), // Ruang ekstra supaya kandungan tak kena tutup dek Nav Bar
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- Widget Panels ----------------

  Widget _totalSpentPanel(BuildContext context, double current, double last) {
    final percent = last == 0 ? 0.0 : ((current - last) / last * 100);
    final isPositive = percent >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("This Month", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    "RM ${current.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFFE91E63), fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%",
                      style: TextStyle(color: isPositive ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const Text("vs last month", style: TextStyle(color: Colors.black54, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              icon: const Icon(Icons.history, size: 18),
              label: const Text("View Full History"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdownPanel(Map<String, double> data) {
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category Distribution", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: data.isEmpty 
              ? const Center(child: Text("No data for this month"))
              : PieChart(
                  PieChartData(
                    sections: List.generate(entries.length, (i) {
                      return PieChartSectionData(
                        value: entries[i].value,
                        color: categoryColors[i % categoryColors.length],
                        title: entries[i].key,
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                      );
                    }),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyBreakdownPanel(Map<int, double> weekly) {
    final maxY = (weekly.values.isEmpty) ? 10.0 : weekly.values.reduce(max) * 1.3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Weekly Spending", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weekly.entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(toY: e.value, color: const Color(0xFFE91E63), width: 18, borderRadius: BorderRadius.circular(4))
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("W${v.toInt()}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ))),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInsightPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.white]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.pink.shade300),
              const SizedBox(width: 8),
              const Text("AI Financial Insight", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Dapatkan ringkasan pintar tentang tabiat perbelanjaan anda bulan ini.", style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiFinancialReportScreen())),
              child: const Text("Generate AI Report"),
            ),
          ),
        ],
      ),
    );
  }
}