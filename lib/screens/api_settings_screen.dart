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
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // کارت راهنما
                Center(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.api,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تنظیمات ارتباط با سرور',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'لطفاً آدرس API و کلید دسترسی را وارد کنید',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'آدرس API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _endpointController,
                            decoration: const InputDecoration(
                              hintText: 'مثال: https://api.example.com/sms',
                              prefixIcon: Icon(Icons.link),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _handleQrScan(type: 'endpoint'),
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                            tooltip: 'اسکن QR Code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'کلید API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            obscuringCharacter: '●',
                            decoration: InputDecoration(
                              hintText: 'کلید API خود را وارد کنید',
                              prefixIcon: const Icon(Icons.vpn_key),
                              suffixIcon: IconButton(
                                onPressed: _toggleSecureText,
                                icon: Icon(
                                  _isSecureText ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                tooltip: _isSecureText ? 'نمایش' : 'مخفی کردن',
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            textDirection: TextDirection.ltr,
                            obscureText: _isSecureText,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _handleQrScan(type: 'apiKey'),
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                            tooltip: 'اسکن QR Code',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (_endpointController.text.isEmpty || _apiKeyController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لطفاً تمام فیلدها را پر کنید'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      await _saveSettings();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'ذخیره تنظیمات',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
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