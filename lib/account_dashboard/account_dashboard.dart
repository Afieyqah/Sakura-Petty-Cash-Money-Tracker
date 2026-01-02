import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDashboard extends StatelessWidget {
  const AccountDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Account Dashboard", style: TextStyle(color: Colors.black87)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {}, 
        ),
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
            for (var doc in docs) {
              totalNetWorth += (doc['balance'] as num).toDouble();
            }

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- NET WORTH CARD ---
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Net Worth", style: TextStyle(fontSize: 18, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          "RM ${totalNetWorth.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text("Accounts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  // --- ACCOUNTS LIST ---
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

                  // --- BOTTOM BUTTONS ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildNavButton(
                          context, 
                          "View Budget", 
                          Icons.visibility, 
                          const Color(0xFFFFE4E1), 
                          '/view_budget'
                        ),
                        const SizedBox(height: 12),
                        _buildNavButton(
                          context, 
                          "Budget List", 
                          Icons.list_alt, 
                          Colors.white.withOpacity(0.9),
                          '/budget_list'
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => _showAddAccountDialog(context, user?.uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAccountTile(String title, double balance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Balance: RM ${balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: () {},
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String text, IconData icon, Color color, String route) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, color: Colors.pink, size: 20),
        label: Text(text, style: const TextStyle(color: Colors.pink, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

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
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: "Account Name")),
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
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}