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
  final _user = FirebaseAuth.instance.currentUser;

  Future<void> _togglePin(bool val) async {
    setState(() => _pinEnabled = val);
    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'security': {'pin_enabled': val}
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SECURITY & PIN")),
      body: SwitchListTile(
        title: const Text("Unlock with PIN"),
        activeColor: Colors.pink,
        value: _pinEnabled,
        onChanged: _togglePin,
      ),
    );
  }
}