import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/incomes_provider.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/shared/models/income.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(incomesProvider);
    final l10n = AppLocalizations.of(context)!;

    return switch (incomesAsync) {
      AsyncData(:final value) => value.isEmpty
          ? Center(child: Text(l10n.noIncomes))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: value.length,
              itemBuilder: (context, index) {
                final income = value[index];
                return _buildIncomeItem(context, ref, income);
              },
            ),
      AsyncError(:final error) => Center(child: Text('${l10n.error}: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildIncomeItem(BuildContext context, WidgetRef ref, Income income) {
    final l10n = AppLocalizations.of(context)!;
    const successGreen = Colors.green;
    
    String categoryName = income.category;
    if (income.category == 'مبيعات') categoryName = l10n.categorySale;
    if (income.category == 'إيجار') categoryName = l10n.categoryRent;
    if (income.category == 'منح') categoryName = l10n.categoryGrant;
    if (income.category == 'مداخيل أخرى') categoryName = l10n.categoryOther;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: successGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.trending_up, color: successGreen),
        ),
        title: Row(
          children: [
            Text(
              categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: income.source == 'invoice' ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                income.source == 'invoice' ? l10n.sourceInvoice : l10n.sourceManual,
                style: TextStyle(
                  fontSize: 10,
                  color: income.source == 'invoice' ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('HH:mm - yyyy/MM/dd', 'en_US').format(income.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${NumberFormat('#,##0.00', 'en_US').format(income.amount)} DH',
              style: const TextStyle(
                color: successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (income.source == 'manual')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context, ref, income);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        const SizedBox(width: 8),
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        onTap: () {
          if (income.note != null && income.note!.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.note),
                content: Text(income.note!),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Income income) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(l10n.confirmDeleteIncome, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(incomesProvider.notifier).deleteIncome(income.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.incomeDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'مداخيل أخرى';
  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFieldsFromAmount);
    _quantityController.addListener(_calculateTotal);
    _unitPriceController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    if (_selectedCategory == 'مبيعات') {
      final qty = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_unitPriceController.text) ?? 0;
      final total = qty * price;
      if (total > 0) {
        _amountController.removeListener(_updateFieldsFromAmount);
        _amountController.text = NumberFormat('#,##0.00', 'en_US').format(total);
        _amountController.addListener(_updateFieldsFromAmount);
      }
    }
  }

  void _updateFieldsFromAmount() {}

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addIncome),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final productsAsync = ref.watch(productsProvider);
          final products = productsAsync.value ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'مبيعات', child: Text(l10n.categorySale)),
                      DropdownMenuItem(value: 'إيجار', child: Text(l10n.categoryRent)),
                      DropdownMenuItem(value: 'منح', child: Text(l10n.categoryGrant)),
                      DropdownMenuItem(value: 'مداخيل أخرى', child: Text(l10n.categoryOther)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                          if (value != 'مبيعات') {
                            _selectedProduct = null;
                            _unitPriceController.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedCategory == 'مبيعات') ...[
                    DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: InputDecoration(
                        labelText: l10n.selectProduct,
                        border: const OutlineInputBorder(),
                      ),
                      items: products.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.name));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProduct = value;
                            _unitPriceController.text = NumberFormat('#,##0.00', 'en_US').format(value.price);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _unitPriceController,
                            decoration: InputDecoration(
                              labelText: l10n.unitPrice,
                              border: const OutlineInputBorder(),
                              suffixText: 'DH',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: l10n.quantity,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      border: const OutlineInputBorder(),
                      suffixText: 'DH',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.error;
                      if (double.tryParse(value.replaceAll(',', '')) == null) return l10n.error;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(l10n.date),
                    subtitle: Text(DateFormat('yyyy/MM/dd', 'en_US').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('en', 'US'),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.note,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _submit(ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.save),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(incomesProvider.notifier).addIncome({
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'date': _selectedDate.toIso8601String(),
        'note': _noteController.text,
        'source': 'manual',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
