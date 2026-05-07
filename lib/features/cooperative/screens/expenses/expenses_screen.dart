import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/cooperative/providers/incomes_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/shared/models/income.dart';
import 'package:gcoop/features/cooperative/screens/expenses/add_expense_screen.dart';
import 'package:gcoop/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1B2A6B);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            l10n.financials,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: l10n.expenses),
              Tab(text: l10n.incomes),
            ],
          ),
        ),
        body: Column(
          children: [
            const _PeriodTabsSection(),
            const _BalanceSummary(),
            const Expanded(
              child: TabBarView(
                children: [
                  _FilteredTransactionsList(isIncome: false),
                  _FilteredTransactionsList(isIncome: true),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(isIncome: tabIndex == 1),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PeriodTabsSection extends ConsumerWidget {
  const _PeriodTabsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(periodFilterProvider);
    final notifier = ref.read(periodFilterProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPeriodTab(ref, PeriodType.day, 'يوم'),
              _buildPeriodTab(ref, PeriodType.week, 'أسبوع'),
              _buildPeriodTab(ref, PeriodType.month, 'شهر'),
              _buildPeriodTab(ref, PeriodType.year, 'سنة'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF1B2A6B)),
                onPressed: () => _navigate(notifier, filter, -1),
              ),
              Text(
                _getPeriodLabel(filter.type, filter.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1B2A6B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF1B2A6B)),
                onPressed: () => _navigate(notifier, filter, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(WidgetRef ref, PeriodType type, String label) {
    final activeType = ref.watch(periodFilterProvider).type;
    final isActive = activeType == type;

    return GestureDetector(
      onTap: () => ref.read(periodFilterProvider.notifier).state = 
          ref.read(periodFilterProvider).copyWith(type: type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B2A6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _navigate(StateController<PeriodFilterState> notifier, PeriodFilterState state, int direction) {
    DateTime nextDate;
    switch (state.type) {
      case PeriodType.day:
        nextDate = state.date.add(Duration(days: direction));
        break;
      case PeriodType.week:
        nextDate = state.date.add(Duration(days: direction * 7));
        break;
      case PeriodType.month:
        nextDate = DateTime(state.date.year, state.date.month + direction, 1);
        break;
      case PeriodType.year:
        nextDate = DateTime(state.date.year + direction, 1, 1);
        break;
    }
    notifier.state = state.copyWith(date: nextDate);
  }

  String _getPeriodLabel(PeriodType type, DateTime date) {
    const months = {
      1: 'يناير', 2: 'فبراير', 3: 'مارس', 4: 'أبريل',
      5: 'مايو', 6: 'يونيو', 7: 'يوليوز', 8: 'غشت', 9: 'شتنبر',
      10: 'أكتوبر', 11: 'نونبر', 12: 'دجنبر'
    };

    switch (type) {
      case PeriodType.day:
        return "${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}";
      case PeriodType.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return "${start.day.toString().padLeft(2, '0')} ${months[start.month]} - ${end.day.toString().padLeft(2, '0')} ${months[end.month]}";
      case PeriodType.month:
        return "${months[date.month]} ${date.year}";
      case PeriodType.year:
        return "${date.year}";
    }
  }
}

class _BalanceSummary extends ConsumerWidget {
  const _BalanceSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(periodFilterProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);

    final expenses = expensesAsync.value ?? [];
    final incomes = incomesAsync.value ?? [];

    final filteredExpenses = _filterItems(expenses, filter);
    final filteredIncomes = _filterItems(incomes, filter);

    final totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = filteredIncomes.fold(0.0, (sum, e) => sum + e.amount);
    final netBalance = totalIncome - totalExpenses;
    final isPositive = netBalance >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              _buildSummaryItem(l10n.totalIncome, totalIncome, Colors.green, Icons.arrow_upward),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              _buildSummaryItem(l10n.totalExpenses, totalExpenses, Colors.red, Icons.arrow_downward),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.netBalance, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Row(
                children: [
                  Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '${netBalance.abs().toStringAsFixed(2)} DH',
                    style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
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
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} DH',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FilteredTransactionsList extends ConsumerWidget {
  final bool isIncome;
  const _FilteredTransactionsList({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(periodFilterProvider);
    final asyncValue = isIncome ? ref.watch(incomesProvider) : ref.watch(expensesProvider);

    return asyncValue.when(
      data: (items) {
        final filtered = _filterItems(items, filter);
        if (filtered.isEmpty) {
          return Center(child: Text(isIncome ? l10n.noIncomes : l10n.noExpenses));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildItem(context, ref, filtered[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, dynamic item) {
    final color = isIncome ? Colors.green : Colors.red;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(isIncome ? Icons.trending_up : Icons.shopping_bag_outlined, color: color),
        ),
        title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(_formatDateTime(item.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.amount.toStringAsFixed(2)} DH', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            _buildActions(context, ref, item),
          ],
        ),
        onTap: () {
          if (item.note != null && item.note!.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.note),
                content: Text(item.note!),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
              ),
            );
          }
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: item, isIncome: isIncome)));
        } else if (value == 'delete') {
          _showDeleteDialog(context, ref, item);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text(l10n.edit), const SizedBox(width: 8), const Icon(Icons.edit, size: 18)])),
        PopupMenuItem(value: 'delete', child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text(l10n.delete, style: const TextStyle(color: Colors.red)), const SizedBox(width: 8), const Icon(Icons.delete, size: 18, color: Colors.red)])),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(isIncome ? "هل تريد حذف هذا الدخل؟" : l10n.confirmDeleteExpense, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isIncome) {
                await ref.read(incomesProvider.notifier).deleteIncome(item.id);
              } else {
                await ref.read(expensesProvider.notifier).deleteExpense(item.id);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

List<dynamic> _filterItems(List<dynamic> items, PeriodFilterState filter) {
  return items.where((item) {
    final date = item.date;
    switch (filter.type) {
      case PeriodType.day:
        return date.year == filter.date.year && date.month == filter.date.month && date.day == filter.date.day;
      case PeriodType.week:
        final start = filter.date.subtract(Duration(days: filter.date.weekday - 1));
        final end = start.add(const Duration(days: 7));
        // Reset time for comparison
        final d = DateTime(date.year, date.month, date.day);
        final s = DateTime(start.year, start.month, start.day);
        final e = DateTime(end.year, end.month, end.day);
        return d.isAfter(s.subtract(const Duration(seconds: 1))) && d.isBefore(e);
      case PeriodType.month:
        return date.year == filter.date.year && date.month == filter.date.month;
      case PeriodType.year:
        return date.year == filter.date.year;
    }
  }).toList();
}
