class SmsParserService {
  Map<String, String> parseMessage(String message) {
    String amount = '';
    String recipeId = '';
    
    // تشخیص مبلغ با استفاده از عبارات رایج در پیامک‌های بانکی
    RegExp amountRegex = RegExp(r'مبلغ[:\s]*([0-9,]+)|([0-9,]+)(?=\s*ریال)|([0-9,]+)(?=\s*تومان)');
    var amountMatch = amountRegex.firstMatch(message);
    if (amountMatch != null) {
      amount = (amountMatch.group(1) ?? amountMatch.group(2) ?? amountMatch.group(3) ?? '')
          .replaceAll(',', '');
    }

    // تشخیص شماره کارت
    RegExp cardRegex = RegExp(r'(?:کارت|شماره کارت|کارت شماره).*?(\d{16}|\d{4}-\d{4}-\d{4}-\d{4})');
    var cardMatch = cardRegex.firstMatch(message);
    if (cardMatch != null) {
      recipeId = cardMatch.group(1)?.replaceAll('-', '') ?? '';
    }

    return {
      'amount': amount,
      'recipeId': recipeId,
    };
  }
} 