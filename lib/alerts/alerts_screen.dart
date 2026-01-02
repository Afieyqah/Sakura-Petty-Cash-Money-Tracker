import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("NOTIFICATIONS")),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil semua bajet untuk user semasa
        stream: FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No budgets found."));
          }

          // Logik Filter: Hanya tunjuk bajet yang terlebih belanja (spent > amount)
          final alertBudgets = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            double spent = (data['spent'] as num? ?? 0).toDouble();
            double limit = (data['amount'] as num? ?? 0).toDouble();
            return spent > limit;
          }).toList();

          if (alertBudgets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text("Everything is on track! No alerts."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: alertBudgets.length,
            itemBuilder: (context, index) {
              final data = alertBudgets[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red[50],
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                  title: Text(
                    "Overspent: ${data['category'] ?? 'Unknown'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Limit: RM ${data['amount']} | Spent: RM ${data['spent']}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}