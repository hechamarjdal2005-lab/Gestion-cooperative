import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/cooperative/providers/incomes_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/shared/models/income.dart';
import 'package:gcoop/features/cooperative/screens/expenses/add_expense_screen.dart';
import 'package:gcoop/features/cooperative/screens/expenses/income_screen.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            l10n.financials,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: l10n.expenses),
              Tab(text: l10n.incomes),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final currentTab = DefaultTabController.of(context).index;
                if (currentTab == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildBalanceSummary(context, expensesAsync, incomesAsync),
            const Expanded(
              child: TabBarView(
                children: [
                  _ExpensesList(),
                  IncomeScreen(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: primaryBlue,
            onPressed: () {
              final tabIndex = DefaultTabController.of(context).index;
              if (tabIndex == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
                );
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(
    BuildContext context,
    AsyncValue<List<Expense>> expensesAsync,
    AsyncValue<List<Income>> incomesAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final totalExpenses = switch (expensesAsync) {
      AsyncData(:final value) => value
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (sum, e) => sum + e.amount),
      _ => 0.0,
    };

    final totalIncome = switch (incomesAsync) {
      AsyncData(:final value) => value
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold(0.0, (sum, e) => sum + e.amount),
      _ => 0.0,
    };

    final netBalance = totalIncome - totalExpenses;
    final isPositive = netBalance >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                l10n.totalIncome,
                totalIncome,
                Colors.green,
                Icons.arrow_upward,
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              _buildSummaryItem(
                l10n.totalExpenses,
                totalExpenses,
                Colors.red,
                Icons.arrow_downward,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.netBalance,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    '${l10n.thisMonth} (${DateFormat('MMMM').format(now)})',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${netBalance.abs().toStringAsFixed(2)} DH',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} DH',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final l10n = AppLocalizations.of(context)!;

    return switch (expensesAsync) {
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
    };
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
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.red),
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
                color: Colors.red,
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: textAlignForLocale(context)),
        content: Text(l10n.confirmDeleteExpense, textAlign: textAlignForLocale(context)),
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

  TextAlign textAlignForLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar' ? TextAlign.right : TextAlign.left;
  }
}
