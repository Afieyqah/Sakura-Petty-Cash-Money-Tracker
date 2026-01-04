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
        title: const Text("Budget", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 26)),
        backgroundColor: Colors.pink.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
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
          stream: FirebaseFirestore.instance
              .collection('budgets')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, budgetSnap) {
            if (!budgetSnap.hasData) return const Center(child: CircularProgressIndicator());

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, expSnap) {
                final allExpenses = expSnap.data?.docs ?? [];
                
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 120, left: 20, right: 20),
                  itemCount: budgetSnap.data!.docs.length,
                  itemBuilder: (context, index) {
                    return _buildStyledBudgetCard(budgetSnap.data!.docs[index], allExpenses);
                  },
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

  Widget _buildStyledBudgetCard(DocumentSnapshot bDoc, List<DocumentSnapshot> expenses) {
    final String category = bDoc['category'] ?? 'General';
    final double budgetLimit = (bDoc['amount'] as num).toDouble();
    double totalSpent = 0;

    for (var exp in expenses) {
      if (exp['category'] == category) {
        totalSpent += (exp['amount'] as num).toDouble();
      }
    }

    double progress = (budgetLimit > 0) ? (totalSpent / budgetLimit) : 0;
    if (progress > 1.0) progress = 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("RM ${budgetLimit.toInt()}", style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "SPENT RM ${totalSpent.toInt()} OF RM ${budgetLimit.toInt()}",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text("${(progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }
}