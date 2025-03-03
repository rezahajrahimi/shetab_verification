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
  
  Future<void> _showAddEditDialog([int? index]) async {
    final isEditing = index != null;
    final phoneNumber = isEditing ? _phoneNumbers[index] : PhoneNumber(number: '', description: '');
    
    final numberController = TextEditingController(text: phoneNumber.number);
    final descriptionController = TextEditingController(text: phoneNumber.description);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'ویرایش سرشماره' : 'افزودن سرشماره جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن',
                hintText: 'مثال: 985000114',
              ),
              textDirection: TextDirection.ltr,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                hintText: 'توضیحات اختیاری',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت سرشماره‌ها'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: _phoneNumbers.length,
        itemBuilder: (context, index) {
          final number = _phoneNumbers[index];
          return ListTile(
            title: Text(number.number, textDirection: TextDirection.ltr),
            subtitle: number.description.isNotEmpty ? Text(number.description) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddEditDialog(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _service.deletePhoneNumber(index);
                    _loadPhoneNumbers();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 