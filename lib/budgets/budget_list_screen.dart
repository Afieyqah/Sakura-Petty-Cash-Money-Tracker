import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("BUDGET LIST", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // Stream 1: Get the user's budget categories
          stream: FirebaseFirestore.instance
              .collection('budgets')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, budgetSnap) {
            if (budgetSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!budgetSnap.hasData || budgetSnap.data!.docs.isEmpty) {
              return const Center(child: Text("No budgets set. Click + to add one."));
            }

            return StreamBuilder<QuerySnapshot>(
              // Stream 2: Get all expenses to calculate progress
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, expSnap) {
                if (!expSnap.hasData) return const SizedBox();

                final allExpenses = expSnap.data!.docs;

                return SafeArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgetSnap.data!.docs.length,
                    itemBuilder: (context, index) {
                      final bDoc = budgetSnap.data!.docs[index];
                      return _buildBudgetCard(bDoc, allExpenses);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => Navigator.pushNamed(context, '/add-budget'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetCard(DocumentSnapshot bDoc, List<DocumentSnapshot> expenses) {
    final String category = bDoc['category'] ?? 'General';
    final double budgetLimit = (bDoc['amount'] as num).toDouble();

    // Calculate total spent for THIS specific category
    double totalSpent = 0;
    for (var exp in expenses) {
      if (exp['category'] == category) {
        totalSpent += (exp['amount'] as num).toDouble();
      }
    }

    double progress = totalSpent / budgetLimit;
    // Cap progress at 1.0 to prevent the bar from breaking
    if (progress > 1.0) progress = 1.0;

    Color progressColor = progress > 0.9 ? Colors.red : Colors.pink;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                "RM ${totalSpent.toStringAsFixed(2)} / RM ${budgetLimit.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% used",
            style: TextStyle(color: progressColor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}