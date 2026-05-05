import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/core/constants/colors.dart';

import 'package:gcoop/features/cooperative/screens/expenses/add_expense_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المصاريف')),
      body: Column(
        children: [
          _buildTotalCard(expensesAsync),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    child: ListTile(
                      title: Text(expense.category),
                      subtitle: Text(DateFormat('yyyy/MM/dd').format(expense.date)),
                      trailing: Text('${expense.amount.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        child: const Icon(Icons.money_off, color: Colors.red),
                      ),
                      onTap: () {
                        if (expense.note != null && expense.note!.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ملاحظة'),
                              content: Text(expense.note!),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTotalCard(AsyncValue<List<dynamic>> expensesAsync) {
    final total = expensesAsync.maybeWhen(
      data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.amount),
      orElse: () => 0.0,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('إجمالي المصاريف', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('${total.toStringAsFixed(2)} DH', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
