import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart' as wm;
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
  wm.Workmanager().executeTask((task, inputData) async {

    final telephony = Telephony.instance;
    final phoneNumberService = PhoneNumberService();
    final apiSettingsService = ApiSettingsService();
    final smsParser = SmsParserService();

    final phoneNumbers = await phoneNumberService.getPhoneNumbers();
    final apiSettings = await apiSettingsService.getApiSettings();

    debugPrint("phoneNumbers: $phoneNumbers");
    debugPrint("apiSettings: $apiSettings");

    if (apiSettings.endpoint.isEmpty || apiSettings.apiKey.isEmpty) {
      EasyLoading.showError("لطفا تنظیمات API را چک بفرمایید");
      return Future.value(true);
    }

    final apiService = ApiService(apiSettings);

    for (var phoneNumber in phoneNumbers) {
      debugPrint("phoneNumber: $phoneNumber");
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(phoneNumber.number),
      );
      debugPrint("messages: $messages");

      for (var message in messages) {
        debugPrint("message: $message");
        debugPrint("started parsing message");
        try {
          final parsedData = smsParser.parseMessage(message.body ?? '');
          debugPrint("parsedData: $parsedData");

          await apiService.sendSmsData(
            from: message.address ?? '',
            message: message.body ?? '',
            date: message.date,
            description: phoneNumber.description,
            amount: parsedData['amount'] ?? '',
            recipeId: parsedData['recipeId'] ?? '',
          );
          debugPrint("message sent");
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
          debugPrint("error: $e");
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

Future<bool> checkPermissions() async {
  final smsStatus = await Permission.sms.status;
  final phoneStatus = await Permission.phone.status;
  
  if (!smsStatus.isGranted || !phoneStatus.isGranted) {
    debugPrint("مجوزهای لازم داده نشده است");
    debugPrint("وضعیت مجوز پیامک: $smsStatus");
    debugPrint("وضعیت مجوز تلفن: $phoneStatus");
    return false;
  }
  return true;
}

Future<void> processSmsMessage(SmsMessage message) async {
  debugPrint("پیامک جدید دریافت شد: ${message.body}");
  
  final phoneNumberService = PhoneNumberService();
  final apiSettingsService = ApiSettingsService();
  final smsParser = SmsParserService();

  final phoneNumbers = await phoneNumberService.getPhoneNumbers();
  final apiSettings = await apiSettingsService.getApiSettings();

  // نرمال‌سازی شماره پیامک
  String normalizedAddress = (message.address ?? '')
    .trim()
    .toLowerCase()
    .replaceAll(" ", "")
    .replaceAll("+98", "")
    .replaceAll("98", "");
  
  if (normalizedAddress.startsWith("0")) {
    normalizedAddress = normalizedAddress.substring(1);
  }
  
  debugPrint("شماره نرمال شده: $normalizedAddress");

  // بررسی اینکه آیا پیامک از شماره‌های مورد نظر است
  final matchingNumber = phoneNumbers.where((number) {
    String normalizedNumber = number.number
      .trim()
      .toLowerCase()
      .replaceAll(" ", "")
      .replaceAll("+98", "")
      .replaceAll("98", "");
    
    if (normalizedNumber.startsWith("0")) {
      normalizedNumber = normalizedNumber.substring(1);
    }
    
    debugPrint("مقایسه: $normalizedAddress با $normalizedNumber");
    return normalizedAddress.contains(normalizedNumber) || 
           normalizedNumber.contains(normalizedAddress);
  }).firstOrNull;

  if (matchingNumber == null) {
    debugPrint("پیامک از شماره‌های تعریف شده نیست");
    return;
  }

  debugPrint("پیامک از شماره ${matchingNumber.number} دریافت شد");

  if (apiSettings.endpoint.isEmpty || apiSettings.apiKey.isEmpty) {
    debugPrint("تنظیمات API کامل نیست");
    return;
  }

  try {
    final parsedData = smsParser.parseMessage(message.body ?? '');
    debugPrint("اطلاعات استخراج شده: $parsedData");

    final apiService = ApiService(apiSettings);
    await apiService.sendSmsData(
      from: message.address ?? '',
      message: message.body ?? '',
      date: message.date,
      description: matchingNumber.description,
      amount: parsedData['amount'] ?? '',
      recipeId: parsedData['recipeId'] ?? '',
    );

    // اضافه کردن لاگ موفق
    await SmsLogService().addLog(SmsLog(
      from: message.address ?? '',
      message: message.body ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
      description: matchingNumber.description,
      amount: parsedData['amount'] ?? '',
      recipeId: parsedData['recipeId'] ?? '',
    ));
    
    debugPrint("پیامک با موفقیت پردازش شد");
  } catch (e) {
    debugPrint("خطا در پردازش پیامک: $e");
    await SmsLogService().addLog(SmsLog(
      from: message.address ?? '',
      message: message.body ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
      description: matchingNumber.description,
      amount: '',
      recipeId: '',
      success: false,
      error: e.toString(),
    ));
  }
}

// تابع پردازش پیامک در پس‌زمینه به صورت استاتیک
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  debugPrint("پیامک جدید در پس‌زمینه دریافت شد");
  await processSmsMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // درخواست و بررسی مجوزها
  await Permission.sms.request();
  await Permission.phone.request();
  
  final hasPermissions = await checkPermissions();
  if (!hasPermissions) {
    debugPrint("لطفا مجوزهای لازم را به برنامه بدهید");
    EasyLoading.showError("لطفا مجوزهای لازم را به برنامه بدهید");
  }

  // تنظیم گیرنده پیامک
  final telephony = Telephony.instance;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      debugPrint("پیامک جدید دریافت شد");
      processSmsMessage(message);
    },
    onBackgroundMessage: backgroundMessageHandler, // استفاده از تابع استاتیک
  );

  // راه‌اندازی سرشماره‌های پیش‌فرض
  await wm.Workmanager().initialize(callbackDispatcher);
  await wm.Workmanager().registerPeriodicTask(
    "sms-reader",
    "readSMS",
    frequency: Duration(minutes: 15),
    initialDelay: Duration(seconds: 20),
    constraints: wm.Constraints(
      networkType: wm.NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
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
