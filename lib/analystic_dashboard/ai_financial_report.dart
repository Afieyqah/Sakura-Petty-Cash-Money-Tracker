import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:selab_project/ai_service.dart';

class AiFinancialReportScreen extends StatefulWidget {
  const AiFinancialReportScreen({super.key});

  @override
  State<AiFinancialReportScreen> createState() => _AiFinancialReportScreenState();
}

class _AiFinancialReportScreenState extends State<AiFinancialReportScreen> {
  String report = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  // This function now pulls EVERYTHING from Firestore
  Future<void> _generateReport() async {
    setState(() => loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('expenses').get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          report = "Your expense list is empty. Add some data to get started!";
          loading = false;
        });
        return;
      }

      // Map all data without date filtering
      final allExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'category': (data['category'] ?? 'misc').toString().toLowerCase().trim(),
          'amount': data['amount'].toString(),
          'date': data['date'].toString(),
        };
      }).toList();

      final aiService = AiService();
      final result = await aiService.generateMonthlyReport(allExpenses);

      setState(() {
        report = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        report = "Error: Could not reach the AI. Check your internet or API key.";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full AI Analysis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE91E63),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport, // Manual Refresh
            tooltip: "Refresh Report",
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: loading 
          ? _buildLoadingState() 
          : _buildReportContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFE91E63)),
          SizedBox(height: 20),
          Text("Consulting your AI Advisor...", 
            style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights, color: Colors.pink),
                  SizedBox(width: 10),
                  Text("Financial Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 30),
              Text(
                report,
                style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}