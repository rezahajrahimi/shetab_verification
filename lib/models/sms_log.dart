class SmsLog {
  final String from;
  final String message;
  final DateTime date;
  final String description;
  final String amount;
  final String recipeId;
  final bool success;
  final String? error;

  SmsLog({
    required this.from,
    required this.message,
    required this.date,
    required this.description,
    required this.amount,
    required this.recipeId,
    this.success = true,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'message': message,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
      'recipeId': recipeId,
      'success': success,
      'error': error,
    };
  }

  factory SmsLog.fromMap(Map<String, dynamic> map) {
    return SmsLog(
      from: map['from'],
      message: map['message'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      amount: map['amount'],
      recipeId: map['recipeId'],
      success: map['success'],
      error: map['error'],
    );
  }
} 