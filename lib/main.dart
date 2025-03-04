import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/phone_numbers_screen.dart';
import 'screens/api_settings_screen.dart';
import 'screens/sms_logs_screen.dart';
import 'services/phone_number_service.dart';
import 'services/api_settings_service.dart';
import 'services/api_service.dart';
import 'services/sms_parser_service.dart';
import 'services/sms_log_service.dart';
import 'models/sms_log.dart';

// Background task handler
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final telephony = Telephony.instance;
    final phoneNumberService = PhoneNumberService();
    final apiSettingsService = ApiSettingsService();
    final smsParser = SmsParserService();

    final phoneNumbers = await phoneNumberService.getPhoneNumbers();
    final apiSettings = await apiSettingsService.getApiSettings();

    if (apiSettings.endpoint.isEmpty || apiSettings.apiKey.isEmpty) {
      EasyLoading.showError("لطفا تنظیمات API را چک بفرمایید");
      return Future.value(true);
    }

    final apiService = ApiService(apiSettings);

    for (var phoneNumber in phoneNumbers) {
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(phoneNumber.number),
      );

      for (var message in messages) {
        try {
          final parsedData = smsParser.parseMessage(message.body ?? '');

          await apiService.sendSmsData(
            from: message.address ?? '',
            message: message.body ?? '',
            date: message.date,
            description: phoneNumber.description,
            amount: parsedData['amount'] ?? '',
            recipeId: parsedData['recipeId'] ?? '',
          );
          
          // اضافه کردن لاگ موفق
          await SmsLogService().addLog(SmsLog(
            from: message.address ?? '',
            message: message.body ?? '',
            date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
            description: phoneNumber.description,
            amount: parsedData['amount'] ?? '',
            recipeId: parsedData['recipeId'] ?? '',
          ));
        } catch (e) {
          // اضافه کردن لاگ خطا
          await SmsLogService().addLog(SmsLog(
            from: message.address ?? '',
            message: message.body ?? '',
            date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
            description: phoneNumber.description,
            amount: '', // در صورت خطا، مقدار خالی قرار می‌دهیم
            recipeId: '', // در صورت خطا، مقدار خالی قرار می‌دهیم
            success: false,
            error: e.toString(),
          ));
          EasyLoading.showError("خطا در ارسال پیامک به API: $e");
        }
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // راه‌اندازی سرشماره‌های پیش‌فرض
  final phoneNumberService = PhoneNumberService();
  await phoneNumberService.initializeDefaultPhoneNumbers();

  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    "sms-reader",
    "readSMS",
    frequency: Duration(seconds: 5),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shetab Verification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Shetab Verification'),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Telephony telephony = Telephony.instance;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.sms.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('برنامه در حال مانیتور کردن پیامک‌ها است'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text('درخواست مجوز پیامک'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PhoneNumbersScreen()),
                );
              },
              child: const Text('مدیریت سرشماره‌ها'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ApiSettingsScreen()),
                );
              },
              child: const Text('تنظیمات API'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SmsLogsScreen()),
                );
              },
              child: const Text('تاریخچه ارسال پیامک‌ها'),
            ),
          ],
        ),
      ),
    );
  }
}
