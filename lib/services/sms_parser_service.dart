class SmsParserService {
  Map<String, String> parseMessage(String message) {
    String amount = '';
    
    // الگوی تشخیص مبلغ برای بلو بانک
    RegExp blueBankRegex = RegExp(r'([0-9,]+)(?=\s*ریال به حساب شما نشست)');
    // الگوی تشخیص مبلغ برای بانک ملت
    RegExp mellatRegex = RegExp(r'واریز([0-9,]+)');
    // الگوی تشخیص مبلغ برای بانک پاسارگاد
    RegExp pasargadRegex = RegExp(r'\+([0-9,]+)');
    
    var amountMatch = blueBankRegex.firstMatch(message);
    if (amountMatch != null) {
      amount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    } else {
      amountMatch = mellatRegex.firstMatch(message);
      if (amountMatch != null) {
        amount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
      } else {
        // اگر الگوهای قبلی پیدا نشد، الگوی پاسارگاد را چک کن
        amountMatch = pasargadRegex.firstMatch(message);
        if (amountMatch != null) {
          amount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
        }
      }
    }

    return {
      'amount': amount,
      'recipeId': '', // چون نیازی به شماره کارت نداریم، خالی می‌فرستیم
    };
  }

  // متد کمکی برای تشخیص نوع بانک (اختیاری)
  String detectBankType(String message) {
    // الگوی پاسارگاد: یک شماره حساب با سه نقطه بین اعداد و یک مبلغ با + در خط بعد
    RegExp pasargadPattern = RegExp(r'^\d+\.\d+\.\d+\.\d+\s*\n\+');
    
    if (message.contains("بلو")) return "BLUEBANK";
    if (message.contains("حساب")) return "MELLAT";
    if (pasargadPattern.hasMatch(message)) return "PASARGAD";
    return "UNKNOWN";
  }
} 