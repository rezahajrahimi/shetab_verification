import 'package:flutter/material.dart';
import 'package:shetab_verification/screens/qr_scanner_screen.dart';
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
  bool _isSecureText = true;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات با موفقیت ذخیره شد')),
    );
  }
  
  Future<void> _handleQrScan({required String type}) async {
    try {
      final qrData = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QrScannerScreen(),
        ),
      );
      
      if (qrData != null && mounted) {
        setState(() {
          if (type == 'endpoint') {
            _endpointController.text = qrData;
          } else if (type == 'apiKey') {
            _apiKeyController.text = qrData;
          }
        });
      }
    } catch (e) {
      debugPrint('خطا در اسکن QR: $e');
    }
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _endpointController,
                    decoration: const InputDecoration(
                      labelText: 'آدرس API',
                      hintText: 'مثال: https://api.example.com/sms',
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                IconButton(
                  onPressed: () => _handleQrScan(type: 'endpoint'),
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apiKeyController,
                    obscuringCharacter: '*',
                    // add show secure and unsecure icon
                    decoration: InputDecoration(
                      labelText: 'کلید API',
                      hintText: 'کلید API خود را وارد کنید',
                      suffixIcon: IconButton( 
                        onPressed: () => _toggleSecureText(),
                        icon: _isSecureText ?  Icon(Icons.visibility) :  Icon(Icons.visibility_off),
                      ),
                    ),
                    textDirection: TextDirection.ltr,
                    obscureText: _isSecureText,
                  ),
                ),
                IconButton(
                  onPressed: () => _handleQrScan(type: 'apiKey'),
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ],
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
  
   _toggleSecureText() {
    setState(() {
      _isSecureText = !_isSecureText;
    });
  }
} 