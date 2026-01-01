import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_navigation.dart';
import 'view_expense.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _selectedCategory = "All";
  String _selectedSort = "Date";
  bool _isAscending = false;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = "";

  final List<String> _categories = [
    "All",
    "Transport",
    "Food",
    "Stationery",
    "Printing",
    "Fuel",
    "Miscellaneous/Others",
  ];
  final List<String> _sortOptions = ["Date", "Category", "Amount", "Expense"];
  final List<String> _months = [
    "All",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  final List<String> _years = ["All", "2023", "2024", "2025", "2026"];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Transport":
        return Icons.directions_car_filled_rounded;
      case "Food":
        return Icons.restaurant_rounded;
      case "Stationery":
        return Icons.draw_rounded;
      case "Printing":
        return Icons.print_rounded;
      case "Fuel":
        return Icons.local_gas_station_rounded;
      case "Miscellaneous/Others":
        return Icons.more_horiz_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/sakura.jpg", fit: BoxFit.cover),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError){
                  return const Center(child: Text("Error loading data"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pink),
                  );
                }

                // --- 1. FILTERING ---
                List<DocumentSnapshot>
                filteredDocs = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  bool categoryMatch =
                      _selectedCategory == "All" ||
                      data['category'] == _selectedCategory;
                  String dateStr = data['date'] ?? "";
                  bool monthMatch = true;
                  bool yearMatch = true;

                  try {
                    DateTime docDate = DateFormat('d MMM yyyy').parse(dateStr);
                    if (_selectedMonth != "All") {
                      monthMatch =
                          DateFormat('MMMM').format(docDate) == _selectedMonth;
                    }
                    if (_selectedYear != "All") {
                      yearMatch = docDate.year.toString() == _selectedYear;
                    }
                  } catch (e) {
                    monthMatch =
                        _selectedMonth == "All" ||
                        dateStr.contains(_selectedMonth);
                    yearMatch =
                        _selectedYear == "All" ||
                        dateStr.contains(_selectedYear);
                  }

                  bool searchMatch =
                      _searchQuery.isEmpty ||
                      (data['remark'] ?? "").toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                  return categoryMatch &&
                      monthMatch &&
                      yearMatch &&
                      searchMatch;
                }).toList();

                // --- 2. SORTING ---
                filteredDocs.sort((a, b) {
                  Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                  Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                  int cmp;
                  switch (_selectedSort) {
                    case "Category":
                      cmp = (dataA['category'] ?? "").compareTo(
                        dataB['category'] ?? "",
                      );
                      break;
                    case "Amount":
                      double amtA =
                          double.tryParse(dataA['amount'].toString()) ?? 0.0;
                      double amtB =
                          double.tryParse(dataB['amount'].toString()) ?? 0.0;
                      cmp = amtA.compareTo(amtB);
                      break;
                    case "Expense":
                      cmp = (dataA['remark'] ?? "").compareTo(
                        dataB['remark'] ?? "",
                      );
                      break;
                    default:
                      try {
                        DateTime dtA = DateFormat(
                          'd MMM yyyy',
                        ).parse(dataA['date'] ?? "");
                        DateTime dtB = DateFormat(
                          'd MMM yyyy',
                        ).parse(dataB['date'] ?? "");
                        cmp = dtA.compareTo(dtB);
                      } catch (e) {
                        cmp = 0;
                      }
                  }
                  return _isAscending ? cmp : -cmp;
                });

                // --- 3. GROUPING (FUEL NESTED UNDER TRANSPORT) ---
                Map<String, List<DocumentSnapshot>> groupedData = {};
                for (var doc in filteredDocs) {
                  String originalCategory =
                      doc['category'] ?? "Miscellaneous/Others";

                  // If category is Fuel, we put it into the Transport group
                  String groupKey = (originalCategory == "Fuel")
                      ? "Transport"
                      : originalCategory;

                  if (!groupedData.containsKey(groupKey)) {
                    groupedData[groupKey] = [];
                  } 
                  groupedData[groupKey]!.add(doc);
                }
                List<String> displayGroups = groupedData.keys.toList()..sort();

                double totalAmount = filteredDocs.fold(0, (total, doc) {
                  return total +
                      (double.tryParse(doc['amount'].toString()) ?? 0.0);
                });

                return Column(
                  children: [
                    _buildAppBar(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("ALL EXPENSES"),
                          const SizedBox(height: 10),
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          _buildFilterCard(totalAmount),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 5,
                              ),
                              itemCount: displayGroups.length,
                              itemBuilder: (context, index) {
                                String groupName = displayGroups[index];
                                List<DocumentSnapshot> items =
                                    groupedData[groupName]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 15,
                                        bottom: 8,
                                        left: 5,
                                      ),
                                      child: Text(
                                        groupName.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ...items
                                        .map(
                                          (doc) =>
                                              _buildExpenseCard(context, doc),
                                        )
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SharedNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewExpenseScreen(documentId: doc.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            204,
          ), // Replaced withAlpha for 0.8 opacity
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFFE0F0),
              child: Icon(
                _getCategoryIcon(data['category'] ?? ""),
                color: Colors.pinkAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['remark'] ?? "No Title",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    data['date'] ?? "",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              "-RM ${data['amount']}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildFilterCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(153),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          _buildFilterRow(Icons.calendar_month, "Period:", [
            _buildDropdown(
              _selectedMonth,
              _months,
              (v) => setState(() => _selectedMonth = v!),
            ),
            const SizedBox(width: 8),
            _buildDropdown(
              _selectedYear,
              _years,
              (v) => setState(() => _selectedYear = v!),
            ),
          ]),
          const SizedBox(height: 10),
          _buildFilterRow(Icons.category_outlined, "Category:", [
            Expanded(
              child: _buildDropdown(
                _selectedCategory,
                _categories,
                (v) => setState(() => _selectedCategory = v!),
              ),
            ),
          ]),
          const Divider(height: 20, color: Colors.pinkAccent),
          _buildSortAndSummaryRow(totalAmount),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pinkAccent.withAlpha(128)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
          hintText: "Search expenses....",
          hintStyle: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.black38,
            fontSize: 13,
          ),
          suffixIcon: Icon(Icons.search, color: Colors.pinkAccent, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: Color(0xFF880E4F),
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      fontStyle: FontStyle.italic,
      fontSize: 16,
    ),
  );

  Widget _buildFilterRow(IconData icon, String label, List<Widget> children) =>
      Row(
        children: [
          Icon(icon, size: 18, color: Colors.pinkAccent),
          const SizedBox(width: 5),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF880E4F),
              ),
            ),
          ),
          ...children,
        ],
      );

  Widget _buildSortAndSummaryRow(double total) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          const Text(
            "Sort:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF880E4F),
            ),
          ),
          const SizedBox(width: 5),
          _buildDropdown(
            _selectedSort,
            _sortOptions,
            (v) => setState(() => _selectedSort = v!),
          ),
          IconButton(
            icon: Icon(
              _isAscending ? Icons.trending_up : Icons.trending_down,
              size: 20,
              color: Colors.pinkAccent,
            ),
            onPressed: () => setState(() => _isAscending = !_isAscending),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "TOTAL",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            "RM ${total.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE0F0),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.pinkAccent.withAlpha(77)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        onChanged: onChanged,
        items: items
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(fontSize: 11)),
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _buildAppBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    decoration: const BoxDecoration(
      color: Colors.pinkAccent,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
          label: const Text(
            "BACK",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const Text(
          "EXPENSE LIST",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage("assets/logo.jpeg"),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 50, color: Colors.white.withAlpha(128)),
        const SizedBox(height: 10),
        const Text(
          "No expenses for this period.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}
