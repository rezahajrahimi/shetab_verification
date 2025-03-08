import 'package:flutter/material.dart';
import '../models/phone_number.dart';
import '../services/phone_number_service.dart';

class PhoneNumbersScreen extends StatefulWidget {
  const PhoneNumbersScreen({super.key});

  @override
  State<PhoneNumbersScreen> createState() => _PhoneNumbersScreenState();
}

class _PhoneNumbersScreenState extends State<PhoneNumbersScreen> {
  final PhoneNumberService _service = PhoneNumberService();
  List<PhoneNumber> _phoneNumbers = [];
  
  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers();
  }
  
  Future<void> _loadPhoneNumbers() async {
    final numbers = await _service.getPhoneNumbers();
    setState(() {
      _phoneNumbers = numbers;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت سرشماره‌ها'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        child: _phoneNumbers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'هیچ سرشماره‌ای تعریف نشده است',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('افزودن سرشماره جدید'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _phoneNumbers.length,
                itemBuilder: (context, index) {
                  final number = _phoneNumbers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_android,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        number.number,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: number.description.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                number.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: () => _showAddEditDialog(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _showDeleteConfirmation(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _phoneNumbers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('افزودن سرشماره'),
            )
          : null,
    );
  }

  Future<void> _showDeleteConfirmation(int index) async {
    final number = _phoneNumbers[index];
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سرشماره'),
        content: Text('آیا از حذف سرشماره ${number.number} اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              await _service.deletePhoneNumber(index);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadPhoneNumbers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog([int? index]) async {
    final isEditing = index != null;
    final phoneNumber = isEditing ? _phoneNumbers[index] : PhoneNumber(number: '', description: '');
    
    final numberController = TextEditingController(text: phoneNumber.number);
    final descriptionController = TextEditingController(text: phoneNumber.description);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'ویرایش سرشماره' : 'افزودن سرشماره جدید',
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: InputDecoration(
                labelText: 'شماره تلفن',
                hintText: 'مثال: 985000114',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'توضیحات',
                hintText: 'توضیحات اختیاری',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () async {
              if (numberController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لطفاً شماره تلفن را وارد کنید'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              
              final newNumber = PhoneNumber(
                number: numberController.text,
                description: descriptionController.text,
              );
              
              if (isEditing) {
                await _service.updatePhoneNumber(index, newNumber);
              } else {
                await _service.addPhoneNumber(newNumber);
              }
              
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadPhoneNumbers();
            },
            child: Text(isEditing ? 'ویرایش' : 'افزودن'),
          ),
        ],
      ),
    );
  }
} 