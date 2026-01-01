import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final TextEditingController _customUnitController = TextEditingController();

  String selectedCategory = "Stationery";
  String selectedUnit = "Pieces";
  String selectedPaymentMethod = "Online banking";
  DateTime selectedDate = DateTime.now();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  final List<String> _categories = [
    "Transport",
    "Food",
    "Stationery",
    "Fuel",
    "Miscellaneous/Others",
  ];

  final List<String> _units = ["Pieces", "kg", "Liter", "Others"];

  final List<String> _paymentMethods = [
    "Online banking",
    "Cash",
    "Credit Card",
    "E-Wallet",
  ];

  // --- OCR LOGIC ---
  Future<void> _performOCR(File imageFile) async {
    setState(() => _isScanning = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String? foundAmount;
      DateTime? foundDate;
      String? foundPayment;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.toUpperCase();

          // 1. Amount Extraction
          if (text.contains("RM") ||
              text.contains("TOTAL") ||
              text.contains("AMOUNT")) {
            RegExp amountReg = RegExp(r"(\d+[\.,]\d{2})");
            var match = amountReg.firstMatch(text);
            if (match != null) {
              foundAmount = match.group(0)?.replaceAll(',', '.');
            }
          }

          // 2. Date Extraction (Supports DD/MM/YYYY or DD-MM-YYYY)
          RegExp dateReg = RegExp(r"(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})");
          var dateMatch = dateReg.firstMatch(text);
          if (dateMatch != null) {
            try {
              foundDate = DateFormat(
                "dd/MM/yyyy",
              ).parse(dateMatch.group(0)!.replaceAll('-', '/'));
            } catch (_) {}
          }

          // 3. Payment Method Detection
          if (text.contains("CASH")) foundPayment = "Cash";
          if (text.contains("VISA") ||
              text.contains("MASTER") ||
              text.contains("CARD")) {
            foundPayment = "Credit Card";
          }
          if (text.contains("E-WALLET") ||
              text.contains("GRABPAY") ||
              text.contains("TNG")) {
            foundPayment = "E-Wallet";
          }
        }
      }

      setState(() {
        if (foundAmount != null) _amountController.text = foundAmount;
        if (foundDate != null) selectedDate = foundDate;
        if (foundPayment != null) selectedPaymentMethod = foundPayment;
      });

      _showSuccessSnackBar("OCR: Auto-filled detected fields");
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      textRecognizer.close();
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (image != null) {
      File file = File(image.path);
      setState(() => _selectedImage = file);
      _performOCR(file);
    }
  }

  // --- SAVE LOGIC ---
  Future<void> _saveExpense() async {
    String finalUnit = selectedUnit == "Others"
        ? _customUnitController.text
        : selectedUnit;

    if (_amountController.text.isEmpty ||
        _remarkController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        (selectedUnit == "Others" && _customUnitController.text.isEmpty)) {
      _showErrorSnackBar("⚠️ Please fill in all required fields (*)");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': _amountController.text,
        'remark': _remarkController.text,
        'category': selectedCategory,
        'payment_method': selectedPaymentMethod,
        'quantity': _quantityController.text,
        'unit': finalUnit,
        'date': DateFormat('dd/MM/yyyy').format(selectedDate),
        'timestamp': FieldValue.serverTimestamp(),
        'receipt_path': imageUrl,
        'has_receipt': imageUrl != null,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Back to list
      _showSuccessSnackBar("Expense added successfully!");
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
          Positioned.fill(
            child: Image.asset("assets/sakura.jpg", fit: BoxFit.cover),
          ),
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
                        if (_isScanning)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Scanning Receipt...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        if (_selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _buildInputCard(
                          "TRANSACTION DATE *",
                          child: _buildDateRow(),
                        ),
                        _buildInputCard(
                          "AMOUNT (RM) *",
                          child: Row(
                            children: [
                              const Text(
                                "RM ",
                                style: TextStyle(
                                  color: Color(0xFF311B92),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: _buildTextField(
                                  _amountController,
                                  isNumber: true,
                                  hint: "0.00",
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildInputCard(
                          "CATEGORY *",
                          child: _buildDropdown(
                            selectedCategory,
                            _categories,
                            (val) => setState(() => selectedCategory = val!),
                          ),
                        ),
                        _buildInputCard(
                          "REMARK *",
                          child: _buildTextField(
                            _remarkController,
                            hint: "e.g., Petrol for site visit",
                          ),
                        ),
                        _buildInputCard(
                          "PAYMENT METHOD *",
                          child: _buildDropdown(
                            selectedPaymentMethod,
                            _paymentMethods,
                            (val) =>
                                setState(() => selectedPaymentMethod = val!),
                          ),
                        ),

                        // QUANTITY & UNIT SECTION
                        _buildInputCard(
                          "QUANTITY & UNIT *",
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildTextField(
                                      _quantityController,
                                      isNumber: true,
                                      hint: "1",
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 3,
                                    child: _buildDropdown(selectedUnit, _units, (
                                      val,
                                    ) {
                                      setState(() {
                                        selectedUnit = val!;
                                        // Auto-set category if unit is "Others"
                                        if (selectedUnit == "Others") {
                                          selectedCategory =
                                              "Miscellaneous/Others";
                                        }
                                      });
                                    }),
                                  ),
                                ],
                              ),
                              if (selectedUnit == "Others")
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildTextField(
                                    _customUnitController,
                                    hint: "Enter custom unit (e.g. Boxes)",
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildSubmitButton(),
                        const SizedBox(height: 50),
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

  // --- REUSABLE COMPONENTS ---
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFE91E63)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              "BACK",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(
            "ADD EXPENSE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage("assets/logo.jpeg"),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, {required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8BBD0).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF311B92),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Color(0xFF311B92)),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: Container(height: 1, color: Colors.purple),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(color: Color(0xFF311B92))),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateRow() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(selectedDate),
              style: const TextStyle(color: Color(0xFF311B92), fontSize: 16),
            ),
            const Icon(Icons.calendar_month, color: Color(0xFF311B92)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF006E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          "SUBMIT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReceiptBadge() {
    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedImage == null ? Colors.orange : Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedImage == null ? Icons.upload_file : Icons.check,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedImage == null ? "Upload Receipt" : "Receipt Attached",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
