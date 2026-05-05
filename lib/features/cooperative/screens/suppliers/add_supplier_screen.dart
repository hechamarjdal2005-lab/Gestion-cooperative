import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId == null) throw 'Cooperative not found';

      await Supabase.instance.client.from('suppliers').insert({
        'cooperative_id': profile!.cooperativeId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _companyController.text.trim(), // Use address field for company info or add it
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المورد بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مورد جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المورد'),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'الشركة / العنوان'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'الهاتف'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
