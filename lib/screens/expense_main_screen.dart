import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Tambah package intl di pubspec.yaml
import 'bottom_navigation.dart';
import 'add_expense.dart';
import 'expenses_list.dart';

class ExpenseMainScreen extends StatefulWidget {
  const ExpenseMainScreen({super.key});

  @override
  State<ExpenseMainScreen> createState() => _ExpenseMainScreenState();
}

class _ExpenseMainScreenState extends State<ExpenseMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();
  final Color themePink = const Color(0xFFE91E63);

  String _selectedDateRange = "All Time";
  String _searchKeyword = "";
  bool _isFabVisible = true;

  final List<String> _dateRanges = ["Today", "Yesterday", "This Week", "This Month", "Last Month", "All Time"];

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(() {
      if (_mainScrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_mainScrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });

    _searchController.addListener(() {
      setState(() => _searchKeyword = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  double _parseAmount(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  // LOGIK TAPISAN TARIKH
  bool _isWithinRange(dynamic dateData) {
    DateTime date;
    if (dateData is Timestamp) {
      date = dateData.toDate();
    } else {
      try {
        date = DateFormat("dd/MM/yyyy").parse(dateData.toString());
      } catch (_) {
        return true; 
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateRange) {
      case "Today":
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case "Yesterday":
        final yesterday = today.subtract(const Duration(days: 1));
        return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
      case "This Week":
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(seconds: 1)));
      case "This Month":
        return date.year == now.year && date.month == now.month;
      case "Last Month":
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return date.year == year && date.month == lastMonth;
      default:
        return true;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case "transport": return Icons.directions_bus_rounded;
      case "food": return Icons.restaurant_rounded;
      case "stationery": return Icons.edit_note_rounded;
      default: return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: AnimatedScale(
        scale: _isFabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 8,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
          child: Icon(Icons.add, color: themePink, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SharedNavigation(
        scrollController: _mainScrollController,
        isFabVisible: _isFabVisible,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cherry_blossom_bg.jpg", fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.4))),
          SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
              builder: (context, accountSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots(),
                  builder: (context, expenseSnap) {
                    if (!accountSnap.hasData || !expenseSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.pink));
                    }

                    // PENGIRAAN REAL-TIME
                    double totalNetWorth = 0;
                    for (var doc in accountSnap.data!.docs) {
                      totalNetWorth += _parseAmount(doc['balance']);
                    }

                    // Tapis data untuk carian dan tarikh
                    var filteredDocs = expenseSnap.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      bool matchSearch = (data['remark'] ?? '').toString().toLowerCase().contains(_searchKeyword) ||
                                         (data['category'] ?? '').toString().toLowerCase().contains(_searchKeyword);
                      bool matchDate = _isWithinRange(data['date']);
                      return matchSearch && matchDate;
                    }).toList();

                    double totalSpent = filteredDocs.fold(0, (sum, doc) => sum + _parseAmount(doc['amount']));
                    double availableBalance = totalNetWorth - totalSpent;

                    return SingleChildScrollView(
                      controller: _mainScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildBalanceCard(availableBalance, totalNetWorth, totalSpent),
                          const SizedBox(height: 20),
                          _buildSearchField(),
                          const SizedBox(height: 15),
                          _buildQuickFilters(),
                          const SizedBox(height: 25),
                          Text(
                            _searchKeyword.isEmpty ? "Recent Activity" : "Search Results (${filteredDocs.length})",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 12),
                          _buildExpenseList(filteredDocs),
                          const SizedBox(height: 20),
                          _buildViewAllButton(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut())
      ],
    );
  }

  Widget _buildBalanceCard(double available, double net, double spent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text("RM ${available.toStringAsFixed(2)}", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: themePink)),
          const SizedBox(height: 20),
          const Divider(thickness: 0.8),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimpleStat("Net Worth", "RM ${net.toStringAsFixed(2)}", Colors.green),
              Container(width: 1, height: 35, color: Colors.grey[300]),
              _buildSimpleStat("Spent", "RM ${spent.toStringAsFixed(2)}", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: themePink),
          hintText: "Search by remark or category...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: _searchKeyword.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchController.clear()) : null,
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDateRange,
          isExpanded: true,
          icon: const Icon(Icons.filter_list_rounded),
          onChanged: (val) => setState(() => _selectedDateRange = val!),
          items: _dateRanges.map((v) => DropdownMenuItem(value: v, child: Text(" $v"))).toList(),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: Text("No transactions found.", style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: docs.take(10).map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return _buildExpenseItem(
          data['remark'] ?? 'No Remark',
          data['category'] ?? 'Other',
          _parseAmount(data['amount']).toStringAsFixed(2),
          data['date'],
        );
      }).toList(),
    );
  }

  Widget _buildExpenseItem(String title, String category, String amount, dynamic date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: themePink.withOpacity(0.1), child: Icon(_getCategoryIcon(category), color: themePink)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text("$category • $date", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          Text("- RM $amount", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: themePink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen())),
        child: const Text("View Full History"),
      ),
    );
  }
}