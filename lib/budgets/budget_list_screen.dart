import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("BUDGET LIST")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('budgets').where('userId', isEqualTo: user?.uid).snapshots(),
        builder: (context, budgetSnap) {
          if (!budgetSnap.hasData) return const CircularProgressIndicator();
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
            builder: (context, expSnap) {
              if (!expSnap.hasData) return const CircularProgressIndicator();
              // Logic to filter expenses by category and display progress bars
              return ListView(children: budgetSnap.data!.docs.map((doc) => _buildItem(doc, expSnap.data!.docs)).toList());
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(DocumentSnapshot bDoc, List<DocumentSnapshot> expenses) {
    // Progress calculation logic based on category matching
    return ListTile(title: Text(bDoc['name']), subtitle: LinearProgressIndicator(value: 0.5));
  }
}