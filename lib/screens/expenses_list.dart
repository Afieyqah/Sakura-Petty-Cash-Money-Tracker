import 'package:flutter/material.dart';
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
  
  String _selectedCategory = "All";
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = "";

  final List<String> _categories = ["All", "Transport", "Food", "Stationery", "Printing", "Fuel", "Others"];
  final List<String> _months = ["All", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  final List<String> _years = ["All", "2024", "2025", "2026"];

  double _forceDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return DateTime(2000); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const SharedNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.pinkAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddExpenseScreen())),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/sakura.jpg", fit: BoxFit.cover)),
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
                      // MEMBAIKI OVERFLOW: Menggunakan SingleChildScrollView supaya dropdown tidak melimpah
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
                    stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data!.docs.where((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        bool searchMatch = (d['remark'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase());
                        bool catMatch = _selectedCategory == "All" || d['category'] == _selectedCategory;
                        DateTime dt = _parseDate(d['date'] ?? "");
                        bool monthMatch = _selectedMonth == "All" || DateFormat('MMMM').format(dt) == _selectedMonth;
                        return searchMatch && catMatch && monthMatch;
                      }).toList();

                      double total = docs.fold(0, (prev, doc) => prev + _forceDouble(doc['amount']));

                      return Column(
                        children: [
                          _buildGradientTotalCard(total), // Gradient Dark Pink
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(15, 5, 15, 100),
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

  // WIDGET: Gradient Dark Pink untuk Total Spent
  Widget _buildGradientTotalCard(double total) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(177, 195, 43, 124), // Dark Pink pekat
            Colors.pinkAccent.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TOTAL SPENT", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
              Text("Filtered results", style: TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          Text(
            "RM ${total.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
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
        fillColor: Colors.white,
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
          items: list.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
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
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text("EXPENSE HISTORY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, DocumentSnapshot doc) {
    var d = doc.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ViewExpenseScreen(documentId: doc.id))),
        leading: const CircleAvatar(backgroundColor: Color(0xFFFCE4EC), child: Icon(Icons.receipt_long, color: Color.fromARGB(238, 227, 69, 122))),
        title: Text(d['remark'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(d['date'] ?? ""),
        trailing: Text("-RM ${_forceDouble(d['amount']).toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    );
  }
}