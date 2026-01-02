import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../dashboard_screen.dart'; // 👈 unified dashboard
import 'custom_pin_screen.dart';
import 'welcome_screen.dart'; // 👈 now used as fallback

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _auth = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;

  bool _checking = true;
  bool _hasFingerprint = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadAuthOptions();
  }

  Future<void> _loadAuthOptions() async {
    final bio = await _auth.hasBiometrics();
    final pin = await _auth.hasPin();
    if (!mounted) return;
    setState(() {
      _hasFingerprint = bio;
      _hasPin = pin;
      _checking = false;
    });

    if (bio) {
      _tryBiometric();
    } else {
      _goPin();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await _auth.authenticateBiometric();
    if (!mounted) return;
    if (ok) {
      _goRoleBasedDashboard();
    } else {
      _goPin();
    }
  }

  void _goPin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomPinScreen(requireSetup: !_hasPin),
      ),
    );
  }

  // 🔎 Unified role-based dashboard with WelcomeScreen fallback
  Future<void> _goRoleBasedDashboard() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final role = await _auth.getUserRole(user.uid); // returns String?
      if (!mounted) return;

      if (role != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Role not assigned")));
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No user logged in")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasFingerprint) ...[
                const Icon(Icons.fingerprint, size: 72, color: Colors.pink),
                const SizedBox(height: 12),
                const Text(
                  "Touch the fingerprint sensor to authenticate",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _tryBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Authenticate"),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(onPressed: _goPin, child: const Text("Enter PIN")),
              TextButton(onPressed: _goPin, child: const Text("Cancel")),
            ],
          ),
        ),
      ),
    );
  }
}
