import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../dashboard_screen.dart';
import 'custom_pin_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _auth = AuthService();

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

    // Auto‑try fingerprint immediately if available
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
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
