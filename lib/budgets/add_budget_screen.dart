import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});
  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Stationery';

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('budgets').add({
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'category': _category,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("ADD BUDGET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 120, left: 20, right: 20),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Budget Label", filled: true, fillColor: Colors.white70)),
              const SizedBox(height: 10),
              TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Limit RM", filled: true, fillColor: Colors.white70)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Stationery', 'Food', 'Transport', 'Bills', 'Fuel', 'Banner'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) => setState(() => _category = val!),
                decoration: const InputDecoration(filled: true, fillColor: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBudget, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
                child: const Text("SAVE", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}