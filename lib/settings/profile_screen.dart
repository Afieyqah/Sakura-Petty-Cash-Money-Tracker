<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MY PROFILE"),
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
        child: Column(
          children: [
            const SizedBox(height: 30),
            // User Avatar Section
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: AssetImage('assets/images/app_icon.png'),
              ),
            ),
            const SizedBox(height: 15),
            
            // Live User Data from Firebase
            Text(
              user?.displayName ?? "Youth 24+ User",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "user@example.com",
              style: const TextStyle(color: Colors.black54),
            ),
            
            const SizedBox(height: 30),
            
            // Menu Options
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    _buildProfileTile(
                      context, 
                      Icons.person_outline, 
                      "Edit Profile", 
                      '/edit_profile'
                    ),
                    _buildProfileTile(
                      context, 
                      Icons.account_balance_wallet_outlined, 
                      "My Accounts", 
                      '/accounts'
                    ),
                    _buildProfileTile(
                      context, 
                      Icons.security_outlined, 
                      "Security & PIN", 
                      '/security'
                    ),
                    const SizedBox(height: 20),
                    
                    // Logout Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/'); 
                        }
                      },
                      child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.8),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
=======
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MY PROFILE"),
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
        child: Column(
          children: [
            const SizedBox(height: 30),
            // User Avatar Section
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: AssetImage('assets/images/app_icon.png'),
              ),
            ),
            const SizedBox(height: 15),
            
            // Live User Data from Firebase
            Text(
              user?.displayName ?? "Youth 24+ User",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "user@example.com",
              style: const TextStyle(color: Colors.black54),
            ),
            
            const SizedBox(height: 30),
            
            // Menu Options
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    _buildProfileTile(
                      context, 
                      Icons.person_outline, 
                      "Edit Profile", 
                      '/edit_profile'
                    ),
                    _buildProfileTile(
                      context, 
                      Icons.account_balance_wallet_outlined, 
                      "My Accounts", 
                      '/accounts'
                    ),
                    _buildProfileTile(
                      context, 
                      Icons.security_outlined, 
                      "Security & PIN", 
                      '/security'
                    ),
                    const SizedBox(height: 20),
                    
                    // Logout Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/'); 
                        }
                      },
                      child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.8),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
>>>>>>> ca32774 (	new file:   lib/account_dashboard/account_dashboard.dart)
}