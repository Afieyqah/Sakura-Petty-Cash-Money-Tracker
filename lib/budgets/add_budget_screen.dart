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
  final _newCatController = TextEditingController();
  String? _selectedCategory;
  String _userRole = 'Staff';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _userRole = doc.data()?['role'] ?? 'Staff');
      }
    }
  }

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty && _selectedCategory != null) {
      await FirebaseFirestore.instance.collection('budgets').add({
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'category': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Category"),
        content: TextField(
          controller: _newCatController,
          decoration: const InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_newCatController.text.isNotEmpty) {
                String newCat = _newCatController.text.trim();
                await FirebaseFirestore.instance.collection('categories').add({
                  'name': newCat,
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                });
                setState(() => _selectedCategory = newCat);
                _newCatController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
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
      // Layout fix: Gunakan BoxConstraints untuk paksa background penuhi skrin
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'), 
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 140), 
                
                TextField(
                  controller: _nameController, 
                  decoration: InputDecoration(
                    labelText: "Budget Label", 
                    filled: true, 
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),
                
                TextField(
                  controller: _amountController, 
                  keyboardType: TextInputType.number, 
                  decoration: InputDecoration(
                    labelText: "Limit RM", 
                    filled: true, 
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    List<String> categories = ['Stationery', 'Food', 'Transport', 'Bills', 'Fuel', 'Banner'];
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        String name = doc['name'];
                        if (!categories.contains(name)) categories.add(name);
                      }
                    }

                    return DropdownButtonFormField<String>(
                      value: categories.contains(_selectedCategory) ? _selectedCategory : null,
                      hint: const Text("Select Category"),
                      decoration: InputDecoration(
                        filled: true, 
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        ...categories.map((val) => DropdownMenuItem(value: val, child: Text(val))),
                        if (_userRole != 'Staff')
                          const DropdownMenuItem(
                            value: "ADD_NEW",
                            child: Text("+ Add New Category", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                          ),
                      ],
                      onChanged: (val) {
                        if (val == "ADD_NEW") {
                          _showAddCategoryDialog();
                        } else {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink, 
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("SAVE BUDGET", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                // Ruang tambahan di bawah supaya tidak rapat sangat dengan hujung skrin
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}