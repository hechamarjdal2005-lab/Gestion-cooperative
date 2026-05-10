import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/cooperative/providers/expenses_provider.dart';
import 'package:gcoop/features/cooperative/screens/products/product_form_screen.dart';
import 'package:gcoop/features/cooperative/screens/documents/create_document_screen.dart';
import 'package:gcoop/features/cooperative/screens/expenses/add_expense_screen.dart';
import 'package:gcoop/features/cooperative/screens/clients/add_client_screen.dart';
import 'package:gcoop/shared/models/document.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/shared/models/cooperative.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Cooperative?> coopAsync = ref.watch(cooperativeProvider);
    final AsyncValue<List<AppDocument>> docsAsync = ref.watch(documentsProvider);
    final AsyncValue<List<Product>> productsAsync = ref.watch(productsProvider);
    final AsyncValue<List<Expense>> expensesAsync = ref.watch(expensesProvider);
    final l10n = AppLocalizations.of(context)!;

    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/logo.png', height: 40, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  switch (coopAsync) {
                    AsyncData(:final value) => Text(
                        '${l10n.welcome}، ${value?.nameAr ?? l10n.cooperative} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    AsyncError() => Text('${l10n.welcome} 👋', style: const TextStyle(color: Colors.white)),
                    _ => const Text('...', style: TextStyle(color: Colors.white)),
                  },
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'en_US').format(DateTime.now()),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid
                  _buildStatsGrid(context, docsAsync, productsAsync, expensesAsync),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions
                  Text(
                    l10n.quickActions,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionBtn(
                        label: l10n.newInvoice,
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateDocumentScreen())),
                      ),
                      _QuickActionBtn(
                        label: l10n.addProduct,
                        icon: Icons.add_box,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen())),
                      ),
                      _QuickActionBtn(
                        label: l10n.newExpense,
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen())),
                      ),
                      _QuickActionBtn(
                        label: l10n.newClient,
                        icon: Icons.person_add,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  Text(
                    l10n.lastOperations,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivity(context, docsAsync, expensesAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue<List<AppDocument>> docsAsync,
    AsyncValue<List<Product>> productsAsync,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        // Card 1: Transactions
        switch (docsAsync) {
          AsyncData(:final value) => (() {
              final today = DateTime.now();
              final todayTotal = value
                  .where((d) => d.type == 'FAC' && _isSameDay(d.date, today))
                  .fold(0.0, (sum, d) => sum + d.total);
              return _StatCard(
                label: l10n.dailySales,
                value: '${NumberFormat('#,##0', 'en_US').format(todayTotal)} DH',
                icon: Icons.trending_up,
                color: Colors.green,
                trend: '', 
                trendColor: Colors.green,
              );
            })(),
          AsyncError() => _StatCard(label: l10n.error, value: '0', icon: Icons.error, color: Colors.grey),
          _ => const _StatCardLoader(),
        },
        // Card 2: Stock
        switch (productsAsync) {
          AsyncData(:final value) => (() {
              final lowStock = value.where((p) => p.stock <= p.minStock).length;
              return _StatCard(
                label: l10n.inventory,
                value: '${value.length}',
                icon: Icons.inventory_2,
                color: Colors.orange,
                trend: '$lowStock ${l10n.lowStockAlerts}',
                trendColor: lowStock > 0 ? Colors.red : Colors.orange,
              );
            })(),
          AsyncError() => _StatCard(label: l10n.error, value: '0', icon: Icons.error, color: Colors.grey),
          _ => const _StatCardLoader(),
        },
        // Card 3: Invoices
        switch (docsAsync) {
          AsyncData(:final value) => (() {
              final todayCount = value.where((d) => d.type == 'FAC' && _isSameDay(d.date, DateTime.now())).length;
              return _StatCard(
                label: l10n.invoices,
                value: '$todayCount',
                icon: Icons.description,
                color: Colors.blue,
                trend: '',
                trendColor: Colors.blue,
              );
            })(),
          AsyncError() => _StatCard(label: l10n.error, value: '0', icon: Icons.error, color: Colors.grey),
          _ => const _StatCardLoader(),
        },
        // Card 4: Expenses
        switch (expensesAsync) {
          AsyncData(:final value) => (() {
              final todayTotal = value
                  .where((e) => _isSameDay(e.date, DateTime.now()))
                  .fold(0.0, (sum, e) => sum + e.amount);
              return _StatCard(
                label: l10n.expenses,
                value: '${NumberFormat('#,##0', 'en_US').format(todayTotal)} DH',
                icon: Icons.payments,
                color: Colors.red,
                trend: '',
                trendColor: Colors.red,
              );
            })(),
          AsyncError() => _StatCard(label: l10n.error, value: '0', icon: Icons.error, color: Colors.grey),
          _ => const _StatCardLoader(),
        },
      ],
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    AsyncValue<List<AppDocument>> docsAsync,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch ((docsAsync, expensesAsync)) {
      (AsyncData(value: final docs), AsyncData(value: final expenses)) => (() {
          final items = <_ActivityItem>[];
          for (var doc in docs.take(5)) {
            items.add(_ActivityItem(
              title: doc.typeLabel,
              subtitle: doc.clientName ?? l10n.unknown,
              amount: '${NumberFormat('#,##0.00', 'en_US').format(doc.total)} DH',
              date: doc.date,
              icon: Icons.description,
              color: Colors.blue,
            ));
          }
          for (var exp in expenses.take(5)) {
            items.add(_ActivityItem(
              title: exp.category,
              subtitle: exp.note ?? l10n.expenses,
              amount: '-${NumberFormat('#,##0.00', 'en_US').format(exp.amount)} DH',
              date: exp.date,
              icon: Icons.payments,
              color: Colors.red,
            ));
          }
          items.sort((a, b) => b.date.compareTo(a.date));
          final recentItems = items.take(6).toList();

          if (recentItems.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(l10n.noOperations)));
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = recentItems[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.color.withOpacity(0.1),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item.amount, style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: item.amount.startsWith('-') ? Colors.red : Colors.black
                      )),
                      Text(DateFormat('HH:mm', 'en_US').format(item.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          );
        })(),
      (AsyncError(), _) || (_, AsyncError()) => Text('${l10n.error} أثناء تحميل البيانات'),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final Color? trendColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text(trend!, style: TextStyle(color: trendColor ?? color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _StatCardLoader extends StatelessWidget {
  const _StatCardLoader();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String amount;
  final DateTime date;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
  });
}
