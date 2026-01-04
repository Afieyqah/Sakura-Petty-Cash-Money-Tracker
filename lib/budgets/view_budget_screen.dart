import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewBudgetScreen extends StatefulWidget {
  const ViewBudgetScreen({super.key});

  @override
  State<ViewBudgetScreen> createState() => _ViewBudgetScreenState();
}

class _ViewBudgetScreenState extends State<ViewBudgetScreen> {
  String _userRole = 'Staff'; 
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'Staff';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        setState(() => _isLoadingRole = false);
      }
    }
  }

  void _deleteBudget(String docId) {
    FirebaseFirestore.instance.collection('budgets').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VIEW BUDGET"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoadingRole 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('budgets').snapshots(),
              builder: (context, budgetSnapshot) {
                if (!budgetSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                  builder: (context, expenseSnapshot) {
                    // --- LOGIK PENGIRAAN YANG SELAMAT (MENGELAKKAN RALAT 'num?') ---
                    Map<String, double> categorySpending = {};
                    if (expenseSnapshot.hasData) {
                      for (var doc in expenseSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        String cat = data['category'] ?? 'General';
                        
                        double amt = 0.0;
                        var rawAmount = data['amount'];

                        // Jika amount disimpan sebagai String ("10.0") atau Number (10.0)
                        if (rawAmount is String) {
                          amt = double.tryParse(rawAmount) ?? 0.0;
                        } else if (rawAmount is num) {
                          amt = rawAmount.toDouble();
                        }
                        
                        categorySpending[cat] = (categorySpending[cat] ?? 0.0) + amt;
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: budgetSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = budgetSnapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        final String category = data['category'] ?? 'General';
                        
                        // Casting yang selamat untuk budget limit
                        double limit = 0.0;
                        var rawLimit = data['amount'];
                        if (rawLimit is String) {
                          limit = double.tryParse(rawLimit) ?? 0.0;
                        } else if (rawLimit is num) {
                          limit = rawLimit.toDouble();
                        }

                        final double spent = categorySpending[category] ?? 0.0;
                        double percent = limit > 0 ? (spent / limit) : 0.0;
                        double barValue = percent > 1.0 ? 1.0 : percent;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white.withOpacity(0.9),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['name']?.toString().toUpperCase() ?? 'BUDGET',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (_userRole != 'Staff')
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showBudgetDialog(context, doc: doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteBudget(doc.id),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Category: $category", style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    value: barValue,
                                    backgroundColor: Colors.pink[50],
                                    color: percent >= 0.9 ? Colors.red : Colors.pink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "RM ${spent.toStringAsFixed(2)} / RM ${limit.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: percent > 1.0 ? Colors.red : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      "${(percent * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                );
              },
            ),
      ),
      floatingActionButton: (_userRole != 'Staff')
          ? FloatingActionButton(
              backgroundColor: Colors.pink,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showBudgetDialog(context),
            )
          : null,
    );
  }

  void _showBudgetDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final nameController = TextEditingController(text: doc != null ? doc['name'] : '');
    final amountController = TextEditingController(text: doc != null ? doc['amount'].toString() : '');
    String? selectedCategory = doc != null ? doc['category'] : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(doc == null ? "Add Budget" : "Edit Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Budget Name")),
            TextField(
              controller: amountController, 
              decoration: const InputDecoration(labelText: "Limit (RM)"), 
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, catSnap) {
                List<String> items = ['Stationery', 'Food', 'Transport', 'Bills', 'Fuel', 'Banner'];
                if (catSnap.hasData) {
                  for (var d in catSnap.data!.docs) {
                    if (!items.contains(d['name'])) items.add(d['name']);
                  }
                }
                return DropdownButtonFormField<String>(
                  value: items.contains(selectedCategory) ? selectedCategory : null,
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => selectedCategory = val,
                  decoration: const InputDecoration(labelText: "Select Category", border: OutlineInputBorder()),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () async {
              if (nameController.text.isEmpty || amountController.text.isEmpty) return;
              
              final data = {
                'name': nameController.text.trim(),
                'amount': double.tryParse(amountController.text) ?? 0.0,
                'category': selectedCategory ?? 'General',
                'userId': FirebaseAuth.instance.currentUser?.uid,
              };

              if (doc == null) {
                await FirebaseFirestore.instance.collection('budgets').add(data);
              } else {
                await FirebaseFirestore.instance.collection('budgets').doc(doc.id).update(data);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}