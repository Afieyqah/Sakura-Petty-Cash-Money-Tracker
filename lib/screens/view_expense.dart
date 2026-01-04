import 'dart:io';
import 'package:flutter/material.dart';
import 'package:selab_project/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart'; 
import 'edit_expense.dart';

class ViewExpenseScreen extends StatefulWidget {
  final String documentId;

  const ViewExpenseScreen({super.key, required this.documentId});

  @override
  State<ViewExpenseScreen> createState() => _ViewExpenseScreenState();
}

class _ViewExpenseScreenState extends State<ViewExpenseScreen> {
  bool _isUploading = false;

  // --- FUNGSI KESELAMATAN TAHAP TINGGI ---
  
  String _safeString(dynamic value, {String fallback = "-"}) {
    if (value == null) return fallback;
    return value.toString();
  }

  String _safeDate(dynamic value) {
    if (value == null) return "No Date";
    try {
      if (value is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(value.toDate());
      }
      if (value is String && value.isNotEmpty) {
        return value; // Pulangkan string asal (cth: "12/12/2024")
      }
    } catch (e) {
      return "Invalid Date";
    }
    return "No Date";
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // --- OCR LOGIC ---
  Future<void> _updateReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String? extractedAmount;
      String? extractedDate;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.toUpperCase();
          if (text.contains("RM") || text.contains("TOTAL")) {
            RegExp amountReg = RegExp(r"(\d+[\.,]\d{2})");
            var match = amountReg.firstMatch(text);
            if (match != null) extractedAmount = match.group(0)?.replaceAll(',', '.');
          }
        }
      }

      String? imageUrl = await CloudinaryService.uploadImage(File(pickedFile.path));
      if (imageUrl == null) throw Exception("Upload failed");

      await FirebaseFirestore.instance.collection('expenses').doc(widget.documentId).update({
        'receipt_path': imageUrl,
        'has_receipt': true,
        if (extractedAmount != null) 'amount': extractedAmount,
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Updated!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      textRecognizer.close();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditExpenseScreen(documentId: widget.documentId))),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').doc(widget.documentId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Firebase Error"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data not found"));

              // PENTING: Cast data sebagai Map secara selamat
              final rawData = snapshot.data!.data();
              if (rawData == null) return const Center(child: Text("Empty Data"));
              final data = rawData as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            _buildInfoRow("Remark", _safeString(data['remark'])),
                            const Divider(),
                            _buildInfoRow("Amount", "RM ${_safeDouble(data['amount']).toStringAsFixed(2)}"),
                            const Divider(),
                            _buildInfoRow("Category", _safeString(data['category'])),
                            const Divider(),
                            _buildInfoRow("Date", _safeDate(data['date'] ?? data['timestamp'])),
                            const Divider(),
                            _buildInfoRow("Quantity", "${_safeDouble(data['quantity']).toStringAsFixed(0)} ${_safeString(data['unit'], fallback: 'Unit')}"),
                            const Divider(),
                            _buildInfoRow("Method", _safeString(data['payment_method'])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Align(alignment: Alignment.centerLeft, child: Text(" RECEIPT", style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    _buildReceiptSection(data['has_receipt'] ?? false, data['receipt_path']),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _showImageSourceActionSheet,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("UPDATE RECEIPT"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    )
                  ],
                ),
              );
            },
          ),
          if (_isUploading) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(bool hasReceipt, String? url) {
    if (!hasReceipt || url == null || url.isEmpty) {
      return Container(
        height: 150, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(url, width: double.infinity, fit: BoxFit.cover),
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera), title: const Text("Camera"), onTap: () { Navigator.pop(ctx); _updateReceipt(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.image), title: const Text("Gallery"), onTap: () { Navigator.pop(ctx); _updateReceipt(ImageSource.gallery); }),
        ],
      ),
    );
  }
}