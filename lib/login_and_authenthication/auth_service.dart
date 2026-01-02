import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // 🔑 Firebase login
  Future<String?> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-not-found':
          return 'No account found for this email';
        case 'wrong-password':
          return 'Incorrect password';
        default:
          return e.message;
      }
    }
  }

  // 🔑 Firebase register with role (default = staff)
  Future<String?> register(
    String email,
    String password, {
    String role = "staff",
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email.trim(),
          'role': role, // "staff", "manager", "owner"
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'weak-password':
          return 'Password must be at least 6 characters';
        case 'email-already-in-use':
          return 'This email is already registered';
        default:
          return e.message;
      }
    }
  }

  // 🔑 Get user role
  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['role'] as String?;
    }
    return null;
  }

  // 🔑 Update user role (promote/demote)
  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔑 Session helpers
  Future<bool> isLoggedIn() async => _firebaseAuth.currentUser != null;
  Future<void> logout() async => _firebaseAuth.signOut();

  String getUid() {
    // ✅ Always return a non-null string
    return _firebaseAuth.currentUser?.uid ?? "";
  }

  String getEmail() {
    // ✅ Always return a non-null string
    return _firebaseAuth.currentUser?.email ?? "";
  }

  // 🔑 Biometrics + PIN
  Future<bool> hasBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint);
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      if (!biometrics.contains(BiometricType.fingerprint)) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasPin') ?? false;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
    await prefs.setBool('hasPin', true);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('pin');
    return saved == pin;
  }
}
