import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _pinEnabled = false;
  bool _isLoading = true;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  // Mengambil status PIN sedia ada dari Firestore
  Future<void> _loadSecuritySettings() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists && doc.data()!['security'] != null) {
        setState(() {
          _pinEnabled = doc.data()!['security']['pin_enabled'] ?? false;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _togglePin(bool val) async {
    setState(() => _pinEnabled = val);
    if (_user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'security': {'pin_enabled': val}
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(val ? "PIN Security Enabled" : "PIN Security Disabled")),
          );
        }
      } catch (e) {
        debugPrint("Error updating security: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SECURITY & PIN"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text("Unlock with PIN", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Require a PIN to access the app"),
                  activeColor: Colors.pink,
                  value: _pinEnabled,
                  onChanged: _togglePin,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.pink),
                  title: const Text("Change PIN"),
                  onTap: _pinEnabled ? () {
                    // Tambah navigasi ke screen tukar PIN di sini nanti
                  } : null,
                  enabled: _pinEnabled,
                ),
              ],
            ),
          ),
    );
  }
}