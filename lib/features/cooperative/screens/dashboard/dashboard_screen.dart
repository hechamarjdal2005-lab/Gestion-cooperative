import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(title: 'الفواتير', value: '24', icon: Icons.description, color: Colors.blue),
                StatCard(title: 'الإيرادات', value: '15,400', icon: Icons.monetization_on, color: Colors.green),
                StatCard(title: 'طلبات الشراء', value: '8', icon: Icons.shopping_cart, color: Colors.orange),
                StatCard(title: 'مخزون منخفض', value: '3', icon: Icons.warning, color: Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Text('الإحصائيات الشهرية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4),
                        FlSpot(5, 6),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('عمليات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(icon: Icons.receipt_long, label: 'فاتورة', color: Colors.blue, onTap: () {}),
                _QuickActionButton(icon: Icons.add_box, label: 'منتج', color: Colors.green, onTap: () {}),
                _QuickActionButton(icon: Icons.account_balance_wallet, label: 'مصروف', color: Colors.orange, onTap: () {}),
                _QuickActionButton(icon: Icons.person_add, label: 'زبون', color: Colors.purple, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
