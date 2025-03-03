import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phone_number.dart';

class PhoneNumberService {
  static const String _key = 'phone_numbers';
  
  // لیست سرشماره‌های پیش‌فرض
  static final List<PhoneNumber> _defaultPhoneNumbers = [
    PhoneNumber(
      number: 'B.Pasargard',
      description: 'بانک پاسارگاد',
    ),
    PhoneNumber(
      number: 'Bank Mellat',
      description: 'بانک ملت',
    ),
    PhoneNumber(
      number: '+98999987641',
      description: 'بلو بانک',
    ),
  ];

  // متد جدید برای بررسی و اضافه کردن سرشماره‌های پیش‌فرض
  Future<void> initializeDefaultPhoneNumbers() async {
    final existingNumbers = await getPhoneNumbers();
    
    if (existingNumbers.isEmpty) {
      await savePhoneNumbers(_defaultPhoneNumbers);
    }
  }

  Future<List<PhoneNumber>> getPhoneNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString == null) {
      // اگر هیچ سرشماره‌ای وجود نداشت، سرشماره‌های پیش‌فرض را اضافه کن
      await initializeDefaultPhoneNumbers();
      return _defaultPhoneNumbers;
    }
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => PhoneNumber.fromJson(json)).toList();
  }
  
  Future<void> savePhoneNumbers(List<PhoneNumber> numbers) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(
      numbers.map((number) => number.toJson()).toList()
    );
    await prefs.setString(_key, jsonString);
  }
  
  Future<void> addPhoneNumber(PhoneNumber number) async {
    final numbers = await getPhoneNumbers();
    numbers.add(number);
    await savePhoneNumbers(numbers);
  }
  
  Future<void> updatePhoneNumber(int index, PhoneNumber number) async {
    final numbers = await getPhoneNumbers();
    if (index >= 0 && index < numbers.length) {
      numbers[index] = number;
      await savePhoneNumbers(numbers);
    }
  }
  
  Future<void> deletePhoneNumber(int index) async {
    final numbers = await getPhoneNumbers();
    if (index >= 0 && index < numbers.length) {
      numbers.removeAt(index);
      await savePhoneNumbers(numbers);
    }
  }
} 