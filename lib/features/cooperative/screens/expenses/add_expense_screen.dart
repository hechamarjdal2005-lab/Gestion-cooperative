import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gcoop/features/cooperative/providers/incomes_provider.dart';
import 'package:gcoop/shared/models/income.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final dynamic expense; // Can be Expense or Income
  final bool isIncome;
  const AddExpenseScreen({super.key, this.expense, this.isIncome = false});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late String _category;
  late DateTime _date;
  bool _isLoading = false;

  // Task 1: Product selection state
  Product? _selectedProduct;
  int _quantity = 1;

  final Map<int, String> arabicMonths = {
    1: 'يناير', 2: 'فبراير', 3: 'مارس', 4: 'أبريل',
    5: 'مايو', 6: 'يونيو', 7: 'يوليوز', 8: 'غشت', 9: 'شتنبر',
    10: 'أكتوبر', 11: 'نونبر', 12: 'دجنبر'
  };

  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.isIncome
        ? ['مبيعات', 'دعم/منح', 'اشتراكات الأعضاء', 'مداخيل أخرى']
        : ['كراء', 'كهرباء/ماء', 'نقل', 'أجور', 'مواد أولية', 'صيانة', 'أخرى'];

    _amountController = TextEditingController(text: widget.expense?.amount.toString());
    _noteController = TextEditingController(text: widget.expense?.note);
    _quantityController = TextEditingController(text: '1');
    _unitPriceController = TextEditingController(text: '0.00');
    _category = widget.expense?.category ?? _categories.first;
    _date = widget.expense?.date ?? DateTime.now();

    _quantityController.addListener(_calculateTotal);
    _unitPriceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    if (_category == 'مبيعات') {
      final qty = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_unitPriceController.text) ?? 0;
      final total = qty * price;
      _amountController.text = total.toStringAsFixed(2);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId == null) throw 'Cooperative not found';

      final amount = double.parse(_amountController.text);
      
      final data = {
        'cooperative_id': profile!.cooperativeId,
        'category': _category,
        'amount': amount,
        'date': _date.toIso8601String(),
        'note': _noteController.text.trim(),
      };

      if (widget.isIncome) {
        data['source'] = 'manual';
        if (widget.expense != null) {
          await ref.read(incomesProvider.notifier).updateIncome(widget.expense!.id, data);
        } else {
          await ref.read(incomesProvider.notifier).addIncome(data);
        }
      } else {
        if (widget.expense != null) {
          await ref.read(expensesProvider.notifier).updateExpense(widget.expense!.id, data);
        } else {
          await ref.read(expensesProvider.notifier).addExpense(data);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isIncome 
              ? (widget.expense != null ? 'تم تعديل الدخل بنجاح' : 'تمت إضافة الدخل بنجاح')
              : (widget.expense != null ? 'تم تعديل المصروف بنجاح' : 'تمت إضافة المصروف بنجاح')), 
            backgroundColor: Colors.green
          ),
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
    final bool isEdit = widget.expense != null;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isIncome 
          ? (isEdit ? 'تعديل دخل' : 'إضافة دخل')
          : (isEdit ? 'تعديل مصروف' : 'إضافة مصروف')),
        backgroundColor: const Color(0xFF1B2A6B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
              const Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  setState(() {
                    _category = val!;
                    _calculateTotal();
                  });
                },
              ),
              const SizedBox(height: 20),

              // Task 1: Product Selector for "مبيعات"
              if (widget.isIncome && _category == 'مبيعات') ...[
                const Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                productsAsync.when(
                  data: (products) => DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    hint: const Text('اختر المنتج'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProduct = val;
                        _unitPriceController.text = val?.price.toStringAsFixed(2) ?? '0.00';
                        _calculateTotal();
                      });
                    },
                    validator: (val) => val == null ? 'مطلوب' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Error loading products: $e'),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الثمن الوحدوي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _unitPriceController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              suffixText: 'DH',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Amount Field (Read-only for "مبيعات")
              const Text('المبلغ (DH)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                readOnly: widget.isIncome && _category == 'مبيعات',
                decoration: InputDecoration(
                  filled: true,
                  fillColor: (widget.isIncome && _category == 'مبيعات') ? Colors.grey.shade100 : Colors.grey.shade50,
                  suffixText: 'DH',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 20),

              // Date Picker
              const Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDate(_date), style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.calendar_today, color: Color(0xFF1B2A6B), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              const Text('ملاحظة (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
