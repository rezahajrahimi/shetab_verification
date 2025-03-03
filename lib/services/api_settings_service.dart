import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_settings.dart';

class ApiSettingsService {
  static const String _key = 'api_settings';
  
  Future<ApiSettings> getApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return ApiSettings(endpoint: '', apiKey: '');
    }
    
    return ApiSettings.fromJson(json.decode(jsonString));
  }
  
  Future<void> saveApiSettings(ApiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(settings.toJson()));
  }
} 