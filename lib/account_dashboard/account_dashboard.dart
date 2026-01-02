import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDashboard extends StatelessWidget {
  const AccountDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ACCOUNT DASHBOARD"),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // Listen to accounts owned by this user
          stream: FirebaseFirestore.instance
              .collection('accounts')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            double totalNetWorth = 0;
            final docs = snapshot.data?.docs ?? [];
            
            // Calculate Total Net Worth
            for (var doc in docs) {
              totalNetWorth += (doc['balance'] as num).toDouble();
            }

            return Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Net Worth",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
                Text(
                  "RM ${totalNetWorth.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final account = docs[index].data() as Map<String, dynamic>;
                      return _buildAccountTile(
                        account['name'] ?? 'Account',
                        (account['balance'] as num).toDouble(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Button to add a new account (e.g., BSN, Cash, Maybank)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => _showAddAccountDialog(context, user?.uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountTile(String title, double balance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.pink,
          child: Icon(Icons.account_balance_wallet, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          "RM ${balance.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Simple dialog to enter a new account name and initial balance
  void _showAddAccountDialog(BuildContext context, String? uid) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: "Account Name (e.g. BSN)")),
            TextField(controller: balanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Initial Balance")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (uid != null && nameCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('accounts').add({
                  'userId': uid,
                  'name': nameCtrl.text.trim(),
                  'balance': double.tryParse(balanceCtrl.text) ?? 0.0,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}