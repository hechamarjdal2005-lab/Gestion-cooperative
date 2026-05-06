import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/features/cooperative/screens/expenses/add_expense_screen.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Expense>> expensesAsync = ref.watch(expensesProvider);
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          l10n.expenses,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, expensesAsync),
          Expanded(
            child: switch (expensesAsync) {
              AsyncData(:final value) => value.isEmpty
                  ? Center(child: Text(l10n.noExpenses))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final expense = value[index];
                        return _buildExpenseItem(context, ref, expense);
                      },
                    ),
              AsyncError(:final error) => Center(child: Text('${l10n.error}: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AsyncValue<List<Expense>> expensesAsync) {
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);
    final today = DateTime.now();
    
    final totalToday = switch (expensesAsync) {
      AsyncData(:final value) => value
          .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
          .fold(0.0, (sum, e) => sum + e.amount),
      _ => 0.0,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.totalExpensesToday,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${totalToday.toStringAsFixed(2)} DH',
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(l10n.confirmDeleteExpense, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.expenseDeleted)),
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

  Widget _buildExpenseItem(BuildContext context, WidgetRef ref, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);
    
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
            color: primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: primaryBlue),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          DateFormat('HH:mm - yyyy/MM/dd').format(expense.date),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} DH',
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref, expense);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(l10n.edit),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 18),
                    ],
                  ),
                ),
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
          if (expense.note != null && expense.note!.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.note),
                content: Text(expense.note!),
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
}
