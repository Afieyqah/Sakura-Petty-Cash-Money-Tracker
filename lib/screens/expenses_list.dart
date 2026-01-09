import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_navigation.dart'; 
import 'view_expense.dart';   
import 'add_expense.dart'; 

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _selectedCategory = "All";
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = "";
  bool _isFabVisible = true; // Logik untuk sorok FAB

  final List<String> _categories = ["All", "Transport", "Food", "Stationery", "Printing", "Fuel", "Others"];
  final List<String> _months = ["All", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  final List<String> _years = ["All", "2024", "2025", "2026"];

  @override
  void initState() {
    super.initState();
    // Logik Scroll untuk SharedNavigation dan FAB
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNGSI PEMBANTU (HELPERS) ---

  double _forceDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime(2000);
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateFormat('dd/MM/yyyy').parse(value);
      } catch (e) {
        return DateTime(2000);
      }
    }
    return DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    const Color themePink = Color(0xFFE91E63);

    return Scaffold(
      extendBody: true,
      
      // --- FAB PUTIH (HIDE ON SCROLL) ---
      floatingActionButton: AnimatedScale(
        scale: _isFabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 6,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
          child: const Icon(Icons.add, color: themePink, size: 35),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- NAV BAR DENGAN CONTROLLER ---
      bottomNavigationBar: SharedNavigation(
        scrollController: _scrollController,
        isFabVisible: _isFabVisible,
      ),
      
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/images/cherry_blossom_bg.jpg", fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.3))),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _dropdown(_selectedMonth, _months, (v) => setState(() => _selectedMonth = v!)),
                            const SizedBox(width: 8),
                            _dropdown(_selectedYear, _years, (v) => setState(() => _selectedYear = v!)),
                            const SizedBox(width: 8),
                            _dropdown(_selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data!.docs.where((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        bool searchMatch = (d['remark'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase());
                        bool catMatch = _selectedCategory == "All" || d['category'] == _selectedCategory;
                        
                        DateTime dt = _parseDate(d['date']);
                        bool monthMatch = _selectedMonth == "All" || DateFormat('MMMM').format(dt) == _selectedMonth;
                        bool yearMatch = _selectedYear == "All" || dt.year.toString() == _selectedYear;
                        
                        return searchMatch && catMatch && monthMatch && yearMatch;
                      }).toList();

                      double total = docs.fold(0, (prev, doc) => prev + _forceDouble(doc.data() is Map ? (doc.data() as Map)['amount'] : 0));

                      return Column(
                        children: [
                          _buildGradientTotalCard(total),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController, // PENTING
                              padding: const EdgeInsets.fromLTRB(15, 5, 15, 130),
                              itemCount: docs.length,
                              itemBuilder: (context, i) => _buildExpenseTile(context, docs[i]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildGradientTotalCard(double total) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [const Color(0xFFC2185B), Colors.pinkAccent.shade700],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL SPENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("RM ${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        hintText: "Search expense...",
        prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dropdown(String val, List<String> list, Function(String?)? onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isDense: true,
          items: list.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF880E4F)), onPressed: () => Navigator.pop(context)),
          const Text("EXPENSE HISTORY", style: TextStyle(color: Color(0xFF880E4F), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, DocumentSnapshot doc) {
    var d = doc.data() as Map<String, dynamic>;
    DateTime dt = _parseDate(d['date']);
    String displayDate = DateFormat('dd MMM yyyy').format(dt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewExpenseScreen(documentId: doc.id))),
        leading: CircleAvatar(
          backgroundColor: Colors.pink.shade50,
          child: const Icon(Icons.receipt_long, color: Colors.pink),
        ),
        title: Text(d['remark'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$displayDate • ${d['category'] ?? 'Other'}"),
        trailing: Text(
          "-RM ${_forceDouble(d['amount']).toStringAsFixed(2)}", 
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
        ),
      ),
    );
  }
}