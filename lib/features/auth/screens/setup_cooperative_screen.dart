import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SetupCooperativeScreen extends ConsumerStatefulWidget {
  const SetupCooperativeScreen({super.key});

  @override
  ConsumerState<SetupCooperativeScreen> createState() => _SetupCooperativeScreenState();
}

class _SetupCooperativeScreenState extends ConsumerState<SetupCooperativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameFrController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _iceController = TextEditingController();
  final _rcController = TextEditingController();
  
  File? _logoFile;
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFF1E3A8A);
  final Color _accentColor = const Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw 'المستخدم غير موجود (User not found)';

      // 1. رفع الشعار (Logo) إن وجد
      String? logoUrl;
      if (_logoFile != null) {
        final fileExt = _logoFile!.path.split('.').last;
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('company-logos').upload(
          fileName, _logoFile!,
          fileOptions: const FileOptions(upsert: true),
        );
        logoUrl = supabase.storage.from('company-logos').getPublicUrl(fileName);
      }

      // 2. إنشاء سجل التعاونية الجديد (INSERT)
      // نستخدم select() للحصول على البيانات المدخلة بما فيها الـ ID الجديد
      final newCoop = await supabase.from('cooperatives').insert({
        'name_ar': _nameArController.text,
        'name_fr': _nameFrController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'ice': _iceController.text,
        'rc': _rcController.text,
        if (logoUrl != null) 'logo_url': logoUrl,
      }).select().single();

      // التحقق من أننا حصلنا على ID
      if (newCoop['id'] == null) throw 'فشل في إنشاء التعاونية';
      
      final newCoopId = newCoop['id'];

      // 3. ربط البروفايل بالتعاونية الجديدة
      final profileError = await supabase.from('profiles').update({
        'cooperative_id': newCoopId,
      }).eq('id', user.id);

      // ملاحظة: update لا يرجع خطأ مباشرة إلا إذا استخدمنا try/catch حول العملية
      // لكن supabase_flutter يرمي exception تلقائياً عند الفشل

      // 4. تحديث المزودات (Providers)
      ref.invalidate(cooperativeProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(isCooperativeSetupCompleteProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعداد التعاونية بنجاح'), backgroundColor: Colors.green),
        );
        // التوجيه للصفحة الرئيسية
        context.go('/');
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إعداد التعاونية' : 'Configuration de la coopérative'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isAr ? 'أكمل معلومات تعاونيتك' : 'Complétez les informations de votre coopérative',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _logoFile != null 
                              ? FileImage(_logoFile!) 
                              : null,
                            child: _logoFile == null
                                ? Icon(Icons.business, size: 60, color: Colors.grey[400])
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton.small(
                              onPressed: _pickImage,
                              backgroundColor: _accentColor,
                              child: const Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr ? 'شعار التعاونية' : 'Logo de la coopérative',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _nameArController,
                      label: 'اسم التعاونية بالعربية',
                      required: true,
                      isRtl: true,
                    ),
                    _buildTextField(
                      controller: _nameFrController,
                      label: 'Nom de la coopérative en français',
                      required: true,
                      isRtl: false,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: isAr ? 'العنوان' : 'Adresse',
                      required: true,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: isAr ? 'الهاتف' : 'Téléphone',
                      required: true,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: isAr ? 'البريد الإلكتروني' : 'Email',
                      required: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _iceController,
                      label: 'ICE (Identifiant Commun de l\'Entreprise)',
                    ),
                    _buildTextField(
                      controller: _rcController,
                      label: 'RC (Registre du Commerce)',
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text(
                        isAr ? 'حفظ وإكمال' : 'Enregistrer et continuer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool isRtl = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        textDirection: isRtl ? TextDirection.rtl : null,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.isEmpty 
                ? (Localizations.localeOf(context).languageCode == 'ar' ? 'هذا الحقل مطلوب' : 'Ce champ est requis') 
                : null
            : null,
      ),
    );
  }
}