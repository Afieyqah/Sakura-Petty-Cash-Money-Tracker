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
        title: const Text("Account Dashboard", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
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

            final docs = snapshot.data?.docs ?? [];
            double totalNetWorth = 0;
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
  BoxShadow(
    color: Colors.black.withOpacity(0.1), // Ini sama nilai dengan black10
    blurRadius: 10,
    offset: const Offset(0, 4), // Opsional: Untuk nampak lebih natural
  ),
],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Real-time Net Worth", style: TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          "RM ${totalNetWorth.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        const Text("My Accounts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.pink, size: 30),
                          onPressed: () => _showAccountDialog(context, user?.uid),
                        ),
                      ],
                    ),
                  ),

                  // --- ACCOUNTS LIST ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildAccountTile(
                          context, 
                          doc.id, 
                          data['name'] ?? 'Account', 
                          (data['balance'] as num).toDouble(), 
                          data['type'] ?? 'Cash', 
                          user?.uid
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildNavButton(context, "View Budget", Icons.account_balance_wallet, const Color(0xFFFFE4E1), '/view_budget'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, String docId, String title, double balance, String type, String? uid) {
    IconData typeIcon;
    switch (type) {
      case 'Online Banking': typeIcon = Icons.account_balance; break;
      case 'E-wallet': typeIcon = Icons.account_balance_wallet; break;
      case 'Credit Card': typeIcon = Icons.credit_card; break;
      default: typeIcon = Icons.payments;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.pink.withOpacity(0.1), child: Icon(typeIcon, color: Colors.pink)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(type, style: const TextStyle(fontSize: 12)),
        trailing: Text("RM ${balance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        onTap: () => _showAccountDialog(context, uid, docId: docId, currentName: title, currentBalance: balance, currentType: type),
        onLongPress: () => _showDeleteConfirmation(context, docId, title),
      ),
    );
  }

  void _showAccountDialog(BuildContext context, String? uid, {String? docId, String? currentName, double? currentBalance, String? currentType}) {
    final nameCtrl = TextEditingController(text: currentName);
    final balanceCtrl = TextEditingController(text: currentBalance?.toString());
    String selectedType = currentType ?? 'Cash';
    final List<String> types = ['Online Banking', 'Cash', 'E-wallet', 'Credit Card'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? "New Account" : "Edit Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Account Name")),
              TextField(controller: balanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Balance")),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: "Type"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (uid != null && nameCtrl.text.isNotEmpty) {
                  final data = {
                    'userId': uid,
                    'name': nameCtrl.text.trim(),
                    'balance': double.tryParse(balanceCtrl.text) ?? 0.0,
                    'type': selectedType,
                  };
                  docId == null 
                    ? await FirebaseFirestore.instance.collection('accounts').add(data)
                    : await FirebaseFirestore.instance.collection('accounts').doc(docId).update(data);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('accounts').doc(docId).delete();
            if (context.mounted) Navigator.pop(context);
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String text, IconData icon, Color color, String route) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, color: Colors.pink),
        label: Text(text, style: const TextStyle(color: Colors.pink)),
        style: OutlinedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      ),
    );
  }
}