import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/bottom_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- FIRESTORE LOGIC: SAVE NEW ACCOUNT ---
  Future<void> _saveAccount(BuildContext context, String name, String balance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('accounts').add({
        'uid': user.uid,
        'accountName': name,
        'balance': double.tryParse(balance) ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account '$name' added!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // --- POP-UP MODAL LOGIC ---
  void _showAddAccountModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    const Color themePink = Color(0xFFE91E63);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Add New Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themePink)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Account Name (e.g. Bank, Cash)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Initial Balance (RM)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themePink,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _saveAccount(context, nameController.text, balanceController.text),
                child: const Text("SAVE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themePink = Color(0xFFE91E63);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text("MY PROFILE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      // --- FAB REVISED: ICON RESTORED TO '+' ---
      floatingActionButton: FloatingActionButton(
        heroTag: "shared_nav_fab",
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 8,
        onPressed: () => _showAddAccountModal(context),
        child: const Icon(Icons.add, size: 35, color: themePink),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SharedNavigation(),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/cherry_blossom_bg.jpg'), fit: BoxFit.cover),
        ),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 60, 20, 120),
              child: Column(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: (user?.photoURL != null)
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/images/app_icon.png') as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(user?.displayName ?? "Sakura User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? "user@example.com", style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 30),
                  _buildProfileTile(context, Icons.person_outline, "Edit Profile", '/edit_profile'),
                  _buildProfileTile(context, Icons.account_balance_wallet_outlined, "My Accounts", '/accounts'),
                  _buildProfileTile(context, Icons.security_outlined, "Security & PIN", '/security'),
                  _buildProfileTile(context, Icons.settings_outlined, "Settings", '/settings'),
                  const SizedBox(height: 25),
                  _buildActionButton(context, Icons.sync, "SYNC DATA", themePink, isOutlined: true),
                  const SizedBox(height: 12),
                  _buildActionButton(context, Icons.logout, "LOGOUT", themePink),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFE91E63)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, {bool isOutlined = false}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white.withOpacity(0.9) : color,
        foregroundColor: isOutlined ? color : Colors.white,
        minimumSize: const Size(double.infinity, 52),
        side: isOutlined ? BorderSide(color: color, width: 1.5) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () { /* Logic handled in full code */ },
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}