import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_navigation.dart';
import 'view_expense.dart';
import 'expenses_list.dart';

class ExpenseMainScreen extends StatefulWidget {
  const ExpenseMainScreen({super.key});

  @override
  State<ExpenseMainScreen> createState() => _ExpenseMainScreenState();
}

class _ExpenseMainScreenState extends State<ExpenseMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateRange = "All Time";
  String _searchKeyword = "";
  final double _initialBudget = 200.00;

  final List<String> _dateRanges = [
    "Today",
    "Yesterday",
    "This Week",
    "This Month",
    "Last Month",
    "All Time",
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

  DateTime _parseDateString(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return DateTime(2000);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case "transport":
        return Icons.directions_bus_rounded;
      case "food":
        return Icons.restaurant_rounded;
      case "stationery":
        return Icons.edit_note_rounded;
      case "miscellaneous/others":
        return Icons.more_horiz_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const SharedNavigation(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/sakura.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.5)),
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
                  const SizedBox(height: 130),
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
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount =
                double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
            totalSpent += amount;
          }
        }
        double remaining = _initialBudget - totalSpent;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Current Petty Cash Balance",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "RM ${remaining.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Total Spent: RM ${totalSpent.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

        if (_searchKeyword.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['remark'] ?? '').toString().toLowerCase().contains(
                  _searchKeyword,
                ) ||
                (data['category'] ?? '').toString().toLowerCase().contains(
                  _searchKeyword,
                );
          }).toList();
        }

        // Sort by Date String parsed to DateTime
        docs.sort((a, b) {
          DateTime dateA = _parseDateString(
            (a.data() as Map<String, dynamic>)['date'] ?? "",
          );
          DateTime dateB = _parseDateString(
            (b.data() as Map<String, dynamic>)['date'] ?? "",
          );
          return dateB.compareTo(dateA);
        });

        var top3 = docs.take(3).toList();
        if (top3.isEmpty) {
          return const Center(child: Text("No expenses found."));
        }
        return Column(
          children: top3.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildExpenseItem(
              context,
              doc.id,
              data['remark'] ?? 'No Remark',
              data['date'] ?? 'No Date',
              data['amount']?.toString() ?? '0.00',
              data['category'] ?? 'Other',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    String docId,
    String title,
    String date,
    String price,
    String category,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewExpenseScreen(documentId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD81B60).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "- RM $price",
                style: const TextStyle(
                  color: Color(0xFFD81B60),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Header, SearchField, QuickFilters, ViewAllButton remain the same as previous)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Expenses",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF880E4F),
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.pink[100],
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage("assets/logo.jpeg"),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5)),
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
        const Text(
          "Sort by: ",
          style: TextStyle(
            color: Color(0xFF880E4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDateRange,
                isExpanded: true,
                onChanged: (val) => setState(() => _selectedDateRange = val!),
                items: _dateRanges
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          shape: const StadiumBorder(),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        ),
        child: const Text(
          "VIEW ALL EXPENSES",
          style: TextStyle(
            color: Color(0xFFD81B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
