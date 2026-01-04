import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditExpenseScreen extends StatefulWidget {
  final String documentId;

  const EditExpenseScreen({super.key, required this.documentId});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _remarkController;
  late TextEditingController _quantityController;
  late TextEditingController _customUnitController;

  String _selectedCategory = "Transport";
  String _selectedPayment = "Online banking";
  String _selectedUnit = "Pieces";
  bool _isLoading = true;
  bool _isCustomUnit = false;

  final List<String> _categories = ["Transport", "Food", "Stationery", "Miscellaneous/Others"];
  final List<String> _paymentMethods = ["Online banking", "Cash", "Credit Card", "E-Wallet"];
  final List<String> _units = ["Pieces", "Litres", "kg", "Persons", "Others"];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _remarkController = TextEditingController();
    _quantityController = TextEditingController();
    _customUnitController = TextEditingController();
    _fetchExpenseDetails();
  }

  // --- FUNGSI PENYELAMAT DATA ---
  String _formatDate(dynamic value) {
    if (value == null) return "";
    if (value is Timestamp) return DateFormat('dd/MM/yyyy').format(value.toDate());
    return value.toString();
  }

  Future<void> _fetchExpenseDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('expenses')
          .doc(widget.documentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Guna fungsi format untuk tarikh
          _dateController.text = _formatDate(data['date'] ?? data['timestamp']);
          
          // Pastikan amount & quantity ditukar ke String untuk Controller
          _amountController.text = data['amount']?.toString() ?? "";
          _remarkController.text = data['remark'] ?? "";
          _quantityController.text = data['quantity']?.toString() ?? "1";

          String savedUnit = data['unit'] ?? "Pieces";
          if (_units.contains(savedUnit) && savedUnit != "Others") {
            _selectedUnit = savedUnit;
            _isCustomUnit = false;
          } else {
            _selectedUnit = "Others";
            _isCustomUnit = true;
            _customUnitController.text = savedUnit;
          }

          if (_categories.contains(data['category'])) {
            _selectedCategory = data['category'];
          }
          if (data['payment_method'] != null && _paymentMethods.contains(data['payment_method'])) {
            _selectedPayment = data['payment_method'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      _showNotification("Error loading data: $e", Colors.red);
    }
  }

  void _showNotification(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateExpense() async {
    final date = _dateController.text.trim();
    final amount = _amountController.text.trim();
    final remark = _remarkController.text.trim();
    final qty = _quantityController.text.trim();
    final customUnit = _customUnitController.text.trim();

    if (date.isEmpty || amount.isEmpty || remark.isEmpty || qty.isEmpty) {
      _showNotification("⚠️ Please fill in all required fields (*)", Colors.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(widget.documentId)
          .update({
            'date': date,
            'amount': amount, // Disimpan sebagai String untuk konsistensi OCR
            'category': _selectedCategory,
            'remark': remark,
            'payment_method': _selectedPayment,
            'quantity': qty,
            'unit': _isCustomUnit ? customUnit : _selectedUnit,
            'last_updated': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      _showNotification("✅ Update Successful!", Colors.green);
      Future.delayed(const Duration(milliseconds: 700), () => Navigator.pop(context));
    } catch (e) {
      setState(() => _isLoading = false);
      _showNotification("❌ Update failed: $e", Colors.red);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _deleteExpense() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('expenses').doc(widget.documentId).delete();
        if (mounted) {
          _showNotification("🗑️ Item deleted", Colors.redAccent);
          Navigator.of(context).pop(); 
        }
      } catch (e) {
        _showNotification("Delete failed: $e", Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    _quantityController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pink)));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("EDIT EXPENSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: _buildInputField("TRANSACTION DATE", _dateController, Icons.calendar_month, isRequired: true),
              ),
            ),
            _buildInputField("AMOUNT", _amountController, null, prefix: "RM ", isRequired: true, isNumeric: true),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildInputField("QUANTITY", _quantityController, null, isRequired: true, isNumeric: true)),
                const SizedBox(width: 15),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildDropdownField("UNIT", _selectedUnit, _units, (val) => setState(() {
                        _selectedUnit = val!;
                        _isCustomUnit = (val == "Others");
                      })),
                      if (_isCustomUnit)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: TextField(
                            controller: _customUnitController,
                            decoration: const InputDecoration(hintText: "Enter Unit...", isDense: true),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            _buildDropdownField("CATEGORY", _selectedCategory, _categories, (val) => setState(() => _selectedCategory = val!)),
            _buildInputField("REMARK", _remarkController, null, isRequired: true),
            _buildDropdownField("PAYMENT METHOD", _selectedPayment, _paymentMethods, (val) => setState(() => _selectedPayment = val!)),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _updateExpense,
                    child: const Text("UPDATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _deleteExpense,
                    child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE WIDGETS ---
  Widget _buildInputField(String label, TextEditingController controller, IconData? icon, {String? prefix, bool isRequired = false, bool isNumeric = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.purple[50]!.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
              if (isRequired) const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          TextField(
            controller: controller,
            keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(prefixText: prefix, suffixIcon: icon != null ? Icon(icon, color: Colors.indigo) : null, isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.purple[50]!.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
          DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            underline: Container(height: 1, color: Colors.purple),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}