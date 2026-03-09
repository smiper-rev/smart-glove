import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/bluetooth_service.dart' as local;
import '../core/language_manager.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LanguageManager _languageManager = LanguageManager();
  String _selectedTranslationLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final bluetoothService = Provider.of<local.BluetoothService>(context, listen: false);
    setState(() {
      _selectedTranslationLanguage = bluetoothService.getTranslationLanguage().isEmpty
          ? 'system'
          : bluetoothService.getTranslationLanguage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<local.BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_languageManager.getLocalizedText('settings')),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTranslationLanguageSection(bluetoothService),
          const SizedBox(height: 24),
          _buildTestSection(bluetoothService),
          const SizedBox(height: 24),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildTranslationLanguageSection(local.BluetoothService bluetoothService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Translation Language',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select language for translating Arduino messages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTranslationLanguage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Translation Language',
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic)')),
                DropdownMenuItem(value: 'fr', child: Text('Français (French)')),
                DropdownMenuItem(value: 'system', child: Text('System Language')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTranslationLanguage = value;
                  });
                  if (value == 'system') {
                    // Use system language
                    bluetoothService.setTranslationLanguage('');
                  } else {
                    bluetoothService.setTranslationLanguage(value);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(local.BluetoothService bluetoothService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Functions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => bluetoothService.testTts(),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Test TTS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Send test message from Arduino to test translation'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('Test Arduino'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Smart Glove App'),
              subtitle: const Text('Version 1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Developer'),
              subtitle: const Text('tmail000024@gmail.com'),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translation Support'),
              subtitle: const Text('English, Arabic, French'),
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Bluetooth Connectivity'),
              subtitle: const Text('Medical gesture detection'),
            ),
          ],
        ),
      ),
    );
  }
}
