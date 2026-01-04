import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themePink = Color(0xFFE91E63);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          // extendBodyBehindAppBar supaya gambar bunga naik sampai ke status bar
          extendBodyBehindAppBar: true, 
          appBar: AppBar(
            title: const Text(
              "MY PROFILE", 
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2
              )
            ),
            backgroundColor: Colors.transparent, // Buang banner pink
            elevation: 0, // Buang bayang-bayang bar
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              // Padding atas ditambah supaya Profile Picture tidak tertutup AppBar
              padding: const EdgeInsets.only(top: kToolbarHeight + 40), 
              child: Column(
                children: [
                  // User Avatar Section
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
                  
                  // Nama & Email
                  Text(
                    user?.displayName ?? "Sakura User",
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "user@example.com",
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Menu Options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileTile(context, Icons.person_outline, "Edit Profile", '/edit_profile'),
                        _buildProfileTile(context, Icons.account_balance_wallet_outlined, "My Accounts", '/accounts'),
                        _buildProfileTile(context, Icons.security_outlined, "Security & PIN", '/security'),
                        
                        // Menu Settings Baru
                        _buildProfileTile(context, Icons.settings_outlined, "Settings", '/settings'),
                        
                        const SizedBox(height: 25),
                        
                        // Logout Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themePink,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/'); 
                            }
                          },
                          child: const Text(
                            "LOGOUT", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), // Kekalkan sedikit telus supaya nampak bunga
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFE91E63)),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}