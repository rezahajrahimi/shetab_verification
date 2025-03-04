import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../models/sms_log.dart';
import '../services/sms_log_service.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  final SmsLogService _logService = SmsLogService();
  static const _pageSize = 20;

  final PagingController<int, SmsLog> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _logService.getLogs(page: pageKey);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه ارسال پیامک‌ها'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: PagedListView<int, SmsLog>(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<SmsLog>(
            itemBuilder: (context, log, index) => Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(log.from),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مبلغ: ${log.amount}'),
                    Text('شناسه تراکنش: ${log.recipeId}'),
                    Text('تاریخ: ${_formatDate(log.date)}'),
                    if (log.error != null)
                      Text('خطا: ${log.error}', 
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                trailing: Icon(
                  log.success ? Icons.check_circle : Icons.error,
                  color: log.success ? Colors.green : Colors.red,
                ),
              ),
            ),
            firstPageProgressIndicatorBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            newPageProgressIndicatorBuilder: (_) => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
            noItemsFoundIndicatorBuilder: (_) => const Center(
              child: Text('هیچ لاگی یافت نشد'),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
} 