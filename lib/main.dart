import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
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
      debugPrint("apiSettings is empty");
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
      // remove old messages with 10 minutes ago 
      messages = messages.where((message) => message.date! > DateTime.now().subtract(Duration(minutes: 10)).millisecondsSinceEpoch).toList();
      debugPrint("messages after removing old messages: $messages");

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
          debugPrint("error: $e");
        }
      }
    }
    return Future.value(true);
  });
}

Future<bool> checkPermissions() async {
  final smsStatus = await Permission.sms.status;
  final phoneStatus = await Permission.phone.status;
  final notificationStatus = await Permission.notification.status;
  
  if (!smsStatus.isGranted || !phoneStatus.isGranted) {
    debugPrint("مجوزهای لازم داده نشده است");
    debugPrint("وضعیت مجوز پیامک: $smsStatus");
    debugPrint("وضعیت مجوز تلفن: $phoneStatus");
    debugPrint("وضعیت مجوز اعلان: $notificationStatus");
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
  await Permission.notification.request(); // اضافه کردن درخواست مجوز اعلان برای اندروید 13+
  
  final hasPermissions = await checkPermissions();
  if (!hasPermissions) {
    debugPrint("لطفا مجوزهای لازم را به برنامه بدهید");
    
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
    await Permission.phone.request();
    await Permission.notification.request(); // اضافه کردن درخواست مجوز اعلان
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // وضعیت سرویس
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.message_outlined,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'سرویس پیامک فعال است',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'در حال مانیتور کردن پیامک‌های ورودی',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // دکمه‌های عملیات
                const Text(
                  'تنظیمات و مدیریت',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.perm_device_information,
                      title: 'مجوزهای برنامه',
                      subtitle: 'درخواست و بررسی دسترسی‌ها',
                      color: Colors.blue,
                      onTap: _requestPermissions,
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.phone_android,
                      title: 'سرشماره‌ها',
                      subtitle: 'مدیریت شماره‌های بانکی',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneNumbersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.settings,
                      title: 'تنظیمات API',
                      subtitle: 'پیکربندی ارتباط با سرور',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApiSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.history,
                      title: 'تاریخچه',
                      subtitle: 'گزارش پیامک‌های دریافتی',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SmsLogsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
