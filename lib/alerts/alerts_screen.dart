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
        // Fetches all budgets for the current user
        stream: FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter logic: Only show budgets where spent > amount
          final alertBudgets = snapshot.data!.docs.where((doc) {
            double spent = (doc['spent'] as num).toDouble();
            double limit = (doc['amount'] as num).toDouble();
            return spent > limit;
          }).toList();

          if (alertBudgets.isEmpty) {
            return const Center(child: Text("Everything is on track! No alerts."));
          }

          return ListView.builder(
            itemCount: alertBudgets.length,
            itemBuilder: (context, index) {
              final data = alertBudgets[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red[50],
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  title: Text("Overspent: ${data['category']}"),
                  subtitle: Text("Limit: RM ${data['amount']} | Spent: RM ${data['spent']}"),
                  trailing: const Text("Check now", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}