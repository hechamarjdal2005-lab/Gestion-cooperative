import 'package:flutter/material.dart';
import 'package:gcoop/features/cooperative/screens/dashboard/dashboard_screen.dart';
import 'package:gcoop/features/cooperative/screens/documents/documents_screen.dart';
import 'package:gcoop/features/cooperative/screens/products/products_screen.dart';
import 'package:gcoop/features/cooperative/screens/expenses/expenses_screen.dart';
import 'package:gcoop/features/cooperative/screens/more/more_screen.dart';
import 'package:gcoop/core/constants/colors.dart';

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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'المصاريف'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}
