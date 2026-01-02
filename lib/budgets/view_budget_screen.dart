import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewBudgetScreen extends StatelessWidget {
  const ViewBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("VIEW BUDGET"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        // Tema estetik Sakura
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // Hanya tarik data milik user semasa
          stream: FirebaseFirestore.instance
              .collection('budgets')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No budgets found. Add one to see progress!",
                  style: TextStyle(backgroundColor: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final String name = data['name'] ?? 'Unnamed';
                final String category = data['category'] ?? 'General';
                final double limit = (data['amount'] as num? ?? 0.0).toDouble();
                final double spent = (data['spent'] as num? ?? 0.0).toDouble();
                
                // Kira peratusan progres
                double percent = limit > 0 ? (spent / limit) : 0.0;
                // Hadkan bar pada 100% (1.0) untuk visual
                double barValue = percent > 1.0 ? 1.0 : percent;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  category,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              "RM ${limit.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: barValue,
                            minHeight: 10,
                            backgroundColor: Colors.pink[50],
                            // Bar jadi MERAH jika belanja > 90% daripada had
                            color: percent >= 0.9 ? Colors.red : Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Spent: RM ${spent.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: percent > 1.0 ? Colors.red : Colors.black87,
                                fontWeight: percent > 1.0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              "${(percent * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}