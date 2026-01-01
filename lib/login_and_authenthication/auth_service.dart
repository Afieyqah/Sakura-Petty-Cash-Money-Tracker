import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
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
      if (e.code == 'invalid-email') return 'Invalid email format';
      if (e.code == 'user-not-found') return 'No account found for this email';
      if (e.code == 'wrong-password') return 'Incorrect password';
      return e.message;
    }
  }

  // 🔑 Firebase register
  Future<String?> register(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email')
        return 'Please enter a valid email address';
      if (e.code == 'weak-password')
        return 'Password must be at least 6 characters';
      if (e.code == 'email-already-in-use')
        return 'This email is already registered';
      return e.message;
    }
  }

  // 🔑 Check if logged in
  Future<bool> isLoggedIn() async => _firebaseAuth.currentUser != null;

  Future<void> logout() async => _firebaseAuth.signOut();

  String? getEmail() => _firebaseAuth.currentUser?.email;

  // 🔑 Fingerprint availability
  Future<bool> hasBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint);
    } catch (_) {
      return false;
    }
  }

  // 🔑 Trigger biometric authentication
  Future<bool> authenticateBiometric() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $biometrics');

      if (!biometrics.contains(BiometricType.fingerprint)) {
        return false;
      }

      // If your API doesn’t support `options:`, use the minimal call:
      return await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
      );
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  // 🔑 PIN fallback
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
