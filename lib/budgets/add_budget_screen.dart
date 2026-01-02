<<<<<<< HEAD
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
        'spent': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADD BUDGET")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Budget Name")),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Limit RM")),
            DropdownButton<String>(
              value: _category,
              items: ['Stationery', 'Food', 'Transport', 'Bills'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _category = newValue!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveBudget, child: const Text("SAVE")),
          ],
        ),
      ),
    );
  }
=======
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
        'spent': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADD BUDGET")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Budget Name")),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Limit RM")),
            DropdownButton<String>(
              value: _category,
              items: ['Stationery', 'Food', 'Transport', 'Bills'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _category = newValue!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveBudget, child: const Text("SAVE")),
          ],
        ),
      ),
    );
  }
>>>>>>> ca32774 (	new file:   lib/account_dashboard/account_dashboard.dart)
}