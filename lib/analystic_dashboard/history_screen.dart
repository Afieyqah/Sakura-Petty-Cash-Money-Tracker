import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Pastikan path ini betul mengikut struktur projek anda
import 'package:selab_project/analystic_dashboard/analystic_screen.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedCategory = "All";
  String selectedSort = "Latest";
  DateTime selectedMonth = DateTime.now();

  final List<String> categories = [
    "All",
    "Food",
    "Fuel",
    "Stationery",
    "Transport",
    "Misc",
  ];

  final List<String> sortOptions = [
    "Latest",
    "Oldest",
    "Highest Amount",
    "Lowest Amount",
  ];

  // Map warna kategori (Pastikan ini selaras dengan skrin Analytics anda)
  final Map<String, Color> categoryColorMap = {
    "Food": Colors.orange,
    "Fuel": Colors.blue,
    "Stationery": Colors.purple,
    "Transport": Colors.green,
    "Misc": Colors.grey,
  };

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      helpText: "Select Month",
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  List<Map<String, dynamic>> _filterExpenses(List<Map<String, dynamic>> data) {
    // Filter by category
    if (selectedCategory != "All") {
      data = data.where((e) => e['category'] == selectedCategory).toList();
    }

    // Filter by month & year
    data = data.where((e) {
      final date = e['date'] as DateTime;
      return date.month == selectedMonth.month &&
          date.year == selectedMonth.year;
    }).toList();

    // Sorting
    data.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      final amountA = a['amount'] as double;
      final amountB = b['amount'] as double;

      switch (selectedSort) {
        case "Oldest":
          return dateA.compareTo(dateB);
        case "Highest Amount":
          return amountB.compareTo(amountA);
        case "Lowest Amount":
          return amountA.compareTo(amountB);
        default: // Latest
          return dateB.compareTo(dateA);
      }
    });

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense History"),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            _filterPanel(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('expenses')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Convert Firestore docs to List<Map<String, dynamic>>
                  List<Map<String, dynamic>> allExpenses = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'category': data['category'] ?? 'Misc',
                      'amount': double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
                      // PEMBETULAN: Menghantar data mentah (dynamic) ke parser
                      'date': _parseFirestoreDate(data['date']),
                    };
                  }).toList();

                  final filtered = _filterExpenses(allExpenses);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("No expenses found", 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final DateTime date = e['date'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: categoryColorMap[e['category']]?.withOpacity(0.2) ?? Colors.grey.shade300,
                            child: Text(
                              (e['category'] as String)[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: categoryColorMap[e['category']] ?? Colors.black,
                              ),
                            ),
                          ),
                          title: Text(e['category'] as String, 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "${date.day.toString().padLeft(2, '0')}/"
                            "${date.month.toString().padLeft(2, '0')}/"
                            "${date.year}",
                          ),
                          trailing: Text(
                            "RM ${(e['amount'] as double).toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER PANEL ----------------
  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSort,
                  decoration: const InputDecoration(
                    labelText: "Sort By",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: sortOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedSort = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text("Month: ${selectedMonth.month}/${selectedMonth.year}"),
              onPressed: _pickMonth,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PEMBETULAN: Firestore Date Parser ----------------
  DateTime _parseFirestoreDate(dynamic raw) {
    // 1. Jika data adalah Timestamp (format standard Firestore)
    if (raw is Timestamp) {
      return raw.toDate();
    }
    
    // 2. Jika data adalah String (format dd/MM/yyyy)
    if (raw is String) {
      try {
        final parts = raw.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // Year
            int.parse(parts[1]), // Month
            int.parse(parts[0]), // Day
          );
        }
      } catch (e) {
        debugPrint("Error parsing date string: $e");
      }
    }
    
    // Default jika data null atau tidak sah
    return DateTime.now();
  }
}