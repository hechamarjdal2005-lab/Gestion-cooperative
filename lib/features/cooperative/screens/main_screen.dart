import 'package:flutter/material.dart';
import 'package:gcoop/features/cooperative/screens/dashboard/dashboard_screen.dart';
import 'package:gcoop/features/cooperative/screens/documents/documents_screen.dart';
import 'package:gcoop/features/cooperative/screens/products/products_screen.dart';
import 'package:gcoop/features/cooperative/screens/expenses/expenses_screen.dart';
import 'package:gcoop/features/cooperative/screens/more/more_screen.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DocumentsScreen(),
    const ProductsScreen(),
    const ExpensesScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: l10n.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.description), label: l10n.invoices),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2), label: l10n.products),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: l10n.financials),
          BottomNavigationBarItem(icon: const Icon(Icons.more_horiz), label: l10n.more),
        ],
      ),
    );
  }
}
