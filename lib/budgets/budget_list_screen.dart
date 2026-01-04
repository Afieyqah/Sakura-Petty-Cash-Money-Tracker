import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // --- SOLUSI RALAT DATA: Menukar apa sahaja jenis data (String/num) kepada double ---
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
                              // --- SOLUSI BLACKOUT: Gunakan Navigator.pop ---
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    // Fallback jika stack kosong
                                    Navigator.pushReplacementNamed(context, '/dashboard');
                                  }
                                },
                              ),
                              const Text(
                                "BUDGET",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 22,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22),
                                onPressed: () => Navigator.pushNamed(context, '/alerts'),
                              ),
                            ],
                          ),
                        ),

                        if (_userRole != 'Staff')
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.8),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/add-budget'),
                                child: const Text(
                                  "Add Budget",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < budgetSnap.data!.docs.length) {
                                  return _buildStyledBudgetCard(budgetSnap.data!.docs[index], allExpenses);
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 50),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/budget_chart'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.pink]),
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                                          ],
                                        ),
                                        child: const Text(
                                          "VIEW ANALYSIS",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
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
    
    // Paksa tukar ke double untuk elak ralat num?
    final double budgetLimit = _convertToDouble(bData['amount']);
    
    double totalSpent = 0;

    for (var expDoc in expenses) {
      final expData = expDoc.data() as Map<String, dynamic>;
      if (expData['category'] == category) {
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.toUpperCase(), style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("RM ${budgetLimit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
              FractionallySizedBox(
                widthFactor: progressFactor,
                child: Container(
                  height: 8, 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isOverBudget ? [Colors.red, Colors.redAccent] : [Colors.pinkAccent, Colors.pink]),
                    borderRadius: BorderRadius.circular(5)
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Spent: RM ${totalSpent.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: isOverBudget ? Colors.red : Colors.pink, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}