import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetChartScreen extends StatelessWidget {
  const BudgetChartScreen({super.key});

  // Define a consistent color palette to use in both chart and legend
  final List<Color> _chartColors = const [
    Colors.pink,
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EXPENSE ANALYSIS"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // Fetch budgets only for the logged-in user
          stream: FirebaseFirestore.instance
              .collection('budgets')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No data available for chart"));
            }

            // Map to hold category totals
            Map<String, double> dataMap = {};
            for (var doc in snapshot.data!.docs) {
              String category = doc['category'] ?? 'Other';
              // Check for 'spent' or 'spentAmount' depending on your Firestore field name
              double spent = (doc['spent'] ?? doc['spentAmount'] ?? 0.0).toDouble();
              if (spent > 0) {
                dataMap[category] = (dataMap[category] ?? 0) + spent;
              }
            }

            if (dataMap.isEmpty) {
              return const Center(child: Text("No spending recorded yet."));
            }

            return Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Spending Distribution",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _getSections(dataMap),
                    ),
                  ),
                ),
                _buildLegend(dataMap),
                const SizedBox(height: 50),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper function to create the pie slices
  List<PieChartSectionData> _getSections(Map<String, double> dataMap) {
    int index = 0;
    return dataMap.entries.map((entry) {
      final color = _chartColors[index % _chartColors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: 'RM${entry.value.toStringAsFixed(0)}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Updated legend: Now shows the correct matching color for each category
  Widget _buildLegend(Map<String, double> dataMap) {
    int index = 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: dataMap.keys.map((category) {
          final color = _chartColors[index % _chartColors.length];
          index++;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle, // Rounded legend looks more modern
                ),
              ),
              const SizedBox(width: 8),
              Text(category, style: const TextStyle(fontSize: 14)),
            ],
          );
        }).toList(),
      ),
    );
  }
}