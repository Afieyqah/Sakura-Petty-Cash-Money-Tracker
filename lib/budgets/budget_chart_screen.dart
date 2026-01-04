import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BudgetChartScreen extends StatefulWidget {
  const BudgetChartScreen({super.key});

  @override
  State<BudgetChartScreen> createState() => _BudgetChartScreenState();
}

class _BudgetChartScreenState extends State<BudgetChartScreen> {
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("EXPENSE ANALYSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            const SizedBox(height: 120),
            _buildMonthFilter(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  Map<String, double> dataMap = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Kendali Tarikh (Timestamp vs String)
                    DateTime date;
                    var d = data['date'];
                    if (d is Timestamp) date = d.toDate();
                    else if (d is String) date = DateTime.tryParse(d) ?? DateTime.now();
                    else date = DateTime.now();

                    if (DateFormat('MMMM yyyy').format(date) == _selectedMonth) {
                      String cat = data['category'] ?? 'Other';
                      dataMap[cat] = (dataMap[cat] ?? 0.0) + _safeDouble(data['amount']);
                    }
                  }

                  if (dataMap.isEmpty) return const Center(child: Text("No data for this month.", style: TextStyle(color: Colors.white)));

                  return _buildChartUI(dataMap);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilter() {
    List<String> months = List.generate(6, (index) => DateFormat('MMMM yyyy').format(DateTime.now().subtract(Duration(days: 30 * index))));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButton<String>(
        value: _selectedMonth,
        isExpanded: true,
        underline: const SizedBox(),
        items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) => setState(() => _selectedMonth = v!),
      ),
    );
  }

  Widget _buildChartUI(Map<String, double> dataMap) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(25)),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: dataMap.entries.map((e) {
                    return PieChartSectionData(
                      color: Colors.pinkAccent.withOpacity(0.7),
                      value: e.value,
                      title: 'RM${e.value.toStringAsFixed(0)}',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              children: dataMap.keys.map((k) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Chip(label: Text(k, style: const TextStyle(fontSize: 10))),
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}