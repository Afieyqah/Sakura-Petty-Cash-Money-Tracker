import 'package:flutter/material.dart';
import '../alerts/alerts_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Data State tempatan
  String selectedCurrency = "Malaysia Ringgit (RM)";
  String selectedLanguage = "English";
  String firstDayOfWeek = "Sunday";
  bool isNotificationOn = true;

  final Color textBlue = const Color(0xFF1A1A80);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cherry_blossom_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 120, left: 20, right: 20),
          children: [
            // --- SECTION: PREFERENCES ---
            _buildPickerItem("Currency", selectedCurrency, _showCurrencyPicker),
            _buildPickerItem("Currency Conversion", null, () {}),
            _buildPickerItem("First day of week", firstDayOfWeek, _showWeekPicker),
            _buildPickerItem("Language", selectedLanguage, _showLanguagePicker),

            // --- SECTION: FEATURES ---
            _buildNavigationItem("Bills", "Manage your monthly bills", () {
                // Tambah navigation di sini jika perlu
            }),

            _buildNavigationItem("Alerts", "Budget & limit reminders", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            }),

            // --- SECTION: NOTIFICATIONS ---
            _buildNotificationSwitch(),
            
            _buildNavigationItem("Reset & Clean Up", "Clear all local data", () {
              _showResetDialog();
            }),
          ],
        ),
      ),
    );
  }

  // Widget untuk item yang buka Picker/Popup
  Widget _buildPickerItem(String title, String? subtitle, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: TextStyle(color: textBlue, fontWeight: FontWeight.bold)),
          // DIUBAH: withOpacity -> withValues (Fix for Flutter 3.33+)
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: textBlue.withValues(alpha: 0.7))) : null,
          onTap: onTap,
        ),
        // DIUBAH: withOpacity -> withValues
        Divider(color: Colors.purple.withValues(alpha: 0.3)),
      ],
    );
  }

  // Widget untuk item yang Navigate ke skrin lain
  Widget _buildNavigationItem(String title, String subtitle, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: TextStyle(color: textBlue, fontWeight: FontWeight.bold)),
          // DIUBAH: withOpacity -> withValues
          subtitle: Text(subtitle, style: TextStyle(color: textBlue.withValues(alpha: 0.7))),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
        Divider(color: Colors.purple.withValues(alpha: 0.3)),
      ],
    );
  }

  // Widget khas untuk Switch Notification
  Widget _buildNotificationSwitch() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text("Notifications", style: TextStyle(color: textBlue, fontWeight: FontWeight.bold)),
          // DIUBAH: withOpacity -> withValues
          subtitle: Text(isNotificationOn ? "Receive all notifications" : "Notifications muted", 
            style: TextStyle(color: textBlue.withValues(alpha: 0.7))),
          value: isNotificationOn,
          activeColor: Colors.pink,
          onChanged: (bool value) {
            setState(() {
              isNotificationOn = value;
            });
          },
        ),
        Divider(color: Colors.purple.withValues(alpha: 0.3)),
      ],
    );
  }

  // --- LOGIK POPUP (PICKERS) ---

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _pickerList(["Malaysia Ringgit (RM)", "US Dollar (USD)", "Singapore Dollar (SGD)"], (val) {
        setState(() => selectedCurrency = val);
      }),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _pickerList(["English", "Bahasa Melayu", "Japanese"], (val) {
        setState(() => selectedLanguage = val);
      }),
    );
  }

  void _showWeekPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _pickerList(["Sunday", "Monday"], (val) {
        setState(() => firstDayOfWeek = val);
      }),
    );
  }

  Widget _pickerList(List<String> options, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(options[index]),
          onTap: () {
            onSelect(options[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Data?"),
        content: const Text("This will clear all your local settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Reset", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}