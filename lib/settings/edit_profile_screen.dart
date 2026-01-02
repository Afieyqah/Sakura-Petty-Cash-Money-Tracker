<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? "";
    _emailController.text = _user?.email ?? "";
  }

  Future<void> _updateProfile() async {
    if (_user != null) {
      // 1. Update Firebase Auth display name
      await _user!.updateDisplayName(_nameController.text.trim());
      
      // 2. Sync with Firestore 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'username': _nameController.text.trim(),
        'email': _user!.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDIT PROFILE")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.pink, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: _emailController, readOnly: true, decoration: const InputDecoration(labelText: "Email (Fixed)")),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
              onPressed: _updateProfile, 
              child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
=======
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? "";
    _emailController.text = _user?.email ?? "";
  }

  Future<void> _updateProfile() async {
    if (_user != null) {
      // 1. Update Firebase Auth display name
      await _user!.updateDisplayName(_nameController.text.trim());
      
      // 2. Sync with Firestore 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'username': _nameController.text.trim(),
        'email': _user!.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDIT PROFILE")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.pink, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: _emailController, readOnly: true, decoration: const InputDecoration(labelText: "Email (Fixed)")),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
              onPressed: _updateProfile, 
              child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
>>>>>>> ca32774 (	new file:   lib/account_dashboard/account_dashboard.dart)
}