import 'package:flutter/material.dart';
import '../models/api_settings.dart';
import '../services/api_settings_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final ApiSettingsService _service = ApiSettingsService();
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _service.getApiSettings();
    setState(() {
      _endpointController.text = settings.endpoint;
      _apiKeyController.text = settings.apiKey;
    });
  }
  
  Future<void> _saveSettings() async {
    final settings = ApiSettings(
      endpoint: _endpointController.text,
      apiKey: _apiKeyController.text,
    );
    await _service.saveApiSettings(settings);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات با موفقیت ذخیره شد')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'آدرس API',
                hintText: 'مثال: https://api.example.com/sms',
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'کلید API',
                hintText: 'کلید API خود را وارد کنید',
              ),
              textDirection: TextDirection.ltr,
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('ذخیره تنظیمات'),
            ),
          ],
        ),
      ),
    );
  }
} 