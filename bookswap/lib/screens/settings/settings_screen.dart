import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationReminders = true;
  bool _emailUpdates = true;
  // Fallback storage when shared_preferences plugin isn't available (e.g., web dev without restart)
  final Map<String, bool> _prefsFallback = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationReminders = prefs.getBool('notificationReminders') ?? true;
        _emailUpdates = prefs.getBool('emailUpdates') ?? true;
      });
    } catch (e) {
      // If plugin isn't available (MissingPluginException), fall back to in-memory values
      // This can happen during web dev if the app wasn't fully restarted after adding the plugin.
      // Use any previously stored fallback values or defaults.
      setState(() {
        _notificationReminders =
            _prefsFallback['notificationReminders'] ?? true;
        _emailUpdates = _prefsFallback['emailUpdates'] ?? true;
      });
    }
  }

  Future<void> _setNotificationReminders(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationReminders', v);
    } catch (e) {
      // fallback to in-memory map when plugin missing
      _prefsFallback['notificationReminders'] = v;
    }
    if (!mounted) return;
    setState(() => _notificationReminders = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          v
              ? 'Notification reminders enabled'
              : 'Notification reminders disabled',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _setEmailUpdates(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emailUpdates', v);
    } catch (e) {
      _prefsFallback['emailUpdates'] = v;
    }
    if (!mounted) return;
    setState(() => _emailUpdates = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(v ? 'Email updates enabled' : 'Email updates disabled'),
        duration: const Duration(seconds: 1),
      ),
    );
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

              const SizedBox(height: 16),

              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('Sign out'),
                  trailing: const Icon(Icons.logout),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final authProv = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await authProv.signOut();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
