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
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

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

  // Fungsi untuk simpan PIN 6-digit ke Firestore
  Future<void> _saveNewPin(String newPin) async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'security': {
            'pin_enabled': true,
            'app_pin': newPin, // Simpan PIN 6-digit
          }
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("6-Digit PIN successfully updated!")),
          );
        }
      } catch (e) {
        debugPrint("Error saving PIN: $e");
      }
    }
  }

  // Dialog untuk tukar PIN
  void _showChangePinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set New 6-Digit PIN", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter 6 digits to secure your app."),
            const SizedBox(height: 15),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: "",
                hintText: "******",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              if (_pinController.text.length == 6) {
                _saveNewPin(_pinController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter exactly 6 digits")),
                );
              }
            },
            child: const Text("Save PIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePin(bool val) async {
    if (val) {
      // Jika user cuba aktifkan, paksa mereka set PIN dulu
      _showChangePinDialog();
    } else {
      setState(() => _pinEnabled = false);
      if (_user != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
          'security': {'pin_enabled': false}
        }, SetOptions(merge: true));
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
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: SwitchListTile(
                    title: const Text("Unlock with PIN", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Require a 6-digit PIN to access the app"),
                    activeColor: Colors.pink,
                    value: _pinEnabled,
                    onChanged: _togglePin,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: _pinEnabled ? Colors.pink : Colors.grey),
                    title: const Text("Change PIN", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Update your 6-digit security code"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _pinEnabled ? _showChangePinDialog : null,
                    enabled: _pinEnabled,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}