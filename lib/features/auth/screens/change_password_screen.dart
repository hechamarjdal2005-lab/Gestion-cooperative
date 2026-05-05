import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // 1. تغيير كلمة المرور
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      // 2. تحديث العلم فـ قاعدة البيانات
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').update({
          'must_change_password': false,
        }).eq('id', user.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تغيير كلمة المرور بنجاح. يرجى تسجيل الدخول مجدداً.'),
          backgroundColor: Colors.green,
        ),
      );

      // 3. تسجيل الخروج الإجباري (الحل السحري)
      // هذا كيخلي التطبيق ينسى الجلسة الحالية ويرجعك لصفحة الدخول
      await supabase.auth.signOut();
      
      // 4. مسح البيانات المخزنة محلياً (Providers)
      ref.invalidate(profileProvider);
      ref.invalidate(mustChangePasswordProvider);
      ref.invalidate(isCooperativeSetupCompleteProvider);

      if (!mounted) return;

      // 5. التوجيه لصفحة الدخول
      context.go('/login');

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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تغيير كلمة المرور' : 'Changer le mot de passe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  isAr 
                    ? 'يجب عليك تغيير كلمة المرور عند أول تسجيل دخول' 
                    : 'Vous devez changer votre mot de passe lors de votre première connexion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isAr ? 'كلمة المرور الجديدة' : 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return isAr ? 'يجب أن تتكون من 6 أحرف على الأقل' : 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isAr ? 'تأكيد كلمة المرور' : 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return isAr ? 'كلمات المرور غير متطابقة' : 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isAr ? 'حفظ وتسجيل الدخول' : 'Enregistrer et se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}