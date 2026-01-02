import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;
  
  File? _imageFile; // Simpan gambar yang baru dipilih
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? "";
    _emailController.text = _user?.email ?? "";
  }

  // Fungsi untuk ambil gambar dari galeri
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Kecilkan saiz gambar untuk jimat storage
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk muat naik gambar ke Firebase Storage
  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return _user?.photoURL;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$uid.jpg');
      
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload gambar (jika ada) dan dapatkan URL
      String? photoUrl = await _uploadImage(_user.uid);

      // 2. Kemaskini Firebase Auth (Nama & Gambar)
      await _user.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await _user.updatePhotoURL(photoUrl);
      }

      // 3. Kemaskini Firestore Collection 'users'
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).set({
        'username': _nameController.text.trim(),
        'email': _user.email,
        'photoUrl': photoUrl ?? _user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EDIT PROFILE"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Bahagian Gambar Profil
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.pink[50],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_user?.photoURL != null 
                                ? NetworkImage(_user!.photoURL!) 
                                : null) as ImageProvider?,
                        child: (_imageFile == null && _user?.photoURL == null)
                            ? const Icon(Icons.person, size: 60, color: Colors.pink)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Tap photo to change", style: TextStyle(color: Colors.grey)),
                
                const SizedBox(height: 30),
                // Input Nama
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                // Input Email (Read Only)
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 40),
                // Butang Save
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _updateProfile,
                    child: const Text(
                      "SAVE CHANGES",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}