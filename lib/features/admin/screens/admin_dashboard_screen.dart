import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/features/admin/screens/accounts_screen.dart';
import 'package:gcoop/features/admin/providers/admin_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/shared/models/cooperative.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardContent(),
            const AccountsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'لوحة القيادة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'التدبير',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'إدارة التعاونيات',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.logout, color: AppColors.primary),
        onPressed: () async {
          await signOut(ref);
          if (mounted) context.go('/login');
        },
        tooltip: 'تسجيل الخروج',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.primary),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(recentCooperativesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildBigStatCard(),
          const SizedBox(height: 16),
          _buildSmallStatsGrid(),
          const SizedBox(height: 24),
          _buildRecentCooperativesHeader(),
          const SizedBox(height: 12),
          _buildRecentCooperativesList(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مرحباً، المدير العام 👋',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'نظرة عامة على نشاط اليوم',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStatCard() {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.hub, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي التعاونيات',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    '${stats['cooperatives']}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Text(
                'عرض الكل',
                style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildSmallStatsGrid() {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildSmallStatCard(
            'الفواتير',
            '${stats['invoices']}',
            Icons.receipt,
            Colors.red[800]!,
          ),
          _buildSmallStatCard(
            'مستخدم نشط',
            '${stats['profiles']}',
            Icons.people,
            Colors.grey[700]!,
          ),
          _buildSmallStatCard(
            'المنتجات',
            '${stats['products']}',
            Icons.inventory_2,
            Colors.blue[900]!,
          ),
          _buildSmallStatCard(
            'المبيعات',
            '${intl.NumberFormat('#,##0.00', 'en_US').format(stats['revenue'] as double)} DH',
            Icons.account_balance_wallet,
            Colors.green[700]!,
          ),
        ],
      ),
      loading: () => const SizedBox(height: 100),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCooperativesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'آخر التعاونيات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppColors.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildRecentCooperativesList() {
    final recentAsync = ref.watch(recentCooperativesProvider);

    return recentAsync.when(
      data: (coops) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: coops.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final coop = coops[index];
          return _buildCooperativeItem(coop);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildCooperativeItem(Cooperative coop) {
    final String initials = coop.name.length >= 2 
        ? coop.name.substring(0, 2).toUpperCase() 
        : coop.name.toUpperCase();
        
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coop.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  coop.address ?? 'بدون مدينة',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Text(
            'اليوم', 
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('تعديل')),
              const PopupMenuItem(child: Text('حذف')),
              const PopupMenuItem(child: Text('عرض')),
            ],
          ),
        ],
      ),
    );
  }
}
