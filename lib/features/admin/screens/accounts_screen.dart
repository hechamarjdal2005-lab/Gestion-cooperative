import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/features/admin/providers/admin_provider.dart';
import 'package:gcoop/shared/models/cooperative.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final coopsAsync = ref.watch(allCooperativesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            _buildAddButton(),
            Expanded(
              child: coopsAsync.when(
                data: (coops) => _buildCooperativesList(coops),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: const Row(
        children: [
          Text(
            'إدارة التعاونيات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: () => _showAddCooperativeSheet(context),
          icon: const Icon(Icons.add_business),
          label: const Text(
            'إضافة تعاونية جديدة / إنشاء سجل تعاوني جديد في النظام',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCooperativesList(List<Cooperative> coops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة التعاونيات (${coops.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: coops.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coop = coops[index];
              return _buildCooperativeCard(coop);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCooperativeCard(Cooperative coop) {
    final String initials = coop.name.length >= 2 
        ? coop.name.substring(0, 2).toUpperCase() 
        : coop.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PopupMenuButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('تعديل')),
              const PopupMenuItem(child: Text('حذف')),
              const PopupMenuItem(child: Text('عرض التفاصيل')),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  coop.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      coop.address ?? 'غير محدد',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  ],
                ),
                Text(
                  coop.email ?? 'لا يوجد بريد إلكتروني',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100 * (coop.name.length % 9 + 1)],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCooperativeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AddCooperativeForm(),
      ),
    );
  }
}

class _AddCooperativeForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddCooperativeForm> createState() => _AddCooperativeFormState();
}

class _AddCooperativeFormState extends ConsumerState<_AddCooperativeForm> {
  final _formKey = GlobalKey<FormState>();
  final _coopNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-cooperative-user',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'fullName': _adminNameController.text.trim(),
          'cooperativeName': _coopNameController.text.trim(),
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ref.invalidate(allCooperativesProvider);
          ref.invalidate(adminStatsProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح'), backgroundColor: AppColors.success),
          );
        }
      } else {
        throw response.data['error'] ?? 'خطأ غير معروف';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إضافة تعاونية جديدة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              _buildTextField(_coopNameController, 'اسم التعاونية', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(_adminNameController, 'اسم المسؤول الكامل', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'كلمة المرور الأولية', Icons.lock, obscure: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        if (icon == Icons.email && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'البريد الإلكتروني غير صالح';
        }
        if (icon == Icons.lock && value.length < 8) {
          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
        }
        return null;
      },
    );
  }
}
