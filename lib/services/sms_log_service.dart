import 'dart:convert';
import '../models/sms_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsLogService {
  static const String _key = 'sms_logs';
  static const int _pageSize = 20;

  Future<void> addLog(SmsLog log) async {
     await SharedPreferences.getInstance();
    final logs = await getLogs();
    logs.insert(0, log);
    await _saveLogs(logs);
  }

  Future<List<SmsLog>> getLogs({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsJson = prefs.getString(_key);
    if (logsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(logsJson);
    final List<SmsLog> logs = decoded.map((item) => SmsLog.fromMap(item)).toList();
    
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    return logs.sublist(startIndex, endIndex.clamp(0, logs.length));
  }

  Future<void> _saveLogs(List<SmsLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(logs.map((log) => log.toMap()).toList());
    await prefs.setString(_key, encoded);
  }
} 