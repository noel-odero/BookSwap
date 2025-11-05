import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationReminders = true;
  bool _emailUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationReminders = prefs.getBool('notificationReminders') ?? true;
      _emailUpdates = prefs.getBool('emailUpdates') ?? true;
    });
  }

  Future<void> _setNotificationReminders(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationReminders', v);
    if (!mounted) return;
    setState(() => _notificationReminders = v);
  }

  Future<void> _setEmailUpdates(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emailUpdates', v);
    if (!mounted) return;
    setState(() => _emailUpdates = v);
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'BookSwap',
      applicationVersion: '1.0.0',
      applicationLegalese: '© ${DateTime.now().year} BookSwap',
      children: [
        const SizedBox(height: 8),
        const Text('A simple app to swap books with your community.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text('Notification reminders'),
                        trailing: Switch(
                          value: _notificationReminders,
                          onChanged: _setNotificationReminders,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: const Text('Email Updates'),
                        trailing: Switch(
                          value: _emailUpdates,
                          onChanged: _setEmailUpdates,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('About'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: _showAbout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
