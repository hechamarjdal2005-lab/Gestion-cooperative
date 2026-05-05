import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'أخرى';
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = [
    'كراء',
    'كهرباء/ماء',
    'نقل',
    'أجور',
    'مواد أولية',
    'صيانة',
    'أخرى'
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId == null) throw 'Cooperative not found';

      final amount = double.parse(_amountController.text);
      
      await ref.read(expensesProvider.notifier).addExpense({
        'cooperative_id': profile!.cooperativeId,
        'category': _category,
        'amount': amount,
        'date': _date.toIso8601String(),
        'note': _noteController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المصروف بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مصروف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'المبلغ (DH)', suffixText: 'DH'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('التاريخ'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
