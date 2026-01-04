import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bottom_navigation.dart'; // Fail SharedNavigation anda
import 'add_expense.dart';       // Skrin tambah expense
import 'view_expense.dart';
import 'expenses_list.dart';

class ExpenseMainScreen extends StatefulWidget {
  const ExpenseMainScreen({super.key});

  @override
  State<ExpenseMainScreen> createState() => _ExpenseMainScreenState();
}

class _ExpenseMainScreenState extends State<ExpenseMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final Color themePink = const Color(0xFFE91E63);
  
  String _selectedDateRange = "All Time";
  String _searchKeyword = "";

  final List<String> _dateRanges = [
    "Today", "Yesterday", "This Week", "This Month", "Last Month", "All Time",
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchKeyword = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _parseAmount(dynamic raw) {
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case "transport": return Icons.directions_bus_rounded;
      case "food": return Icons.restaurant_rounded;
      case "stationery": return Icons.edit_note_rounded;
      case "miscellaneous/others": return Icons.more_horiz_rounded;
      default: return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Supaya background nampak di belakang Nav Bar
      bottomNavigationBar: const SharedNavigation(),
      
      // --- FLOATING ACTION BUTTON (DENGAN NOTCH) ---
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: themePink,
          elevation: 8,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
            );
          },
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/cherry_blossom_bg.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.4)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildSearchField(),
                  const SizedBox(height: 15),
                  _buildQuickFilters(),
                  const SizedBox(height: 25),
                  const Text(
                    "Recent Expenses:",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF880E4F),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExpenseContent(),
                  const SizedBox(height: 20),
                  _buildViewAllButton(),
                  const SizedBox(height: 130), // Ruang untuk Nav Bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').where('userId', isEqualTo: user?.uid).snapshots(),
      builder: (context, accountSnapshot) {
        double totalNetWorth = 0.0;
        if (accountSnapshot.hasData) {
          for (var doc in accountSnapshot.data!.docs) {
            totalNetWorth += _parseAmount(doc['balance']);
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expenseSnapshot) {
            double totalSpent = 0.0;
            if (expenseSnapshot.hasData) {
              for (var doc in expenseSnapshot.data!.docs) {
                totalSpent += _parseAmount(doc['amount']);
              }
            }
            double remaining = totalNetWorth - totalSpent;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: themePink.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Available Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    "RM ${remaining.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Net Worth: RM ${totalNetWorth.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Spent: RM ${totalSpent.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Expenses", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF880E4F))),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.pink[100],
          child: const CircleAvatar(radius: 20, backgroundImage: AssetImage("assets/images/logo.jpeg")),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, size: 18, color: Colors.pink),
          hintText: "Search..",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Row(
      children: [
        const Text("Sort by: ", style: TextStyle(color: Color(0xFF880E4F), fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDateRange,
                isExpanded: true,
                onChanged: (val) => setState(() => _selectedDateRange = val!),
                items: _dateRanges.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

        if (_searchKeyword.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['remark'] ?? '').toString().toLowerCase().contains(_searchKeyword) ||
                   (data['category'] ?? '').toString().toLowerCase().contains(_searchKeyword);
          }).toList();
        }

        var top3 = docs.take(3).toList();
        if (top3.isEmpty) return const Center(child: Text("No records found."));

        return Column(
          children: top3.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildExpenseItem(
              context,
              doc.id,
              data['remark'] ?? 'No Remark',
              data['category'] ?? 'Other',
              _parseAmount(data['amount']).toStringAsFixed(2),
              data['category'] ?? 'Other',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExpenseItem(BuildContext context, String docId, String title, String date, String price, String category) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewExpenseScreen(documentId: docId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD81B60).withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(_getCategoryIcon(category), color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("Category: $category", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text("- RM $price", style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: const StadiumBorder(),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseListScreen())),
        child: const Text("VIEW ALL EXPENSES", style: TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold)),
      ),
    );
  }
}