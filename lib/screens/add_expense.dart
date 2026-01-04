import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:selab_project/cloudinary_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final TextEditingController _customUnitController = TextEditingController();

  String selectedCategory = "Stationery";
  String selectedUnit = "Pieces";
  String selectedPaymentMethod = "Online Banking"; // Penyelarasan huruf besar
  DateTime selectedDate = DateTime.now();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  final List<String> _categories = ["Transport", "Food", "Stationery", "Fuel", "Miscellaneous/Others"];
  final List<String> _units = ["Pieces", "kg", "Liter", "Others"];
  
  // Mesti sama dengan kategori di Dashboard
  final List<String> _paymentMethods = ["Online Banking", "Cash", "Credit Card", "E-wallet"];

  // --- OCR LOGIC (Kekal Sama) ---
  Future<void> _performOCR(File imageFile) async {
    setState(() => _isScanning = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String? foundAmount;
      DateTime? foundDate;
      String? foundPayment;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.toUpperCase();
          if (text.contains("RM") || text.contains("TOTAL") || text.contains("AMOUNT")) {
            RegExp amountReg = RegExp(r"(\d+[\.,]\d{2})");
            var match = amountReg.firstMatch(text);
            if (match != null) foundAmount = match.group(0)?.replaceAll(',', '.');
          }
          if (text.contains("CASH")) foundPayment = "Cash";
          if (text.contains("VISA") || text.contains("CARD")) foundPayment = "Credit Card";
          if (text.contains("TNG") || text.contains("WALLET")) foundPayment = "E-wallet";
        }
      }

      setState(() {
        if (foundAmount != null) _amountController.text = foundAmount;
        if (foundPayment != null) selectedPaymentMethod = foundPayment;
      });
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      textRecognizer.close();
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
    if (image != null) {
      File file = File(image.path);
      setState(() => _selectedImage = file);
      _performOCR(file);
    }
  }

  // --- REVISED SAVE LOGIC (WITH REAL-TIME BALANCE UPDATE) ---
  Future<void> _saveExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    String finalUnit = selectedUnit == "Others" ? _customUnitController.text : selectedUnit;

    if (_amountController.text.isEmpty || _remarkController.text.isEmpty || user == null) {
      _showErrorSnackBar("⚠️ Please fill in all required fields");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      double expenseAmount = double.parse(_amountController.text);
      String? imageUrl;
      if (_selectedImage != null) imageUrl = await CloudinaryService.uploadImage(_selectedImage!);

      // 1. Tambah ke koleksi Expenses
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'amount': _amountController.text,
        'remark': _remarkController.text,
        'category': selectedCategory,
        'payment_method': selectedPaymentMethod,
        'quantity': _quantityController.text,
        'unit': finalUnit,
        'date': DateFormat('dd/MM/yyyy').format(selectedDate),
        'timestamp': FieldValue.serverTimestamp(),
        'receipt_path': imageUrl,
      });

      // 2. Cari Akaun yang sepadan dan tolak baki
      final accountSnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: selectedPaymentMethod)
          .limit(1)
          .get();

      if (accountSnapshot.docs.isNotEmpty) {
        final doc = accountSnapshot.docs.first;
        double currentBalance = (doc['balance'] as num).toDouble();
        await FirebaseFirestore.instance.collection('accounts').doc(doc.id).update({
          'balance': currentBalance - expenseAmount,
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Back to list
      _showSuccessSnackBar("Expense added and balance updated!");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/sakura.jpg", fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildReceiptBadge(),
                        const SizedBox(height: 20),
                        _buildInputCard("TRANSACTION DATE *", child: _buildDateRow()),
                        _buildInputCard("AMOUNT (RM) *", child: Row(
                          children: [
                            const Text("RM ", style: TextStyle(color: Color(0xFF311B92), fontWeight: FontWeight.bold)),
                            Expanded(child: _buildTextField(_amountController, isNumber: true, hint: "0.00")),
                          ],
                        )),
                        _buildInputCard("CATEGORY *", child: _buildDropdown(selectedCategory, _categories, (val) => setState(() => selectedCategory = val!))),
                        _buildInputCard("REMARK *", child: _buildTextField(_remarkController, hint: "e.g., Petrol")),
                        _buildInputCard("PAYMENT METHOD *", child: _buildDropdown(selectedPaymentMethod, _paymentMethods, (val) => setState(() => selectedPaymentMethod = val!))),
                        _buildInputCard("QUANTITY & UNIT *", child: Row(
                          children: [
                            Expanded(flex: 2, child: _buildTextField(_quantityController, isNumber: true)),
                            const SizedBox(width: 15),
                            Expanded(flex: 3, child: _buildDropdown(selectedUnit, _units, (val) => setState(() => selectedUnit = val!))),
                          ],
                        )),
                        const SizedBox(height: 25),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components (Simplified for brevity, use your existing styling) ---
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF06292), Color(0xFFE91E63)])),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text("ADD EXPENSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const CircleAvatar(radius: 16, backgroundImage: AssetImage("assets/logo.jpeg")),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, {required Widget child}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), child]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {String? hint, bool isNumber = false}) {
    return TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, isDense: true));
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return DropdownButton<String>(value: value, isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged);
  }

  Widget _buildDateRow() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd/MM/yyyy').format(selectedDate)), const Icon(Icons.calendar_month)]),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveExpense, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF006E)), child: const Text("SUBMIT", style: TextStyle(color: Colors.white))));
  }

  Widget _buildReceiptBadge() {
    return ActionChip(
      avatar: Icon(_selectedImage == null ? Icons.upload : Icons.check, size: 16, color: Colors.white),
      label: Text(_selectedImage == null ? "Upload Receipt" : "Receipt Attached", style: const TextStyle(color: Colors.white)),
      backgroundColor: _selectedImage == null ? Colors.orange : Colors.green,
      onPressed: () => _pickImage(ImageSource.gallery),
    );
  }

  void _showSuccessSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _showErrorSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
}