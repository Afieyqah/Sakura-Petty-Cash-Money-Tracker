import 'dart:io';
import 'package:flutter/material.dart';
import 'package:selab_project/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'edit_expense.dart';

class ViewExpenseScreen extends StatefulWidget {
  final String documentId;

  const ViewExpenseScreen({super.key, required this.documentId});

  @override
  State<ViewExpenseScreen> createState() => _ViewExpenseScreenState();
}

class _ViewExpenseScreenState extends State<ViewExpenseScreen> {
  bool _isUploading = false;

  // --- OCR & UPDATE LOGIC ---
  Future<void> _updateReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String? extractedAmount;
      String? extractedDate;

      final Map<String, String> monthMap = {
        'JAN': '01',
        'FEB': '02',
        'MAR': '03',
        'APR': '04',
        'MAY': '05',
        'JUN': '06',
        'JUL': '07',
        'AUG': '08',
        'SEP': '09',
        'OCT': '10',
        'NOV': '11',
        'DEC': '12',
      };

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.toUpperCase();

          // Amount Extraction
          if (text.contains("RM") ||
              text.contains("TOTAL") ||
              text.contains("AMOUNT") ||
              text.contains("AMT")) {
            RegExp amountReg = RegExp(r"(\d+[\.,]\d{2})");
            var match = amountReg.firstMatch(text);
            if (match != null) {
              extractedAmount = match.group(0)?.replaceAll(',', '.');
            }
          }

          // Date Extraction
          RegExp numericDate = RegExp(r"(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})");
          var numMatch = numericDate.firstMatch(text);

          if (numMatch != null) {
            extractedDate =
                "${numMatch.group(1)}/${numMatch.group(2)}/${numMatch.group(3)}";
          } else {
            for (var month in monthMap.keys) {
              if (text.contains(month)) {
                RegExp textDate = RegExp(
                  r"(\d{1,2})\s+" + month + r"\s+(\d{2,4})",
                );
                var textMatch = textDate.firstMatch(text);
                if (textMatch != null) {
                  extractedDate =
                      "${textMatch.group(1)}/${monthMap[month]}/${textMatch.group(2)}";
                }
              }
            }
          }
        }
      }

      String? imageUrl = await CloudinaryService.uploadImage(
        File(pickedFile.path),
      );
      if (imageUrl == null) throw Exception("Upload failed");

      Map<String, dynamic> updateData = {
        'receipt_path': imageUrl,
        'has_receipt': true,
      };

      if (extractedAmount != null) updateData['amount'] = extractedAmount;
      if (extractedDate != null) updateData['date'] = extractedDate;

      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(widget.documentId)
          .update(updateData);

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            extractedAmount != null
                ? "✅ Scanned: RM $extractedAmount"
                : "✅ Receipt uploaded!",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      textRecognizer.close();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteReceipt() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Receipt"),
        content: const Text(
          "Are you sure you want to remove this receipt image?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.documentId)
            .update({'receipt_path': null, 'has_receipt': false});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🗑️ Receipt removed"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Delete failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (innerContext) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Update Receipt",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.pinkAccent),
              title: const Text('Take New Photo'),
              onTap: () {
                Navigator.pop(innerContext);
                _updateReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.pinkAccent,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(innerContext);
                _updateReceipt(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Expense Details",
          style: TextStyle(
            color: Colors.pinkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.pinkAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditExpenseScreen(documentId: widget.documentId),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expenses')
                .doc(widget.documentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading data"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Expense not found"));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            "Remark",
                            data['remark'] ?? 'No Remark',
                            Icons.notes,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            "Amount",
                            "RM ${data['amount'] ?? '0.00'}",
                            Icons.attach_money,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            "Category",
                            data['category'] ?? 'Other',
                            Icons.category,
                          ),
                          const Divider(),
                          _buildInfoTile(
                            "Date",
                            data['date'] ?? 'No Date',
                            Icons.calendar_today,
                          ),
                          const Divider(),
                          // UPDATED: Quantity display
                          _buildInfoTile(
                            "Quantity",
                            "${data['quantity'] ?? '1'}",
                            Icons.format_list_numbered,
                          ),
                          const Divider(),
                          // ADDED: Payment Method display
                          _buildInfoTile(
                            "Payment Method",
                            data['payment_method'] ?? 'Online banking',
                            Icons.payment,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "RECEIPT EVIDENCE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF880E4F),
                          ),
                        ),
                        Row(
                          children: [
                            if (data['has_receipt'] == true)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: _deleteReceipt,
                              ),
                            TextButton.icon(
                              onPressed: _showImageSourceActionSheet,
                              icon: const Icon(
                                Icons.cloud_upload,
                                size: 20,
                                color: Colors.pinkAccent,
                              ),
                              label: const Text(
                                "Update",
                                style: TextStyle(color: Colors.pinkAccent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.pinkAccent),
                    _buildReceiptDisplay(
                      data['has_receipt'] ?? false,
                      data['receipt_path'],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "DONE",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptDisplay(bool hasReceipt, String? path) {
    if (!hasReceipt || path == null || path.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No receipt attached", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        path,
        width: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.pink.withValues(alpha: 0.1),
        child: Icon(icon, color: Colors.pinkAccent),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
