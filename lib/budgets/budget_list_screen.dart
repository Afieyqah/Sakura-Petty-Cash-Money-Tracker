import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/bottom_navigation.dart';
import 'add_budget_screen.dart'; // Pastikan import ini betul

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
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
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'Staff';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingRole = false);
      }
    }
  }

  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true, // Biar background nampak di belakang nav bar

      // --- 1. FAB YANG TELAH DIKEMASKINI KE ADD BUDGET ---
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 8,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
        },
        child: const Icon(Icons.add, size: 35, color: Color(0xFFE91E63)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- 2. BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: const SharedNavigation(),

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
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('budgets').snapshots(),
              builder: (context, budgetSnap) {
                if (!budgetSnap.hasData) return const Center(child: CircularProgressIndicator());

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                  builder: (context, expSnap) {
                    final allExpenses = expSnap.data?.docs ?? [];

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.pink.withOpacity(0.8),
                          elevation: 0,
                          automaticallyImplyLeading: false,
                          centerTitle: true,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                "BUDGET LIST",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22),
                                onPressed: () => Navigator.pushNamed(context, '/alerts'),
                              ),
                            ],
                          ),
                        ),

                        // Tambah padding di atas list supaya tak rapat sangat dengan AppBar
                        SliverToBoxAdapter(child: const SizedBox(height: 10)),

                        SliverPadding(
                          // Padding bawah 120 supaya item terakhir tidak tenggelam bawah nav bar
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < budgetSnap.data!.docs.length) {
                                  return _buildStyledBudgetCard(budgetSnap.data!.docs[index], allExpenses);
                                }
                                
                                // Butang Analisis di penghujung senarai
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15, bottom: 20),
                                  child: Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () => Navigator.pushNamed(context, '/budget_chart'),
                                      icon: const Icon(Icons.analytics_outlined),
                                      label: const Text("VIEW BUDGET ANALYSIS"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.pink,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: budgetSnap.data!.docs.length + 1,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildStyledBudgetCard(DocumentSnapshot bDoc, List<DocumentSnapshot> expenses) {
    final Map<String, dynamic> bData = bDoc.data() as Map<String, dynamic>;
    final String category = bData['category'] ?? 'General';
    final double budgetLimit = _convertToDouble(bData['amount']);
    
    // Kira total spent untuk kategori ini
    double totalSpent = 0;
    for (var expDoc in expenses) {
      final expData = expDoc.data() as Map<String, dynamic>;
      if (expData['category'].toString().toLowerCase() == category.toLowerCase()) {
        totalSpent += _convertToDouble(expData['amount']);
      }
    }

    double progress = (budgetLimit > 0) ? (totalSpent / budgetLimit) : 0;
    bool isOverBudget = totalSpent > budgetLimit;
    double progressFactor = progress > 1.0 ? 1.0 : progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.toUpperCase(), 
                style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Limit: RM ${budgetLimit.toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 10, 
                width: double.infinity, 
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))
              ),
              FractionallySizedBox(
                widthFactor: progressFactor,
                child: Container(
                  height: 10, 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverBudget 
                        ? [Colors.red, Colors.orange] 
                        : [Colors.pinkAccent, Colors.pink]
                    ),
                    borderRadius: BorderRadius.circular(5)
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Spent: RM ${totalSpent.toStringAsFixed(2)}", 
                style: TextStyle(
                  fontSize: 12, 
                  color: isOverBudget ? Colors.red : Colors.black54,
                  fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal
                )),
              Text("${(progress * 100).toStringAsFixed(0)}%", 
                style: TextStyle(
                  color: isOverBudget ? Colors.red : Colors.pink, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                )),
            ],
          ),
        ],
      ),
    );
  }
}