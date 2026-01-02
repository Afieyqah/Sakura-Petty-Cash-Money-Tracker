import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../dashboard_screen.dart';

class CustomPinScreen extends StatefulWidget {
  final bool requireSetup;
  const CustomPinScreen({super.key, this.requireSetup = false});

  @override
  State<CustomPinScreen> createState() => _CustomPinScreenState();
}

class _CustomPinScreenState extends State<CustomPinScreen> {
  final _auth = AuthService();
  String _pin = '';
  String _error = '';

  void _onKeyTap(String digit) {
    if (_pin.length < 6) {
      setState(() => _pin += digit);
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _onSubmit() async {
    if (_pin.length != 6) {
      setState(() => _error = 'Enter 6 digits');
      return;
    }

    if (widget.requireSetup) {
      // Save new PIN
      await _auth.setPin(_pin);
      if (!mounted) return;

      // Fetch role from Firestore
      final uid = _auth.getUid(); // ✅ already non-null
      final role = await _auth.getUserRole(uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(role: role ?? "staff"),
        ),
      );
    } else {
      // Verify existing PIN
      final ok = await _auth.verifyPin(_pin);
      if (!mounted) return;
      if (ok) {
        // Fetch role from Firestore
        final uid = _auth.getUid(); // ✅ already non-null
        final role = await _auth.getUserRole(uid);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(role: role ?? "staff"),
          ),
        );
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _pin = '';
        });
      }
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.pink : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['del', '0', 'ok'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (key == 'del') {
                    _onDelete();
                  } else if (key == 'ok') {
                    _onSubmit();
                  } else {
                    _onKeyTap(key);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: key == 'ok' ? Colors.blue : Colors.white,
                  foregroundColor: key == 'ok' ? Colors.white : Colors.black,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                  elevation: 2,
                ),
                child: key == 'del'
                    ? const Icon(Icons.backspace_outlined)
                    : Text(key, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.requireSetup ? 'Set PIN' : 'Enter PIN';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              widget.requireSetup
                  ? 'Create a 6-digit PIN to secure your app.'
                  : 'Enter your 6-digit PIN to continue.',
            ),
            const SizedBox(height: 24),
            _buildDots(),
            const SizedBox(height: 24),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }
}
