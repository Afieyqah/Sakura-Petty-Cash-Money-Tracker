// lib/screens/ai_financial_report_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:selab_project/ai_service.dart'; // make sure the path is correct

class AiFinancialReportScreen extends StatefulWidget {
  const AiFinancialReportScreen({super.key});

  @override
  State<AiFinancialReportScreen> createState() =>
      _AiFinancialReportScreenState();
}

class _AiFinancialReportScreenState extends State<AiFinancialReportScreen> {
  String report = "Generating report...";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    try {
      final now = DateTime.now();

      // 1️⃣ Get all expenses from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .get();

      // 2️⃣ Convert Firestore docs to usable list
      final expenses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'category': data['category'] ?? 'Misc',
          'amount': data['amount'].toString(),
          'date': data['date'] ?? '',
        };
      }).toList();

      // 3️⃣ Filter expenses for this month
      final thisMonthExpenses = expenses.where((e) {
        try {
          final parts = e['date'].split('/');
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return date.month == now.month && date.year == now.year;
        } catch (_) {
          return false;
        }
      }).toList();

      // 4️⃣ Generate AI report
      final aiService = AiService();
      final generatedReport = await aiService.generateMonthlyReport(
        thisMonthExpenses,
      );

      // 5️⃣ Update UI
      setState(() {
        report = generatedReport.isNotEmpty
            ? generatedReport
            : "No expenses this month to generate report.";
        loading = false;
      });
    } catch (e) {
      setState(() {
        report = "Failed to generate report. Please check your connection.";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Financial Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Text(
                  report,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
      ),
    );
  }
}
