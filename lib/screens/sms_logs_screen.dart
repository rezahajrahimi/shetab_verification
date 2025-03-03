import 'package:flutter/material.dart';
import '../models/sms_log.dart';
import '../services/sms_log_service.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  final SmsLogService _logService = SmsLogService();
  List<SmsLog> _logs = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    final newLogs = await _logService.getLogs(page: _currentPage);
    
    setState(() {
      _logs.addAll(newLogs);
      _hasMore = newLogs.length == 20;
      _currentPage++;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه ارسال پیامک‌ها'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _logs = [];
            _currentPage = 1;
            _hasMore = true;
          });
          await _loadLogs();
        },
        child: ListView.builder(
          itemCount: _logs.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _logs.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final log = _logs[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(log.from),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مبلغ: ${log.amount}'),
                    Text('شناسه تراکنش: ${log.recipeId}'),
                    Text('تاریخ: ${_formatDate(log.date)}'),
                  ],
                ),
                trailing: Icon(
                  log.success ? Icons.check_circle : Icons.error,
                  color: log.success ? Colors.green : Colors.red,
                ),
              ),
            );
          },
          onEndReached: _loadLogs,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
} 